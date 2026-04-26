# Contributing

Thanks for helping improve Meeting Recap.

## Principles

- Keep the app local-first.
- Do not add a backend.
- Do not commit secrets, recordings, transcripts, generated summaries, or model files.
- Keep paid and cloud services optional.
- Put external integrations behind protocols or focused service types.
- Prefer clear Swift and small modules over clever abstractions.

## Development

```bash
xcodegen generate
xcodebuild -project MeetingRecap.xcodeproj -scheme MeetingRecap -configuration Debug build
xcodebuild test -project MeetingRecap.xcodeproj -scheme MeetingRecap -destination 'platform=macOS'
```

## Provider Contributions

Provider implementations should:

- Detect availability without side effects.
- Return setup instructions when unavailable.
- Avoid storing credentials unless they use Keychain or the provider's own local auth.
- Keep provider-specific code out of `RecordingManager` where possible.

## Pull Requests

Please include:

- What changed.
- How you tested it.
- Any privacy or provider-behavior implications.
- Screenshots for UI changes when helpful.
