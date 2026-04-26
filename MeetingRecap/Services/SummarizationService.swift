import Foundation

protocol SummarizationService {
    var id: String { get }
    var displayName: String { get }
    func isAvailable() async -> Bool
    func summarize(transcript: String, metadata: MeetingMetadata) async throws -> String
}

enum ProviderError: LocalizedError {
    case setupRequired(String)
    case invalidResponse(String)

    var errorDescription: String? {
        switch self {
        case .setupRequired(let message), .invalidResponse(let message):
            return message
        }
    }
}
