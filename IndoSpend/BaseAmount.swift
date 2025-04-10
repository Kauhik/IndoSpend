import Foundation
import SwiftData

@Model
final class BaseAmount {
    var id: UUID = UUID()
    var currency: Currency
    var amount: Double
    var label: String

    init(currency: Currency, amount: Double, label: String = "") {
        self.currency = currency
        self.amount = amount
        self.label = label
    }
}
