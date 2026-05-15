import 'dart:convert';
import 'dart:io';

import 'package:celebreats/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'favorite.dart';
import 'caterer_registration_page.dart';
import 'caterer_dashboard.dart';
import 'sign_up.dart';
import 'notifications_screen.dart';
import 'payment_methods_page.dart';
import 'help_support_page.dart';
import 'terms_conditions_page.dart';

// ─────────────────────────────────────────────────────────────
// AUTH DIALOG
// ─────────────────────────────────────────────────────────────

void showLoginRequiredDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _LoginRequiredSheet(),
  );
}

class _LoginRequiredSheet extends StatelessWidget {
  const _LoginRequiredSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A00), Color(0xFFFF3D3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Login Required",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "You need an account to access this feature.\nPlease log in or sign up to continue.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: Color(0xFFFF6B22),
                      width: 1.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Color(0xFFFF6B22),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFFF6B22),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Log In",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              "Maybe Later",
              style: TextStyle(
                color: Colors.black45,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROFILE PAGE
// ─────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  bool get _isLoggedIn => _currentUser != null;

  Stream<DocumentSnapshot>? get _userStream => _isLoggedIn
      ? FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .snapshots()
      : null;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleCatererModeTap(bool isCaterer) {
    if (isCaterer) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CatererDashboardPage()),
      );
    } else {
      _showCatererRegistrationDialog();
    }
  }

  void _showCatererRegistrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A00), Color(0xFFFF3D3D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Become a Caterer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Register your catering business to start receiving bookings. Would you like to proceed?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CatererRegistrationPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFFF6B22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Yes, Proceed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        "assets/logo.png",
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.restaurant,
                          color: Colors.deepOrange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "CelebrEats",
                        style: GoogleFonts.pacifico(
                          fontSize: 20,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: SvgPicture.asset(
                      "assets/icons/settings_ic.svg",
                      height: 26,
                      width: 26,
                      placeholderBuilder: (_) =>
                          const Icon(Icons.settings, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoggedIn
                  ? _buildLoggedInBody(context)
                  : _buildLoggedOutBody(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // LOGGED IN BODY
  // ─────────────────────────────────────────────────────────
  Widget _buildLoggedInBody(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name =
            data?['name'] as String? ?? _currentUser?.displayName ?? 'User';
        final email = data?['email'] as String? ?? _currentUser?.email ?? '';
        final photo = data?['photo'] as String? ?? '';

        final bookingCount = (data?['booking_count'] as int?) ?? 0;
        final reviewCount = (data?['review_count'] as int?) ?? 0;
        final favoriteCount = (data?['favorite_count'] as int?) ?? 0;

        final isCaterer = data?['is_caterer'] as bool? ?? false;

        ImageProvider? avatarImage;
        if (photo.isNotEmpty) {
          avatarImage = photo.startsWith('data:image')
              ? MemoryImage(base64Decode(photo.split(',').last))
              : NetworkImage(photo) as ImageProvider;
        }

        return ListView(
          children: [
            // ── Profile card ──────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFFFF3D3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.deepOrange,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        value: bookingCount.toString(),
                        label: "Bookings",
                      ),
                      _StatItem(
                        value: reviewCount.toString(),
                        label: "Reviews",
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FavoritePage(),
                          ),
                        ),
                        child: _StatItem(
                          value: favoriteCount.toString(),
                          label: "Favorites",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Caterer Mode tile ─────────────────────────────
            _CatererModeTile(
              isCaterer: isCaterer,
              onTap: () => _handleCatererModeTap(isCaterer),
            ),

            _MenuTile(
              iconPath: "assets/icons/mybooking_ic.svg",
              title: "My Booking",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyBookingsPage()),
              ),
            ),
            _MenuTile(
              iconPath: "assets/icons/person_ic.svg",
              title: "Edit Profile",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ),
            ),
            const _MenuTile(
              iconPath: "assets/icons/changepassword_ic.svg",
              title: "Change Password",
            ),
            _MenuTile(
              iconPath: "assets/icons/notification_ic.svg",
              title: "Notification",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            _MenuTile(
              iconPath: "assets/icons/favorites_ic.svg",
              title: "Favorites",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritePage()),
              ),
            ),
            // ── Payment Methods ───────────────────────────────
            _MenuTile(
              iconPath: "assets/icons/payment_method_ic.svg",
              title: "Payment Methods",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
              ),
            ),
            // ── Help & Support ────────────────────────────────
            _MenuTile(
              iconPath: "assets/icons/help_support_ic.svg",
              title: "Help & Support",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportPage()),
              ),
            ),
            // ── Terms & Conditions ────────────────────────────
            _MenuTile(
              iconPath: "assets/icons/terms_condition_ic.svg",
              title: "Terms & Conditions",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE6E6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // LOGGED OUT BODY
  // ─────────────────────────────────────────────────────────
  Widget _buildLoggedOutBody(BuildContext context) {
    void guard(VoidCallback onLoggedIn) {
      if (_isLoggedIn) {
        onLoggedIn();
      } else {
        showLoginRequiredDialog(context);
      }
    }

    return ListView(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD5B5)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFFFE0C8),
                child: Icon(Icons.person, size: 40, color: Color(0xFFFF6B22)),
              ),
              const SizedBox(height: 12),
              const Text(
                "You're not logged in",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Log in to access your profile, bookings, and favorites.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => showLoginRequiredDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Log In / Sign Up",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _CatererModeTile(
          isCaterer: false,
          onTap: () => showLoginRequiredDialog(context),
        ),
        _MenuTile(
          iconPath: "assets/icons/mybooking_ic.svg",
          title: "My Booking",
          onTap: () => guard(
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsPage()),
            ),
          ),
        ),
        _MenuTile(
          iconPath: "assets/icons/person_ic.svg",
          title: "Edit Profile",
          onTap: () => guard(
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
          ),
        ),
        _MenuTile(
          iconPath: "assets/icons/changepassword_ic.svg",
          title: "Change Password",
          onTap: () => showLoginRequiredDialog(context),
        ),
        _MenuTile(
          iconPath: "assets/icons/notification_ic.svg",
          title: "Notification",
          onTap: () => showLoginRequiredDialog(context),
        ),
        _MenuTile(
          iconPath: "assets/icons/favorites_ic.svg",
          title: "Favorites",
          onTap: () => guard(
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritePage()),
            ),
          ),
        ),
        // ── Payment Methods (guest → login prompt) ────────
        _MenuTile(
          iconPath: "assets/icons/payment_method_ic.svg",
          title: "Payment Methods",
          onTap: () => showLoginRequiredDialog(context),
        ),
        // ── Help & Support (guest → open freely) ─────────
        _MenuTile(
          iconPath: "assets/icons/help_support_ic.svg",
          title: "Help & Support",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpSupportPage()),
          ),
        ),
        // ── Terms & Conditions (guest → open freely) ──────
        _MenuTile(
          iconPath: "assets/icons/terms_condition_ic.svg",
          title: "Terms & Conditions",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATERER MODE TILE
// ─────────────────────────────────────────────────────────────

class _CatererModeTile extends StatelessWidget {
  final bool isCaterer;
  final VoidCallback onTap;

  const _CatererModeTile({required this.isCaterer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withValues(alpha: 0.15),
        child: SvgPicture.asset(
          "assets/icons/help_support_ic.svg",
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
        ),
      ),
      title: const Text("Caterer Mode"),
      subtitle: Text(
        isCaterer
            ? "Tap to open your dashboard"
            : "Manage your catering business",
      ),
      trailing: IgnorePointer(
        child: Switch(
          value: isCaterer,
          activeTrackColor: Colors.orange,
          onChanged: (_) {},
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EDIT PROFILE PAGE
// ─────────────────────────────────────────────────────────────

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  File? _pickedImage;
  String _currentPhoto = '';

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _currentPhoto = data['photo'] ?? '';
        _isLoading = false;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                "Change Profile Photo",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE0C8),
                child: Icon(Icons.photo_library, color: Color(0xFFFF6B22)),
              ),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE0C8),
                child: Icon(Icons.camera_alt, color: Color(0xFFFF6B22)),
              ),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_currentPhoto.isNotEmpty || _pickedImage != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE6E6),
                  child: Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text(
                  "Remove Photo",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _pickedImage = null;
                    _currentPhoto = '';
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 400,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not pick image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _toBase64(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> _saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isSaving = true);
    try {
      String photoValue = _currentPhoto;
      if (_pickedImage != null) photoValue = await _toBase64(_pickedImage!);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'photo': photoValue,
      });
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF6B22);

    ImageProvider? avatarImage;
    if (_pickedImage != null) {
      avatarImage = FileImage(_pickedImage!);
    } else if (_currentPhoto.isNotEmpty) {
      avatarImage = _currentPhoto.startsWith('data:image')
          ? MemoryImage(base64Decode(_currentPhoto.split(',').last))
          : NetworkImage(_currentPhoto) as ImageProvider;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFF3F3F3),
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? const Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: primaryOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the camera icon to change photo",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 32),
                  _buildEditField("Full Name", _nameController),
                  const SizedBox(height: 20),
                  _buildEditField("Email", _emailController, enabled: false),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? const Color(0xFFF9F9F9)
                : const Color(0xFFEEEEEE),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED COMPONENTS
// ─────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback? onTap;
  const _MenuTile({required this.iconPath, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MY BOOKINGS PAGE
// ─────────────────────────────────────────────────────────────

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                return;
              }
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          title: const Text(
            'My Bookings',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF6B22),
            labelColor: Color(0xFFFF6B22),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Upcoming (2)'),
              Tab(text: 'Past (0)'),
            ],
          ),
        ),
        body: const TabBarView(children: [UpcomingTab(), PastTab()]),
      ),
    );
  }
}

class UpcomingTab extends StatelessWidget {
  const UpcomingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        BookingCard(
          title: "Manang Anna's Catering",
          status: "pending",
          statusColor: Color(0xFFFFB020),
          statusBg: Color(0xFFFFF4D6),
        ),
        SizedBox(height: 12),
        BookingCard(
          title: "Xian's Catering Services",
          status: "confirmed",
          statusColor: Color(0xFF28A745),
          statusBg: Color(0xFFD1F4CE),
        ),
      ],
    );
  }
}

class PastTab extends StatelessWidget {
  const PastTab({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text("No past bookings"));
}

class BookingCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final Color statusBg;
  const BookingCard({
    super.key,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Birthday • 2024-03-15 at 8:00 am",
              style: TextStyle(color: Colors.grey),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Php 50,000",
                  style: TextStyle(
                    color: Color(0xFFFF6B22),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B22),
                  ),
                  child: const Text(
                    "View Details",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
