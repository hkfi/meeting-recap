import Foundation

final class MacWhisperTranscriptionService: TranscriptionService {
    let id = "macwhisper-cli"
    let displayName = "MacWhisper CLI"

    private let commandRunner: ExternalCommandRunner

    init(commandRunner: ExternalCommandRunner) {
        self.commandRunner = commandRunner
    }

    func isAvailable(settings: SettingsStore) async -> Bool {
        executablePath() != nil
    }

    func transcribe(audioURL: URL, outputDirectory: URL, settings: SettingsStore) async throws -> TranscriptionResult {
        guard let executable = executablePath() else {
            throw ExternalCommandError.executableNotFound("mw")
        }

        let outputURL = outputDirectory.appendingPathComponent("macwhisper-transcript.txt")
        _ = try await commandRunner.runOrThrow(
            executable: executable,
            arguments: ["transcribe", audioURL.path, "--output", outputURL.path],
            currentDirectory: outputDirectory
        )

        let transcript = try String(contentsOf: outputURL, encoding: .utf8)
        return TranscriptionResult(transcript: "# Transcript\n\n\(transcript)", providerID: id, warnings: [])
    }

    private func executablePath() -> String? {
        commandRunner.findExecutable(
            named: "mw",
            commonPaths: ["/opt/homebrew/bin/mw", "/usr/local/bin/mw"]
        )
    }
}
