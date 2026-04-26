import AppKit
import Foundation

@MainActor
final class RecordingManager: ObservableObject {
    private let appState: AppState
    private let settingsStore: SettingsStore
    private let commandRunner = ExternalCommandRunner()
    private let permissionsService = PermissionsService()
    private let audioRecordingService = AudioRecordingService()
    private let systemAudioCaptureService = SystemAudioCaptureService()
    private let screenCaptureService = ScreenCaptureService()
    private let fileStorageService = FileStorageService()

    private var startedAt: Date?
    private var activeOutputDirectory: URL?
    private var rawAudioURL: URL?
    private var activeWarnings: [String] = []

    init(appState: AppState, settingsStore: SettingsStore) {
        self.appState = appState
        self.settingsStore = settingsStore
    }

    func startRecording() {
        guard appState.recordingState.canStart else { return }

        Task {
            do {
                appState.recordingState = .requestingPermissions
                appState.latestMessage = "Requesting microphone access"
                activeWarnings = []

                if settingsStore.recordMicrophone {
                    let allowed = await permissionsService.requestMicrophoneAccess()
                    guard allowed else {
                        throw RecordingFlowError.microphonePermissionDenied
                    }
                }

                let startedAt = Date()
                let outputDirectory = try fileStorageService.createSessionDirectory(
                    baseDirectory: settingsStore.outputFolderURL,
                    startedAt: startedAt
                )

                self.startedAt = startedAt
                activeOutputDirectory = outputDirectory
                appState.lastOutputDirectory = outputDirectory

                if settingsStore.recordMicrophone {
                    rawAudioURL = try audioRecordingService.startRecording(in: outputDirectory)
                }

                if settingsStore.attemptSystemAudioCapture {
                    activeWarnings.append(contentsOf: await systemAudioCaptureService.startIfAvailable(in: outputDirectory))
                }

                if settingsStore.saveScreenRecording {
                    activeWarnings.append(contentsOf: await screenCaptureService.startIfEnabled(in: outputDirectory))
                }

                if settingsStore.capturePeriodicScreenshots {
                    activeWarnings.append("Periodic screenshots are planned for Phase 3 and are not captured in the Phase 1 MVP.")
                }

                appState.recentWarnings = activeWarnings
                appState.recordingState = .recording
                appState.latestMessage = "Recording"
            } catch {
                appState.recordingState = .error(error.localizedDescription)
                appState.latestMessage = error.localizedDescription
            }
        }
    }

    func stopRecording() {
        guard appState.recordingState.canStop else { return }

        Task {
            appState.recordingState = .stopping
            appState.latestMessage = "Stopping recording"

            let endedAt = Date()
            var warnings = activeWarnings
            var errors: [String] = []

            do {
                let microphoneURL = try audioRecordingService.stopRecording()
                let _ = await systemAudioCaptureService.stop()
                let recordingURL = await screenCaptureService.stop()

                guard let startedAt, let outputDirectory = activeOutputDirectory else {
                    throw RecordingFlowError.noActiveRecording
                }

                guard let sourceAudioURL = microphoneURL ?? rawAudioURL else {
                    throw RecordingFlowError.noAudioRecorded
                }

                appState.recordingState = .processing
                appState.latestMessage = "Preparing audio"

                let audioExportService = AudioExportService(commandRunner: commandRunner)
                let exportResult = try await audioExportService.exportTranscriptionReadyWAV(
                    inputURL: sourceAudioURL,
                    outputDirectory: outputDirectory
                )
                warnings.append(contentsOf: exportResult.warnings)

                var metadata = makeMetadata(
                    startedAt: startedAt,
                    endedAt: endedAt,
                    outputDirectory: outputDirectory,
                    audioURL: exportResult.audioURL,
                    transcriptURL: outputDirectory.appendingPathComponent("transcript.md"),
                    summaryURL: outputDirectory.appendingPathComponent("summary.md"),
                    recordingURL: recordingURL,
                    transcriptionProvider: "pending",
                    summarizationProvider: "pending",
                    warnings: warnings,
                    errors: errors
                )

                appState.latestMessage = "Transcribing"
                let transcriptionResult = await transcribe(
                    audioURL: exportResult.audioURL,
                    outputDirectory: outputDirectory,
                    settings: settingsStore,
                    warnings: &warnings,
                    errors: &errors
                )
                warnings.append(contentsOf: transcriptionResult.warnings)
                let transcriptURL = try fileStorageService.writeTranscript(transcriptionResult.transcript, to: outputDirectory)
                metadata.transcriptPath = transcriptURL.path
                metadata.transcriptionProvider = transcriptionResult.providerID

                appState.latestMessage = "Summarizing"
                metadata.warnings = warnings
                metadata.errors = errors
                let summaryResult = await summarize(
                    transcript: transcriptionResult.transcript,
                    metadata: metadata,
                    settings: settingsStore,
                    warnings: &warnings,
                    errors: &errors
                )
                let summaryURL = try fileStorageService.writeSummary(summaryResult.summary, to: outputDirectory)

                metadata.summaryPath = summaryURL.path
                metadata.summarizationProvider = summaryResult.providerID
                metadata.warnings = warnings
                metadata.errors = errors
                _ = try fileStorageService.writeMetadata(metadata, to: outputDirectory)

                if settingsStore.copySummaryToClipboardWhenDone {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(summaryResult.summary, forType: .string)
                }

                if settingsStore.autoOpenSummaryWhenDone {
                    NSWorkspace.shared.open(summaryURL)
                }

                appState.lastOutputDirectory = outputDirectory
                appState.recentWarnings = warnings
                appState.recordingState = .done
                appState.latestMessage = "Saved summary"
                resetActiveRecording()
            } catch {
                errors.append(error.localizedDescription)
                appState.recentWarnings = warnings
                appState.recordingState = .error(error.localizedDescription)
                appState.latestMessage = error.localizedDescription
            }
        }
    }

    func openOutputFolder() {
        let url = appState.lastOutputDirectory ?? settingsStore.outputFolderURL
        NSWorkspace.shared.open(url)
    }

    private func transcribe(
        audioURL: URL,
        outputDirectory: URL,
        settings: SettingsStore,
        warnings: inout [String],
        errors: inout [String]
    ) async -> TranscriptionResult {
        let manual = ManualTranscriptionService()
        let candidates: [TranscriptionService]

        switch settings.transcriptionProvider {
        case .auto:
            candidates = [
                WhisperCppTranscriptionService(commandRunner: commandRunner),
                MacWhisperTranscriptionService(commandRunner: commandRunner),
                manual
            ]
        case .whisperCpp:
            candidates = [WhisperCppTranscriptionService(commandRunner: commandRunner), manual]
        case .macWhisper:
            candidates = [MacWhisperTranscriptionService(commandRunner: commandRunner), manual]
        }

        for provider in candidates {
            guard await provider.isAvailable(settings: settings) else {
                continue
            }
            do {
                return try await provider.transcribe(audioURL: audioURL, outputDirectory: outputDirectory, settings: settings)
            } catch {
                errors.append("\(provider.displayName): \(error.localizedDescription)")
            }
        }

        return (try? await manual.transcribe(audioURL: audioURL, outputDirectory: outputDirectory, settings: settings))
            ?? TranscriptionResult(transcript: "# Transcript\n\nUnavailable.", providerID: manual.id, warnings: ["Manual transcription fallback failed."])
    }

    private func summarize(
        transcript: String,
        metadata: MeetingMetadata,
        settings: SettingsStore,
        warnings: inout [String],
        errors: inout [String]
    ) async -> (summary: String, providerID: String) {
        let manual = ManualSummarizationService()
        let selectedProvider: SummarizationService

        switch settings.summarizationProvider {
        case .ollama:
            selectedProvider = OllamaSummarizationService(model: settings.ollamaModel)
        case .manual:
            selectedProvider = manual
        case .openAIAPI:
            selectedProvider = OpenAIAPISummarizationService(apiKey: settings.openAIAPIKey(), model: settings.openAIModel)
        case .codexCLI:
            selectedProvider = CodexCLISummarizationService(commandRunner: commandRunner)
        }

        if await selectedProvider.isAvailable() {
            do {
                let summary = try await selectedProvider.summarize(transcript: transcript, metadata: metadata)
                return (summary, selectedProvider.id)
            } catch {
                errors.append("\(selectedProvider.displayName): \(error.localizedDescription)")
                warnings.append("\(selectedProvider.displayName) failed; falling back to Manual summarization.")
            }
        } else if selectedProvider.id != manual.id {
            warnings.append("\(selectedProvider.displayName) is not available; falling back to Manual summarization.")
        }

        do {
            return (try await manual.summarize(transcript: transcript, metadata: metadata), manual.id)
        } catch {
            errors.append("Manual: \(error.localizedDescription)")
            return ("# Meeting Summary\n\nSummary generation failed. See metadata.json for details.", manual.id)
        }
    }

    private func makeMetadata(
        startedAt: Date,
        endedAt: Date,
        outputDirectory: URL,
        audioURL: URL,
        transcriptURL: URL,
        summaryURL: URL,
        recordingURL: URL?,
        transcriptionProvider: String,
        summarizationProvider: String,
        warnings: [String],
        errors: [String]
    ) -> MeetingMetadata {
        MeetingMetadata(
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: endedAt.timeIntervalSince(startedAt),
            appVersion: AppEnvironment.appVersion,
            macOSVersion: AppEnvironment.macOSVersion,
            outputDirectory: outputDirectory.path,
            audioPath: audioURL.path,
            transcriptPath: transcriptURL.path,
            summaryPath: summaryURL.path,
            recordingPath: recordingURL?.path,
            screenshotPaths: [],
            transcriptionProvider: transcriptionProvider,
            summarizationProvider: summarizationProvider,
            errors: errors,
            warnings: warnings
        )
    }

    private func resetActiveRecording() {
        startedAt = nil
        activeOutputDirectory = nil
        rawAudioURL = nil
        activeWarnings = []
    }

    enum RecordingFlowError: LocalizedError {
        case microphonePermissionDenied
        case noActiveRecording
        case noAudioRecorded

        var errorDescription: String? {
            switch self {
            case .microphonePermissionDenied:
                return "Microphone permission is required for the Phase 1 audio MVP."
            case .noActiveRecording:
                return "No active recording session was found."
            case .noAudioRecorded:
                return "No audio was recorded. Enable microphone recording in Settings and try again."
            }
        }
    }
}
