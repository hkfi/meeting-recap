import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var outputFolderPath: String {
        didSet { defaults.set(outputFolderPath, forKey: Keys.outputFolderPath) }
    }
    @Published var transcriptionProvider: TranscriptionProviderKind {
        didSet { defaults.set(transcriptionProvider.rawValue, forKey: Keys.transcriptionProvider) }
    }
    @Published var whisperModelPath: String {
        didSet { defaults.set(whisperModelPath, forKey: Keys.whisperModelPath) }
    }
    @Published var summarizationProvider: SummarizationProviderKind {
        didSet { defaults.set(summarizationProvider.rawValue, forKey: Keys.summarizationProvider) }
    }
    @Published var ollamaModel: String {
        didSet { defaults.set(ollamaModel, forKey: Keys.ollamaModel) }
    }
    @Published var openAIModel: String {
        didSet { defaults.set(openAIModel, forKey: Keys.openAIModel) }
    }
    @Published var recordMicrophone: Bool {
        didSet { defaults.set(recordMicrophone, forKey: Keys.recordMicrophone) }
    }
    @Published var attemptSystemAudioCapture: Bool {
        didSet { defaults.set(attemptSystemAudioCapture, forKey: Keys.attemptSystemAudioCapture) }
    }
    @Published var saveScreenRecording: Bool {
        didSet { defaults.set(saveScreenRecording, forKey: Keys.saveScreenRecording) }
    }
    @Published var capturePeriodicScreenshots: Bool {
        didSet { defaults.set(capturePeriodicScreenshots, forKey: Keys.capturePeriodicScreenshots) }
    }
    @Published var autoOpenSummaryWhenDone: Bool {
        didSet { defaults.set(autoOpenSummaryWhenDone, forKey: Keys.autoOpenSummaryWhenDone) }
    }
    @Published var copySummaryToClipboardWhenDone: Bool {
        didSet { defaults.set(copySummaryToClipboardWhenDone, forKey: Keys.copySummaryToClipboardWhenDone) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        outputFolderPath = defaults.string(forKey: Keys.outputFolderPath) ?? AppEnvironment.defaultOutputDirectory.path
        transcriptionProvider = TranscriptionProviderKind(rawValue: defaults.string(forKey: Keys.transcriptionProvider) ?? "") ?? .auto
        whisperModelPath = defaults.string(forKey: Keys.whisperModelPath) ?? ""
        summarizationProvider = SummarizationProviderKind(rawValue: defaults.string(forKey: Keys.summarizationProvider) ?? "") ?? .ollama
        ollamaModel = defaults.string(forKey: Keys.ollamaModel) ?? "llama3.1"
        openAIModel = defaults.string(forKey: Keys.openAIModel) ?? "gpt-5-mini"
        recordMicrophone = defaults.object(forKey: Keys.recordMicrophone) as? Bool ?? true
        attemptSystemAudioCapture = defaults.object(forKey: Keys.attemptSystemAudioCapture) as? Bool ?? true
        saveScreenRecording = defaults.object(forKey: Keys.saveScreenRecording) as? Bool ?? false
        capturePeriodicScreenshots = defaults.object(forKey: Keys.capturePeriodicScreenshots) as? Bool ?? false
        autoOpenSummaryWhenDone = defaults.object(forKey: Keys.autoOpenSummaryWhenDone) as? Bool ?? true
        copySummaryToClipboardWhenDone = defaults.object(forKey: Keys.copySummaryToClipboardWhenDone) as? Bool ?? false
    }

    var outputFolderURL: URL {
        URL(fileURLWithPath: outputFolderPath, isDirectory: true)
    }

    func openAIAPIKey() -> String {
        (try? KeychainService.read(account: KeychainService.openAIAPIKeyAccount)) ?? ""
    }

    func saveOpenAIAPIKey(_ value: String) throws {
        try KeychainService.save(value, account: KeychainService.openAIAPIKeyAccount)
    }

    private enum Keys {
        static let outputFolderPath = "outputFolderPath"
        static let transcriptionProvider = "transcriptionProvider"
        static let whisperModelPath = "whisperModelPath"
        static let summarizationProvider = "summarizationProvider"
        static let ollamaModel = "ollamaModel"
        static let openAIModel = "openAIModel"
        static let recordMicrophone = "recordMicrophone"
        static let attemptSystemAudioCapture = "attemptSystemAudioCapture"
        static let saveScreenRecording = "saveScreenRecording"
        static let capturePeriodicScreenshots = "capturePeriodicScreenshots"
        static let autoOpenSummaryWhenDone = "autoOpenSummaryWhenDone"
        static let copySummaryToClipboardWhenDone = "copySummaryToClipboardWhenDone"
    }
}
