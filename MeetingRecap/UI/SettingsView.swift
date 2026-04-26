import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @State private var openAIAPIKey = ""
    @State private var keychainMessage = ""

    var body: some View {
        Form {
            Section("Storage") {
                HStack {
                    TextField("Output folder", text: $settingsStore.outputFolderPath)
                    Button("Choose") {
                        chooseOutputFolder()
                    }
                }
            }

            Section("Transcription") {
                Picker("Provider", selection: $settingsStore.transcriptionProvider) {
                    ForEach(TranscriptionProviderKind.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                HStack {
                    TextField("Whisper model path", text: $settingsStore.whisperModelPath)
                    Button("Choose") {
                        chooseWhisperModel()
                    }
                }
            }

            Section("Summarization") {
                Picker("Provider", selection: $settingsStore.summarizationProvider) {
                    ForEach(SummarizationProviderKind.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                TextField("Ollama model", text: $settingsStore.ollamaModel)
                TextField("OpenAI API model", text: $settingsStore.openAIModel)

                HStack {
                    SecureField("OpenAI API key", text: $openAIAPIKey)
                    Button("Save Key") {
                        saveOpenAIKey()
                    }
                }

                if !keychainMessage.isEmpty {
                    Text(keychainMessage)
                        .foregroundStyle(.secondary)
                }

                Text("OpenAI API provider uses your own API key and API billing. It is separate from ChatGPT, Codex, or other subscriptions.")
                    .foregroundStyle(.secondary)

                Text("Codex CLI support is experimental and depends on your local Codex installation and plan limits.")
                    .foregroundStyle(.secondary)
            }

            Section("Recording") {
                Toggle("Record microphone", isOn: $settingsStore.recordMicrophone)
                Toggle("Attempt system audio capture", isOn: $settingsStore.attemptSystemAudioCapture)
                Toggle("Save screen recording", isOn: $settingsStore.saveScreenRecording)
                Toggle("Capture periodic screenshots", isOn: $settingsStore.capturePeriodicScreenshots)
            }

            Section("After Processing") {
                Toggle("Auto-open summary when done", isOn: $settingsStore.autoOpenSummaryWhenDone)
                Toggle("Copy summary to clipboard when done", isOn: $settingsStore.copySummaryToClipboardWhenDone)
            }
        }
        .padding(24)
        .onAppear {
            openAIAPIKey = settingsStore.openAIAPIKey()
        }
    }

    private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = settingsStore.outputFolderURL
        if panel.runModal() == .OK, let url = panel.url {
            settingsStore.outputFolderPath = url.path
        }
    }

    private func chooseWhisperModel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            settingsStore.whisperModelPath = url.path
        }
    }

    private func saveOpenAIKey() {
        do {
            try settingsStore.saveOpenAIAPIKey(openAIAPIKey)
            keychainMessage = openAIAPIKey.isEmpty ? "OpenAI API key removed." : "OpenAI API key saved in Keychain."
        } catch {
            keychainMessage = error.localizedDescription
        }
    }
}
