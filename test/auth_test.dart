import 'package:learningfirebase/services/auth/auth_exceptions.dart';
import 'package:learningfirebase/services/auth/auth_provider.dart';
import 'package:learningfirebase/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group("Mock Authentication", () {
    final provider = MockAuthProvider();

    test("should not be initialozed to begin with", () {
      expect(provider.isInitialized, false);
    });
    

    /// exceute the logout()
    /// testing the result of logout() against the expected type of exception
    test("cannot log out if not initialized", () {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedException>()),
      );
    });

    test("should be able to initialze", () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });

    test("user should be null after initialization", () {
      expect(provider.currentUser, null);
    });

    test("should be able to initialize in less than 2 seconds", () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );

    test("create user should delegate to login function", () async {
      /// calling bad email user
      final badEmailUser = provider.createUser(email: "foo@bar.com", password: "anypassword");
      expect(badEmailUser, throwsA(const TypeMatcher<UserNotFoundAuthException>()));
      /// calling bad password user
      final badPasswordUser = provider.createUser(email: "someone@bar.com", password: "foobar");
      expect(badPasswordUser, throwsA(const TypeMatcher<WrongPasswordAuthException>()));
      /// calling good user
      final user = await provider.createUser(email: "foo", password: "bar");
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
      });

      test("logged in user should be able tot get verified", () async {
        await provider.sendEmailVerification();
        final user = provider.currentUser;
        expect(user, isNotNull);
        expect(user?.isEmailVerified, true);
      });

      test("should be able to log out and log in again", () async {
        await provider.logOut();
        await provider.logIn(email: "email", password: "password"); 
        final user = provider.currentUser;
        expect(user, isNotNull);
      });
  });
}

class NotInitializedException implements Exception {}

/// Mocking and Testing Auth Provider
class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// createUser()
  /// 1. Checks if the provider is initialized or it throws an exception
  /// 2. It does a mock 1 sec wait to simulate initialization delay (faking api call)
  /// 3. Returns the result of Login to get the created user
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 2));
    return logIn(email: email, password: password);
  }

  @override
  AuthUser? get currentUser => _user;

  /// initialize()
  /// 1. Waits for 1 second to give faking of api call
  /// 2. sets _isInitialized to true
  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  /// Login()
  /// 1. Checks if the provider is initialized or it throws an exception
  /// 2. If the email is 'foo@bar.com' it throws UserNotFoundAuthException
  /// 3. If the password is 'foobar' it throws WrongPasswordAuthException
  /// 4. Otherwise it creates a new AuthUser with isEmailVerified set to false
  ///    and assigns it to _user and returns it
  @override
  Future<AuthUser> logIn({required String email, required String password}) {
    if (!isInitialized) throw NotInitializedException();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw WrongPasswordAuthException();
    const user = AuthUser(isEmailVerified: false, email: 'foo@bar.com', id: 'skdbvjkbvkjdfbvjk');
    _user = user;
    return Future.value(user);
  }

  /// logOut()
  /// 1. Checks if the provider is initialized or it throws an exception
  /// 2. If there is no current user, it throws UserNotFoundAuthException
  /// 3. Waits for 1 second to simulate api call delay
  /// 4. Sets the _user to null
  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  /// sendEmailVerification()
  /// 1. Checks if the provider is initialized or it throws an exception
  /// 2. If there is no current user, it throws UserNotFoundAuthException
  /// 3. Creates a new AuthUser with isEmailVerified set to true and assigns it to _user
  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser(isEmailVerified: true, email: 'foo@bar.com', id: 'sdvhjshdfbvsbf');
    _user = newUser;
  }
  
  @override
  Future<void> sendPasswordResetEmail({required String toEmail}) {
    throw UnimplementedError();
  }
}
