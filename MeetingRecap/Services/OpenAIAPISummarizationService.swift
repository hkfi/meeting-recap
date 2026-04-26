import Foundation

final class OpenAIAPISummarizationService: SummarizationService {
    let id = "openai-api"
    let displayName = "OpenAI API"

    private let apiKey: String
    private let model: String
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }

    func isAvailable() async -> Bool {
        !apiKey.isEmpty
    }

    func summarize(transcript: String, metadata: MeetingMetadata) async throws -> String {
        guard !apiKey.isEmpty else {
            throw ProviderError.setupRequired("Add an OpenAI API key in Settings. This uses API billing, not a ChatGPT or Codex subscription.")
        }

        let prompt = SummaryPromptBuilder.buildPrompt(transcript: transcript, metadata: metadata)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(OpenAIRequest(model: model, input: prompt))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let body = String(decoding: data, as: UTF8.self)
            throw ProviderError.invalidResponse("OpenAI API returned an error. \(body)")
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        if let text = decoded.outputText, !text.isEmpty {
            return text
        }
        let text = decoded.output
            .flatMap(\.content)
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw ProviderError.invalidResponse("OpenAI API response did not include output text.")
        }
        return text
    }

    private struct OpenAIRequest: Encodable {
        var model: String
        var input: String
    }

    private struct OpenAIResponse: Decodable {
        var outputText: String?
        var output: [OutputItem]

        enum CodingKeys: String, CodingKey {
            case outputText = "output_text"
            case output
        }
    }

    private struct OutputItem: Decodable {
        var content: [ContentItem]
    }

    private struct ContentItem: Decodable {
        var text: String?
    }
}
