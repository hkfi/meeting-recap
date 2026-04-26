import Foundation

final class CodexCLISummarizationService: SummarizationService {
    let id = "codex-cli-experimental"
    let displayName = "Codex CLI Experimental"

    private let commandRunner: ExternalCommandRunner
    private let fileStorageService = FileStorageService()

    init(commandRunner: ExternalCommandRunner) {
        self.commandRunner = commandRunner
    }

    func isAvailable() async -> Bool {
        executablePath() != nil
    }

    func summarize(transcript: String, metadata: MeetingMetadata) async throws -> String {
        guard let executable = executablePath() else {
            throw ProviderError.setupRequired("""
            Codex CLI was not found. Install Codex CLI, run `codex`, sign in with ChatGPT, then select Codex CLI Experimental again.
            """)
        }

        let outputDirectory = URL(fileURLWithPath: metadata.outputDirectory, isDirectory: true)
        let prompt = SummaryPromptBuilder.buildPrompt(transcript: transcript, metadata: metadata)
        let promptURL = try fileStorageService.writePrompt(prompt, to: outputDirectory)
        let outputURL = outputDirectory.appendingPathComponent("codex-summary-output.md")

        _ = try await commandRunner.runOrThrow(
            executable: executable,
            arguments: [
                "exec",
                "--skip-git-repo-check",
                "--ephemeral",
                "--sandbox", "read-only",
                "--output-last-message", outputURL.path,
                "-"
            ],
            currentDirectory: outputDirectory,
            standardInput: """
            Summarize this meeting transcript. Return only the final Markdown summary.

            Prompt file: \(promptURL.path)

            \(prompt)
            """
        )

        let summary = try String(contentsOf: outputURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty else {
            throw ProviderError.invalidResponse("Codex CLI produced an empty summary.")
        }
        return summary
    }

    private func executablePath() -> String? {
        commandRunner.findExecutable(
            named: "codex",
            commonPaths: [
                "/opt/homebrew/bin/codex",
                "/usr/local/bin/codex",
                "/Applications/Codex.app/Contents/Resources/codex"
            ]
        )
    }
}
