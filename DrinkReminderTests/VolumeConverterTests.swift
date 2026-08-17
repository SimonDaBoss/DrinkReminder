import XCTest
@testable import DrinkReminder

final class VolumeConverterTests: XCTestCase {
    func testOunceConversionRoundTrips() {
        let milliliters = VolumeConverter.milliliters(from: 16, unit: .ounces)
        let ounces = VolumeConverter.displayValue(fromMilliliters: milliliters, unit: .ounces)

        XCTAssertEqual(milliliters, 473.176473, accuracy: 0.000_001)
        XCTAssertEqual(ounces, 16, accuracy: 0.000_001)
    }

    func testMillilitersDoNotChange() {
        XCTAssertEqual(VolumeConverter.milliliters(from: 500, unit: .milliliters), 500)
        XCTAssertEqual(VolumeConverter.displayValue(fromMilliliters: 500, unit: .milliliters), 500)
    }
}
