import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

final authServiceProvider = Provider((ref) => AuthService(ref));

/// Stream of current Firebase user
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// User ka display name - pehle Firebase, phir Firestore se
final userDisplayNameProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);

  return ref.read(firestoreServiceProvider).watchUserProfile(user.uid).map((doc) {
    final firestoreName = doc.data()?['displayName'] as String?;
    if (firestoreName != null && firestoreName.trim().isNotEmpty) {
      return firestoreName;
    }
    return user.displayName;
  });
});

class AuthService {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService(this._ref);

  // Track auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google (v6 - simple & stable)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        try {
          await _ref.read(firestoreServiceProvider).saveUserProfile(
            cred.user!.uid,
            cred.user!.displayName ?? '',
            cred.user!.email ?? '',
          );
        } catch (_) {
          // Firestore save failed, but sign-in is still valid
        }
      }
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // Phone Verification
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Sign in with OTP
  Future<UserCredential> signInWithOtp(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Login with Email/Password
  Future<UserCredential> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user != null && cred.user!.emailVerified) {
        try {
          await _ref.read(firestoreServiceProvider).saveUserProfile(
            cred.user!.uid,
            cred.user!.displayName ?? 'User',
            email,
          );
        } catch (_) {
          // Firestore save failed, but login is still valid
        }
      }
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // Signup with Email/Password
  Future<UserCredential> signUp(String email, String password, {required String displayName}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await cred.user!.updateDisplayName(displayName);
      }
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // Reset Password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return _auth.currentUser!.emailVerified;
    }
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.delete();
      await signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Re-authenticate user
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    bool isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');

    if (isGoogleUser) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'Google re-authentication was cancelled';
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    } else if (password != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } else {
      throw 'Password is required for email providers';
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
