import Foundation

@MainActor
enum PriceFormatter {
    private static let usdFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = "USD"
        return formatter
    }()

    static func usd(_ value: Double) -> String {
        usdFormatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    static func discount(_ rate: Double) -> String {
        "-\(Int(rate.rounded()))%"
    }
}
