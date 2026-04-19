import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    if (value.length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please accept Privacy & Terms of Use"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'photo': '',
        'created_at': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Please log in 🎉"),
            backgroundColor: Colors.green,
          ),
        );

        final args = ModalRoute.of(context)?.settings.arguments;
        final fromBooking = args is Map && args['returnToBooking'] == true;

        Navigator.pushNamed(
          context,
          '/login',
          arguments: fromBooking ? {'returnToBooking': true} : null,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = "Sign up failed.";
        if (e.code == 'email-already-in-use') message = "Email already in use.";
        if (e.code == 'weak-password') message = "Password is too weak.";
        if (e.code == 'invalid-email') message = "Invalid email address.";
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

  // ── Shared input decoration ──────────────────────────────────────────────
  InputDecoration _inputDecoration({required String label, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black45, fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.never,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE8A87C), width: 1.2),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _visibilityIcon(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.black45,
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EC),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 36),

                  // ── Logo ─────────────────────────────────────────────────
                  Image.asset(
                    'assets/logo.png',
                    height: 140,
                    errorBuilder: (_, __, ___) => SizedBox(
                      height: 140,
                      width: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipPath(
                            clipper: _FlameClipper(),
                            child: Container(
                              width: 110,
                              height: 140,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFA4A2A),
                                    Color(0xFFFFA726),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.restaurant,
                            size: 60,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Title ─────────────────────────────────────────────────
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Join CelebrEats today",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Username ──────────────────────────────────────────────
                  _fieldLabel("Username"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_isLoading,
                    validator: _validateUsername,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDecoration(label: "Username"),
                  ),

                  const SizedBox(height: 16),

                  // ── Email ─────────────────────────────────────────────────
                  _fieldLabel("Email"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDecoration(label: "Email"),
                  ),

                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────────────────────────
                  _fieldLabel("Password"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    validator: _validatePassword,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDecoration(
                      label: "Password",
                      suffix: _visibilityIcon(
                        _obscurePassword,
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Confirm Password ──────────────────────────────────────
                  _fieldLabel("Confirm Password"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                    validator: _validateConfirmPassword,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDecoration(
                      label: "Confirm Password",
                      suffix: _visibilityIcon(
                        _obscureConfirmPassword,
                        () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Accept Terms ──────────────────────────────────────────
                  Row(
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged: _isLoading
                              ? null
                              : (v) =>
                                    setState(() => _acceptTerms = v ?? false),
                          activeColor: const Color(0xFFFA4A2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFFA4A2A),
                            width: 1.5,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // TODO: open terms screen
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontFamily: 'Poppins',
                            ),
                            children: [
                              TextSpan(text: "I accept "),
                              TextSpan(
                                text: "Privacy & Terms of Use",
                                style: TextStyle(
                                  color: Color(0xFFFA4A2A),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Sign Up button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
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
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Already have account ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.pushNamed(context, '/login'),
                        child: Text(
                          "Log In",
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

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Flame/teardrop shape clipper for the fallback logo
class _FlameClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.85, h * 0.2, w, h * 0.45, w, h * 0.65);
    path.arcToPoint(
      Offset(0, h * 0.65),
      radius: Radius.circular(w * 0.5),
      clockwise: false,
    );
    path.cubicTo(0, h * 0.45, w * 0.15, h * 0.2, w * 0.5, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_FlameClipper oldClipper) => false;
}
