import XCTest
@testable import DiskVakt

final class ThresholdProfileTests: XCTestCase {
    func testDefaultsFor256GBDisk() {
        XCTAssertEqual(
            ThresholdProfile.defaults(totalBytes: 256_000_000_000),
            ThresholdProfile(warningGB: 40, persistentGB: 25, criticalGB: 15)
        )
    }

    func testDefaultsFor512GBDisk() {
        XCTAssertEqual(
            ThresholdProfile.defaults(totalBytes: 512_000_000_000),
            ThresholdProfile(warningGB: 80, persistentGB: 50, criticalGB: 30)
        )
    }

    func testDefaultsFor1TBDisk() {
        XCTAssertEqual(
            ThresholdProfile.defaults(totalBytes: 1_000_000_000_000),
            ThresholdProfile(warningGB: 150, persistentGB: 100, criticalGB: 60)
        )
    }
}
