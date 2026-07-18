import SwiftUI

struct ContentView: View {
    @State private var viewModel = BioharvestViewModel()
    @State private var exportTask: Task<Void, Never>?
    @State private var selectedPreset: ExportWindowPreset?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                backgroundLayer

                ScrollView {
                    VStack(spacing: BioharvestTheme.sectionSpacing) {
                        BioharvestHeroHeader(
                            dayCount: viewModel.exportWindow.dayCount,
                            enabledMetricCount: enabledMetricCount
                        )

                        if viewModel.showPermissionBanner {
                            BioharvestAlertBanner(
                                title: "Health Permissions Denied",
                                message: "Enable read access in the Health app to harvest your data.",
                                icon: "heart.text.square.fill",
                                tint: .red,
                                actionTitle: "Open Health App",
                                action: {
                                    HapticFeedback.lightTap()
                                    viewModel.openHealthSettings()
                                }
                            )
                        }

                        exportWindowCard
                        metricsCard
                        transmitCard

                        if viewModel.hasLastReport {
                            BioharvestSecondaryButton(
                                title: "View Last Report",
                                icon: "doc.text.magnifyingglass"
                            ) {
                                HapticFeedback.lightTap()
                                viewModel.viewLastReport()
                            }
                        }

                        Color.clear.frame(height: 160)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                floatingActionBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("bioharvest")
                        .font(.headline)
                        .foregroundStyle(.clear)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(BioharvestTheme.harvestGreen)
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showExportReport) {
                ExportReportView(viewModel: viewModel)
            }
            .alert(
                viewModel.exportAlert?.title ?? "Export Error",
                isPresented: Binding(
                    get: { viewModel.exportAlert != nil },
                    set: { if !$0 { viewModel.dismissExportAlert() } }
                )
            ) {
                if viewModel.exportAlert?.retryable == true {
                    Button("Retry") {
                        HapticFeedback.lightTap()
                        viewModel.dismissExportAlert()
                        startExport { await viewModel.retryLastOperation() }
                    }
                }
                Button("OK", role: .cancel) {
                    viewModel.dismissExportAlert()
                }
            } message: {
                Text(viewModel.exportAlert?.message ?? "")
            }
            .overlay {
                if let progress = viewModel.exportProgress {
                    ExportProgressOverlay(progress: progress) {
                        HapticFeedback.softTap()
                        exportTask?.cancel()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.exportProgress?.fraction)
            .onChange(of: viewModel.metricInclusion) { _, inclusion in
                inclusion.save()
            }
            .onAppear {
                HapticFeedback.prepare()
                syncSelectedPreset()
            }
            .onChange(of: viewModel.exportWindow) { _, _ in
                syncSelectedPreset()
            }
        }
    }

    // MARK: - Sections

    private var exportWindowCard: some View {
        BioharvestCard(title: "Export Window", icon: "calendar", accent: BioharvestTheme.duskTeal) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ExportWindowPreset.allCases) { preset in
                        PresetChip(
                            title: preset.rawValue,
                            isSelected: selectedPreset == preset
                        ) {
                            HapticFeedback.lightTap()
                            selectedPreset = preset
                            viewModel.applyPreset(preset)
                        }
                    }
                }
            }

            VStack(spacing: 4) {
                DatePicker(
                    "Start",
                    selection: Binding(
                        get: { viewModel.exportWindow.start },
                        set: { viewModel.updateExportStart($0) }
                    ),
                    displayedComponents: .date
                )
                DatePicker(
                    "End",
                    selection: Binding(
                        get: { viewModel.exportWindow.end },
                        set: { viewModel.updateExportEnd($0) }
                    ),
                    displayedComponents: .date
                )
            }
            .datePickerStyle(.compact)

            HStack {
                Label(
                    "\(viewModel.exportWindow.dayCount) day\(viewModel.exportWindow.dayCount == 1 ? "" : "s") selected",
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Reset") {
                    HapticFeedback.lightTap()
                    viewModel.resetWindowToDefault()
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(BioharvestTheme.harvestGreen)
            }

            if !viewModel.windowIsValid {
                Label("End must be on or after start", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BioharvestTheme.harvestGreen)
                    .frame(width: 28, height: 28)
                    .background(BioharvestTheme.harvestGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                Text("Metric Visibility")
                    .font(.headline)
                Spacer()
                Text("\(enabledMetricCount) on")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(MetricCategory.allCases) { category in
                    MetricCategorySection(
                        category: category,
                        coverage: viewModel.metricCoverage,
                        inclusion: $viewModel.metricInclusion
                    )
                }
            }
        }
    }

    private var transmitCard: some View {
        BioharvestCard(title: "Transmit", icon: "antenna.radiowaves.left.and.right", accent: BioharvestTheme.duskTeal) {
            if !viewModel.hasWebhookURL {
                BioharvestAlertBanner(
                    title: "No Webhook",
                    message: "Add a webhook URL in Settings to transmit to your agent.",
                    icon: "link.badge.plus",
                    tint: .orange
                )
            }

            BioharvestSecondaryButton(
                title: "Transmit to Agent",
                icon: "arrow.up.circle.fill",
                isDisabled: viewModel.isExporting || !viewModel.windowIsValid || !viewModel.hasWebhookURL
            ) {
                HapticFeedback.lightTap()
                startExport { await viewModel.transmitToAgent() }
            }

            if let statusText = viewModel.transmissionStatus.displayText {
                HStack {
                    transmissionIndicator
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor(for: viewModel.transmissionStatus))
                }
            }
        }
    }

    @ViewBuilder
    private var transmissionIndicator: some View {
        switch viewModel.transmissionStatus {
        case .transmitting:
            ProgressView()
                .controlSize(.small)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        case .idle:
            EmptyView()
        }
    }

    private var floatingActionBar: some View {
        VStack(spacing: 10) {
            BioharvestPrimaryButton(
                title: "Send to Coach",
                icon: "paperplane.fill",
                gradient: BioharvestTheme.coachButtonGradient,
                isDisabled: viewModel.isExporting || !viewModel.windowIsValid
            ) {
                HapticFeedback.lightTap()
                startExport { await viewModel.sendToCoach() }
            }

            BioharvestSecondaryButton(
                title: "Generate Report",
                icon: "doc.text.fill",
                isDisabled: viewModel.isExporting || !viewModel.windowIsValid
            ) {
                HapticFeedback.lightTap()
                startExport { await viewModel.generateReport() }
            }
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

    private var backgroundLayer: some View {
        ZStack {
            Color(.systemGroupedBackground)
            BioharvestTheme.surfaceGradient
                .ignoresSafeArea()
        }
    }

    // MARK: - Helpers

    private var enabledMetricCount: Int {
        MetricKey.allCases.filter { $0.isEnabled(in: viewModel.metricInclusion) }.count
    }

    private func syncSelectedPreset() {
        selectedPreset = ExportWindowPreset.allCases.first { preset in
            preset.makeWindow() == viewModel.exportWindow
        }
    }

    private func startExport(_ operation: @escaping () async -> Void) {
        exportTask?.cancel()
        exportTask = Task {
            await operation()
        }
    }

    private func statusColor(for status: TransmissionStatus) -> Color {
        switch status {
        case .success: return .green
        case .failed: return .red
        default: return .secondary
        }
    }
}

extension ExportAlert {
    var title: String {
        switch self {
        case .failed(let title, _, _): return title
        }
    }

    var message: String {
        switch self {
        case .failed(_, let message, _): return message
        }
    }

    var retryable: Bool {
        switch self {
        case .failed(_, _, let retryable): return retryable
        }
    }
}

#Preview {
    ContentView()
}
