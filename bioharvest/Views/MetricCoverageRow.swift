import SwiftUI

struct MetricCoverageRow: View {
    let coverage: MetricCoverage

    private var fraction: Double {
        guard coverage.totalDays > 0 else { return 0 }
        return Double(coverage.daysWithData) / Double(coverage.totalDays)
    }

    private var barColor: Color {
        if !coverage.hasAnyData { return Color(.tertiaryLabel) }
        if fraction >= 0.75 { return BioharvestTheme.harvestGreen }
        if fraction >= 0.4 { return .orange }
        return .red.opacity(0.8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: coverage.key.category.icon)
                    .font(.caption)
                    .foregroundStyle(coverage.key.category.accent)
                    .frame(width: 20)

                Text(coverage.displayName)
                    .font(.subheadline)

                Spacer()

                Text(coverage.summaryText)
                    .foregroundStyle(coverage.hasAnyData ? .secondary : .tertiary)
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 4)

                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * fraction, height: 4)
                        .animation(.spring(duration: 0.5), value: fraction)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricCoverageRow(
            coverage: MetricCoverage(
                key: .hrv,
                displayName: "HRV",
                daysWithData: 6,
                totalDays: 7
            )
        )
        MetricCoverageRow(
            coverage: MetricCoverage(
                key: .proteinG,
                displayName: "Protein",
                daysWithData: 0,
                totalDays: 7
            )
        )
    }
    .padding()
}
