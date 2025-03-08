import SwiftUI

struct ExpenseEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var amount: String
    @State var description: String
    let expense: Expense
    let onSave: (Double, String) -> Void
    let onDelete: () -> Void

    init(expense: Expense, onSave: @escaping (Double, String) -> Void, onDelete: @escaping () -> Void) {
        self.expense = expense
        self.onSave = onSave
        self.onDelete = onDelete
        _amount = State(initialValue: String(expense.amount))
        _description = State(initialValue: expense.description)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Description")) {
                    TextField("Description", text: $description)
                }
                Section {
                    Button("Delete Expense") {
                        onDelete()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Expense")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let newAmount = Double(amount) {
                            onSave(newAmount, description)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ExpenseEditView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseEditView(expense: Expense(amount: 10.0, description: "Sample", currency: .SGD),
                        onSave: { _, _ in },
                        onDelete: {})
    }
}
