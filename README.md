# Docsmind

**Docsmind** is a versatile, cross-platform document scanning application built with Flutter. It supports real-time edge detection, manual corner adjustment, and PDF generation. The application leverages native **OpenCV 4.12.0** and **YOLOv8** for high-accuracy document detection and image processing, providing a seamless and highly performant experience on Android, Windows, and the Web.

---

## 🔥 Key Features

- **Advanced Document Scanning**: Uses a customized YOLOv8 model combined with OpenCV for reliable real-time document edge detection and cropping.
- **Cross-Platform Support**: Built primarily for Android, with foundations for Web and Windows support.
- **Modern UI/UX**: Features a sleek, minimalist monochrome camera interface and intuitive controls.
- **PDF Generation**: Compress and export scanned standard-quality documents directly to PDF.
- **Native Performance**: Heavy image processing and matrix operations are offloaded to C++ using JNI on Android to ensure buttery smooth performance.
- **State Management**: Scalable architecture using `flutter_riverpod` for responsive state management.

---

## 📁 Repository Structure

The project follows a feature-first architecture to ensure scalability and separation of concerns.

```text
docsmind/
├── android/                 # Native Android implementation
│   ├── app/src/main/
│   │   ├── cpp/             # C++ native binaries (OpenCV hooks & image processing)
│   │   ├── kotlin/          # Kotlin source files & Flutter MethodChannels
│   │   └── res/             # Android-specific resources (Launcher Icons, etc.)
│   └── opencv/              # Local Android Library Module for OpenCV 4.12.0 integration
├── assets/                  # Local assets
│   ├── images/              # App images and icons
│   └── models/              # YOLOv8 and TensorFlow Lite models
├── lib/                     # Flutter Dart source code
│   ├── constants/           # Global app constants (Typography, Colors, Layouts)
│   ├── core/                # Core utilities, theme configuration, and Splash Screen
│   ├── features/            # Feature-driven modular code
│   │   ├── camera/          # Custom Camera implementation & minimalist UI
│   │   │   ├── models/      # Data abstractions for camera state
│   │   │   ├── providers/   # Riverpod state providers for camera
│   │   │   ├── screens/     # Camera feature screens
│   │   │   └── widgets/     # Reusable UI widgets (Preview, Shutter, Zoom)
│   │   ├── document_scanner/# Core document detection logic
│   │   │   └── services/    # YOLO & OpenCV native bridge communication logic
│   │   └── settings/        # User preferences and app settings logic
│   ├── screens/             # Primary standalone screens (Home, Compress, Settings)
│   └── main.dart            # Flutter application entry point
├── linux/                   # Linux platform configuration
├── macos/                   # macOS platform configuration
├── test/                    # Unit and widget tests
├── web/                     # Web platform configuration
├── windows/                 # Windows platform configuration
├── yolo/                    # Local YOLO model training/export scripts & utilities
├── PROJECT_STATUS.md        # Real-time development tracking, dev log & milestones
└── pubspec.yaml             # Dart dependencies and asset declarations
```

---

## 🚀 Getting Started

### Prerequisites

To run this project, make sure you have the following installed on your machine:

1. **Flutter SDK** (`>=3.6.0`) - [Install Guide](https://docs.flutter.dev/get-started/install)
2. **Android Studio** (for Android development) or **Visual Studio** (for Windows development).
3. **NDK (Native Development Kit)** & **CMake** via Android Studio SDK Manager (Required for building C++ OpenCV extensions).
4. **Java 17** (Required for the latest Gradle build standards).

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/docsmind.git
   cd docsmind
   ```

2. **Fetch Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App:**
   Make sure you have an Android device connected or an emulator running.
   ```bash
   flutter run
   ```

> **Note on OpenCV Integration (Android):** 
> The application uses a precompiled offline version of OpenCV (`libopencv_java4.so`). When building the app, Gradle relies on CMake to include the shared C++ library (`libc++_shared.so`). If you encounter OpenCV initialization errors, run `flutter clean` followed by `flutter run`.

---

## 🛠 Tech Stack

- **Frontend/UI:** Flutter & Dart
- **State Management:** Riverpod (`flutter_riverpod`)
- **Native Bridge:** MethodChannels (Kotlin <-> Dart)
- **Computer Vision:** OpenCV (C++ / Java via JNI) & YOLOv8 (TFLite)
- **Hardware Integrations:** `camera` plugin for custom camera view
- **Document Processing:** `google_mlkit_document_scanner`, `pdf`, `image`

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check [issues page](https://github.com/your-username/docsmind/issues). 

Please review `PROJECT_STATUS.md` before making pull requests to align with ongoing development goals and known bug fixes.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
