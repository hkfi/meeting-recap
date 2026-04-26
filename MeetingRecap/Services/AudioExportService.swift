import Foundation

struct AudioExportResult {
    var audioURL: URL
    var warnings: [String]
}

final class AudioExportService {
    private let commandRunner: ExternalCommandRunner

    init(commandRunner: ExternalCommandRunner) {
        self.commandRunner = commandRunner
    }

    func exportTranscriptionReadyWAV(inputURL: URL, outputDirectory: URL) async throws -> AudioExportResult {
        let outputURL = outputDirectory.appendingPathComponent("audio.wav")
        let ffmpeg = commandRunner.findExecutable(
            named: "ffmpeg",
            commonPaths: ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]
        )

        guard let ffmpeg else {
            if inputURL.path != outputURL.path {
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    try FileManager.default.removeItem(at: outputURL)
                }
                try FileManager.default.copyItem(at: inputURL, to: outputURL)
            }
            return AudioExportResult(
                audioURL: outputURL,
                warnings: ["ffmpeg was not found. Meeting Recap recorded 16 kHz mono WAV directly and saved it as audio.wav."]
            )
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        _ = try await commandRunner.runOrThrow(
            executable: ffmpeg,
            arguments: ["-y", "-i", inputURL.path, "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", outputURL.path]
        )
        return AudioExportResult(audioURL: outputURL, warnings: [])
    }
}
