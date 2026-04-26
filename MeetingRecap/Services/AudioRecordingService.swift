import AVFoundation
import Foundation

final class AudioRecordingService: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var currentURL: URL?

    func startRecording(in outputDirectory: URL) throws -> URL {
        let url = outputDirectory.appendingPathComponent("raw-audio.wav")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw RecordingError.failedToStartMicrophone
        }

        self.recorder = recorder
        currentURL = url
        return url
    }

    func stopRecording() throws -> URL? {
        guard let recorder else { return currentURL }
        recorder.stop()
        self.recorder = nil
        return currentURL
    }

    enum RecordingError: LocalizedError {
        case failedToStartMicrophone

        var errorDescription: String? {
            "Microphone recording could not be started."
        }
    }
}
