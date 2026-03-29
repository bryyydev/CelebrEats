import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  // Wrap navigation in addPostFrameCallback so it fires AFTER the current
  // frame — prevents crash when Firebase auth listeners trigger rebuilds
  // at the same time as Navigator.pushNamedAndRemoveUntil.
  void _handleAfterLogin() {
    if (!mounted) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final returnToBooking = args is Map && args['returnToBooking'] == true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (returnToBooking) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/customize-package',
          (route) => route.isFirst,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    });
  }

  Future<void> loginUser() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter email and password"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      DocumentSnapshot? userDoc;
      try {
        userDoc = await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .get()
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw Exception('Connection timed out.'),
            );
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
          _handleAfterLogin();
        }
        return;
      }

      if (!userDoc.exists) {
        await _auth.signOut();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account not found. Please sign up first."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _handleAfterLogin();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = "Login failed.";
        if (e.code == 'user-not-found') {
          message = "No account found for this email.";
        } else if (e.code == 'wrong-password') {
          message = "Incorrect password.";
        } else if (e.code == 'invalid-email') {
          message = "Invalid email address.";
        } else if (e.code == 'invalid-credential') {
          message = "Invalid email or password.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);

      final userDoc = await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': cred.user!.displayName ?? 'User',
          'email': cred.user!.email ?? '',
          'is_caterer': false,
          'photo': cred.user!.photoURL ?? '',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _handleAfterLogin();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google sign-in failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter your email first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent! Check your inbox."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = "Could not send reset email.";
        if (e.code == 'user-not-found') {
          message = "No account found for this email.";
        } else if (e.code == 'invalid-email') {
          message = "Invalid email address.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.black38, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF2EAE0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE8A87C), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFFA4A2A), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE8A87C), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 26),

              // ── Logo
              Image.asset(
                'assets/logo.png',
                height: 340,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  width: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFA4A2A), Color(0xFFFFA726)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),

              // ── Title ─────────────────────────────────────────────────────
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Join CelebrEats today",
                style: TextStyle(fontSize: 17, color: Colors.black45),
              ),

              const SizedBox(height: 20),

              // ── Email label ───────────────────────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Email field ───────────────────────────────────────────────
              TextField(
                controller: emailCtrl,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDecoration(
                  hint: "Enter your email",
                  prefixIcon: Icons.mail_outline_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // ── Password label ────────────────────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Password field ────────────────────────────────────────────
              TextField(
                controller: passCtrl,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDecoration(
                  hint: "Enter your password",
                  prefixIcon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.black45,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Remember me + Forgot Password ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: _isLoading
                              ? null
                              : (val) =>
                                    setState(() => _rememberMe = val ?? false),
                          activeColor: const Color(0xFFFA4A2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFFA4A2A),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Remember me",
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xFFFA4A2A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Log In button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFA5C1A),
                    disabledBackgroundColor: Colors.grey.shade400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── OR divider ────────────────────────────────────────────────
              const Row(
                children: [
                  Expanded(
                    child: Divider(thickness: 1, color: Color(0xFFD4C4B0)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(thickness: 1, color: Color(0xFFD4C4B0)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Social buttons ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2EAE0),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide.none,
                      ),
                      onPressed: _isLoading ? null : () {},
                      icon: Image.asset(
                        'assets/facebook.png',
                        width: 22,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.facebook,
                          color: Color(0xFF1877F2),
                          size: 22,
                        ),
                      ),
                      label: const Text(
                        "Facebook",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2EAE0),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide.none,
                      ),
                      onPressed: _isLoading ? null : signInWithGoogle,
                      icon: Image.asset(
                        'assets/google.png',
                        width: 22,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                      label: const Text(
                        "Google",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Sign up link ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Do not have an account? ",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => Navigator.pushNamed(context, '/signup'),
                    child: Text(
                      "Sign up",
                      style: TextStyle(
                        color: _isLoading
                            ? Colors.grey
                            : const Color(0xFFFA4A2A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
