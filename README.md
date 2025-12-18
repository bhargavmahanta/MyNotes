# MyNotes – Flutter Notes App with Firebase Authentication

A Flutter application demonstrating **Firebase Authentication** integrated with **Bloc (flutter_bloc)** for state management. The app implements a complete authentication flow (register, login, email verification, logout) and a simple **notes management system** with create and update functionality.

This project is suitable for learning:

* Flutter app architecture
* Bloc-based authentication flow
* Firebase email/password authentication
* Route-based navigation in Flutter

---

## Features

* Email & Password Authentication (Firebase)
* Email Verification Flow
* Bloc (BLoC Pattern) for state management
* Clean separation of UI, business logic, and services
* Notes CRUD (Create / Update / View)
* Route-based navigation
* Scalable project structure

---

## Tech Stack

* **Flutter**
* **Dart**
* **Firebase Authentication**
* **flutter_bloc**
* **Material UI**

---

## Project Structure

```
lib/
│
├── constants/
│   └── routes.dart
│
├── services/
│   └── auth/
│       ├── bloc/
│       │   ├── auth_bloc.dart
│       │   ├── auth_event.dart
│       │   └── auth_state.dart
│       └── firebase_auth_provider.dart
│
├── views/
│   ├── login_views.dart
│   ├── register_view.dart
│   ├── verify_email_view.dart
│   └── notes/
│       ├── notes_view.dart
│       └── create_update_note_view.dart
│
└── main.dart
```

---

## Authentication Flow (High-Level)

1. App starts → `AuthEventInitialize` is dispatched.
2. Bloc checks Firebase authentication state.
3. Based on the state:

   * Logged in → `NotesView`
   * Email not verified → `VerifyEmailView`
   * Logged out → `LoginView`
4. UI reacts automatically using `BlocBuilder`.

---

## Main Entry Point

The app initializes Firebase and provides `AuthBloc` globally using `BlocProvider`.

```dart
BlocProvider<AuthBloc>(
  create: (context) => AuthBloc(FirebaseAuthProvider()),
  child: const HomePage(),
)
```

---

## Routes Used

| Route Name          | Screen               |
| ------------------- | -------------------- |
| /login              | LoginView            |
| /register           | RegisterView         |
| /notes              | NotesView            |
| /verify-email       | VerifyEmailView      |
| /create-update-note | CreateUpdateNoteView |

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/learningfirebase.git
cd learningfirebase
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

* Create a Firebase project
* Enable **Email/Password Authentication**
* Download:

  * `google-services.json` (Android)
  * `GoogleService-Info.plist` (iOS)
* Place them in their respective platform directories
* Ensure `firebase_core` and `firebase_auth` are added in `pubspec.yaml`

### 4. Run the App

```bash
flutter run
```

---

## Packages Used

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.x.x
  firebase_core: ^2.x.x
  firebase_auth: ^4.x.x
```

---

## Learning Outcomes

* Understand Bloc-based authentication workflows
* Learn clean Flutter project structuring
* Implement Firebase Auth with email verification
* Handle authentication states reactively
* Apply separation of concerns in Flutter apps

---

## Future Enhancements

* Persistent local storage for notes
* Firestore-backed notes synchronization
* Password reset functionality
* UI/UX improvements
* Dark mode support

---

## License

This project is for educational purposes.

---

## Author

Built as part of a Flutter + Firebase learning journey.

Happy Coding 🚀
