import SwiftUI

// MARK: - Hero Header

struct BioharvestHeroHeader: View {
    let dayCount: Int
    let enabledMetricCount: Int
    @State private var leafPulse = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(BioharvestTheme.leafMint)
                            .symbolEffect(.pulse, options: .repeating, value: leafPulse)
                            .onAppear { leafPulse = true }

                        Text("bioharvest")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("Harvest your Health data for Coach")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(dayCount)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text(dayCount == 1 ? "day" : "days")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                    Text("\(enabledMetricCount) metrics")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(20)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius, style: .continuous))
        .shadow(color: BioharvestTheme.forestDeep.opacity(0.25), radius: 12, y: 6)
    }

    @ViewBuilder
    private var heroBackground: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.55, 0.45], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    BioharvestTheme.forestDeep,
                    BioharvestTheme.harvestGreen,
                    BioharvestTheme.duskTeal,
                    BioharvestTheme.harvestGreen.opacity(0.8),
                    BioharvestTheme.leafMint.opacity(0.6),
                    BioharvestTheme.forestDeep,
                    BioharvestTheme.duskTeal,
                    BioharvestTheme.harvestGreen,
                    BioharvestTheme.forestDeep.opacity(0.9)
                ]
            )
        } else {
            BioharvestTheme.heroGradient
        }
    }
}

// MARK: - Cards

struct BioharvestCard<Content: View>: View {
    let title: String?
    let icon: String?
    let accent: Color
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        icon: String? = nil,
        accent: Color = BioharvestTheme.harvestGreen,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accent = accent
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(accent)
                            .frame(width: 28, height: 28)
                            .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    }
                    Text(title)
                        .font(.headline)
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Preset Chips

struct PresetChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule().fill(BioharvestTheme.primaryButtonGradient)
                    } else {
                        Capsule().fill(Color(.tertiarySystemFill))
                    }
                }
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
}

// MARK: - Primary Buttons

struct BioharvestPrimaryButton: View {
    let title: String
    let icon: String
    var gradient: LinearGradient = BioharvestTheme.primaryButtonGradient
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.45 : 1)
        .disabled(isDisabled)
    }
}

struct BioharvestSecondaryButton: View {
    let title: String
    let icon: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.45 : 1)
        .disabled(isDisabled)
    }
}

// MARK: - Alert Banner

struct BioharvestAlertBanner: View {
    let title: String
    let message: String
    let icon: String
    let tint: Color
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(tint)
                        .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Collapsible Category

struct MetricCategorySection: View {
    let category: MetricCategory
    let coverage: [MetricCoverage]
    @Binding var inclusion: MetricInclusion
    @State private var isExpanded = true

    private var enabledCount: Int {
        category.metrics.filter { $0.key.isEnabled(in: inclusion) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.25)) {
                    isExpanded.toggle()
                }
                HapticFeedback.lightTap()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(category.accent)
                        .frame(width: 30, height: 30)
                        .background(category.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                    Text(category.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(enabledCount)/\(category.metrics.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.tertiarySystemFill), in: Capsule())

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.leading, 54)

                VStack(spacing: 0) {
                    ForEach(category.metrics, id: \.key) { metric in
                        metricRow(metric.key, title: metric.title)
                        if metric.key != category.metrics.last?.key {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func metricRow(_ key: MetricKey, title: String) -> some View {
        Toggle(isOn: binding(for: key)) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                if let hint = inclusion.coverageHint(for: key, in: coverage) {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: category.accent))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .sensoryFeedback(.selection, trigger: key.isEnabled(in: inclusion))
    }

    private func binding(for key: MetricKey) -> Binding<Bool> {
        Binding(
            get: { key.isEnabled(in: inclusion) },
            set: { newValue in
                key.setEnabled(newValue, in: &inclusion)
            }
        )
    }
}

// MARK: - Coverage Ring

struct CoverageRingView: View {
    let filled: Int
    let total: Int
    var lineWidth: CGFloat = 8

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(filled) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: [BioharvestTheme.leafMint, BioharvestTheme.harvestGreen, BioharvestTheme.forestDeep],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: fraction)

            VStack(spacing: 0) {
                Text("\(filled)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                Text("of \(total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Status Pill

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: Capsule())
        .foregroundStyle(color)
    }
}
