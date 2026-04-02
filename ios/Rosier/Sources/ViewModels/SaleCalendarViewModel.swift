import Foundation
import SwiftUI


/// Represents a known sale event from a retailer.
struct SaleEvent: Identifiable, Hashable {
    let id = UUID()
    let retailerId: UUID
    let retailerName: String
    let saleName: String
    let startDate: Date
    let endDate: Date
    let discountPercent: Int?
    var isNotificationEnabled: Bool = false

    /// Number of items in user's dresser from this retailer.
    var itemCountInDresser: Int = 0

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SaleEvent, rhs: SaleEvent) -> Bool {
        lhs.id == rhs.id
    }
}

/// ViewModel managing sale events and calendar data.
@Observable final class SaleCalendarViewModel {
    // MARK: - Properties

    var saleEvents: [SaleEvent] = []
    var filteredEvents: [SaleEvent] = []
    var selectedDate: Date?
    var selectedRetailer: UUID?
    var isLoading = false
    var error: String?

    private let networkService = NetworkService.shared
    private let calendar = Calendar.current

    // MARK: - Initializers

    init() {
        loadSaleEvents()
    }

    // MARK: - Public Methods

    /// Loads all known sale events for the upcoming year.
    func loadSaleEvents() {
        isLoading = true
        error = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.saleEvents = Self.knownSaleEvents()
            self.filterEvents()
            self.isLoading = false
        }
    }

    /// Toggles notification for a specific sale event.
    /// - Parameter event: The sale event to toggle
    func toggleNotification(for event: SaleEvent) {
        if let index = saleEvents.firstIndex(where: { $0.id == event.id }) {
            saleEvents[index].isNotificationEnabled.toggle()

            // TODO: Persist this preference to user defaults or backend
            if saleEvents[index].isNotificationEnabled {
                scheduleNotification(for: saleEvents[index])
            } else {
                cancelNotification(for: saleEvents[index])
            }
        }
    }

    /// Filters events by selected date or retailer.
    func filterEvents() {
        var filtered = saleEvents

        if let selectedDate = selectedDate {
            filtered = filtered.filter { event in
                calendar.isDate(selectedDate, inSameDayAs: event.startDate)
                    || (selectedDate >= event.startDate && selectedDate <= event.endDate)
            }
        }

        if let selectedRetailer = selectedRetailer {
            filtered = filtered.filter { $0.retailerId == selectedRetailer }
        }

        filteredEvents = filtered.sorted { $0.startDate < $1.startDate }
    }

    /// Selects a specific date in the calendar.
    /// - Parameter date: The date to select
    func selectDate(_ date: Date) {
        selectedDate = calendar.isDateInToday(date) ? nil : date
        filterEvents()
    }

    /// Resets all filters.
    func resetFilters() {
        selectedDate = nil
        selectedRetailer = nil
        filterEvents()
    }

    /// Returns all dates with sales for a given month.
    /// - Parameter dateComponents: The month and year to query
    /// - Returns: Set of day integers (1-31)
    func datesWithSalesInMonth(_ dateComponents: DateComponents) -> Set<Int> {
        guard let monthStart = calendar.date(from: dateComponents),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)
        else {
            return []
        }

        var datesWithSales = Set<Int>()

        for event in saleEvents {
            if event.startDate <= monthEnd && event.endDate >= monthStart {
                // Event overlaps with this month
                let eventStart = max(event.startDate, monthStart)
                let eventEnd = min(event.endDate, monthEnd)

                let startDay = calendar.component(.day, from: eventStart)
                let endDay = calendar.component(.day, from: eventEnd)

                for day in startDay...endDay {
                    datesWithSales.insert(day)
                }
            }
        }

        return datesWithSales
    }

    /// Gets events for a specific date.
    /// - Parameter date: The date to query
    /// - Returns: Array of events on that date
    func eventsForDate(_ date: Date) -> [SaleEvent] {
        saleEvents.filter { event in
            date >= event.startDate && date <= event.endDate
        }
        .sorted { $0.startDate < $1.startDate }
    }

    /// Gets upcoming events within the next N days.
    /// - Parameter days: Number of days to look ahead (default: 30)
    /// - Returns: Array of upcoming events
    func upcomingEvents(within days: Int = 30) -> [SaleEvent] {
        let endDate = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()

        return saleEvents.filter { event in
            event.startDate <= endDate && event.endDate >= Date()
        }
        .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Private Methods

    private func scheduleNotification(for event: SaleEvent) {
        // TODO: Implement push notification scheduling
        // For now, this is a placeholder
        print("Scheduled notification for \(event.saleName)")
    }

    private func cancelNotification(for event: SaleEvent) {
        // TODO: Implement push notification cancellation
        // For now, this is a placeholder
        print("Cancelled notification for \(event.saleName)")
    }

    // MARK: - Static Known Sale Events

    /// Returns a hardcoded list of known retail sale events.
    static func knownSaleEvents() -> [SaleEvent] {
        let now = Date()
        let calendar = Calendar.current

        let thisYear = calendar.component(.year, from: now)
        let thisMonth = calendar.component(.month, from: now)

        var events: [SaleEvent] = []

        // Helper function to create dates
        func createDate(year: Int, month: Int, day: Int) -> Date {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            return calendar.date(from: components) ?? now
        }

        // SSENSE Private Sale - Semi-annual (May/November)
        if thisMonth <= 5 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "SSENSE",
                saleName: "SSENSE Spring Sale",
                startDate: createDate(year: thisYear, month: 5, day: 1),
                endDate: createDate(year: thisYear, month: 5, day: 31),
                discountPercent: 50,
                itemCountInDresser: 3
            ))
        }

        if thisMonth <= 11 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "SSENSE",
                saleName: "SSENSE Autumn Sale",
                startDate: createDate(year: thisYear, month: 11, day: 1),
                endDate: createDate(year: thisYear, month: 11, day: 30),
                discountPercent: 50,
                itemCountInDresser: 1
            ))
        }

        // Farfetch Seasonal Sales (June/December)
        if thisMonth <= 6 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "Farfetch",
                saleName: "Farfetch Summer Sale",
                startDate: createDate(year: thisYear, month: 6, day: 15),
                endDate: createDate(year: thisYear, month: 6, day: 30),
                discountPercent: 40,
                itemCountInDresser: 2
            ))
        }

        if thisMonth <= 12 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "Farfetch",
                saleName: "Farfetch Year-End Sale",
                startDate: createDate(year: thisYear, month: 12, day: 15),
                endDate: createDate(year: thisYear, month: 12, day: 31),
                discountPercent: 45,
                itemCountInDresser: 0
            ))
        }

        // END Clothing Sales (June/January)
        if thisMonth <= 6 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "END Clothing",
                saleName: "END Summer Sale",
                startDate: createDate(year: thisYear, month: 6, day: 10),
                endDate: createDate(year: thisYear, month: 7, day: 5),
                discountPercent: 40,
                itemCountInDresser: 4
            ))
        }

        // Mytheresa Seasonal Sales (June/December)
        if thisMonth <= 6 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "Mytheresa",
                saleName: "Mytheresa Summer Sale",
                startDate: createDate(year: thisYear, month: 6, day: 1),
                endDate: createDate(year: thisYear, month: 6, day: 30),
                discountPercent: 50,
                itemCountInDresser: 2
            ))
        }

        if thisMonth <= 12 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "Mytheresa",
                saleName: "Mytheresa Winter Sale",
                startDate: createDate(year: thisYear, month: 12, day: 15),
                endDate: createDate(year: thisYear + 1, month: 1, day: 31),
                discountPercent: 50,
                itemCountInDresser: 0
            ))
        }

        // NET-A-PORTER Seasonal Sales (June/December)
        if thisMonth <= 6 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "NET-A-PORTER",
                saleName: "NET-A-PORTER Summer Sale",
                startDate: createDate(year: thisYear, month: 6, day: 18),
                endDate: createDate(year: thisYear, month: 7, day: 9),
                discountPercent: 50,
                itemCountInDresser: 5
            ))
        }

        if thisMonth <= 12 {
            events.append(SaleEvent(
                retailerId: UUID(),
                retailerName: "NET-A-PORTER",
                saleName: "NET-A-PORTER Winter Sale",
                startDate: createDate(year: thisYear, month: 12, day: 20),
                endDate: createDate(year: thisYear + 1, month: 1, day: 30),
                discountPercent: 50,
                itemCountInDresser: 0
            ))
        }

        return events.sorted { $0.startDate < $1.startDate }
    }
}
