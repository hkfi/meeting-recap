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
make build
make test
make run
make smoke-launch
make install
```

## Versioning

Use the version helper before tagging a release:

```bash
scripts/set-version.sh 0.2.0 2
```

Publish a release with:

```bash
make release VERSION=0.2.0
```

`make release` runs tests, builds locally, launches the built app, confirms it is running, and then pushes the tag. The release workflow validates the tag against `VERSION` and the Xcode `MARKETING_VERSION`, then builds and ad-hoc signs the app using the same lightweight pattern as DailyPhotos.

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
