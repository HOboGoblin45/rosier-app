import SwiftUI

/// Sheet view displaying upcoming retail sales with a clean calendar interface.
/// Shows sale dates, retailer info, and number of matching items in the user's Dresser.
struct SaleCalendarView: View {
    @Bindable var viewModel: SaleCalendarViewModel
    @Environment(\.dismiss) var dismiss

    @State private var displayedMonth = Date()
    @State private var selectedEvent: SaleEvent?

    private var calendar: Calendar {
        Calendar.current
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Text("Sale Calendar")
                                .styleTitleLarge()
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 44, height: 44)
                            }
                        }

                        // Month navigation
                        HStack {
                            Button(action: previousMonth) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.brandAccent)
                                    .frame(width: 44, height: 44)
                            }

                            Text(monthString)
                                .styleBodyBold()
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity)

                            Button(action: nextMonth) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.brandAccent)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .padding(16)

                    Divider()

                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Calendar grid
                            calendarGrid()

                            Divider()
                                .padding(.vertical, 8)

                            // Upcoming events
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Sales")
                                    .styleTitleMedium()
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal, 16)

                                if viewModel.upcomingEvents().isEmpty {
                                    HStack(spacing: 12) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.textTertiary)

                                        Text("No upcoming sales scheduled")
                                            .styleCaption()
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(viewModel.upcomingEvents()) { event in
                                            SaleEventCard(
                                                event: event,
                                                onNotificationToggle: {
                                                    viewModel.toggleNotification(for: event)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }

                            Spacer()
                                .frame(height: 12)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
        }
    }

    // MARK: - Calendar Grid

    @ViewBuilder
    private func calendarGrid() -> some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .styleMicro()
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)

            // Calendar days
            let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
            let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
            let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30

            let gridItems = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

            LazyVGrid(columns: gridItems, spacing: 8) {
                // Empty cells for days before month starts
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Text("")
                        .frame(height: 44)
                }

                // Days of month
                let datesWithSales = viewModel.datesWithSalesInMonth(calendar.dateComponents([.year, .month], from: displayedMonth))

                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) ?? Date()
                    let hasSale = datesWithSales.contains(day)
                    let isToday = calendar.isDateInToday(date)
                    let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate ?? Date())

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectDate(date)
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    isSelected ? Color.brandAccent.opacity(0.2) :
                                    isToday ? Color.brandAccent.opacity(0.05) :
                                    Color.surfaceCard
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            isSelected ? Color.brandAccent : Color.clear,
                                            lineWidth: 2
                                        )
                                )

                            // Day number
                            Text("\(day)")
                                .styleCaption()
                                .foregroundColor(.textPrimary)

                            // Sale indicator dot
                            if hasSale {
                                Circle()
                                    .fill(Color.saleRed)
                                    .frame(width: 5, height: 5)
                                    .padding(6)
                            }
                        }
                        .frame(height: 44)
                    }
                    .disabled(isToday && calendar.isDateInToday(date))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helper Methods

    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? Date()
        }
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? Date()
        }
    }
}

// MARK: - Sale Event Card

struct SaleEventCard: View {
    let event: SaleEvent
    var onNotificationToggle: () -> Void

    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startStr = formatter.string(from: event.startDate)
        let endStr = formatter.string(from: event.endDate)

        return "\(startStr) – \(endStr)"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Retailer logo placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.surfaceCard)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(event.retailerName.prefix(2).uppercased())
                            .styleMicro()
                            .fontWeight(.semibold)
                            .foregroundColor(.brandAccent)
                    )

                // Event info
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.saleName)
                        .styleCaption()
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                        Text(dateRange)
                            .styleMicro()
                    }
                    .foregroundColor(.textSecondary)

                    if event.itemCountInDresser > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("\(event.itemCountInDresser) items in your Dresser")
                                .styleMicro()
                        }
                        .foregroundColor(.successGreen)
                    }
                }

                Spacer()

                // Notification toggle
                Button(action: onNotificationToggle) {
                    Image(systemName: event.isNotificationEnabled ? "bell.fill" : "bell")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(event.isNotificationEnabled ? .brandAccent : .textTertiary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(12)
            .background(Color.surfaceCard)
            .cornerRadius(8)

            // Discount badge
            if let discount = event.discountPercent {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Up to \(discount)% off")
                        .styleMicro()
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.saleRed,
                            Color.saleRed.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SaleCalendarView(viewModel: SaleCalendarViewModel())
        .preferredColorScheme(.light)
}
