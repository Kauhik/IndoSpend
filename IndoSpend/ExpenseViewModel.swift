import Foundation
import Combine

class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var baseAmountSGD: Double = 0.0
    @Published var baseAmountIDR: Double = 0.0
    
    // Conversion rate: 1 SGD = 10500 IDR by default
    @Published var conversionRate: Double = 10500.0
    
    func addExpense(amount: Double, description: String, currency: Currency) {
        let expense = Expense(amount: amount, description: description, currency: currency)
        expenses.append(expense)
    }
    
    func updateExpense(expense: Expense, newAmount: Double, newDescription: String) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index].amount = newAmount
            expenses[index].description = newDescription
        }
    }
    
    func deleteExpense(expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }
    
    func totalSpent(currency: Currency) -> Double {
        expenses.filter { $0.currency == currency }.reduce(0) { $0 + $1.amount }
    }
    
    func remainingBalance(for currency: Currency) -> Double {
        switch currency {
        case .SGD:
            return baseAmountSGD - totalSpent(currency: .SGD)
        case .IDR:
            return baseAmountIDR - totalSpent(currency: .IDR)
        }
    }
    
    // Converts an SGD amount to IDR using the conversionRate
    func convertedAmount(sgdAmount: Double) -> Double {
        return sgdAmount * conversionRate
    }
}
