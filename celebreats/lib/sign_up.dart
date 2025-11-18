import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

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

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ------------------------------
  // VALIDATIONS
  // ------------------------------
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
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

  // ------------------------------------------------------
  // 🔥 SAVE ACCOUNT TO SHARED PREFERENCES
  // ------------------------------------------------------
  Future<void> _saveAccount() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("username", _usernameController.text.trim());
    await prefs.setString("email", _emailController.text.trim());
    await prefs.setString("password", _passwordController.text.trim());

    // USER IS NOW CREATED → GO BACK TO LOGIN PAGE
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Account created! Please log in."),
        backgroundColor: Colors.green,
      ),
    );
  }

  // SIGN-UP BUTTON LOGIC
  void _handleSignUp() {
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

    // Everything is valid → save account
    _saveAccount();
  }

  // ---------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFFDF3),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  Image.asset('assets/logo.png', height: 250),
                  const SizedBox(height: 10),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Create your account",
                      style: TextStyle(
                        color: Color(0xFFE65C2A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // USERNAME
                  TextFormField(
                    controller: _usernameController,
                    validator: _validateUsername,
                    decoration: _input("Username"),
                  ),
                  const SizedBox(height: 15),

                  // EMAIL
                  TextFormField(
                    controller: _emailController,
                    validator: _validateEmail,
                    decoration: _input("Email"),
                  ),
                  const SizedBox(height: 15),

                  // PASSWORD
                  TextFormField(
                    controller: _passwordController,
                    validator: _validatePassword,
                    obscureText: _obscurePassword,
                    decoration: _input("Password").copyWith(
                      suffixIcon: _toggleIcon(
                        _obscurePassword,
                        () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // CONFIRM PASSWORD
                  TextFormField(
                    controller: _confirmPasswordController,
                    validator: _validateConfirmPassword,
                    obscureText: _obscureConfirmPassword,
                    decoration: _input("Confirm password").copyWith(
                      suffixIcon: _toggleIcon(
                        _obscureConfirmPassword,
                        () => setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // CHECKBOX
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (v) =>
                            setState(() => _acceptTerms = v ?? false),
                        activeColor: const Color(0xFFFF6347),
                      ),
                      const Text(
                        "I accept Privacy & Term of Use",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // SIGN UP BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA726), Color(0xFFFA4A2A)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // REUSABLE WIDGET STYLES
  // ---------------------------------------------------------
  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5E6D3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.brown.shade300),
    );
  }

  IconButton _toggleIcon(bool state, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        state ? Icons.visibility_off : Icons.visibility,
        color: const Color(0xFFFF6347),
      ),
      onPressed: onTap,
    );
  }
}
