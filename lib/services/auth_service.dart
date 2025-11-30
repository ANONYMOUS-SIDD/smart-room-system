import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';
import 'toast_service.dart';

/// Service Handling All Authentication Related Operations
class AuthService extends GetxService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ToastService _toastService = ToastService();

  /// Create New User Account With Email And Password
  Future<User?> createUserWithEmailAndPassword({required String email, required String password, required String fullName, required String phone}) async {
    try {
      // Check If Email Already Exists
      final emailQuery = await _firestore.collection('User').where('Email', isEqualTo: email.trim()).get();

      if (emailQuery.docs.isNotEmpty) {
        _toastService.showErrorMessage("Email Already Exists");
        return null;
      }

      // Create User In Firebase Authentication (Email & Password)
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("User Creation Failed");
      }

      // Create User Document In Firestore (Store all data except password)
      await _createUserDocument(userId: user.uid, fullName: fullName, phone: phone, email: email);

      // Send Email Verification
      await user.sendEmailVerification();

      _toastService.showSuccessMessage("Account Created Successfully!");
      return user;
    } on FirebaseAuthException catch (error) {
      _handleFirebaseAuthError(error);
      return null;
    } catch (error) {
      _toastService.showErrorMessage("An Unexpected Error Occurred");
      return null;
    }
  }

  /// Create User Document In Firestore Database
  Future<void> _createUserDocument({required String userId, required String fullName, required String phone, required String email}) async {
    final userModel = UserModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: fullName.trim(),
      phone: phone.trim(), // Store phone number in database
      email: email.trim(),
      sessionId: userId,
      profilePath: "https://firebasestorage.googleapis.com/v0/b/online-2cdb1.appspot.com/o/1707049056458970?alt=media&token=2bcfcd4d-c2e1-4795-a064-312d5265eb21",
    );

    await _firestore.collection("User").doc(userId).set(userModel.toFirestoreMap());
  }

  /// Handle Firebase Authentication Specific Errors
  void _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case "network-request-failed":
        _toastService.showErrorMessage("Please Check Your Connection");
        break;
      case "too-many-requests":
        _toastService.showErrorMessage("Too Many Attempts");
        break;
      case "email-already-in-use":
        _toastService.showErrorMessage("Email Is Already Registered");
        break;
      case "weak-password":
        _toastService.showErrorMessage("Use A Stronger Password");
        break;
      case "invalid-email":
        _toastService.showErrorMessage("Invalid Email Address.");
        break;
      case "operation-not-allowed":
        _toastService.showErrorMessage("Email/Password Accounts Are Not Enabled.");
        break;
      default:
        _toastService.showErrorMessage("Error: ${error.message ?? 'Unknown Error'}");
    }
  }
}
