import Foundation

final class ScreenCaptureService {
    func startIfEnabled(in outputDirectory: URL) async -> [String] {
        [
            "Screen recording is not part of the Phase 1 MVP and remains disabled until Phase 2."
        ]
    }

    func stop() async -> URL? {
        nil
    }
}
