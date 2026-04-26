import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var recordingManager: RecordingManager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Start Recording", systemImage: "record.circle") {
            recordingManager.startRecording()
        }
        .disabled(!appState.recordingState.canStart)

        Button("Stop Recording", systemImage: "stop.circle") {
            recordingManager.stopRecording()
        }
        .disabled(!appState.recordingState.canStop)

        Divider()

        Text("Status: \(appState.recordingState.displayName)")
        if !appState.latestMessage.isEmpty {
            Text(appState.latestMessage)
                .foregroundStyle(.secondary)
        }

        if case .error(let message) = appState.recordingState {
            Text(message)
                .foregroundStyle(.red)
        }

        Divider()

        Button("Open Output Folder", systemImage: "folder") {
            recordingManager.openOutputFolder()
        }

        Button("Settings", systemImage: "gearshape") {
            openSettings()
        }

        Divider()

        Button("Quit", systemImage: "power") {
            NSApplication.shared.terminate(nil)
        }
    }
}
