# 📚 BookSwap

> **Swap books, share stories** — A modern Flutter app for book lovers to discover, share, and exchange books with their community.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-9.0+-FFCA28?logo=firebase)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## ✨ Features

### 🔐 Authentication
- ✅ Email/Password authentication with Firebase Auth
- ✅ Secure signup and login flows
- ✅ User profile management
- ✅ Session persistence

### 📖 Book Management
- ✅ **Add Books** — Upload book listings with cover images
- ✅ **Browse Books** — Discover available books from other users
- ✅ **My Listings** — View and manage your own book listings
- ✅ **Edit/Delete** — Update book details or remove listings
- ✅ **Search** — Filter books by title or author
- ✅ **Real-time Updates** — See new books instantly via Firestore streams

### 💬 Messaging
- ✅ **Chat System** — Communicate with other users about book swaps
- ✅ **Real-time Messages** — Instant message delivery
- ✅ **Chat History** — Persistent conversation threads

### ⚙️ Settings
- ✅ **Profile Management** — Update display name
- ✅ **Notifications** — Toggle notification preferences
- ✅ **Account Info** — View user details
- ✅ **Logout** — Secure session termination

### 🎨 UI/UX
- ✅ **Modern Design** — Clean, bold purple gradient theme
- ✅ **Responsive Layout** — Works on phones and tablets
- ✅ **Smooth Animations** — Hero animations and transitions
- ✅ **Offline Fonts** — Local Poppins font support
- ✅ **Loading States** — Shimmer effects and progress indicators
- ✅ **Error Handling** — User-friendly error messages

---

## 📸 Screenshots

| Welcome Screen | Browse Books | My Listings | Chat |
|:--------------:|:------------:|:-----------:|:----:|
| ![Welcome](screenshots/welcome.png) | ![Browse](screenshots/browse.png) | ![Listings](screenshots/listings.png) | ![Chat](screenshots/chat.png) |
| Login Screen | Add Book | Book Details | Settings |
| ![Login](screenshots/login.png) | ![Add Book](screenshots/add_book.png) | ![Details](screenshots/details.png) | ![Settings](screenshots/settings.png) |

> 📝 **Note:** Add your screenshots to the `screenshots/` directory and update the paths above.

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.0.0 or higher)
- **Dart** (3.0.0 or higher)
- **Firebase Account** (free tier works)
- **Android Studio** / **Xcode** (for mobile development)
- **VS Code** or **Android Studio** (recommended IDE)

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/bookswap_app.git
cd bookswap_app
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Firebase Setup

##### a. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `bookswap-app`
4. Follow the setup wizard

##### b. Add Android App
1. In Firebase Console, click the Android icon
2. Register app with package name: `com.example.bookswap_app`
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

##### c. Add iOS App (Optional)
1. In Firebase Console, click the iOS icon
2. Register app with bundle ID: `com.example.bookswapApp`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/GoogleService-Info.plist`

##### d. Enable Authentication
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password** provider

##### e. Create Firestore Database
1. Go to **Firestore Database**
2. Click "Create database"
3. Start in **test mode** (we'll add rules below)
4. Choose a location (e.g., `us-central1`)

##### f. Set Up Firebase Storage
1. Go to **Storage**
2. Click "Get started"
3. Start in **test mode** (we'll add rules below)

#### 4. Configure Firebase in Flutter

The app automatically initializes Firebase using `firebase_options.dart`. Ensure your `google-services.json` and `GoogleService-Info.plist` files are in the correct locations.

#### 5. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For a specific device
flutter devices
flutter run -d <device-id>
```

---

## 🔥 Firebase Security Rules

### Firestore Rules

Add these rules in **Firestore Database** → **Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Books collection
    match /books/{bookId} {
      // Anyone can read available books
      allow read: if resource.data.status == 'available';
      
      // Users can create their own books
      allow create: if request.auth != null 
        && request.resource.data.ownerId == request.auth.uid;
      
      // Users can update/delete their own books
      allow update, delete: if request.auth != null 
        && resource.data.ownerId == request.auth.uid;
    }
    
    // Swap requests collection
    match /swap_requests/{requestId} {
      allow read: if request.auth != null 
        && (resource.data.requesterId == request.auth.uid 
            || resource.data.recipientId == request.auth.uid);
      
      allow create: if request.auth != null 
        && request.resource.data.requesterId == request.auth.uid;
      
      allow update: if request.auth != null 
        && resource.data.recipientId == request.auth.uid;
    }
    
    // Chats collection
    match /chats/{chatId} {
      allow read: if request.auth != null 
        && request.auth.uid in resource.data.participants;
      
      allow create: if request.auth != null 
        && request.auth.uid in request.resource.data.participants;
      
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null 
          && request.resource.data.senderId == request.auth.uid;
      }
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Storage Rules

Add these rules in **Storage** → **Rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Book images
    match /books/{userId}/{imageId} {
      // Anyone can read book images
      allow read: if true;
      
      // Users can upload their own book images
      allow write: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024 // 5MB limit
        && request.resource.contentType.matches('image/.*');
      
      // Users can delete their own images
      allow delete: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Profile images (if implemented)
    match /profiles/{userId}/{imageId} {
      allow read: if true;
      allow write: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.size < 2 * 1024 * 1024 // 2MB limit
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## 📁 Project Structure

```
bookswap_app/
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── lib/
│   ├── main.dart           # App entry point
│   ├── firebase_options.dart # Firebase configuration
│   ├── models/             # Data models
│   │   ├── book_model.dart
│   │   ├── user_model.dart
│   │   ├── chat_message_model.dart
│   │   └── swap_request_model.dart
│   ├── providers/          # State management (Provider)
│   │   ├── auth_provider.dart
│   │   ├── book_provider.dart
│   │   ├── chat_provider.dart
│   │   └── swap_provider.dart
│   ├── screens/            # Screen widgets
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── welcome_screen.dart
│   │   ├── browse/
│   │   │   └── book_details_page.dart
│   │   ├── chats/
│   │   │   └── chat_screen.dart
│   │   ├── listings/
│   │   │   ├── add_book_page.dart
│   │   │   └── edit_book_page.dart
│   │   └── home_screen.dart
│   ├── services/           # Firebase services
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── storage_service.dart
│   ├── tabs/              # Bottom navigation tabs
│   │   ├── browse_tab.dart
│   │   ├── listings_tab.dart
│   │   ├── chats_tab.dart
│   │   └── settings_tab.dart
│   └── utils/             # Utilities
│       └── text_styles.dart
├── assets/
│   └── fonts/             # Local Poppins fonts
│       ├── Poppins-Regular.ttf
│       ├── Poppins-Medium.ttf
│       ├── Poppins-SemiBold.ttf
│       ├── Poppins-Bold.ttf
│       └── Poppins-ExtraBold.ttf
├── pubspec.yaml           # Dependencies
└── README.md              # This file
```

---

## 🏗️ Architecture & State Management

### State Management Pattern

BookSwap uses **Provider** for state management combined with **StreamBuilder** for real-time Firebase data:

#### Provider Pattern
- **`AuthProvider`** — Manages user authentication state
- **`BookProvider`** — Handles book CRUD operations and caching
- **`ChatProvider`** — Manages chat messages and conversations
- **`SwapProvider`** — Handles swap request logic

#### Real-time Updates
- **StreamBuilder** listens to Firestore streams for instant updates
- Books appear/disappear in real-time as users add/remove listings
- Chat messages sync instantly across devices

#### Example: Book Provider

```dart
class BookProvider extends ChangeNotifier {
  List<BookModel> _browseBooks = [];
  List<BookModel> _myBooks = [];
  
  // Real-time stream for browse books
  void getBrowseListings() {
    _firestoreService.getBrowseListings().listen((books) {
      _browseBooks = books;
      notifyListeners();
    });
  }
  
  // Real-time stream for user's books
  void getMyBooks() {
    _firestoreService.getMyBooks().listen((books) {
      _myBooks = books;
      notifyListeners();
    });
  }
}
```

#### Example: Using Provider in UI

```dart
// Watch for changes
final bookProvider = context.watch<BookProvider>();
final books = bookProvider.browseBooks;

// Or read once
final bookProvider = context.read<BookProvider>();
bookProvider.getBrowseListings();
```

---

## 🎥 Demo Video

📹 **[Watch Demo Video](https://youtube.com/watch?v=your-video-id)**

> Add your demo video link above once you've created a screen recording.

---

## 🛠️ Built With

- **[Flutter](https://flutter.dev/)** — Cross-platform UI framework
- **[Firebase](https://firebase.google.com/)** — Backend services
  - **Firebase Auth** — User authentication
  - **Cloud Firestore** — NoSQL database
  - **Firebase Storage** — Image storage
- **[Provider](https://pub.dev/packages/provider)** — State management
- **[Image Picker](https://pub.dev/packages/image_picker)** — Image selection
- **[Google Fonts (Local)](https://fonts.google.com/specimen/Poppins)** — Poppins typography

---

## 📦 Dependencies

Key packages used in this project:

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^3.4.0 | Firebase initialization |
| `firebase_auth` | ^5.3.0 | Authentication |
| `cloud_firestore` | ^5.4.0 | Database |
| `firebase_storage` | ^12.3.0 | File storage |
| `provider` | ^6.1.2 | State management |
| `image_picker` | ^1.1.2 | Image selection |
| `shared_preferences` | ^2.3.2 | Local storage |

See `pubspec.yaml` for the complete list.

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Firebase Not Initialized
```
Error: FirebaseException: [core/no-app] No Firebase App '[DEFAULT]' has been created
```
**Solution:** Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location.

#### 2. Font Files Not Found
```
Error: unable to locate asset entry in pubspec.yaml: assets/fonts/Poppins-Regular.ttf
```
**Solution:** Download Poppins fonts from [Google Fonts](https://fonts.google.com/specimen/Poppins) and place them in `assets/fonts/`.

#### 3. Firestore Permission Denied
```
Error: [cloud_firestore/permission-denied] The caller does not have permission
```
**Solution:** Check your Firestore security rules match the rules provided above.

#### 4. Image Upload Fails
```
Error: [firebase_storage/unauthorized] User does not have permission
```
**Solution:** Verify Storage security rules allow authenticated users to upload.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Your Name**
- Nmae: Glory Paul
- Email: g.paul@alustudent.com

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev/) for the amazing framework
- [Firebase](https://firebase.google.com/) for backend services
- [Google Fonts](https://fonts.google.com/) for Poppins typography
- All contributors and testers

---

## 📊 Project Status

✅ **Active Development** — New features and improvements are being added regularly.

**Current Version:** 1.0.0

**Last Updated:** December 2024

---

<div align="center">

**Made with ❤️ using Flutter & Firebase**

⭐ Star this repo if you find it helpful!

</div>
