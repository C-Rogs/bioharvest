import SwiftUI

struct ExportProgressOverlay: View {
    let progress: ExportProgress
    var onCancel: (() -> Void)?
    @State private var elapsedSeconds = 0
    @State private var ringPulse = false
    private let elapsedTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.3))

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 6)
                        .frame(width: 72, height: 72)

                    Circle()
                        .trim(from: 0, to: progress.fraction)
                        .stroke(
                            AngularGradient(
                                colors: [BioharvestTheme.leafMint, BioharvestTheme.harvestGreen, BioharvestTheme.forestDeep],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.4), value: progress.fraction)

                    Image(systemName: phaseIcon)
                        .font(.title3)
                        .foregroundStyle(BioharvestTheme.harvestGreen)
                        .symbolEffect(.pulse, options: .repeating, value: ringPulse)
                }

                VStack(spacing: 6) {
                    Text(progress.phase)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)

                    Text("\(Int((progress.fraction * 100).rounded()))%")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(BioharvestTheme.harvestGreen)
                        .contentTransition(.numericText())
                }

                if elapsedSeconds >= 30 {
                    Label(formattedElapsed, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                if let onCancel {
                    Button("Cancel", role: .cancel, action: onCancel)
                        .font(.subheadline.weight(.medium))
                        .padding(.top, 4)
                }
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: BioharvestTheme.forestDeep.opacity(0.2), radius: 24, y: 12)
        }
        .onReceive(elapsedTimer) { _ in
            elapsedSeconds += 1
        }
        .onAppear {
            elapsedSeconds = 0
            ringPulse = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.phase) \(Int((progress.fraction * 100).rounded())) percent")
    }

    private var phaseIcon: String {
        let phase = progress.phase.lowercased()
        if phase.contains("transmit") { return "antenna.radiowaves.left.and.right" }
        if phase.contains("access") || phase.contains("permission") { return "heart.text.square" }
        if phase.contains("complete") { return "checkmark" }
        return "leaf.fill"
    }

    private var formattedElapsed: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "Still working… %d:%02d", minutes, seconds)
    }
}

#Preview {
    ExportProgressOverlay(
        progress: ExportProgress.fetchingMetric("sleep", completed: 3, total: 12),
        onCancel: {}
    )
}
