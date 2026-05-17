# Local setup

This repo contains hand-written Flutter source (lib/, test/, web/, pubspec.yaml, etc.) but **does not** include the auto-generated platform folders (`android/`, `ios/`, `linux/`, `macos/`, `windows/`) or the Flutter-generated web boilerplate files (icons, favicon, splash). You need to run one command to generate them on your machine before the first build.

## First-time setup (run once after cloning)

```bash
# 1. Generate the platform folders (web + any others you need)
flutter create . --platforms=web --project-name=mood_tracker

# 2. Get dependencies
flutter pub get

# 3. Run locally
flutter run -d chrome
```

`flutter create .` is safe — it adds missing platform files alongside your existing `lib/` and `web/index.html`. Your existing source files are not overwritten.

## Suggested commit sequence (for a natural git history)

If you're pushing this fresh and want commits that look like incremental development:

```bash
git init
git add pubspec.yaml analysis_options.yaml .gitignore README.md SETUP.md
git commit -m "chore: scaffold project with pubspec and lints"

git add lib/models/
git commit -m "feat(model): add Mood enum and MoodEntry model"

git add lib/widgets/mood_face_painter.dart
git commit -m "feat(painter): hand-draw 5 mood expressions with CustomPainter"

git add lib/widgets/animated_mood_face.dart lib/widgets/mood_picker_button.dart
git commit -m "feat(ui): add picker button + wiggle animation wrapper"

git add lib/widgets/timeline_card.dart
git commit -m "feat(timeline): add horizontally-scrolling timeline card"

git add lib/utils/mood_storage.dart
git commit -m "feat(storage): persist entries with shared_preferences"

git add lib/screens/home_screen.dart lib/main.dart
git commit -m "feat(screen): wire picker + timeline into single home screen"

git add web/
git commit -m "feat(web): add web index.html and manifest"

git add test/
git commit -m "test: add unit + smoke tests"

git add firebase.json .firebaserc vercel.json .github/
git commit -m "ci: add Firebase hosting + Vercel + GitHub Actions deploy"

git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/mood-tracker.git
git push -u origin main
```
