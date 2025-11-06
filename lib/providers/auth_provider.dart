import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null && user.emailVerified) {
        _currentUser = await _authService.getUserData(user.uid);
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    User? user = _authService.currentUser;
    if (user != null && user.emailVerified) {
      _currentUser = await _authService.getUserData(user.uid);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserModel? user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      _isLoading = false;
      if (user != null) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserModel? user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _isLoading = false;
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> isEmailVerified() async {
    return await _authService.isEmailVerified();
  }

  Future<void> resendVerificationEmail() async {
    await _authService.resendVerificationEmail();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? profileImageUrl}) async {
    await _authService.updateUserProfile(
      name: name,
      profileImageUrl: profileImageUrl,
    );
    if (_currentUser != null) {
      _currentUser = await _authService.getUserData(_currentUser!.id);
      notifyListeners();
    }
  }

  Future<void> updateNotificationPreferences(Map<String, bool> preferences) async {
    await _authService.updateNotificationPreferences(preferences);
    if (_currentUser != null) {
      _currentUser = await _authService.getUserData(_currentUser!.id);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}