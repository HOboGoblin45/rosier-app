import Foundation

extension Decimal {
    // MARK: - Currency Formatting

    /// Formats the decimal as a currency string in USD (e.g., "$29.99").
    var usdString: String {
        currencyString(currency: "USD", locale: Locale(identifier: "en_US"))
    }

    /// Formats the decimal as a currency string in the specified currency.
    func currencyString(currency: String, locale: Locale = Locale.current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = locale

        return formatter.string(from: self as NSDecimalNumber) ?? "$\(self)"
    }

    /// Formats the decimal as a compact currency string (e.g., "$2.9K", "$1.2M").
    var compactCurrencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.usesGroupingSeparator = true

        let value = abs(NSDecimalNumber(decimal: self).doubleValue)

        if value >= 1_000_000 {
            let millions = value / 1_000_000
            return "$\(String(format: "%.1f", millions))M"
        } else if value >= 1_000 {
            let thousands = value / 1_000
            return "$\(String(format: "%.1f", thousands))K"
        } else {
            return formatter.string(from: self as NSDecimalNumber) ?? "$\(self)"
        }
    }

    // MARK: - Price Range Formatting

    /// Formats two decimals as a price range (e.g., "$29.99 - $99.99").
    static func priceRange(_ min: Decimal, _ max: Decimal) -> String {
        "\(min.usdString) - \(max.usdString)"
    }

    // MARK: - Discount Calculation

    /// Calculates the discount percentage between original and current price.
    static func discountPercentage(original: Decimal, current: Decimal) -> Int {
        guard original > 0 else { return 0 }

        let discount = ((original - current) / original) * 100
        return NSDecimalNumber(decimal: discount).rounding(accordingToBehavior: nil).intValue
    }

    /// Formats the discount as a string (e.g., "Save 25%").
    static func discountString(original: Decimal, current: Decimal) -> String {
        let percentage = discountPercentage(original: original, current: current)

        if percentage > 0 {
            return "Save \(percentage)%"
        }

        return ""
    }

    // MARK: - Price Comparison

    /// Checks if the current price is on sale compared to the original price.
    func isOnSale(originalPrice: Decimal) -> Bool {
        self < originalPrice
    }

    /// Calculates the savings amount.
    func savingsAmount(originalPrice: Decimal) -> Decimal {
        max(0, originalPrice - self)
    }

    // MARK: - Rounding

    /// Rounds the decimal to the nearest cent.
    func roundedToCent() -> Decimal {
        let handler = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 2,
            raiseOnExactness: false,
            raiseOnOverflow: true,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: true
        )

        let rounded = (self as NSDecimalNumber).rounding(accordingToBehavior: handler)
        return rounded as Decimal
    }

    /// Rounds the decimal to a specific number of decimal places.
    func rounded(to places: Int) -> Decimal {
        let handler = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: Int16(places),
            raiseOnExactness: false,
            raiseOnOverflow: true,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: true
        )

        let rounded = (self as NSDecimalNumber).rounding(accordingToBehavior: handler)
        return rounded as Decimal
    }

    // MARK: - Arithmetic

    /// Adds a percentage to the decimal (useful for calculating tax).
    func addingPercentage(_ percentage: Decimal) -> Decimal {
        self + (self * (percentage / 100))
    }

    /// Subtracts a percentage from the decimal (useful for discounts).
    func subtractingPercentage(_ percentage: Decimal) -> Decimal {
        self - (self * (percentage / 100))
    }

    // MARK: - Formatting for Display

    /// Formats as a short price string without currency symbol (e.g., "29.99").
    var shortPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }

    /// Formats as a whole number price (e.g., "$30").
    var wholeNumberPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        return formatter.string(from: self as NSDecimalNumber) ?? "$\(self)"
    }

    // MARK: - Price Bracket Classification

    /// Classifies the price into a budget category.
    enum PriceBracket {
        case budget      // < $50
        case affordable  // $50-$150
        case moderate    // $150-$500
        case premium     // $500-$1,500
        case luxury      // > $1,500

        var displayName: String {
            switch self {
            case .budget:
                return "Budget"
            case .affordable:
                return "Affordable"
            case .moderate:
                return "Moderate"
            case .premium:
                return "Premium"
            case .luxury:
                return "Luxury"
            }
        }
    }

    /// Determines the price bracket for this price.
    var bracket: PriceBracket {
        let doubleValue = NSDecimalNumber(decimal: self).doubleValue

        switch doubleValue {
        case 0..<50:
            return .budget
        case 50..<150:
            return .affordable
        case 150..<500:
            return .moderate
        case 500..<1500:
            return .premium
        default:
            return .luxury
        }
    }

    // MARK: - Localized Formatting

    /// Formats the decimal with locale-specific currency formatting.
    func localizedCurrencyString(locale: Locale = Locale.current) -> String {
        guard let currencyCode = locale.currencyCode else {
            return usdString
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale

        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
}
