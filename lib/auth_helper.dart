import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Check if user is currently logged in via Firebase Auth
Future<bool> isUserLoggedIn() async {
  return FirebaseAuth.instance.currentUser != null;
}

// ✅ Redirect to login if not logged in, then callback when done
Future<void> requireLogin(
  BuildContext context, {
  required VoidCallback onLoggedIn,
}) async {
  final loggedIn = await isUserLoggedIn();

  if (!context.mounted) return;

  if (loggedIn) {
    onLoggedIn();
  } else {
    Navigator.pushNamed(context, '/login').then((_) async {
      final checkAgain = await isUserLoggedIn();
      if (checkAgain) onLoggedIn();
    });
  }
}

// ✅ Stream for listening to auth state changes (used in main.dart)
Stream<User?> authStateStream() {
  return FirebaseAuth.instance.authStateChanges();
}

// ✅ Sign out helper
Future<void> signOutUser() async {
  await FirebaseAuth.instance.signOut();
}

// ✅ Get current logged-in user
User? getCurrentUser() {
  return FirebaseAuth.instance.currentUser;
}
