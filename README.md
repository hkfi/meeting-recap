# Meeting Recap

Meeting Recap is an open-source native macOS menu bar app for recording meetings, transcribing them, and generating AI summaries. The project is local-first, privacy-conscious, and provider-pluggable: there is no backend, no bundled model file, and no hardcoded paid service.

## Current Status

Phase 1 audio-only MVP is implemented:

- Start and stop recording from the macOS menu bar.
- Record microphone audio.
- Save recordings to timestamped folders.
- Export transcription-ready `audio.wav`.
- Transcribe with local CLI providers where available.
- Summarize with a pluggable provider.
- Write `transcript.md`, `summary.md`, and `metadata.json`.

Phase 2 screen recording, Phase 3 visual context, and Phase 4 exports/templates are tracked as TODOs in the codebase.

## Privacy Model

Meeting Recap stores meeting artifacts on your Mac under:

```text
~/Documents/Meeting Recap/YYYY-MM-DD-HH-mm/
  audio.wav
  transcript.md
  summary.md
  metadata.json
```

Local providers keep processing on your machine where possible. Cloud providers are optional and require you to bring your own credentials. You are responsible for getting consent before recording meetings.

## Requirements

- macOS 14+
- Xcode 15+
- Optional: `ffmpeg`
- Optional: `whisper-cli` from whisper.cpp
- Optional: `mw` from MacWhisper CLI
- Optional: Ollama
- Optional: OpenAI API key
- Optional experimental: locally installed and already authenticated Codex CLI

## Build

```bash
make build    # Build only
make test     # Run unit tests
make run      # Build and launch
make install  # Build and install to ~/Applications
make clean    # Remove build artifacts
```

The build uses XcodeGen and Xcode, then ad-hoc signs the app with `CODE_SIGN_IDENTITY="-"`, matching the lightweight DailyPhotos release pattern. Open `MeetingRecap.xcodeproj` in Xcode for local development after running `xcodegen generate`.

## Versioning and GitHub Releases

The app version is tracked in `VERSION` and mirrored into `project.yml` as `MARKETING_VERSION`. `Info.plist` reads `$(MARKETING_VERSION)`, so the built app exposes the same release version as GitHub.

Update the app version with:

```bash
scripts/set-version.sh 0.2.0 2
```

The first argument is the release version. The optional second argument is the Xcode build number.

To publish a release:

```bash
make release VERSION=0.2.0
```

GitHub Actions builds the app, ad-hoc signs it, packages it with `ditto --sequesterRsrc --keepParent`, and creates a GitHub release with the zip attached.

## Audio Conversion

Meeting Recap detects `ffmpeg` in:

- `/opt/homebrew/bin/ffmpeg`
- `/usr/local/bin/ffmpeg`
- `ffmpeg` in `PATH`

Install with Homebrew:

```bash
brew install ffmpeg
```

The conversion command is:

```bash
ffmpeg -i input -ar 16000 -ac 1 -c:a pcm_s16le audio.wav
```

If `ffmpeg` is not installed, the app records 16 kHz mono WAV directly and saves it as `audio.wav`.

## Transcription Providers

### Auto

Auto tries providers in this order:

1. whisper.cpp CLI
2. MacWhisper CLI
3. Manual fallback

### whisper.cpp CLI

Detected paths:

- `/opt/homebrew/bin/whisper-cli`
- `/usr/local/bin/whisper-cli`
- `whisper-cli` in `PATH`

Install whisper.cpp with Homebrew:

```bash
brew install whisper.cpp
```

Download a compatible model yourself and set the model path in Settings. Model files are not included in this repository.

### MacWhisper CLI

Detected paths:

- `/opt/homebrew/bin/mw`
- `/usr/local/bin/mw`
- `mw` in `PATH`

Install and authenticate MacWhisper CLI according to its own documentation, then select it in Settings.

### Manual Fallback

If no local transcription tool is available, Meeting Recap still saves `audio.wav` and writes instructions into `transcript.md`.

## Summarization Providers

### Ollama

Ollama is the default local provider. Meeting Recap calls:

```text
http://localhost:11434/api/generate
```

with `stream=false`. The default model is `llama3.1`, configurable in Settings.

Install Ollama, then pull a model:

```bash
brew install ollama
ollama pull llama3.1
ollama serve
```

### Manual

Manual provider is always available. It saves `summarize-prompt.md`, copies the prompt to the clipboard, and lets you paste it into ChatGPT, Claude, a local model, or any other tool.

### OpenAI API

OpenAI API provider is optional. Add your own API key in Settings; it is stored in macOS Keychain.

This uses OpenAI API billing. A ChatGPT subscription or Codex subscription is not the same thing as OpenAI API access.

The app uses the OpenAI Responses API at:

```text
https://api.openai.com/v1/responses
```

### Codex CLI Experimental

Codex CLI support is experimental because Codex is primarily a coding agent, not a dedicated summarization API. Meeting Recap does not implement OAuth, does not manage login, and does not store Codex credentials.

To use it:

1. Install Codex CLI.
2. Run `codex`.
3. Sign in with ChatGPT.
4. Return to Meeting Recap and select Codex CLI Experimental.

Detected paths:

- `/opt/homebrew/bin/codex`
- `/usr/local/bin/codex`
- `/Applications/Codex.app/Contents/Resources/codex`
- `codex` in `PATH`

If Codex CLI is unavailable or invocation fails, Meeting Recap falls back to Manual summarization.

## Summary Format

`summary.md` uses this structure:

- TL;DR
- Key Topics Discussed
- Decisions Made
- Action Items
- Open Questions
- Risks / Concerns
- Notable Details
- Follow-up Draft

## Metadata

`metadata.json` includes:

- `startedAt`
- `endedAt`
- `durationSeconds`
- `appVersion`
- `macOSVersion`
- `outputDirectory`
- `audioPath`
- `transcriptPath`
- `summaryPath`
- `recordingPath`
- `screenshotPaths`
- `transcriptionProvider`
- `summarizationProvider`
- `errors`
- `warnings`

## Architecture

Core components:

- `AppState`
- `RecordingManager`
- `AudioRecordingService`
- `SystemAudioCaptureService`
- `ScreenCaptureService`
- `AudioExportService`
- `TranscriptionService`
- `WhisperCppTranscriptionService`
- `MacWhisperTranscriptionService`
- `SummarizationService`
- `OllamaSummarizationService`
- `OpenAIAPISummarizationService`
- `CodexCLISummarizationService`
- `ManualSummarizationService`
- `FileStorageService`
- `PermissionsService`
- `SettingsStore`
- `ExternalCommandRunner`

External integrations live behind protocols or focused service types so contributors can add providers without changing the recording pipeline.

## Known Limitations

- No speaker diarization in the MVP.
- System audio capture may vary by macOS version and is currently a Phase 1 placeholder.
- Screen recording is planned for Phase 2.
- Periodic screenshots are planned for Phase 3.
- Codex CLI provider is experimental.
- Users are responsible for consent before recording meetings.

## License

MIT
