# ARS Live 💬📞

ARS Live is a secure, real-time messaging and high-quality voice calling application built with Flutter, designed to keep people connected instantly, anywhere.

## Features

- 💬 Real-time messaging powered by Socket.IO
- 📞 High-quality voice calling via WebRTC
- 🔐 Secure authentication with Google Sign-In
- 🎨 Clean, modern UI with custom fonts (Google Fonts) and Lottie animations
- 📱 Cross-platform support (Android, iOS, Web)
- 📝 Markdown rendering support for chat content

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Real-time Communication:** Socket.IO Client, Flutter WebRTC
- **Authentication:** Google Sign-In
- **Local Storage:** Shared Preferences
- **Networking:** HTTP
- **UI/UX:** Google Fonts, Font Awesome Flutter, Lottie, Flutter Markdown Plus

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.10.4 or compatible)
- Dart SDK
- Android Studio / Xcode (for mobile builds)
- A running instance of the ARS Live backend server

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/ars2k03/ARS-Live_Frontend.git
   cd ARS-Live_Frontend
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the app
   ```bash
   flutter run
   ```

### Build

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## Project Structure

```
ARS-Live_Frontend/
├── android/          # Android platform-specific files
├── assets/images/    # Image assets
├── lib/              # Main application source code
├── test/             # Unit and widget tests
├── web/              # Web platform-specific files
├── pubspec.yaml      # Project dependencies and metadata
└── analysis_options.yaml
```

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check the [issues page](https://github.com/ars2k03/ARS-Live_Frontend/issues).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.