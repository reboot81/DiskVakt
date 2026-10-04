import Foundation

struct ThresholdProfile: Equatable, Sendable {
    let warningGB: Double
    let persistentGB: Double
    let criticalGB: Double

    static func defaults(totalBytes: Int64) -> ThresholdProfile {
        let totalGB = Double(totalBytes) / 1_000_000_000
        if totalGB < 400 {
            return ThresholdProfile(warningGB: 40, persistentGB: 25, criticalGB: 15)
        }
        if totalGB < 750 {
            return ThresholdProfile(warningGB: 80, persistentGB: 50, criticalGB: 30)
        }
        return ThresholdProfile(warningGB: 150, persistentGB: 100, criticalGB: 60)
    }
}
