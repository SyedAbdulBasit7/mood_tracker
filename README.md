# Mood Tracker — Flutter Web

A single-screen mood tracker where you tap to log how you feel, see your last 7 entries in a horizontal timeline, and tap any past entry to watch it animate. All mood faces are hand-rendered with Flutter's `CustomPainter` — no images, emoji, or icon fonts.

🔗 **Live demo:** https://mood-tracker-407c6.web.app
📦 **Repo:** _add your GitHub repo URL here_

---

## ✨ Features

- **5 hand-painted expressions** drawn entirely from primitives (`drawCircle`, `drawArc`, `drawPath`, `drawLine`): Happy, Good, Neutral, Sad, Angry.
- **Tap to log** — tap any face in the picker to save the current mood with a timestamp.
- **Last 7 entries** rendered as a horizontally scrollable timeline of cards. Each card shows the date, time, mood label, the drawn face, and a color accent matching the mood.
- **Tap any past entry to animate** — the face wiggles + scales briefly.
- **Persistent storage** via `shared_preferences` (uses `localStorage` on web), so refresh-safe.
- **Responsive layout** that works on mobile, tablet, and desktop browsers.

---

## 🎨 How the faces are drawn

Every face lives in `lib/widgets/mood_face_painter.dart` as a `CustomPainter`. The painter assembles each expression from canvas primitives:

| Feature | Primitives used |
|---|---|
| Face circle + outline | `canvas.drawCircle` |
| Eyes (dots / arcs) | `canvas.drawCircle`, `canvas.drawArc` |
| Eyebrows (angle differs per mood) | `canvas.drawLine`, `canvas.drawPath` (quadratic bezier) |
| Mouth (smile / frown / wave / straight) | `canvas.drawArc`, `canvas.drawLine`, `canvas.drawPath` |
| Blush (happy only) | `canvas.drawCircle` |
| Tear (sad only) | `canvas.drawPath` |

Differences between moods are clearly visible in:
- **Mouth arc direction** — upward for happy/good, flat for neutral, inverted for sad, zig-zag path for angry.
- **Eyebrow angle** — inward-down for angry, outer-down for sad, flat for neutral, gentle arc for good/happy.
- **Eye style** — happy eyes become upward arcs (closed-smile look) while others are filled circles.
- **Extras** — blush on happy/good, tear on sad.

---

## 🏗️ Architecture

```
lib/
├── main.dart                       # App entry, MaterialApp setup
├── models/
│   └── mood.dart                   # Mood enum (label + accent color) + MoodEntry model
├── utils/
│   └── mood_storage.dart           # shared_preferences persistence layer
├── widgets/
│   ├── mood_face_painter.dart      # The CustomPainter — heart of the project
│   ├── animated_mood_face.dart     # Wiggle + scale animation wrapper
│   ├── mood_picker_button.dart     # Tappable hover-scaling face button
│   └── timeline_card.dart          # Timeline entry card
└── screens/
    └── home_screen.dart            # Single screen with picker + timeline
```

State management is intentionally simple `setState` since the app is single-screen and the dataset is tiny. The storage layer is abstracted in `MoodStorage` so swapping to Hive, Firestore, or any backend later is a one-file change.

---

## 🚀 Running locally

```bash
flutter pub get
flutter run -d chrome
```

Build a release bundle:

```bash
flutter build web --release
```

The output lands in `build/web/`.

---

## ☁️ Deployment

### Option A — Firebase Hosting

1. Install the Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
4. Replace `YOUR_FIREBASE_PROJECT_ID` in `.firebaserc` with your project ID.
5. Build and deploy:
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

The included `firebase.json` already points the public dir at `build/web` and adds long-lived caching for static assets.

A GitHub Actions workflow is included at `.github/workflows/deploy.yml` — set these repo secrets to enable automatic deploys on push to `main`:
- `FIREBASE_SERVICE_ACCOUNT` — JSON from a service account with Hosting Admin role.
- `FIREBASE_PROJECT_ID` — your Firebase project ID.

### Option B — Vercel

1. Push the repo to GitHub.
2. Import the repo in Vercel.
3. Vercel reads `vercel.json` automatically — build command is `flutter build web --release` and output is `build/web`.
4. For Vercel to install Flutter, add a `vercel-build` script or use a Flutter buildpack. Easiest path:
   ```json
   "scripts": {
     "vercel-build": "git clone https://github.com/flutter/flutter.git -b stable --depth 1 && export PATH=\"$PATH:`pwd`/flutter/bin\" && flutter build web --release"
   }
   ```
   (add to a `package.json` at root if Vercel can't natively detect Flutter).

---

## 📝 License

MIT — do whatever you want.
