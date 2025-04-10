import SwiftUI
import SwiftData

struct BaseAmountListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var baseAmounts: [BaseAmount]
    
    let selectedCurrency: Currency
    
    @State private var showBaseAmountEdit: BaseAmount?
    @State private var newBaseAmountInput: String = ""
    @State private var newBaseAmountLabelInput: String = ""
    
    var body: some View {
        VStack {
            List {
                ForEach(baseAmounts.filter { $0.currency == selectedCurrency }) { baseAmount in
                    HStack {
                        if baseAmount.label.isEmpty {
                            Text("\(baseAmount.amount, specifier: "%.2f")")
                        } else {
                            VStack(alignment: .leading) {
                                Text(baseAmount.label)
                                    .font(.headline)
                                Text("\(baseAmount.amount, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showBaseAmountEdit = baseAmount
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            Divider()
            
            HStack {
                TextField("Amount", text: $newBaseAmountInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Label (optional)", text: $newBaseAmountLabelInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    if let value = Double(newBaseAmountInput) {
                        let newEntry = BaseAmount(currency: selectedCurrency, amount: value, label: newBaseAmountLabelInput)
                        modelContext.insert(newEntry)
                        do {
                            try modelContext.save()
                        } catch {
                            print("Error saving base amount: \(error)")
                        }
                        newBaseAmountInput = ""
                        newBaseAmountLabelInput = ""
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("\(selectedCurrency.rawValue) Base Amounts")
        .sheet(item: $showBaseAmountEdit) { baseAmount in
            BaseAmountEditView(baseAmount: baseAmount)
        }
    }
}

struct BaseAmountListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BaseAmountListView(selectedCurrency: .SGD)
        }
    }
}
