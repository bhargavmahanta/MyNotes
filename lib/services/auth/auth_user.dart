// Import only the Firebase User type.
//
// This is intentionally limited to the auth layer.
// No UI or business logic should ever import Firebase User directly.
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

/// ---------------------------------------------------------------------------
/// AUTH USER (DOMAIN MODEL)
/// ---------------------------------------------------------------------------
///
/// AuthUser represents an authenticated user **from the app’s perspective**.
///
/// Key characteristics:
/// - Backend-agnostic (not Firebase-specific)
/// - Immutable
/// - Minimal and purpose-driven
///
/// This is NOT:
/// - A database entity
/// - A Firebase SDK model
/// - A UI widget
///
/// It is a DOMAIN VALUE OBJECT.
///
@immutable
class AuthUser {
  final String? email;
  /// Indicates whether the user has verified their email address.
  ///
  /// WHY THIS FIELD EXISTS:
  /// - Email verification impacts navigation and permissions
  /// - UI logic often depends on this state
  ///
  /// WHY ONLY THIS FIELD?
  /// - Keep domain models minimal
  /// - Add fields ONLY when the app truly needs them
  final bool isEmailVerified;

  /// Creates an AuthUser instance.
  ///
  /// WHY THIS CONSTRUCTOR IS const:
  /// - Enables compile-time optimizations
  /// - Reinforces immutability
  /// - Improves predictability of app state
  const AuthUser({required this.isEmailVerified, required this.email});

  /// Factory constructor that converts a Firebase User
  /// into an application-level AuthUser.
  ///
  /// WHY A FACTORY?
  /// - Encapsulates conversion logic
  /// - Prevents Firebase types from leaking into app layers
  ///
  /// WHY THIS MAPPING IS IMPORTANT:
  /// - Firebase User has dozens of fields
  /// - Your app only needs one (for now)
  /// - Avoids tight coupling and overexposure
  ///
  /// This method is the ONLY place where Firebase User
  /// is allowed to be translated into AuthUser.
  factory AuthUser.fromFirebase(User user) =>
      AuthUser(isEmailVerified: user.emailVerified, email: user.email ?? '');
}
