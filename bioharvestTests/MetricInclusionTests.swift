import XCTest
@testable import bioharvest

final class MetricInclusionTests: XCTestCase {
    private let storageKey = BioharvestStorage.metricInclusionKey

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        super.tearDown()
    }

    func testNeedsSleepWhenAnySleepMetricEnabled() {
        var inclusion = MetricInclusion()
        inclusion.sleepTotal = false
        inclusion.sleepDeep = false
        inclusion.sleepREM = false
        XCTAssertFalse(inclusion.needsSleep)

        inclusion.sleepREM = true
        XCTAssertTrue(inclusion.needsSleep)
    }

    func testSaveAndLoadRoundTrip() {
        var inclusion = MetricInclusion()
        inclusion.workouts = false
        inclusion.trainingLoad = false
        inclusion.hrvToday = false
        inclusion.save()

        let loaded = MetricInclusion.load()
        XCTAssertEqual(loaded, inclusion)
    }

    func testLoadReturnsDefaultsWhenMissing() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        XCTAssertEqual(MetricInclusion.load(), MetricInclusion())
    }
}
