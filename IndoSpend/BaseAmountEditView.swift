import SwiftUI
import SwiftData

struct BaseAmountEditView: View {
    @Environment(\.presentationMode) var presentationMode
    let baseAmount: BaseAmount
    @State private var amount: String
    @State private var label: String

    init(baseAmount: BaseAmount) {
        self.baseAmount = baseAmount
        _amount = State(initialValue: String(format: "%.2f", baseAmount.amount))
        _label = State(initialValue: baseAmount.label)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Label (optional)")) {
                    TextField("Label", text: $label)
                }
                Section {
                    Button("Delete Base Amount") {
                        if let context = baseAmount.modelContext {
                            context.delete(baseAmount)
                            do {
                                try context.save()
                            } catch {
                                print("Error deleting base amount: \(error)")
                            }
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Base Amount")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let newAmount = Double(amount) {
                            baseAmount.amount = newAmount
                            baseAmount.label = label
                            if let context = baseAmount.modelContext {
                                do {
                                    try context.save()
                                } catch {
                                    print("Error saving edit: \(error)")
                                }
                            }
                        }
                        presentationMode.wrappedValue.dismiss()
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

struct BaseAmountEditView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, using a dummy BaseAmount. In production this is provided via SwiftData context.
        let dummy = BaseAmount(currency: .SGD, amount: 100.0, label: "Primary")
        return BaseAmountEditView(baseAmount: dummy)
    }
}
