import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    _isInitializing = true;
    notifyListeners();

    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _fetchUserData(firebaseUser.uid);
    }

    _isLoading = false;
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid) async {
    int attempts = 3;
    for (int i = 0; i < attempts; i++) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
          return; // Success!
        } else {
          print('Fetch User: Document does not exist yet (attempt ${i + 1}/$attempts)');
        }
      } catch (e) {
        print('Fetch User Error (attempt ${i + 1}/$attempts): $e');
      }
      // Delay before retrying to allow auth token to propagate to Firestore
      await Future.delayed(Duration(milliseconds: 800 * (i + 1)));
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String branch,
    required String semester,
    required String section,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = UserModel(
        uid: userCred.user!.uid,
        email: email,
        name: name,
        role: role,
        branch: branch,
        semester: semester,
        section: section,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCred.user!.uid)
          .set(_currentUser!.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign Up Error: ${e.code}');
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'This email is already registered. Try logging in instead.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'Password is too weak. Please choose a stronger password.';
      } else if (e.code == 'operation-not-allowed') {
        _errorMessage = 'Account creation is currently disabled. Please contact support.';
      } else if (e.code == 'network-request-failed') {
        _errorMessage = 'No internet connection. Please check your network and try again.';
      } else {
        _errorMessage = 'Sign up failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Sign Up Error: $e');
      _errorMessage = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _fetchUserData(userCred.user!.uid);

      if (_currentUser == null) {
        _errorMessage = 'Failed to retrieve user profile. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign In Error: ${e.code}');
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _errorMessage = 'Invalid email or password';
      } else if (e.code == 'user-not-found') {
        _errorMessage = 'No user found with this email';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Invalid email format';
      } else {
        _errorMessage = e.message ?? 'Login failed. Please check your credentials';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Sign In Error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Get User Error: $e');
    }
    return null;
  }
}