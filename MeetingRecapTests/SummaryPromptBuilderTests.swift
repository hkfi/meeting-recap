import XCTest
@testable import MeetingRecap

final class SummaryPromptBuilderTests: XCTestCase {
    func testPromptIncludesRequiredSummarySections() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let metadata = MeetingMetadata(
            startedAt: now,
            endedAt: now.addingTimeInterval(1800),
            durationSeconds: 1800,
            appVersion: "0.1.0",
            macOSVersion: "macOS",
            outputDirectory: "/tmp/meeting",
            audioPath: "/tmp/meeting/audio.wav",
            transcriptPath: "/tmp/meeting/transcript.md",
            summaryPath: "/tmp/meeting/summary.md",
            recordingPath: nil,
            screenshotPaths: [],
            transcriptionProvider: "manual",
            summarizationProvider: "manual",
            errors: [],
            warnings: []
        )

        let prompt = SummaryPromptBuilder.buildPrompt(
            transcript: "Alice: We will ship the MVP Friday.",
            metadata: metadata
        )

        XCTAssertTrue(prompt.contains("## TL;DR"))
        XCTAssertTrue(prompt.contains("## Decisions Made"))
        XCTAssertTrue(prompt.contains("## Action Items"))
        XCTAssertTrue(prompt.contains("## Follow-up Draft"))
        XCTAssertTrue(prompt.contains("Alice: We will ship the MVP Friday."))
    }
}
