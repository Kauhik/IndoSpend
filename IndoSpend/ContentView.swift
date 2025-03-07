import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ExpenseViewModel()
    @State private var selectedCurrency: Currency = .SGD
    @State private var amountInput: String = ""
    @State private var descriptionInput: String = ""
    @State private var baseAmountInput: String = ""
    
    @State private var showReceiptScanner = false
    @State private var showVoiceInput = false

    var body: some View {
        NavigationView {
            VStack {
                // Picker for currency tracker
                Picker("Currency", selection: $selectedCurrency) {
                    Text("SGD").tag(Currency.SGD)
                    Text("IDR").tag(Currency.IDR)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Input for base amount (only for the selected tracker)
                HStack {
                    Text("Base Amount (\(selectedCurrency.rawValue)):")
                    TextField("Enter amount", text: $baseAmountInput, onCommit: {
                        if let amount = Double(baseAmountInput) {
                            if selectedCurrency == .SGD {
                                viewModel.baseAmountSGD = amount
                                // Optionally, update the IDR base using conversion
                                viewModel.baseAmountIDR = viewModel.convertedAmount(sgdAmount: amount)
                            } else {
                                viewModel.baseAmountIDR = amount
                            }
                        }
                    })
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Remaining balance display
                HStack {
                    Text("Remaining Balance:")
                    Spacer()
                    Text("\(viewModel.remainingBalance(for: selectedCurrency), specifier: "%.2f") \(selectedCurrency.rawValue)")
                }
                .padding()
                
                // List of expenses for the selected currency
                List {
                    ForEach(viewModel.expenses.filter { $0.currency == selectedCurrency }) { expense in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "creditcard") // SF Symbol icon
                                Text(expense.description)
                            }
                            Text("Amount: \(expense.amount, specifier: "%.2f") \(selectedCurrency.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(expense.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // New expense input area
                VStack {
                    TextField("Expense Amount", text: $amountInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    TextField("Description", text: $descriptionInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Button(action: {
                            // Add expense manually
                            if let amount = Double(amountInput), !descriptionInput.isEmpty {
                                viewModel.addExpense(amount: amount, description: descriptionInput, currency: selectedCurrency)
                                amountInput = ""
                                descriptionInput = ""
                            }
                        }) {
                            Text("Add Expense")
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Present receipt scanner
                            showReceiptScanner = true
                        }) {
                            Image(systemName: "camera")
                                .font(.title)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Present voice input view
                            showVoiceInput = true
                        }) {
                            Image(systemName: "mic")
                                .font(.title)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("IndoSpend")
            .background(backgroundColor().ignoresSafeArea())
            // Present the receipt scanner as a sheet
            .sheet(isPresented: $showReceiptScanner) {
                ReceiptScannerView { recognizedAmount, recognizedDescription in
                    viewModel.addExpense(amount: recognizedAmount, description: recognizedDescription, currency: selectedCurrency)
                }
            }
            // Present the voice input view as a sheet
            .sheet(isPresented: $showVoiceInput) {
                VoiceInputView { spokenAmount, spokenDescription in
                    viewModel.addExpense(amount: spokenAmount, description: spokenDescription, currency: selectedCurrency)
                }
            }
        }
    }
    
    // Adjusts the background color based on how much balance is left
    func backgroundColor() -> Color {
        let remaining = viewModel.remainingBalance(for: selectedCurrency)
        let base: Double = (selectedCurrency == .SGD ? viewModel.baseAmountSGD : viewModel.baseAmountIDR)
        let ratio = base > 0 ? remaining / base : 1.0
        
        if ratio > 0.5 {
            return Color.green.opacity(0.2)
        } else if ratio > 0.2 {
            return Color.yellow.opacity(0.2)
        } else {
            return Color.red.opacity(0.2)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
