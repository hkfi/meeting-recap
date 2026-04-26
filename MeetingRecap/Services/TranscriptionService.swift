import Foundation

struct TranscriptionResult {
    var transcript: String
    var providerID: String
    var warnings: [String]
}

@MainActor
protocol TranscriptionService {
    var id: String { get }
    var displayName: String { get }
    func isAvailable(settings: SettingsStore) async -> Bool
    func transcribe(audioURL: URL, outputDirectory: URL, settings: SettingsStore) async throws -> TranscriptionResult
}

final class ManualTranscriptionService: TranscriptionService {
    let id = "manual"
    let displayName = "Manual"

    func isAvailable(settings: SettingsStore) async -> Bool {
        true
    }

    func transcribe(audioURL: URL, outputDirectory: URL, settings: SettingsStore) async throws -> TranscriptionResult {
        let transcript = """
        # Transcript

        Automatic transcription was not available.

        Audio was saved here:
        \(audioURL.path)

        Install one of the supported local transcription tools, then record again:
        - whisper.cpp CLI: install `whisper-cli` and choose a local model file in Settings.
        - MacWhisper CLI: install `mw` and select MacWhisper CLI in Settings.

        You can also transcribe the audio manually and replace this file.
        """
        return TranscriptionResult(
            transcript: transcript,
            providerID: id,
            warnings: ["No automatic transcription provider was available; wrote manual fallback instructions."]
        )
    }
}
