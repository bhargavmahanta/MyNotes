// Import the application-level user model.
//
// IMPORTANT:
// This is NOT a Firebase user.
// This is your OWN domain model that represents
// "a user" as far as your app is concerned.
//
// This keeps Firebase (or any auth backend) hidden
// from the rest of the app.
import 'package:learningfirebase/services/auth/auth_user.dart';

// Import the abstract authentication contract.
//
// AuthProvider is an INTERFACE (abstract class)
// that defines WHAT authentication can do,
// but NOT HOW it is implemented.
//
// This is the foundation of decoupling.
import 'package:learningfirebase/services/auth/auth_provider.dart';

// Import the Firebase-specific implementation.
//
// This file is the ONLY place where Firebase Auth
// should be known as a concrete implementation.
import 'package:learningfirebase/services/auth/firebase_auth_provider.dart';

/// ---------------------------------------------------------------------------
/// AUTH SERVICE
/// ---------------------------------------------------------------------------
///
/// AuthService is a **facade** and **dependency inversion layer**.
///
/// Responsibilities:
/// 1. Expose authentication functionality to the UI
/// 2. Hide the concrete auth backend (Firebase, etc.)
/// 3. Enforce that the UI only depends on abstractions
///
/// Architecture:
/// UI → AuthService → AuthProvider → FirebaseAuthProvider → Firebase SDK
///
class AuthService implements AuthProvider {
  /// The actual authentication provider.
  ///
  /// This is NOT Firebase-specific.
  /// It is typed as `AuthProvider`, which means:
  /// - Any implementation that satisfies AuthProvider can be used
  /// - Firebase can be swapped out later without touching the UI
  ///
  /// Example alternatives:
  /// - SupabaseAuthProvider
  /// - AppwriteAuthProvider
  /// - MockAuthProvider (for testing)
  final AuthProvider provider;

  /// Constructor that accepts an AuthProvider.
  ///
  /// This enables **dependency injection**.
  ///
  /// Why dependency injection matters:
  /// - Makes testing possible
  /// - Makes the app modular
  /// - Prevents tight coupling
  const AuthService(this.provider);

  /// Factory constructor that returns a Firebase-backed AuthService.
  ///
  /// Why a factory?
  /// - Provides a clean, readable way to initialize the service
  /// - Avoids exposing FirebaseAuthProvider throughout the app
  ///
  /// Usage:
  ///   final authService = AuthService.firebase();
  ///
  /// The UI still does NOT know Firebase exists.
  factory AuthService.firebase() => AuthService(FirebaseAuthProvider());

  /// -------------------------------------------------------------------------
  /// AUTH PROVIDER DELEGATION
  /// -------------------------------------------------------------------------
  ///
  /// All methods below simply DELEGATE to the underlying provider.
  ///
  /// Why not call Firebase directly?
  /// - This keeps AuthService as a stable API
  /// - Implementation details remain replaceable
  /// - UI depends on behavior, not technology

  /// Creates a new user using email and password.
  ///
  /// Flow:
  /// UI → AuthService → AuthProvider → FirebaseAuthProvider → Firebase SDK
  ///
  /// Returns:
  /// - An AuthUser (your app model)
  /// - OR null if creation fails
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) => provider.createUser(email: email, password: password);

  /// Returns the currently authenticated user.
  ///
  /// This does NOT return Firebase's User object.
  ///
  /// Why this matters:
  /// - UI remains unaware of Firebase
  /// - App logic stays consistent even if backend changes
  ///
  /// Can be null if:
  /// - No user is logged in
  /// - Auth has not been initialized
  @override
  AuthUser? get currentUser => provider.currentUser;

  /// Logs in a user with email and password.
  ///
  /// This method abstracts:
  /// - FirebaseAuth.signInWithEmailAndPassword
  /// - Any future backend-specific login logic
  ///
  /// The UI never sees tokens, sessions, or providers.
  @override
  Future<AuthUser> logIn({required String email, required String password}) =>
      provider.logIn(email: email, password: password);

  /// Logs out the current user.
  ///
  /// This method ensures:
  /// - Session cleanup
  /// - State consistency
  /// - Backend independence
  ///
  /// Whether it’s Firebase, JWT, or OAuth,
  /// the UI calls the same method.
  @override
  Future<void> logOut() => provider.logOut();

  /// Sends an email verification to the current user.
  ///
  /// Important architectural note:
  /// - UI does not know HOW verification is sent
  /// - UI only knows that verification CAN be sent
  ///
  /// This allows backend logic to change freely.
  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();

  /// Initializes the authentication system.
  ///
  /// Typical responsibilities:
  /// - Firebase.initializeApp()
  /// - Restore persisted sessions
  /// - Prepare auth state listeners
  ///
  /// Why explicit initialization?
  /// - Prevents race conditions
  /// - Ensures auth state is ready before UI renders
  @override
  Future<void> initialize() => provider.initialize();
  
  @override
  Future<void> sendPasswordResetEmail({required String toEmail})=> provider.sendPasswordResetEmail(toEmail: toEmail);
}
