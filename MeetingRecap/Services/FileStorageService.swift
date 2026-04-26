import Foundation

final class FileStorageService {
    func createSessionDirectory(baseDirectory: URL, startedAt: Date) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm"
        let directory = baseDirectory.appendingPathComponent(formatter.string(from: startedAt), isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func writeTranscript(_ transcript: String, to outputDirectory: URL) throws -> URL {
        let url = outputDirectory.appendingPathComponent("transcript.md")
        try transcript.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func writeSummary(_ summary: String, to outputDirectory: URL) throws -> URL {
        let url = outputDirectory.appendingPathComponent("summary.md")
        try summary.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func writeMetadata(_ metadata: MeetingMetadata, to outputDirectory: URL) throws -> URL {
        let url = outputDirectory.appendingPathComponent("metadata.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(metadata).write(to: url, options: .atomic)
        return url
    }

    func writePrompt(_ prompt: String, to outputDirectory: URL) throws -> URL {
        let url = outputDirectory.appendingPathComponent("summarize-prompt.md")
        try prompt.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
