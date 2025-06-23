# InfoAssistant 🚀

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/yourusername/infoassistant/actions)
[![Flutter](https://img.shields.io/badge/flutter-3.7.0%2B-blue)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20windows%20%7C%20macos%20%7C%20linux-blueviolet)](#)
[![License](https://img.shields.io/badge/license-unlicensed-lightgrey)](#license)

---

> **Your cross-platform AI-powered information assistant.**

InfoAssistant is a beautiful, modern, and cross-platform conversational assistant built with Flutter. It features voice input, text-to-speech, and a smart backend for context-aware Q&A. Designed for mobile, web, and desktop, InfoAssistant is your go-to digital helper for information retrieval and productivity.

---

## Table of Contents
- [Features](#features)
- [Screenshots](#screenshots)
- [Demo](#demo)
- [Getting Started](#getting-started)
- [Requirements](#requirements)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Features
- 🤖 **Conversational AI Chat**: Natural language Q&A with context-aware responses.
- 🎤 **Speech Recognition**: Ask questions using your voice (powered by `speech_to_text`).
- 🔊 **Text-to-Speech**: Listen to answers read aloud (powered by `flutter_tts`).
- 💬 **Persistent Chat History**: Maintains conversation context for more relevant answers.
- 🌗 **Dark & Light Mode**: Toggle between themes for comfortable viewing.
- 🔗 **Link Detection**: Recognizes and enables clickable URLs in responses.
- 🖥️ **Cross-Platform**: Runs on Android, iOS, Web, Windows, Linux, and macOS.
- ☁️ **Firebase Integration**: Uses Firebase for initialization and potential analytics/extensions.

---

## Screenshots
<p align="center">
  <img src="assets/icon.png" alt="App Icon" width="120"/>
  <!-- Add more screenshots as needed -->
</p>

---

## Demo
<!-- Add a link to a demo video or GIF if available -->

---

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/infoassistant.git
cd infoassistant
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
- The project uses Firebase for initialization. Configuration files are already included for Android, iOS, Web, and Windows.
- If you wish to use your own Firebase project, update `lib/firebase_options.dart` and the relevant platform files (e.g., `android/app/google-services.json`).

### 4. Run the App
- **Mobile/Web/Desktop:**
  ```bash
  flutter run -d <device>
  ```
- **Web:**
  ```bash
  flutter run -d chrome
  ```

---

## Requirements
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.7.0)
- Dart SDK (compatible with Flutter)
- Firebase account (optional, for custom backend)
- Internet connection (for backend API)

### Key Dependencies
- [`provider`](https://pub.dev/packages/provider) (state management)
- [`url_launcher`](https://pub.dev/packages/url_launcher) (open links)
- [`flutter_tts`](https://pub.dev/packages/flutter_tts) (text-to-speech)
- [`speech_to_text`](https://pub.dev/packages/speech_to_text) (speech recognition)
- [`firebase_core`](https://pub.dev/packages/firebase_core) (Firebase integration)
- [`http`](https://pub.dev/packages/http) (API requests)

---

## Project Structure
```
lib/
  main.dart              # App entry point
  chat_screen.dart       # Main chat UI and logic
  api_service.dart       # Handles backend API communication
  speech_service.dart    # Speech recognition and TTS logic
  firebase_options.dart  # Firebase config (auto-generated)
assets/
  icon.png               # App icon
```

---

## Architecture Overview
- **UI Layer:** Built with Flutter's Material components, supporting both light and dark themes.
- **Chat Logic:** `chat_screen.dart` manages chat state, message rendering, speech controls, and user interactions.
- **Speech Services:** `speech_service.dart` abstracts speech-to-text and text-to-speech, supporting voice input/output.
- **API Integration:** `api_service.dart` communicates with a backend AI (default: [info-assistant-qhctotcy8-reggie-s-projects.vercel.app](https://info-assistant-qhctotcy8-reggie-s-projects.vercel.app)), sending user queries and chat history for context-aware answers.
- **Firebase:** Used for initialization and extensibility (analytics, auth, etc. can be added).

---

## Contributing
Contributions are welcome! To contribute:
1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

Please follow best practices and ensure your code passes `flutter analyze`.

---

## License
This project is currently **unlicensed**. Please contact the maintainer if you wish to use or distribute this code.

---

## Contact
For questions, suggestions, or collaboration:
- GitHub: [yourusername](https://github.com/yourusername)
- Email: your.email@example.com

---

<p align="center"><b>InfoAssistant</b> – Your cross-platform AI-powered information assistant. 🤖</p>
