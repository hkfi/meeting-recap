import Foundation

struct MeetingMetadata: Codable {
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: TimeInterval
    var appVersion: String
    var macOSVersion: String
    var outputDirectory: String
    var audioPath: String
    var transcriptPath: String
    var summaryPath: String
    var recordingPath: String?
    var screenshotPaths: [String]
    var transcriptionProvider: String
    var summarizationProvider: String
    var errors: [String]
    var warnings: [String]
}

enum TranscriptionProviderKind: String, CaseIterable, Identifiable {
    case auto
    case whisperCpp
    case macWhisper

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto:
            return "Auto"
        case .whisperCpp:
            return "whisper.cpp"
        case .macWhisper:
            return "MacWhisper CLI"
        }
    }
}

enum SummarizationProviderKind: String, CaseIterable, Identifiable {
    case ollama
    case manual
    case openAIAPI
    case codexCLI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollama:
            return "Ollama"
        case .manual:
            return "Manual"
        case .openAIAPI:
            return "OpenAI API"
        case .codexCLI:
            return "Codex CLI Experimental"
        }
    }
}
