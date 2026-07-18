# 🎓 Academic Hub (Academic Resource Sharing & Communication System)

Academic Hub is a premium, feature-rich Flutter Android application designed to streamline resource distribution and communication between Faculty and Students. It integrates real-time database syncing, secure document storage, and cutting-edge **Generative AI** features.

---

## 🤖 Advanced AI Features (Groq Cloud API)

This app features state-of-the-art AI integration powered by **Llama 3.3 70B** through the Groq Cloud API, delivering responses in milliseconds:

1. **💬 DocuChat AI (Interactive Study Buddy)**
   - Open any PDF in the app and open the DocuChat panel.
   - Ask questions, get explanations, clarify complex definitions, or request instant summaries directly from the PDF's text content.
2. **📝 AI Lecture Drafts (Auto-Note Generation)**
   - Faculty can input any topic and class context.
   - The AI automatically drafts structured, beautifully-formatted Markdown lecture notes (including practice questions) which the faculty can edit and post instantly.
3. **✨ Automatic AI Fallbacks**
   - Built-in templates prevent application crashes or stalls if connection limits are reached.

---

## 🚀 Core Features

### 🔐 Role-Based Access Control
* **Faculty Interface**: Upload documents (PDF, PPT, Word), manage uploaded files, create class-specific alerts, view download counts, and chat with students.
* **Student Interface**: View and download study materials tailored to their specific Branch, Semester, and Section; read PDFs in-app, and create collaborative learning groups.

### 📁 Smart Materials Hub
* Filtered automatically by **Branch ➔ Semester ➔ Section**.
* Supports direct in-app PDF rendering with custom zoom and page controls.
* Built-in warning banner alert if non-PDF formats are uploaded, informing users about DocuChat AI compatibility.

### ✉️ Real-Time Messaging & Collaboration
* **1-to-1 Messaging**: Direct real-time chat between students and faculty.
* **Group Discussions**: Peer-to-peer chat rooms created by students for collaborative group study.
* **Rich Attachments**: Real-time image and document uploads directly inside chat bubbles.
* **Security**: Support for deleting messages in real-time.

### 📄 Advanced PDF Engine (Dual-Library Architecture)
The app uses a two-library approach to deliver a premium, fully-featured PDF experience:

* **`pdfx` (Native PDF Rendering)**
  - Renders PDF pages directly on-device using the platform's **native PDF engine** (Android's `PdfRenderer` API).
  - Delivers pixel-perfect, smooth, high-resolution page rendering with pinch-to-zoom and page-swipe navigation.
  - Because rendering happens natively on the device, it is extremely fast and works completely offline with no internet connection required.

* **`syncfusion_flutter_pdf` (On-Device Text Extraction)**
  - Used exclusively to **extract raw text content** from a PDF's pages entirely on-device without sending the file to any server.
  - The extracted text is then fed into the **DocuChat AI prompt**, allowing the Groq Llama 3.3 70B model to answer contextual questions about the document.
  - This design keeps user documents **100% private** — the actual PDF file is never uploaded to any AI server.

---

## 📁 Complete Project Structure

```text
academicapp/                                    # Flutter project root
│
├── android/                                    # Android native platform project
│   ├── app/
│   │   ├── AndroidManifest.xml                 # App-level manifest (permissions, metadata)
│   │   ├── build.gradle                        # App module build configuration
│   │   ├── google-services.json                # Firebase Android connection credentials
│   │   └── src/
│   │       ├── main/
│   │       │   ├── AndroidManifest.xml         # Main activity & permissions declaration
│   │       │   ├── kotlin/
│   │       │   │   └── MainActivity.kt         # Android app entry point (Flutter host)
│   │       │   └── res/                        # Android resources (icons, splash, styles)
│   │       ├── debug/
│   │       │   └── AndroidManifest.xml         # Debug-only manifest overrides
│   │       └── profile/
│   │           └── AndroidManifest.xml         # Profile/perf-mode manifest overrides
│   ├── build.gradle.kts                        # Root Android build configuration
│   ├── gradle.properties                       # Gradle JVM and build flags
│   ├── gradlew                                 # Unix Gradle wrapper script
│   ├── gradlew.bat                             # Windows Gradle wrapper script
│   └── settings.gradle.kts                    # Gradle module and plugin settings
│
├── ios/                                        # iOS native platform project
│   └── Runner/
│       ├── AppDelegate.swift                   # iOS application lifecycle entry point
│       ├── SceneDelegate.swift                 # iOS scene session management
│       ├── Info.plist                          # iOS app permissions and metadata config
│       ├── Runner-Bridging-Header.h            # Swift/Objective-C bridging header
│       ├── GeneratedPluginRegistrant.h         # Auto-generated Flutter plugin header
│       ├── GeneratedPluginRegistrant.m         # Auto-generated Flutter plugin registration
│       └── Assets.xcassets/                   # App icon and splash image assets
│
├── web/                                        # Web platform configuration
├── windows/                                    # Windows desktop configuration
├── macos/                                      # macOS desktop configuration
├── linux/                                      # Linux desktop configuration
│
├── assets/                                     # Static files bundled inside the APK
│   └── holographic_students.png                # Welcome screen hero illustration
│
├── test/                                       # Automated test directory
│   └── widget_test.dart                        # Default Flutter widget smoke test
│
├── lib/                                        # ✅ Core Dart/Flutter application code
│   │
│   ├── main.dart                               # App entry point, theme & AuthWrapper router
│   ├── firebase_options.dart                   # Auto-generated Firebase platform config
│   │
│   ├── config/                                 # Environment and secrets configuration
│   │   ├── secrets.dart                        # 🔑 Real API keys — GITIGNORED (never pushed)
│   │   └── secrets.example.dart                # Public template — copy & rename to set up
│   │
│   ├── models/                                 # Typed data structure definitions (DTOs)
│   │   ├── user_model.dart                     # Student/Faculty profile (name, role, branch)
│   │   ├── material_model.dart                 # Uploaded document metadata (title, URL, type)
│   │   ├── message_model.dart                  # 1-to-1 chat message (text, sender, timestamp)
│   │   └── group_chat_model.dart               # Group chat room (name, members, avatar, ID)
│   │
│   ├── providers/                              # Reactive state management (Provider package)
│   │   └── auth_provider.dart                  # Login, signup, logout, session & role state
│   │
│   ├── services/                               # Backend & external API communication layer
│   │   ├── ai_service.dart                     # Groq API client (Llama 3.3 70B) — DocuChat & drafts
│   │   ├── firestore_service.dart              # Firestore CRUD & real-time snapshot streams
│   │   └── storage_service.dart                # Cloudinary upload client with timeout handling
│   │
│   ├── screens/                                # Full-page UI views (one file = one screen)
│   │   ├── splash_screen.dart                  # Animated logo intro screen (particle + fade-in)
│   │   ├── welcome_screen.dart                 # Staggered greeting hero screen shown after login
│   │   ├── login_screen.dart                   # Sign-in form with real-time inline validation
│   │   ├── signup_screen.dart                  # Registration with Branch/Semester/Section pickers
│   │   ├── home_screen.dart                    # Bottom tab bar hub (Materials, Chat, My Files)
│   │   ├── upload_material_screen.dart         # File upload panel + AI lecture draft generator
│   │   ├── view_materials_screen.dart          # Branch → Semester → Section filtered material list
│   │   ├── my_materials_screen.dart            # Uploader's file manager (edit title, delete)
│   │   ├── pdf_viewer_screen.dart              # Native pdfx PDF reader + DocuChat AI bottom sheet
│   │   ├── messaging_screen.dart               # 1-to-1 real-time chat (text, image, file sharing)
│   │   └── group_chat_screen.dart              # Group study channel with member management
│   │
│   └── widgets/                               # Reusable UI component library
│       └── premium_background.dart             # Glassmorphism cards, glow sweeps & float animations
│
├── pubspec.yaml                                # Project metadata & package dependency declarations
├── pubspec.lock                                # Exact locked versions of all resolved packages
├── firebase.json                               # Firebase CLI project configuration
├── analysis_options.yaml                       # Dart linter and static analysis rules
├── .gitignore                                  # Files and folders excluded from GitHub pushes
└── README.md                                   # Project documentation (this file)
```

---

## ⚙️ Setup Instructions

### 1. Prerequisites
* Flutter SDK (>= 3.0.0)
* Android SDK & Android Studio
* A Firebase Console project
* A Cloudinary free account (for high-speed document uploads)

### 2. Clone and Setup Dependencies
```bash
git clone <repository-url>
cd academicapp
flutter pub get
```

### 3. Add API Keys (Secrets Setup)
To prevent API keys from leaking publicly to GitHub, they are stored in a gitignored configuration file:
1. Navigate to `lib/config/`
2. Duplicate `secrets.example.dart` and rename it to `secrets.dart`.
3. Open `secrets.dart` and fill in your keys:
   ```dart
   class AppSecrets {
     static const String groqApiKey = 'your_groq_api_key';
     static const String cloudinaryCloudName = 'your_cloudinary_cloud_name';
     static const String cloudinaryUploadPreset = 'your_upload_preset';
   }
   ```

### 4. Connect Firebase
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Email/Password Authentication** and **Cloud Firestore Database**.
3. Register your Android app (Package name: `com.example.academicapp`).
4. Download the `google-services.json` file and place it in the `android/app/` folder.

### 5. Build and Run
```bash
# Perform a clean build setup
flutter clean
flutter pub get

# Run on a connected device/emulator
flutter run
```

---

## 🔒 Firestore Security Rules

To secure user accounts and communication, paste the following rules in your Firestore Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null;
    }
    
    match /materials/{materialId} {
      allow read, write: if request.auth != null;
    }
    
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    match /groupChats/{groupId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    match /groupChats/{groupId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🛠️ Stack & Dependencies
* **Core**: Flutter / Dart
* **Backend**: Firebase Auth, Cloud Firestore
* **Storage**: Cloudinary (Unsigned Preset API)
* **AI engine**: Groq API (Llama 3.3 70B Versatile)
* **PDF Rendering**: `pdfx` — Native on-device PDF page renderer (uses Android's PdfRenderer API)
* **PDF Text Extraction**: `syncfusion_flutter_pdf` — On-device text extraction to power DocuChat AI without uploading documents to any server
* **Packages**: `provider`, `http`, `file_picker`, `google_fonts`, `intl`.

---

**Made with ❤️ for Academic Excellence**