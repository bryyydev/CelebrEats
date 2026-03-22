import 'dart:io';
import 'dart:convert';
import 'package:celebreats/caterer_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'caterer_dashboard.dart'; // ← adjust path if needed

// ─────────────────────────────────────────────────────────────
// CATERER REGISTRATION PAGE
//
// Writes to Firestore (matching your schema):
//
//  users/{uid}
//    └─ is_caterer: true
//
//  caterers/{uid}
//    ├─ caterer_id       (string)
//    ├─ user_id          (string)
//    ├─ name             (string)  ← business name
//    ├─ owner_name       (string)
//    ├─ contact          (string)
//    ├─ email            (string)
//    ├─ location         (string)  ← address
//    ├─ service_area     (string)
//    ├─ business_permit  (string)  ← base64
//    ├─ valid_id         (string)  ← base64
//    ├─ menu_photos      (array)   ← base64 strings
//    ├─ rating           0.0
//    ├─ review_count     0
//    ├─ is_verified      false
//    ├─ is_active        true
//    ├─ created_at       (timestamp)
//    └─ updated_at       (timestamp)
// ─────────────────────────────────────────────────────────────

class CatererRegistrationPage extends StatefulWidget {
  const CatererRegistrationPage({super.key});

  @override
  State<CatererRegistrationPage> createState() =>
      _CatererRegistrationPageState();
}

class _CatererRegistrationPageState extends State<CatererRegistrationPage> {
  // ── Form ──────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _serviceAreaCtrl = TextEditingController();

  // ── Files (base64 — Spark plan compatible) ─────────────────
  File? _businessPermitFile;
  File? _validIdFile;
  final List<File> _menuPhotoFiles = [];
  final ImagePicker _picker = ImagePicker();

  // ── Submit state ──────────────────────────────────────────
  bool _isLoading = false;
  String _uploadStatus = '';

  // ── Colors ────────────────────────────────────────────────
  static const Color _primary = Color(0xFFFF6B22);
  static const Color _primaryLight = Color(0xFFFFAA55);
  static const Color _primaryBg = Color(0xFFFFF3ED);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMid = Color(0xFF777777);
  static const Color _textLight = Color(0xFFAAAAAA);

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    _serviceAreaCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF333333),
      ),
    );
  }

  /// File → base64 data URI (same format as users.photo)
  Future<String> _toBase64(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // ─────────────────────────────────────────────────────────
  // FILE PICKERS
  // ─────────────────────────────────────────────────────────
  Future<void> _pickSingleFile(String type) async {
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (img == null) return;
    setState(() {
      if (type == 'permit') _businessPermitFile = File(img.path);
      if (type == 'id') _validIdFile = File(img.path);
    });
  }

  Future<void> _pickMenuPhoto() async {
    if (_menuPhotoFiles.length >= 4) {
      _showSnack('Maximum 4 photos allowed');
      return;
    }
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (img != null) setState(() => _menuPhotoFiles.add(File(img.path)));
  }

  // ─────────────────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _uploadStatus = 'Preparing data…';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in.');

      // Convert files → base64
      String? permitBase64;
      if (_businessPermitFile != null) {
        setState(() => _uploadStatus = 'Processing business permit…');
        permitBase64 = await _toBase64(_businessPermitFile!);
      }

      String? idBase64;
      if (_validIdFile != null) {
        setState(() => _uploadStatus = 'Processing valid ID…');
        idBase64 = await _toBase64(_validIdFile!);
      }

      final List<String> menuBase64 = [];
      for (int i = 0; i < _menuPhotoFiles.length; i++) {
        setState(
          () => _uploadStatus =
              'Processing photo ${i + 1} of ${_menuPhotoFiles.length}…',
        );
        menuBase64.add(await _toBase64(_menuPhotoFiles[i]));
      }

      // 1. users/{uid} → is_caterer: true
      setState(() => _uploadStatus = 'Updating user profile…');
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'is_caterer': true,
      });

      // 2. caterers/{uid} → full document
      setState(() => _uploadStatus = 'Saving caterer profile…');
      await FirebaseFirestore.instance.collection('caterers').doc(uid).set({
        'caterer_id': uid,
        'user_id': uid,
        'name': _businessNameCtrl.text.trim(),
        'owner_name': _ownerNameCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'service_area': _serviceAreaCtrl.text.trim(),
        if (permitBase64 != null) 'business_permit': permitBase64,
        if (idBase64 != null) 'valid_id': idBase64,
        'menu_photos': menuBase64,
        'rating': 0.0,
        'review_count': 0,
        'is_verified': false,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isLoading = false;
        _uploadStatus = '';
      });
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CatererSuccessPage(businessName: _businessNameCtrl.text.trim()),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _uploadStatus = '';
      });
      _showSnack('Error: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _subtitleBanner(),
                        const SizedBox(height: 12),
                        _buildBusinessInfoCard(),
                        const SizedBox(height: 12),
                        _buildLocationCard(),
                        const SizedBox(height: 12),
                        _buildRequirementsCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),

          // ── Progress overlay ───────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          color: _primary,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Submitting Registration',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _uploadStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textMid,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          backgroundColor: Color(0xFFEEEEEE),
                          color: _primary,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: _textDark,
                        size: 20,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    'Caterer Registration',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
          ],
        ),
      ),
    );
  }

  // ── Subtitle ──────────────────────────────────────────────
  Widget _subtitleBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'Register your catering business to start receiving bookings.',
        style: TextStyle(fontSize: 13, color: _textMid, height: 1.5),
      ),
    );
  }

  // ─── Card 1: Business Information ────────────────────────
  Widget _buildBusinessInfoCard() {
    return _sectionCard(
      title: 'Business Information',
      child: Column(
        children: [
          _iconField(
            icon: Icons.storefront_outlined,
            hint: 'Business Name',
            controller: _businessNameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Business name is required'
                : null,
          ),
          const SizedBox(height: 10),
          _iconField(
            icon: Icons.person_outline,
            hint: 'Owner Name',
            controller: _ownerNameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Owner name is required'
                : null,
          ),
          const SizedBox(height: 10),
          _iconField(
            icon: Icons.phone_outlined,
            hint: 'Contact Number',
            controller: _contactCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Enter a valid contact number'
                : null,
          ),
          const SizedBox(height: 10),
          _iconField(
            icon: Icons.email_outlined,
            hint: 'Email Address',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── Card 2: Location ─────────────────────────────────────
  Widget _buildLocationCard() {
    return _sectionCard(
      title: 'Location',
      child: Column(
        children: [
          _iconField(
            icon: Icons.location_on_outlined,
            hint: 'Address',
            helperText: 'Enter your complete address',
            controller: _locationCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Address is required' : null,
          ),
          const SizedBox(height: 10),
          _iconField(
            icon: Icons.map_outlined,
            hint: 'Service Area',
            helperText: 'Coverage area (e.g. Quezon City, Metro Manila)',
            controller: _serviceAreaCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Service area is required'
                : null,
          ),
        ],
      ),
    );
  }

  // ─── Card 3: Requirements ────────────────────────────────
  Widget _buildRequirementsCard() {
    return _sectionCard(
      title: 'Requirements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _uploadRow(
            icon: Icons.verified_user_outlined,
            label: 'Upload Business Permit',
            buttonLabel: 'Upload Permit',
            file: _businessPermitFile,
            onTap: () => _pickSingleFile('permit'),
          ),
          const SizedBox(height: 10),
          _uploadRow(
            icon: Icons.badge_outlined,
            label: 'Upload Valid ID',
            buttonLabel: 'Upload ID',
            file: _validIdFile,
            onTap: () => _pickSingleFile('id'),
          ),
          const SizedBox(height: 10),
          _uploadRow(
            icon: Icons.photo_library_outlined,
            label: 'Upload Sample Menu / Photos',
            buttonLabel: 'Upload Files',
            file: _menuPhotoFiles.isNotEmpty ? _menuPhotoFiles.first : null,
            fileCount: _menuPhotoFiles.length,
            onTap: _pickMenuPhoto,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline, size: 13, color: _textLight),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Max 4 menu photos. Images are compressed automatically.',
                  style: TextStyle(fontSize: 11, color: _textMid),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _primaryLight]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _iconField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3ED),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(9),
                    bottomLeft: Radius.circular(9),
                  ),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  validator: validator,
                  style: const TextStyle(fontSize: 14, color: _textDark),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 14, color: _textLight),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperText,
              style: const TextStyle(fontSize: 11, color: _textMid),
            ),
          ),
        ],
      ],
    );
  }

  Widget _uploadRow({
    required IconData icon,
    required String label,
    required String buttonLabel,
    required File? file,
    required VoidCallback onTap,
    int fileCount = 0,
  }) {
    final uploaded = file != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                if (uploaded)
                  Text(
                    fileCount > 1
                        ? '$fileCount files selected'
                        : '1 file selected ✓',
                    style: const TextStyle(fontSize: 11, color: _primary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: uploaded ? _primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primary, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload_outlined,
                    color: uploaded ? Colors.white : _primary,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    uploaded ? 'Change' : buttonLabel,
                    style: TextStyle(
                      color: uploaded ? Colors.white : _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUCCESS PAGE
// ─────────────────────────────────────────────────────────────
class CatererSuccessPage extends StatelessWidget {
  final String businessName;
  const CatererSuccessPage({super.key, required this.businessName});

  static const Color _primary = Color(0xFFFF6B22);
  static const Color _primaryLight = Color(0xFFFF9B55);
  static const Color _primaryBg = Color(0xFFFFF3ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            height: MediaQuery.of(context).padding.top + 80,
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'CelebrEats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _primaryBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _primary, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: _primary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "You're now a Caterer!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your profile is live and ready to receive bookings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primary.withOpacity(0.25)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'REGISTERED AS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              businessName.isNotEmpty
                                  ? businessName
                                  : 'Your Catering Business',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "What's next:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _step('1', 'Add your catering packages & pricing'),
                      const SizedBox(height: 10),
                      _step('2', 'Set your availability calendar'),
                      const SizedBox(height: 10),
                      _step('3', 'Start accepting bookings!'),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton(
                            // ── FIXED: Navigate to CatererDashboardPage
                            // and clear the entire back stack so the user
                            // cannot go back to the registration form.
                            onPressed: () =>
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CatererDashboardPage(),
                                  ),
                                  (route) => false,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Go to Caterer Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Text(
              'Switch back to customer mode anytime from Profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: _primaryBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
        ),
      ],
    );
  }
}
