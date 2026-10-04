import Foundation

enum StorageCapacityFormatter {
    static func string(fromByteCount bytes: Int64, locale: Locale = .current) -> String {
        let usesTerabytes = bytes >= 1_000_000_000_000
        let divisor = usesTerabytes ? 1_000_000_000_000.0 : 1_000_000_000.0
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = usesTerabytes ? 1 : 0
        formatter.roundingMode = .halfUp
        let value = Double(max(0, bytes)) / divisor
        let number = formatter.string(from: NSNumber(value: value)) ?? String(Int(value.rounded()))
        return "\(number) \(usesTerabytes ? "TB" : "GB")"
    }
}

enum HealthLevel: Int, Comparable, Sendable {
    case ok = 0
    case attention = 1
    case critical = 2
    case unknown = 3

    static func < (lhs: HealthLevel, rhs: HealthLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct VolumeSnapshot: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let totalBytes: Int64
    let availableBytes: Int64
    let isSystem: Bool

    var freePercent: Int {
        guard totalBytes > 0 else { return 0 }
        return Int((Double(availableBytes) / Double(totalBytes) * 100).rounded())
    }

    var usedPercent: Int { 100 - freePercent }
}

struct HealthSnapshot: Equatable, Sendable {
    var level: HealthLevel
    var reason: String?
    var checkedAt: Date?

    static let unknown = HealthSnapshot(level: .unknown, reason: nil, checkedAt: nil)
}
