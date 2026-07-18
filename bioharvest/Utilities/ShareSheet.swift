import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Presents JSON for Share extensions (Coach) with explicit `public.json` / plain-text types,
/// while still offering a named `.json` file URL for Save to Files and similar targets.
final class BioharvestCoachExportItemSource: NSObject, UIActivityItemSource {
    let fileURL: URL
    let jsonData: Data

    init(fileURL: URL, jsonData: Data) {
        self.fileURL = fileURL
        self.jsonData = jsonData
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        jsonData
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        if prefersFileURL(for: activityType) {
            return fileURL
        }
        return makeItemProvider()
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        "bioharvest coach export"
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        prefersFileURL(for: activityType) ? UTType.fileURL.identifier : UTType.json.identifier
    }

    private func prefersFileURL(for activityType: UIActivity.ActivityType?) -> Bool {
        guard let raw = activityType?.rawValue else { return false }
        return raw.contains("DocumentManager") || raw.contains("CloudDocs") || raw.contains("SaveToFiles")
    }

    private func makeItemProvider() -> NSItemProvider {
        let provider = NSItemProvider()
        provider.suggestedName = fileURL.lastPathComponent

        provider.registerDataRepresentation(
            forTypeIdentifier: UTType.json.identifier,
            visibility: .all
        ) { [jsonData] completion in
            completion(jsonData, nil)
            return nil
        }

        provider.registerDataRepresentation(
            forTypeIdentifier: UTType.plainText.identifier,
            visibility: .all
        ) { [jsonData] completion in
            completion(jsonData, nil)
            return nil
        }

        provider.registerFileRepresentation(
            forTypeIdentifier: UTType.json.identifier,
            fileOptions: [],
            visibility: .all
        ) { [fileURL] completion in
            completion(fileURL, true, nil)
            return nil
        }

        return provider
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: ((UIActivity.ActivityType?, Bool) -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { activityType, completed, _, _ in
            onComplete?(activityType, completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
