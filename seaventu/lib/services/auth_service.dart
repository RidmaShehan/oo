import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' : null,
  );
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Email/Password Authentication
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign Up Error: ${e.message}');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign In Error: ${e.message}');
      return null;
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential result = await _auth.signInWithCredential(credential);
      notifyListeners();
      return result.user;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  // Token Management
  Future<String?> getAuthToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Biometric Authentication
  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    
    try {
      final LocalAuthentication auth = LocalAuthentication();
      final canAuthenticate = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      return canAuthenticate && isSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometrics check error: ${e.message}');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    
    try {
      final LocalAuthentication auth = LocalAuthentication();
      return await auth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.message}');
      return false;
    }
  }

  Future<bool> isBiometricEnabledForUser(String userId) async {
    if (kIsWeb) return false;
    final enabled = await _secureStorage.read(key: 'biometric_$userId');
    return enabled == 'true';
  }

  Future<void> setBiometricEnabledForUser(String userId, bool enabled) async {
    if (kIsWeb) return;
    await _secureStorage.write(
      key: 'biometric_$userId',
      value: enabled.toString(),
    );
    notifyListeners();
  }

  Future<User?> authenticateWithBiometricsAndLogin() async {
    try {
      final canAuth = await canUseBiometrics();
      if (!canAuth) return null;

      final authenticated = await authenticateWithBiometrics();
      if (!authenticated) return null;

      final email = await _secureStorage.read(key: 'email');
      final password = await _secureStorage.read(key: 'password');
      
      if (email == null || password == null) return null;

      return await signInWithEmail(email, password);
    } catch (e) {
      debugPrint('Biometric login error: $e');
      return null;
    }
  }

  // Session Management
  Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: 'email', value: email);
    await _secureStorage.write(key: 'password', value: password);
    notifyListeners();
  }

  Future<Map<String, String?>> getCredentials() async {
    return {
      'email': await _secureStorage.read(key: 'email'),
      'password': await _secureStorage.read(key: 'password'),
    };
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: 'email');
    await _secureStorage.delete(key: 'password');
    notifyListeners();
  }

  // Other Methods
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await clearCredentials();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get userStream {
    return _auth.authStateChanges();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      rethrow;
    }
  }
}