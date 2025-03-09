import Foundation
import SwiftData

@Model
final class BaseAmount {
    var id: UUID = UUID()
    var currency: Currency
    var amount: Double

    init(currency: Currency, amount: Double) {
        self.currency = currency
        self.amount = amount
    }
}
