import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel = ExpenseViewModel()

    // Expenses query
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var expenses: [Expense]
    
    // BaseAmount query (all entries)
    @Query private var baseAmounts: [BaseAmount]
    
    @State private var selectedCurrency: Currency = .SGD
    
    // User-entered text fields for base amounts for new addition
    @State private var baseAmountSGDInput: String = ""
    @State private var baseAmountIDRInput: String = ""
    
    // Expense input fields
    @State private var amountInput: String = ""
    @State private var descriptionInput: String = ""
    
    @State private var showReceiptScanner = false
    @State private var showVoiceInput = false
    
    @FocusState private var isBaseAmountFocused: Bool
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isDescriptionFocused: Bool

    // Expense editing
    @State private var expenseToEdit: Expense? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Currency Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Currency")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Picker("Currency", selection: $selectedCurrency) {
                                Text("SGD").tag(Currency.SGD)
                                Text("IDR").tag(Currency.IDR)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        
                        // Base Amount Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Base Amount")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            HStack {
                                if selectedCurrency == .SGD {
                                    TextField("Enter amount", text: $baseAmountSGDInput)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        .focused($isBaseAmountFocused)
                                } else {
                                    TextField("Enter amount", text: $baseAmountIDRInput)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        .focused($isBaseAmountFocused)
                                }
                                
                                // Currency label becomes a navigation link that opens the base amount list.
                                NavigationLink(destination: BaseAmountListView(selectedCurrency: selectedCurrency)) {
                                    Text(selectedCurrency.rawValue)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .padding(.trailing, 8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Balance Card: Remaining balance is the sum of all base values minus expenses.
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remaining Balance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("\(remainingBalance, specifier: "%.2f")")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                
                                Text(selectedCurrency.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            
                            let ratio = calculateRatio()
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(progressColor(ratio: ratio))
                                        .frame(width: geometry.size.width * CGFloat(ratio), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Expenses List
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Expenses")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            let filteredExpenses = expenses.filter { $0.currency == selectedCurrency }
                            
                            if filteredExpenses.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    Text("No expenses yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredExpenses) { expense in
                                        HStack(spacing: 16) {
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Image(systemName: "creditcard")
                                                        .foregroundColor(.blue)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(expense.expenseDescription)
                                                    .font(.headline)
                                                Text(expense.date, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("-\(expense.amount, specifier: "%.2f")")
                                                .font(.system(.headline, design: .rounded))
                                                .foregroundColor(.red)
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                        .onTapGesture {
                                            expenseToEdit = expense
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        // Add Expense Section (for expenses; base amount additions are handled above)
                        VStack(spacing: 12) {
                            HStack {
                                TextField("Amount", text: $amountInput)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    .focused($isAmountFocused)
                                
                                Text(selectedCurrency.rawValue)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                            
                            TextField("Description", text: $descriptionInput)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                .padding(.horizontal)
                                .focused($isDescriptionFocused)
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    showReceiptScanner = true
                                }) {
                                    VStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 50, height: 50)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                        
                                        Text("Scan")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                NavigationLink(destination: SpendingChartView(selectedCurrency: selectedCurrency)) {
                                    Text("View Chart")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                
                                Button(action: {
                                    showVoiceInput = true
                                }) {
                                    VStack {
                                        Image(systemName: "mic.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 50, height: 50)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                        
                                        Text("Voice")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground).opacity(0.95))
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                        
                        Spacer()
                            .frame(height: 300)
                    }
                    .padding(.top)
                }
                
                // Floating Add Button (visible when any text field is focused)
                if isBaseAmountFocused || isAmountFocused || isDescriptionFocused {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                // Add new base amount if the base amount field is focused.
                                if selectedCurrency == .SGD {
                                    if let newValue = Double(baseAmountSGDInput), !baseAmountSGDInput.isEmpty {
                                        let newBase = BaseAmount(currency: .SGD, amount: newValue)
                                        modelContext.insert(newBase)
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Error saving new base amount: \(error)")
                                        }
                                        // Refresh the text field with the updated total.
                                        baseAmountSGDInput = String(baseSGD)
                                    }
                                } else {
                                    if let newValue = Double(baseAmountIDRInput), !baseAmountIDRInput.isEmpty {
                                        let newBase = BaseAmount(currency: .IDR, amount: newValue)
                                        modelContext.insert(newBase)
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Error saving new base amount: \(error)")
                                        }
                                        baseAmountIDRInput = String(baseIDR)
                                    }
                                }
                                
                                // Add expense if expense inputs are provided.
                                if let amount = Double(amountInput), !descriptionInput.isEmpty {
                                    viewModel.addExpense(
                                        amount: amount,
                                        expenseDescription: descriptionInput,
                                        currency: selectedCurrency
                                    )
                                    amountInput = ""
                                    descriptionInput = ""
                                }
                                
                                // Dismiss keyboards.
                                isBaseAmountFocused = false
                                isAmountFocused = false
                                isDescriptionFocused = false
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add")
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                                .shadow(radius: 5)
                            }
                            .padding()
                        }
                        .padding(.bottom, 10)
                    }
                }
            }
            .navigationTitle("IndoSpend")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isBaseAmountFocused = false
                            isAmountFocused = false
                            isDescriptionFocused = false
                        }
                    }
                }
            }
            .sheet(isPresented: $showReceiptScanner) {
                ReceiptScannerView { recognizedAmount, recognizedDescription in
                    viewModel.addExpense(amount: recognizedAmount,
                                         expenseDescription: recognizedDescription,
                                         currency: selectedCurrency)
                }
            }
            .sheet(isPresented: $showVoiceInput) {
                VoiceInputView { spokenAmount, spokenDescription in
                    viewModel.addExpense(amount: spokenAmount,
                                         expenseDescription: spokenDescription,
                                         currency: selectedCurrency)
                }
            }
            .sheet(item: $expenseToEdit) { expense in
                ExpenseEditView(
                    expense: expense,
                    onSave: { newAmount, newExpenseDescription in
                        viewModel.updateExpense(
                            expense: expense,
                            newAmount: newAmount,
                            newExpenseDescription: newExpenseDescription
                        )
                        expenseToEdit = nil
                    },
                    onDelete: {
                        viewModel.deleteExpense(expense: expense)
                        expenseToEdit = nil
                    }
                )
            }
        }
        // When the view appears, set the text fields to display the current summed base amount.
        .onAppear {
            viewModel.setContext(modelContext)
            baseAmountSGDInput = String(baseSGD)
            baseAmountIDRInput = String(baseIDR)
        }
        // Update the text field when the selected currency changes.
        .onChange(of: selectedCurrency) { newValue in
            if newValue == .SGD {
                baseAmountSGDInput = String(baseSGD)
            } else {
                baseAmountIDRInput = String(baseIDR)
            }
        }
        // Observe changes in the underlying baseAmounts so that the text field updates dynamically.
        .onChange(of: baseAmounts) { _ in
            if !isBaseAmountFocused {
                if selectedCurrency == .SGD {
                    baseAmountSGDInput = String(baseSGD)
                } else {
                    baseAmountIDRInput = String(baseIDR)
                }
            }
        }
    }
    
    // MARK: - Computed base amounts (summing entries for each currency)
    private var baseSGD: Double {
        baseAmounts.filter { $0.currency == .SGD }.reduce(0) { $0 + $1.amount }
    }
    
    private var baseIDR: Double {
        baseAmounts.filter { $0.currency == .IDR }.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Balances
    private var remainingBalance: Double {
        let base = (selectedCurrency == .SGD) ? baseSGD : baseIDR
        let spent = totalSpent(currency: selectedCurrency)
        return base - spent
    }
    
    private func totalSpent(currency: Currency) -> Double {
        expenses.filter { $0.currency == currency }.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateRatio() -> Double {
        let base = (selectedCurrency == .SGD) ? baseSGD : baseIDR
        return base > 0 ? min(max(remainingBalance / base, 0), 1) : 1.0
    }
    
    private func progressColor(ratio: Double) -> Color {
        if ratio > 0.5 {
            return Color.green
        } else if ratio > 0.2 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
    
    func backgroundColor() -> Color {
        let ratio = calculateRatio()
        if ratio > 0.5 {
            return Color.green.opacity(0.1)
        } else if ratio > 0.2 {
            return Color.yellow.opacity(0.1)
        } else {
            return Color.red.opacity(0.1)
        }
    }
}

// MARK: - RoundedCorner helper (remains unchanged)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
