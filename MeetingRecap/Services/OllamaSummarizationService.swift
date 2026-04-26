import Foundation

final class OllamaSummarizationService: SummarizationService {
    let id = "ollama"
    let displayName = "Ollama"

    private let model: String
    private let endpoint = URL(string: "http://localhost:11434/api/generate")!
    private let tagsEndpoint = URL(string: "http://localhost:11434/api/tags")!

    init(model: String) {
        self.model = model
    }

    func isAvailable() async -> Bool {
        do {
            var request = URLRequest(url: tagsEndpoint)
            request.timeoutInterval = 2
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func summarize(transcript: String, metadata: MeetingMetadata) async throws -> String {
        let prompt = SummaryPromptBuilder.buildPrompt(transcript: transcript, metadata: metadata)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(OllamaRequest(model: model, prompt: prompt, stream: false))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let body = String(decoding: data, as: UTF8.self)
            throw ProviderError.invalidResponse("Ollama returned an error. \(body)")
        }

        let decoded = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct OllamaRequest: Encodable {
        var model: String
        var prompt: String
        var stream: Bool
    }

    private struct OllamaResponse: Decodable {
        var response: String
    }
}
