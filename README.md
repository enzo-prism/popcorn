# Popcorn

Popcorn is a SwiftUI + SwiftData iOS app for building a personal movie ranking through fast A/B picks. It is local-first and falls back to bundled sample data when no TMDb API key is configured.

## Prereqs

- Xcode 15+ (SwiftData requires iOS 17+)
- iOS 17.0+ deployment target
- XcodeGen (`brew install xcodegen`)

## Setup

```sh
git clone https://github.com/enzo-prism/popcorn.git
cd popcorn
xcodegen
open Popcorn.xcodeproj
```

## TMDb API key

The app reads your TMDb API key from either:

1) `Secrets.xcconfig` (Xcode builds), or
2) the `TMDB_API_KEY` environment variable (fallback).

Create `Secrets.xcconfig` in the repo root (it is gitignored):

```xcconfig
TMDB_API_KEY = YOUR_TMDB_KEY_HERE
```

If no key is present, the app runs in demo mode using the bundled `Popcorn/Resources/SampleMovies.json`.

## How the Top 500 fetch works

- Uses TMDb `/discover/movie`.
- Filters to the last 30 years (primary release date).
- Sorts by `vote_average` descending.
- Enforces `vote_count.gte` using `AppConfig.minimumVoteCount` (default 2000).
- Paginates until 500 unique movies are collected, then saves to SwiftData.
- Credits and keywords are fetched lazily only when insights need them.

To re-run the fetch, reset the local SwiftData store (see below) and relaunch.

## Taste personality (adaptive)

Popcorn learns a 6D taste profile from A/B picks using a forced-choice Bayesian update. Each movie has a stored taste vector built from genres (and optional keywords). The model keeps:

- `mu` (your latent taste vector) and `sigma` (uncertainty)
- a per-axis info tracker for balancing under-learned axes
- confidence = `1 - trace(sigma) / trace(sigma0)` where `sigma0 = identity * AppConfig.tasteSigmaScale`

The profile is considered stable once it reaches both:

- minimum comparisons (default 20), and
- confidence threshold (default 0.5)

### Tuning taste axes

Edit `popcorn/Resources/TasteAxesConfig.json` to change genre/keyword weights. When you change weights, bump the `version` number in the config. The app will recompute and cache movie taste vectors in SwiftData on next launch.

## Reset local data

Any of these will wipe local SwiftData storage:

- Delete the app from the simulator/device.
- In Simulator: Device > Erase All Content and Settings.

## Build and test

If you have a different simulator name, swap the destination accordingly.

```sh
xcodebuild -project Popcorn.xcodeproj -scheme Popcorn -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build
xcodebuild -project Popcorn.xcodeproj -scheme Popcorn -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
```

## TMDb attribution

The About and Credits sections include the required TMDb attribution text and a logo placeholder. Replace the placeholder with the official TMDb logo asset if desired.
