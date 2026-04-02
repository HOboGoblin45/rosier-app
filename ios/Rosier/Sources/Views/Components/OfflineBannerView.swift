import SwiftUI
import Network

/// Reusable offline banner that slides down from the top when the device loses internet.
/// Automatically dismisses when connectivity is restored.
struct OfflineBannerView: View {
    @State private var isOffline = false
    @State private var monitor: NWPathMonitor?
    @State private var monitorQueue = DispatchQueue(label: "com.rosier.monitor")

    var body: some View {
        VStack(spacing: 0) {
            if isOffline {
                offlineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    @ViewBuilder
    private func offlineBanner() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text("You're Offline")
                    .styleCaption()
                    .fontWeight(.semibold)

                Text("Showing saved items")
                    .styleMicro()
                    .opacity(0.8)
            }

            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .opacity(0.6)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
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
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isOffline = false
            }
        }
    }

    private func startMonitoring() {
        let monitor = NWPathMonitor()

        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isOffline = path.status != .satisfied
                }
            }
        }

        monitor.start(queue: monitorQueue)
        self.monitor = monitor
    }

    private func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
}

// MARK: - Preview

#Preview {
    VStack {
        OfflineBannerView()
            .background(Color.surfaceBackground)

        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<10, id: \.self) { i in
                    HStack {
                        Circle()
                            .fill(Color.brandAccent.opacity(0.2))
                            .frame(width: 50, height: 50)

                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.textTertiary.opacity(0.2))
                                .frame(height: 10)
                                .frame(maxWidth: 150)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.textTertiary.opacity(0.1))
                                .frame(height: 8)
                                .frame(maxWidth: 100)
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
        }

        Spacer()
    }
    .background(Color.surfaceBackground)
    .preferredColorScheme(.light)
}
