import SwiftUI

@main
struct MeetingRecapApp: App {
    @StateObject private var appState: AppState
    @StateObject private var settingsStore: SettingsStore
    @StateObject private var recordingManager: RecordingManager

    init() {
        let state = AppState()
        let settings = SettingsStore()
        _appState = StateObject(wrappedValue: state)
        _settingsStore = StateObject(wrappedValue: settings)
        _recordingManager = StateObject(wrappedValue: RecordingManager(appState: state, settingsStore: settings))
    }

    var body: some Scene {
        MenuBarExtra("Meeting Recap", systemImage: appState.menuBarIconName) {
            MenuBarContentView(appState: appState, recordingManager: recordingManager)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settingsStore: settingsStore)
                .frame(width: 560, height: 620)
        }
    }
}
