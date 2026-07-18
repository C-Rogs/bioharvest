import XCTest
@testable import bioharvest

final class RoundedDoubleTests: XCTestCase {
    func testRoundsToTwoDecimalPlaces() {
        XCTAssertEqual(RoundedDouble(3.14159)?.value, 3.14)
        XCTAssertEqual(RoundedDouble(1.006)?.value, 1.01)
        XCTAssertEqual(RoundedDouble(2.0)?.value, 2.0)
    }

    func testNilInputReturnsNil() {
        XCTAssertNil(RoundedDouble(nil))
    }

    func testEncodesAsBareDouble() throws {
        let rounded = try XCTUnwrap(RoundedDouble(12.345))
        let data = try JSONEncoder().encode(rounded)
        XCTAssertEqual(String(data: data, encoding: .utf8), "12.35")
    }
}
