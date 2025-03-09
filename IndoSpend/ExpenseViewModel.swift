import Foundation
import SwiftData
import SwiftUI

class ExpenseViewModel: ObservableObject {
    // If you had a conversion rate or other logic, keep it here.
    @Published var conversionRate: Double = 10500.0

    private var modelContext: ModelContext?

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Expense CRUD
    func addExpense(amount: Double, expenseDescription: String, currency: Currency) {
        guard let context = modelContext else { return }
        let expense = Expense(amount: amount, expenseDescription: expenseDescription, currency: currency)
        context.insert(expense)
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }
    }
    
    func updateExpense(expense: Expense, newAmount: Double, newExpenseDescription: String) {
        expense.amount = newAmount
        expense.expenseDescription = newExpenseDescription
        do {
            try modelContext?.save()
        } catch {
            print("Update save error: \(error)")
        }
    }
    
    func deleteExpense(expense: Expense) {
        modelContext?.delete(expense)
        do {
            try modelContext?.save()
        } catch {
            print("Delete save error: \(error)")
        }
    }
}
