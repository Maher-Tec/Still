<div align="center">

<img src="assets/images/banner.png" alt="STILL — a quiet ambient water scene" width="100%" />

# STILL

### A small, interactive place to pause.

Flutter app · Ambient water scene · No account or cloud service

</div>

---

STILL is an ambient landscape you can touch. Make ripples on the water, move the light, choose a scene mood, or set your phone down and watch the surface settle.

The app is intentionally focused: it has no feed, goals, reminders, or session history.

## ✦ What you can do

| Interaction | What happens |
| --- | --- |
| Touch or draw on the water | Expanding ripples follow your touch. |
| Drag the light | Move the celestial light and its reflection. |
| Choose a mood | Switch between Dusk, Midnight, Eclipse, Emerald, Aurora, and Dawn. |
| Tilt your phone | Gently shift the light and horizon with accelerometer input. |
| Stay still | After a short pause, the water’s movement eases toward rest. |
| Enable sound | Hear a quiet loop matched to the selected mood. Sound is optional. |
| Use the breath pacer | Follow a visual breathing guide with selectable rhythms. |

Settings also include motion and haptics controls and a sleep timer. First launch offers a choice to keep sound off or enable it; that preference is remembered on the device.

## ◌ The scene

The landscape is painted in Flutter with `CustomPainter`. Gradients, layered shorelines, stars, reflected light, slow water swells, and touch ripples are drawn in code. The scene responds to touch and device movement, and settles visually when the phone is still. It does not rely on a full-screen background image or a separate game engine.

## 🚀 Run it locally

### Requirements

- Flutter SDK and Dart SDK compatible with the constraints in `pubspec.yaml`
- A connected device or emulator

```bash
git clone <your-repository-url>
cd still
flutter pub get
flutter run
```

Audio is bundled in `assets/audio/`. Sound can be enabled during first launch or from the main screen.

## 🧰 Built with

- **Flutter** for the app and custom-painted scene
- [`sensors_plus`](https://pub.dev/packages/sensors_plus) for accelerometer input
- [`audioplayers`](https://pub.dev/packages/audioplayers) for optional ambient audio
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) for on-device preferences

`lottie` and `cupertino_icons` are listed in `pubspec.yaml`, but are not currently used by the Dart source.

## 🗂️ Project structure

```text
lib/
├── main.dart
├── app/
│   └── still_app.dart
├── core/
│   ├── app_colors.dart
│   └── app_durations.dart
├── screens/
│   ├── first_launch_screen.dart
│   └── still_screen.dart
├── services/
│   ├── ambient_tone_service.dart
│   └── whisper_event_service.dart
└── widgets/
    ├── ambient_water_scene.dart
    ├── micro_grain.dart
    ├── mode_dial.dart
    ├── presence_glow.dart
    └── subtle_gradient.dart
```

## 🔒 Data and storage

STILL has no backend, accounts, or cloud sync. `shared_preferences` stores app preferences on the device, including onboarding completion, sound, motion, haptics, selected mood, and breathing-pacer settings. There is no personal content or session history feature.

## 📄 License

No license has been selected for this repository yet. Until a license is added, the source and bundled assets are not granted open-source reuse rights. If you want others to use, modify, and redistribute this project under the MIT License, add a `LICENSE` file containing the MIT License text and your copyright holder and year.

---

<div align="center">
Made with Flutter · Designed for a quieter moment
</div>
