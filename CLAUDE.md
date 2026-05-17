# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                          # install deps
flutter run -d chrome                    # dev (web is the only supported platform)
flutter analyze                          # lint — CI gates on this
flutter test                             # all tests
flutter test test/mood_test.dart         # one file
flutter test --plain-name "round-trips"  # one test by name
flutter build web --release              # output -> build/web/
```

### First-time setup gotcha

Platform folders (`android/`, `ios/`, `web/icons`, etc.) are intentionally not committed — only `lib/`, `test/`, `web/index.html`, `pubspec.yaml` are. Before the first build on a fresh clone, run:

```bash
flutter create . --platforms=web --project-name=mood_tracker
```

This adds the missing scaffolding without touching existing source. See `SETUP.md`.

## Architecture

Single-screen Flutter **web** app. State is plain `setState` in `HomeScreen`; the dataset is intentionally tiny so no state-management library is used.

**Data flow:** `HomeScreen` owns the `List<MoodEntry>` and a `MoodStorage` instance. Tapping a `MoodPickerButton` calls `_logMood`, which prepends an entry, calls `setState`, then asynchronously persists via `shared_preferences` (key `mood_entries_v1`). On boot, `_load()` reads and sorts newest-first. The timeline displays `_entries.take(7)`.

**The `Mood` enum (`lib/models/mood.dart`) is the source of truth.** Each value carries its own `label` and `accent` color via switch expressions. Adding a new mood requires updates in **four** places:
1. `Mood` enum + `label` switch + `accent` switch (`mood.dart`)
2. `_drawEyebrows` switch in `MoodFacePainter`
3. `_drawMouth` switch in `MoodFacePainter`
4. Special-case extras (blush/tear) in `MoodFacePainter.paint`

Forgetting any of the painter switches will throw at runtime because they're non-exhaustive.

**The CustomPainter is the heart of the project.** `MoodFacePainter` (`lib/widgets/mood_face_painter.dart`) draws every face from canvas primitives only — `drawCircle`, `drawArc`, `drawPath`, `drawLine`. **No images, emoji, or icon fonts.** All feature positions/sizes are expressed as fractions of `radius` so faces scale correctly at any size. When changing a face, preserve the visual distinction between moods (mouth direction, eyebrow angle, eye style) called out in `README.md` — these are the spec.

**Animation pattern:** `AnimatedMoodFace` runs a wiggle+scale `TweenSequence` whenever its `animateKey` prop changes (compared in `didUpdateWidget`). `HomeScreen` triggers this by incrementing `_pickerAnimTrigger` (for the preview face) or `_animateTrigger` + setting `_animateIndex` (for a specific timeline card). The key is just an `Object?` sentinel — its value is meaningless, only the change matters.

**Storage layer is deliberately isolated** in `MoodStorage` so swapping `shared_preferences` for Hive/Firestore later is a one-file change. Decode errors fall back to an empty list rather than throwing.

## Lints

`analysis_options.yaml` enforces `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, and `avoid_print` on top of `flutter_lints`. CI fails on analyzer warnings. Use a logger or rethrow rather than `print`.

## Deployment

- **Firebase Hosting** is the primary target. GitHub Actions (`.github/workflows/deploy.yml`) runs `flutter analyze` → `flutter build web --release` → deploy on push to `main`. Requires repo secrets `FIREBASE_SERVICE_ACCOUNT` and `FIREBASE_PROJECT_ID`. `.firebaserc` still contains the placeholder `YOUR_FIREBASE_PROJECT_ID` — replace before deploying.
- **Vercel** is a secondary option (`vercel.json` is committed); see `README.md` for the buildpack workaround needed to install Flutter on Vercel.
