import Foundation
import Darwin

enum DeviceIdentity {
    static var fallbackDisplayName: String {
        hardwareDisplayName(
            modelIdentifier: sysctlString("hw.model"),
            chipName: sysctlString("machdep.cpu.brand_string")
        )
    }

    static func hardwareDisplayName(
        modelIdentifier: String?,
        chipName: String?
    ) -> String {
        let cleanModel = modelIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanChip = chipName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "Apple ", with: "")
        let family = productFamily(for: cleanModel)

        if let family, let cleanChip, !cleanChip.isEmpty {
            return "\(family) \(cleanChip)"
        }
        if let family {
            return family
        }
        if let cleanChip, !cleanChip.isEmpty {
            return "Mac \(cleanChip)"
        }
        if let cleanModel, !cleanModel.isEmpty {
            return "Mac \(cleanModel)"
        }
        return "Mac"
    }

    static func automationTag(for name: String) -> String {
        let folded = name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        let normalized = folded.unicodeScalars
            .map { allowed.contains($0) ? String($0) : "-" }
            .joined()
        let slug = normalized.split(separator: "-").joined(separator: "-")
        return "source-\(slug.isEmpty ? "mac" : String(slug.prefix(40)))"
    }

    private static func productFamily(for modelIdentifier: String?) -> String? {
        guard let modelIdentifier else { return nil }

        let modernFamilies = [
            "Mac13,1": "Mac Studio",
            "Mac13,2": "Mac Studio",
            "Mac14,13": "Mac Studio",
            "Mac14,14": "Mac Studio",
            "Mac16,9": "Mac Studio",
            "Mac16,10": "Mac Studio"
        ]
        if let family = modernFamilies[modelIdentifier] {
            return family
        }

        let legacyFamilies = [
            ("MacBookAir", "MacBook Air"),
            ("MacBookPro", "MacBook Pro"),
            ("MacBook", "MacBook"),
            ("Macmini", "Mac mini"),
            ("iMacPro", "iMac Pro"),
            ("iMac", "iMac"),
            ("MacPro", "Mac Pro")
        ]
        return legacyFamilies.first { modelIdentifier.hasPrefix($0.0) }?.1
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else {
            return nil
        }

        var buffer = [CChar](repeating: 0, count: size)
        let result = buffer.withUnsafeMutableBytes { bytes in
            sysctlbyname(name, bytes.baseAddress, &size, nil, 0)
        }
        guard result == 0 else { return nil }
        return buffer.withUnsafeBufferPointer { pointer in
            guard let baseAddress = pointer.baseAddress else { return nil }
            return String(cString: baseAddress)
        }
    }
}

struct RemoteAlert: Equatable, Sendable {
    let title: String
    let message: String
    let priority: Int
    let tags: [String]
}

struct NtfyPublishPayload: Codable, Equatable, Sendable {
    let topic: String
    let title: String
    let message: String
    let priority: Int
    let tags: [String]
}

protocol RemoteAlertProvider: Sendable {
    var identifier: String { get }
    func send(_ alert: RemoteAlert) async throws
}

enum NtfyTopicValidation: Equatable {
    case empty
    case valid
    case tooLong
    case invalidCharacters
}

enum NtfyTopicValidator {
    static let maximumLength = 64

    private static let allowedCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    )

    static func validate(_ topic: String) -> NtfyTopicValidation {
        let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTopic.isEmpty else { return .empty }
        guard cleanTopic.count <= maximumLength else { return .tooLong }
        guard cleanTopic.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
            return .invalidCharacters
        }
        return .valid
    }
}

enum NtfyTopicGenerator {
    private static let maximumSuffixValue: UInt64 = 0xFFFF_FFFF_FFFF

    static func makeTopic() -> String {
        topic(hexValue: UInt64.random(in: 0...maximumSuffixValue))
    }

    static func topic(hexValue: UInt64) -> String {
        let hex = String(hexValue & maximumSuffixValue, radix: 16, uppercase: false)
        let padding = String(repeating: "0", count: max(0, 12 - hex.count))
        return "diskvakt-\(padding)\(hex)"
    }
}

enum NtfyError: LocalizedError {
    case invalidTopic
    case invalidResponse
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .invalidTopic: String(localized: "Ogiltigt topic")
        case .invalidResponse: String(localized: "Ogiltigt svar från ntfy")
        case .server(let code): String(localized: "ntfy svarade med HTTP \(code)")
        }
    }
}

struct NtfyProvider: RemoteAlertProvider {
    let topic: String

    var identifier: String { "ntfy" }

    func send(_ alert: RemoteAlert) async throws {
        let request = try request(for: alert)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw NtfyError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw NtfyError.server(response.statusCode)
        }
    }

    func request(for alert: RemoteAlert) throws -> URLRequest {
        let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard NtfyTopicValidator.validate(cleanTopic) == .valid,
              let url = URL(string: "https://ntfy.sh/") else {
            throw NtfyError.invalidTopic
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(
            NtfyPublishPayload(
                topic: cleanTopic,
                title: alert.title,
                message: alert.message,
                priority: alert.priority,
                tags: alert.tags
            )
        )
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        return request
    }
}
