import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ SIGN UP WITH EMAIL & PASSWORD
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = result.user;

      if (user == null) throw Exception('User creation failed.');

      // ✅ Update Firebase Auth display name
      await user.updateDisplayName(name);
      await user.reload();

      // ✅ Send verification email
      await user.sendEmailVerification();

      // ✅ Create Firestore user document
      UserModel newUser = UserModel(
        id: user.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        notificationPreferences: {
          'swaps': true,
          'messages': true,
          'offers': true,
        },
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Signup failed. Please try again.';

      if (e.code == 'email-already-in-use') {
        errorMsg = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Please enter a valid email.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Password should be at least 6 characters.';
      }

      throw Exception(errorMsg);
    } catch (e) {
      print('Sign up error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ✅ SIGN IN WITH EMAIL & PASSWORD (Checks verification)
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = result.user;

      if (user == null) throw Exception('Login failed.');

      // ✅ Check email verification
      if (!user.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before logging in.');
      }

      // ✅ Fetch Firestore user profile
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        throw Exception('User profile not found. Please contact support.');
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Login failed. Please try again.';

      if (e.code == 'user-not-found') {
        errorMsg = 'No account found for this email.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email format.';
      }

      throw Exception(errorMsg);
    } catch (e) {
      print('Sign in error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ✅ Check if user's email is verified
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  // ✅ Resend verification email
  Future<void> resendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw Exception('User is already verified or not logged in.');
    }
  }

  // ✅ Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ✅ Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Get user data error: $e');
    }
    return null;
  }

  // ✅ Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

    await _firestore.collection('users').doc(user.uid).update(updates);

    // Also update Firebase Auth display name
    if (name != null) await user.updateDisplayName(name);
  }

  // ✅ Update notification preferences
  Future<void> updateNotificationPreferences(
      Map<String, bool> preferences) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'notificationPreferences': preferences,
      });
    }
  }
}