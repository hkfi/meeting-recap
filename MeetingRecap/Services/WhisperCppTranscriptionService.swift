import Foundation

final class WhisperCppTranscriptionService: TranscriptionService {
    let id = "whisper.cpp"
    let displayName = "whisper.cpp"

    private let commandRunner: ExternalCommandRunner

    init(commandRunner: ExternalCommandRunner) {
        self.commandRunner = commandRunner
    }

    func isAvailable(settings: SettingsStore) async -> Bool {
        executablePath() != nil && !settings.whisperModelPath.isEmpty
    }

    func transcribe(audioURL: URL, outputDirectory: URL, settings: SettingsStore) async throws -> TranscriptionResult {
        guard let executable = executablePath() else {
            throw ExternalCommandError.executableNotFound("whisper-cli")
        }
        guard !settings.whisperModelPath.isEmpty else {
            throw ProviderError.setupRequired("Choose a whisper.cpp model path in Settings.")
        }

        let outputBase = outputDirectory.appendingPathComponent("whisper-transcript")
        _ = try await commandRunner.runOrThrow(
            executable: executable,
            arguments: [
                "-m", settings.whisperModelPath,
                "-f", audioURL.path,
                "-otxt",
                "-of", outputBase.path
            ],
            currentDirectory: outputDirectory
        )

        let transcriptURL = outputDirectory.appendingPathComponent("whisper-transcript.txt")
        let transcript = try String(contentsOf: transcriptURL, encoding: .utf8)
        return TranscriptionResult(transcript: "# Transcript\n\n\(transcript)", providerID: id, warnings: [])
    }

    private func executablePath() -> String? {
        commandRunner.findExecutable(
            named: "whisper-cli",
            commonPaths: ["/opt/homebrew/bin/whisper-cli", "/usr/local/bin/whisper-cli"]
        )
    }
}
