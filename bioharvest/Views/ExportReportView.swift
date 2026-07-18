import SwiftUI

struct ExportReportView: View {
    @Bindable var viewModel: BioharvestViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var expandedDays: Set<String> = []
    @State private var showHideEmptyBanner = true
    @State private var coachError: String?

    private var payload: ExportPayload? { viewModel.lastExportPayload }
    private var coverage: [MetricCoverage] { viewModel.metricCoverage }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: BioharvestTheme.sectionSpacing) {
                        headerSection
                        coverageSection
                        if showHideEmptyBanner, !emptyMetrics.isEmpty {
                            hideEmptyBanner
                        }
                        dailySection
                        Color.clear.frame(height: 120)
                    }
                    .padding()
                }

                actionBar
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticFeedback.lightTap()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.exportFileURL,
                   let data = viewModel.lastExportData {
                    ShareSheet(items: [
                        BioharvestCoachExportItemSource(fileURL: url, jsonData: data)
                    ]) { activityType, completed in
                        guard completed, CoachHandoff.isCoachShareActivity(activityType) else { return }
                        CoachHandoff.openCoachApp()
                    }
                }
            }
            .alert("Coach Handoff Error", isPresented: Binding(
                get: { coachError != nil },
                set: { if !$0 { coachError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(coachError ?? "")
            }
            .overlay(alignment: .top) {
                if viewModel.showCopiedBanner {
                    copiedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: viewModel.showCopiedBanner)
        }
    }

    private var emptyMetrics: [MetricCoverage] {
        MetricCoverage.emptyMetrics(in: coverage)
    }

    private var copiedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(BioharvestTheme.harvestGreen)
            Text("Copied to clipboard")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.top, 8)
        .task(id: viewModel.showCopiedBanner) {
            guard viewModel.showCopiedBanner else { return }
            try? await Task.sleep(for: .seconds(2))
            viewModel.showCopiedBanner = false
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        if let payload {
            BioharvestCard(title: "Summary", icon: "chart.bar.doc.horizontal", accent: BioharvestTheme.harvestGreen) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(payload.exportRange.startDate) – \(payload.exportRange.endDate)")
                            .font(.headline)

                        HStack(spacing: 12) {
                            Label(
                                "\(payload.logs.count) day\(payload.logs.count == 1 ? "" : "s")",
                                systemImage: "calendar"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        healthKitBadge(payload.healthKitStatus)
                    }

                    Spacer()

                    if !coverage.isEmpty {
                        CoverageRingView(
                            filled: MetricCoverage.metricsWithDataCount(in: coverage),
                            total: coverage.count,
                            lineWidth: 6
                        )
                        .frame(width: 72, height: 72)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var coverageSection: some View {
        if !coverage.isEmpty {
            BioharvestCard(title: "Coverage", icon: "chart.bar.fill", accent: BioharvestTheme.duskTeal) {
                let withData = MetricCoverage.metricsWithDataCount(in: coverage)
                Text("\(withData) of \(coverage.count) metrics had data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 14) {
                    ForEach(coverage) { item in
                        MetricCoverageRow(coverage: item)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var hideEmptyBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "eye.slash")
                .foregroundStyle(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 10) {
                Text("Hide \(emptyMetrics.count) metric\(emptyMetrics.count == 1 ? "" : "s") with no data?")
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 10) {
                    Button("Hide") {
                        HapticFeedback.lightTap()
                        viewModel.hideEmptyMetrics()
                        showHideEmptyBanner = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(BioharvestTheme.harvestGreen)

                    Button("Keep") {
                        HapticFeedback.softTap()
                        showHideEmptyBanner = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var dailySection: some View {
        if let logs = payload?.logs, !logs.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(BioharvestTheme.harvestGreen)
                    Text("Daily Breakdown")
                        .font(.headline)
                }

                ForEach(logs, id: \.date) { log in
                    dayCard(log)
                }
            }
        }
    }

    private func dayCard(_ log: DailyLog) -> some View {
        let isExpanded = expandedDays.contains(log.date)
        let rowCount = dayMetricRows(for: log).count

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.25)) {
                    HapticFeedback.lightTap()
                    if isExpanded {
                        expandedDays.remove(log.date)
                    } else {
                        expandedDays.insert(log.date)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedDate(log.date))
                            .font(.subheadline.weight(.semibold))
                        if rowCount > 0 {
                            Text("\(rowCount) metric\(rowCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 14)
                dayMetrics(log)
                    .padding(14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BioharvestTheme.cardCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func dayMetrics(_ log: DailyLog) -> some View {
        let rows = dayMetricRows(for: log)
        if rows.isEmpty {
            Text("No data this period")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows, id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(row.value)
                            .font(.subheadline.monospacedDigit().weight(.medium))
                            .foregroundStyle(row.value == "No data" ? .tertiary : .primary)
                    }
                    .font(.caption)
                }
            }
        }
    }

    private struct DayMetricRow {
        let label: String
        let value: String
    }

    private func dayMetricRows(for log: DailyLog) -> [DayMetricRow] {
        var rows: [DayMetricRow] = []
        let inclusion = viewModel.metricInclusion

        if inclusion.hrvToday {
            rows.append(metricRow("HRV", log.cnsAndCardio.hrvSdnn.map { String(format: "%.2f ms", $0.value) }))
        }
        if inclusion.rhrToday {
            rows.append(metricRow("RHR", log.cnsAndCardio.restingHeartRate.map { String(format: "%.2f bpm", $0.value) }))
        }
        if inclusion.sleepTotal {
            rows.append(metricRow("Sleep", log.sleepAndRecovery.sleepTotalMinutes.map { String(format: "%.2f min", $0.value) }))
        }
        if inclusion.sleepDeep {
            rows.append(metricRow("Deep Sleep", log.sleepAndRecovery.deepSleepMinutes.map { String(format: "%.2f min", $0.value) }))
        }
        if inclusion.sleepREM {
            rows.append(metricRow("REM Sleep", log.sleepAndRecovery.remSleepMinutes.map { String(format: "%.2f min", $0.value) }))
        }
        if inclusion.weight {
            rows.append(metricRow("Weight", log.bodyComposition.bodyWeightKg.map { String(format: "%.2f kg", $0.value) }))
        }
        if inclusion.bodyFat {
            rows.append(metricRow("Body Fat", log.bodyComposition.bodyFatPercent.map { String(format: "%.2f%%", $0.value) }))
        }
        if inclusion.stepCount {
            rows.append(metricRow("Steps", log.activityAndStrain.stepCount.map { "\($0)" }))
        }
        if inclusion.activeEnergy {
            rows.append(metricRow("Active Energy", log.activityAndStrain.activeEnergyKcal.map { String(format: "%.2f kcal", $0.value) }))
        }
        if inclusion.restingEnergy {
            rows.append(metricRow("Resting Energy", log.activityAndStrain.restingEnergyKcal.map { String(format: "%.2f kcal", $0.value) }))
        }
        if inclusion.exerciseMinutes {
            rows.append(metricRow("Exercise", log.activityAndStrain.exerciseMinutes.map { String(format: "%.2f min", $0.value) }))
        }
        if inclusion.trainingLoad {
            rows.append(metricRow("Training Load", log.activityAndStrain.trainingLoadContribution.map { String(format: "%.2f", $0.value) }))
        }
        if inclusion.workouts {
            let count = log.activityAndStrain.workouts.count
            rows.append(metricRow("Workouts", count > 0 ? "\(count)" : nil))
        }
        if inclusion.caloriesConsumed {
            rows.append(metricRow("Calories", log.nutritionAndToxicity.caloriesConsumedKcal.map { String(format: "%.2f kcal", $0.value) }))
        }
        if inclusion.proteinG {
            rows.append(metricRow("Protein", log.nutritionAndToxicity.proteinG.map { String(format: "%.2f g", $0.value) }))
        }
        if inclusion.carbsG {
            rows.append(metricRow("Carbs", log.nutritionAndToxicity.carbsG.map { String(format: "%.2f g", $0.value) }))
        }
        if inclusion.fatG {
            rows.append(metricRow("Fat", log.nutritionAndToxicity.fatG.map { String(format: "%.2f g", $0.value) }))
        }
        if inclusion.waterLiters {
            rows.append(metricRow("Water", log.nutritionAndToxicity.waterLiters.map { String(format: "%.2f L", $0.value) }))
        }
        if inclusion.alcoholicBeveragesCount {
            rows.append(metricRow("Alcohol", log.nutritionAndToxicity.alcoholicBeveragesCount.map { "\($0)" }))
        }

        return rows
    }

    private func metricRow(_ label: String, _ value: String?) -> DayMetricRow {
        DayMetricRow(label: label, value: value ?? "No data")
    }

    private func formattedDate(_ isoDate: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: isoDate) else { return isoDate }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .none
        return display.string(from: date)
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    HapticFeedback.lightTap()
                    viewModel.copyJSONToClipboard()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.lastExportJSON == nil)

                Button {
                    HapticFeedback.lightTap()
                    viewModel.presentShareSheet()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(BioharvestTheme.primaryButtonGradient, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canShare)
            }

            Button {
                HapticFeedback.lightTap()
                do {
                    try viewModel.sendToCoachFromReport()
                } catch let error as CoachHandoff.CoachHandoffError {
                    HapticFeedback.error()
                    coachError = error.errorDescription
                } catch {
                    HapticFeedback.error()
                    coachError = error.localizedDescription
                }
            } label: {
                Label("Send to Coach", systemImage: "paperplane.fill")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.lastExportData == nil)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        }
    }

    @ViewBuilder
    private func healthKitBadge(_ status: HealthKitStatus) -> some View {
        let (text, color): (String, Color) = {
            switch status {
            case .liveAuthorized: return ("Health data connected", BioharvestTheme.harvestGreen)
            case .denied: return ("Health permissions denied", .red)
            case .notDetermined: return ("Health permissions pending", .orange)
            case .unavailable: return ("HealthKit unavailable", .secondary)
            case .error: return ("HealthKit error", .red)
            }
        }()
        StatusPill(text: text, color: color)
    }
}
