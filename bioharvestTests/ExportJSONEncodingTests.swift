import XCTest
@testable import bioharvest

final class ExportJSONEncodingTests: XCTestCase {
    func testCompactEncodingOmitsPrettyWhitespace() throws {
        let payload = ExportPayload(
            schemaVersion: ExportPayload.currentSchemaVersion,
            app: "bioharvest",
            purpose: "time_series_coach_export",
            exportDate: Date(timeIntervalSince1970: 1_700_000_000),
            healthKitStatus: .liveAuthorized,
            exportRange: ExportRange(startDate: "2026-07-01", endDate: "2026-07-01"),
            logs: []
        )

        let encoder = JSONEncoder()
        ExportJSONEncoding.compact.configure(encoder)
        let data = try encoder.encode(payload)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertFalse(json.contains("\n  "))
        XCTAssertTrue(json.contains("\"schema_version\":2"))
    }

    func testHumanReadableEncodingUsesPrettyPrint() throws {
        let payload = ExportPayload(
            schemaVersion: ExportPayload.currentSchemaVersion,
            app: "bioharvest",
            purpose: "time_series_coach_export",
            exportDate: Date(timeIntervalSince1970: 1_700_000_000),
            healthKitStatus: .liveAuthorized,
            exportRange: ExportRange(startDate: "2026-07-01", endDate: "2026-07-01"),
            logs: []
        )

        let encoder = JSONEncoder()
        ExportJSONEncoding.humanReadable.configure(encoder)
        let data = try encoder.encode(payload)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("\n"))
    }
}
