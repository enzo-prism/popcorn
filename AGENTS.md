# AGENTS.md

Guidance for Codex CLI working on the Popcorn iOS app.

Quick start
- Requirements: Xcode 15+, iOS 17+ deployment, XcodeGen.
- Generate the project: `xcodegen` (run after any file add/rename or `project.yml` change).
- Open `Popcorn.xcodeproj` (generated; do not hand-edit).

Build and test
- Scheme: `Popcorn`.
- Example build: `xcodebuild -project Popcorn.xcodeproj -scheme Popcorn -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build`
- Example test: `xcodebuild -project Popcorn.xcodeproj -scheme Popcorn -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' test`
- Unit tests live in `PopcornTests/`.

API key and demo mode
- Provide TMDb key via `Secrets.xcconfig` (gitignored) or `TMDB_API_KEY` env var.
- `Configs/Debug.xcconfig` and `Configs/Release.xcconfig` include `Secrets.xcconfig`.
- No key => demo mode with `popcorn/Resources/SampleMovies.json` (~100 movies).

Core architecture
- `popcorn/Data`: TMDb client, repositories, caches, demo loader.
- `popcorn/Domain`: Elo, pairing, taste model, insights logic.
- `popcorn/Models`: SwiftData models.
- `popcorn/ViewModels`: view state and mutations.
- `popcorn/Views`: SwiftUI views, UI styling.
- `popcorn/Resources`: assets and JSON configs.

Data behavior
- `MovieRepository` bootstraps the local SwiftData store on first launch.
- With an API key, it fetches up to `AppConfig.topMovieTargetCount` (default 1000) from TMDb.
- Reset local data by deleting the app or erasing simulator contents.

Tuning knobs
- `popcorn/Data/AppConfig.swift` for thresholds and constants.
- Pairing logic: `popcorn/Domain/PairSelector.swift` and `popcorn/Domain/TasteCATSelector.swift`.
- Taste vectors: edit `popcorn/Resources/TasteAxesConfig.json` and bump its `version` to force recompute.

Security and attribution
- Never commit real API keys or secrets.
- TMDb attribution is required in the app UI (About/Credits).
