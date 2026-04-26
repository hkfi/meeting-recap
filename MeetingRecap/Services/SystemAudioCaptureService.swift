import Foundation

final class SystemAudioCaptureService {
    func startIfAvailable(in outputDirectory: URL) async -> [String] {
        [
            "System audio capture is a best-effort Phase 1 placeholder. Microphone recording continues; full ScreenCaptureKit capture is tracked as a Phase 2 TODO."
        ]
    }

    func stop() async -> URL? {
        nil
    }
}
