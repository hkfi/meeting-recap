import Foundation

enum RecordingState: Equatable {
    case idle
    case requestingPermissions
    case recording
    case stopping
    case processing
    case done
    case error(String)

    var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .requestingPermissions:
            return "Requesting Permissions"
        case .recording:
            return "Recording"
        case .stopping:
            return "Stopping"
        case .processing:
            return "Processing"
        case .done:
            return "Done"
        case .error:
            return "Error"
        }
    }

    var canStart: Bool {
        switch self {
        case .idle, .done, .error:
            return true
        case .requestingPermissions, .recording, .stopping, .processing:
            return false
        }
    }

    var canStop: Bool {
        self == .recording
    }
}
