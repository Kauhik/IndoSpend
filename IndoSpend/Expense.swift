import Foundation
import SwiftData

enum Currency: String, Codable {
    case SGD, IDR
}

@Model
final class Expense {
    var id: UUID = UUID()
    var amount: Double
    var expenseDescription: String
    var date: Date = Date()
    var currency: Currency

    init(amount: Double, expenseDescription: String, date: Date = Date(), currency: Currency) {
        self.amount = amount
        self.expenseDescription = expenseDescription
        self.date = date
        self.currency = currency
    }
}
