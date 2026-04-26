import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var lastOutputDirectory: URL?
    @Published var latestMessage = "Ready"
    @Published var recentWarnings: [String] = []

    var menuBarIconName: String {
        switch recordingState {
        case .recording:
            return "record.circle.fill"
        case .processing, .stopping:
            return "waveform.circle"
        case .error:
            return "exclamationmark.triangle"
        case .done:
            return "checkmark.circle"
        case .idle, .requestingPermissions:
            return "mic.circle"
        }
    }
}
