// Import the application-level user abstraction.
//
// AuthUser represents a user in YOUR DOMAIN,
// not a backend-specific user (e.g., Firebase User).
//
// This ensures that all authentication providers
// return a consistent user model understood by the app.
// ignore_for_file: unintended_html_in_doc_comment

import 'package:learningfirebase/services/auth/auth_user.dart';

/// ---------------------------------------------------------------------------
/// AUTH PROVIDER (ABSTRACT CONTRACT)
/// ---------------------------------------------------------------------------
///
/// AuthProvider is an **interface / contract** that defines:
/// - WHAT authentication capabilities exist
/// - NOT how they are implemented
///
/// This is the cornerstone of:
/// - Dependency Inversion
/// - Clean Architecture
/// - Backend-agnostic design
///
/// Any authentication system (Firebase, Supabase, custom API)
/// MUST implement this contract to be used by the app.
///
abstract class AuthProvider {

  /// Initializes the authentication system.
  ///
  /// WHY THIS EXISTS:
  /// - Some auth systems require async startup logic
  /// - Firebase requires initialization before use
  /// - Session restoration may happen here
  ///
  /// HOW IT IS USED:
  /// - Called once during app startup
  /// - Ensures auth state is ready before UI access
  ///
  /// PROFESSIONAL BENEFIT:
  /// - Prevents race conditions
  /// - Guarantees predictable app behavior
  Future<void> initialize();

  /// Returns the currently authenticated user, if any.
  ///
  /// WHY THIS IS A GETTER:
  /// - Represents current application state
  /// - Does not trigger network or database operations
  ///
  /// WHY IT RETURNS AuthUser?:
  /// - Null represents "not authenticated"
  /// - Avoids throwing exceptions for normal control flow
  ///
  /// PROFESSIONAL BENEFIT:
  /// - Clean, expressive API
  /// - Easy state checks in UI and business logic
  AuthUser? get currentUser;

  /// Authenticates a user using email and password.
  ///
  /// WHAT THIS DOES:
  /// - Verifies credentials with the auth backend
  /// - Establishes an authenticated session
  /// - Returns a domain-level AuthUser
  ///
  /// WHY EMAIL & PASSWORD ARE PARAMETERS:
  /// - Makes the contract explicit
  /// - Allows alternative providers to map internally
  ///
  /// WHY THIS RETURNS Future<AuthUser?>:
  /// - Authentication is asynchronous
  /// - Null allows graceful failure handling
  ///
  /// PROFESSIONAL BENEFIT:
  /// - UI does not know about tokens or sessions
  /// - Backend logic remains isolated
  Future<AuthUser?> logIn({
    required String email,
    required String password,
  });

  /// Creates a new user account.
  ///
  /// WHAT THIS DOES:
  /// - Registers a new user with the backend
  /// - May automatically authenticate the user
  ///
  /// WHY THIS IS SEPARATE FROM logIn():
  /// - Registration and authentication are distinct concerns
  /// - Different validation and error handling paths
  ///
  /// WHY RETURN AuthUser?:
  /// - Allows immediate access to user data
  /// - Keeps the UI backend-agnostic
  ///
  /// PROFESSIONAL BENEFIT:
  /// - Clear separation of responsibilities
  /// - Supports future providers without UI changes
  Future<AuthUser?> createUser({
    required String email,
    required String password,
  });

  /// Logs out the currently authenticated user.
  ///
  /// WHAT THIS DOES:
  /// - Invalidates local session
  /// - Clears cached auth state
  /// - Triggers auth state changes
  ///
  /// WHY IT RETURNS Future<void>:
  /// - Logout may require async cleanup
  ///
  /// PROFESSIONAL BENEFIT:
  /// - Consistent logout behavior across providers
  /// - Prevents state corruption
  Future<void> logOut();

  /// Sends an email verification to the current user.
  ///
  /// WHAT THIS DOES:
  /// - Delegates verification mechanics to backend
  ///
  /// WHY THIS IS IN THE CONTRACT:
  /// - Not all providers handle verification identically
  /// - UI should not manage verification logic
  ///
  /// PROFESSIONAL BENEFIT:
  /// - Future-proof verification flows
  /// - Clean separation between UI and auth mechanics
  Future<void> sendEmailVerification();
}

