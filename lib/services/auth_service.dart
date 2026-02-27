import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'local_storage_service.dart';

class AuthService {
  static final _googleSignIn = GoogleSignIn(
    // Web client ID (client_type 3) from google-services.json
    serverClientId:
        '355567000935-hh4d4tqkcgh5gnd4b5ngqdg80ia5alsk.apps.googleusercontent.com',
  );

  /// Signs in with Google using Firebase Auth.
  /// On success, caches the user in [LocalStorageService] so the rest of the
  /// app (which reads from shared_prefs) sees a valid session.
  /// Returns the [User] on success, or throws.
  static Future<User> signInWithGoogle() async {
    // Trigger the Google authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Sign-in cancelled by user.');
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user!;

    // Cache the user locally so LocalStorageService.getCurrentUser() works
    await _cacheUser(user);
    return user;
  }

  /// Signs out from both Firebase and Google.
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    await LocalStorageService.logout();
  }

  /// Returns the currently signed-in Firebase user (or null).
  static User? get currentFirebaseUser => FirebaseAuth.instance.currentUser;

  // ── internal ──────────────────────────────────────────────────────────────

  static Future<void> _cacheUser(User user) async {
    final email = user.email ?? '';
    final name = user.displayName ?? email.split('@').first;

    // Register in LocalStorageService if not already present (no-op on dup)
    await LocalStorageService.registerUser(
      name: name,
      email: email,
      password: '', // no password for OAuth users
    );

    // Ensure the current session is set
    await LocalStorageService.login(email, '').then((u) async {
      if (u == null) {
        // Manually set session prefs for OAuth user
        await LocalStorageService.forceSession(name: name, email: email);
      }
    });
  }
}
