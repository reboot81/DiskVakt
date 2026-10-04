import Foundation

enum SMARTAvailability: Equatable {
    case verified
    case failing
    case unavailable
}

protocol SMARTHealthProviding: Sendable {
    func overallStatus() async -> SMARTAvailability
}

struct SandboxSMARTHealthProvider: SMARTHealthProviding, Sendable {
    func overallStatus() async -> SMARTAvailability {
        .unavailable
    }
}
