import AppKit
import Foundation

final class ManualSummarizationService: SummarizationService {
    let id = "manual"
    let displayName = "Manual"

    private let fileStorageService = FileStorageService()

    func isAvailable() async -> Bool {
        true
    }

    func summarize(transcript: String, metadata: MeetingMetadata) async throws -> String {
        let outputDirectory = URL(fileURLWithPath: metadata.outputDirectory, isDirectory: true)
        let prompt = SummaryPromptBuilder.buildPrompt(transcript: transcript, metadata: metadata)
        let promptURL = try fileStorageService.writePrompt(prompt, to: outputDirectory)

        await MainActor.run {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(prompt, forType: .string)
        }

        return """
        # Meeting Summary

        Manual summarization is selected or the configured AI provider was unavailable.

        A prompt was saved and copied to the clipboard:
        \(promptURL.path)

        Paste it into your preferred assistant, then replace this file with the generated summary.
        """
    }
}
