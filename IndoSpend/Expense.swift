import Foundation

enum Currency: String, Codable {
    case SGD, IDR
}

struct Expense: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var description: String
    var date: Date = Date()
    var currency: Currency
}
