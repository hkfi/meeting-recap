import Foundation

enum SummaryPromptBuilder {
    static func buildPrompt(transcript: String, metadata: MeetingMetadata) -> String {
        """
        You are summarizing a meeting transcript for a local-first macOS app called Meeting Recap.

        Return Markdown in exactly this structure:

        # Meeting Summary

        ## TL;DR
        - 3 to 5 bullets.

        ## Key Topics Discussed
        Group related discussion points by topic.

        ## Decisions Made
        List concrete decisions. If none, write "None captured."

        ## Action Items
        | Owner | Task | Due date | Confidence |
        | --- | --- | --- | --- |

        Use "Unknown" when owner or due date is unclear. Confidence should be High, Medium, or Low.

        ## Open Questions
        List unresolved questions.

        ## Risks / Concerns
        List concerns, blockers, ambiguity, or follow-up risks.

        ## Notable Details
        Include useful details, names, dates, numbers, or short quotes.

        ## Follow-up Draft
        Write a concise follow-up message/email.

        Meeting metadata:
        - Started: \(metadata.startedAt)
        - Ended: \(metadata.endedAt)
        - Duration seconds: \(Int(metadata.durationSeconds))

        Transcript:
        \(transcript)
        """
    }
}
