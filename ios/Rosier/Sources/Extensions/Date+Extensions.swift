import Foundation

extension Date {
    // MARK: - Date Formatting

    /// Formats the date as a short date string (e.g., "Mar 15, 2026").
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Formats the date as a long date string (e.g., "Monday, March 15, 2026").
    var longDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Formats the date as a time string (e.g., "2:45 PM").
    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Formats the date as a relative string (e.g., "2 hours ago").
    var relativeString: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: now)

        if let year = components.year, year > 0 {
            return "\(year)y ago"
        } else if let month = components.month, month > 0 {
            return "\(month)mo ago"
        } else if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        }

        return "now"
    }

    // MARK: - Date Calculation

    /// Returns a date by adding days to this date.
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Returns a date by adding hours to this date.
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Returns a date by adding minutes to this date.
    func addingMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// Checks if this date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Checks if this date is tomorrow.
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Checks if this date is yesterday.
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Checks if this date is in the past.
    var isPast: Bool {
        self < Date()
    }

    /// Checks if this date is in the future.
    var isFuture: Bool {
        self > Date()
    }

    // MARK: - Date Components

    /// Gets the beginning of the day.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Gets the end of the day.
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Gets the beginning of the month.
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Gets the end of the month.
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    /// Gets the beginning of the week.
    var startOfWeek: Date {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Gets the end of the week.
    var endOfWeek: Date {
        var components = DateComponents()
        components.day = 7
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek) ?? self
    }

    // MARK: - Date Comparison

    /// Checks if this date is in the same day as another date.
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    /// Calculates the number of days between this date and another.
    func daysSince(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: self)
        return components.day ?? 0
    }

    /// Calculates the number of hours between this date and another.
    func hoursSince(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: date, to: self)
        return components.hour ?? 0
    }

    // MARK: - Formatting for Display

    /// Formats the date as "Sale ends in X days".
    func saleEndingString() -> String {
        let daysRemaining = daysSince(Date())

        if daysRemaining <= 0 {
            return "Sale ended"
        } else if daysRemaining == 1 {
            return "Ends tomorrow"
        } else if daysRemaining <= 7 {
            return "Ends in \(daysRemaining) days"
        } else {
            return "Ends \(shortDateString)"
        }
    }

    /// Formats the date for social sharing.
    func shareDateString() -> String {
        let now = Date()

        if isSameDay(as: now) {
            return "Today at \(shortTimeString)"
        } else if isSameDay(as: now.addingDays(-1)) {
            return "Yesterday at \(shortTimeString)"
        } else if daysSince(now) <= 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            return shortDateString
        }
    }
}
