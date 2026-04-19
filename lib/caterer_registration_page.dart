import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'caterer_dashboard.dart';

class CatererRegistrationPage extends StatefulWidget {
  const CatererRegistrationPage({super.key});

  @override
  State<CatererRegistrationPage> createState() =>
      _CatererRegistrationPageState();
}

class _CatererRegistrationPageState extends State<CatererRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _serviceAreaCtrl = TextEditingController();

  File? _businessPermitFile;
  File? _validIdFile;
  final List<File> _menuPhotoFiles = [];
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String _uploadStatus = '';

  // Event type tags
  static const List<String> _allEventTypes = [
    'Birthday',
    'Wedding',
    'Baptism',
    'Reunion',
    'Corporate',
    'Anniversary',
    'Graduation',
    'Christmas Party',
  ];
  final Set<String> _selectedEventTypes = {};

  // Map state
  LatLng? _pickedLatLng;
  final MapController _mapController = MapController();
  bool _mapLoading = false;

  static const Color _primary = Color(0xFFFF6B22);
  static const Color _primaryLight = Color(0xFFFFAA55);
  static const Color _primaryBg = Color(0xFFFFF3ED);
  static const Color _border = Color(0xFFEEEEEE);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMid = Color(0xFF777777);
  static const Color _textLight = Color(0xFFAAAAAA);
  static const Color _bgPage = Color(0xFFF5F5F5);

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    _serviceAreaCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

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

  // ── Convert file to Base64 string ─────────────────────────
  Future<String> _fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    // Firestore doc limit is 1MB — we compress heavily to stay safe
    return base64Encode(bytes);
  }

  Future<void> _pickSingleFile(String type) async {
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40, // compress more since storing in Firestore
      maxWidth: 600, // smaller size to stay under Firestore 1MB limit
    );
    if (img == null) return;
    setState(() {
      if (type == 'permit') _businessPermitFile = File(img.path);
      if (type == 'id') _validIdFile = File(img.path);
    });
  }

  Future<void> _pickMenuPhoto() async {
    if (_menuPhotoFiles.length >= 3) {
      _showSnack('Maximum 3 photos allowed');
      return;
    }
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 600,
    );
    if (img != null) setState(() => _menuPhotoFiles.add(File(img.path)));
  }

  // ── Map helpers ───────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    setState(() => _mapLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.');
        setState(() => _mapLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          setState(() => _mapLoading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied.');
        setState(() => _mapLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 16);
      await _onMapTap(latLng);
    } catch (e) {
      _showSnack('Could not get location: $e');
    }
    setState(() => _mapLoading = false);
  }

  Future<void> _onMapTap(LatLng pos) async {
    setState(() => _pickedLatLng = pos);
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        final area = [
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        setState(() {
          _locationCtrl.text = address;
          if (_serviceAreaCtrl.text.isEmpty) _serviceAreaCtrl.text = area;
        });
      }
    } catch (_) {}
  }

  // ── Submit ────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedEventTypes.isEmpty) {
      _showSnack('Please select at least one event type');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Preparing data…';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in.');

      // Convert images to Base64
      String? permitBase64;
      String? idBase64;
      final List<String> menuBase64List = [];

      if (_businessPermitFile != null) {
        setState(() => _uploadStatus = 'Processing business permit…');
        permitBase64 = await _fileToBase64(_businessPermitFile!);
      }

      if (_validIdFile != null) {
        setState(() => _uploadStatus = 'Processing valid ID…');
        idBase64 = await _fileToBase64(_validIdFile!);
      }

      for (int i = 0; i < _menuPhotoFiles.length; i++) {
        setState(
          () => _uploadStatus =
              'Processing photo ${i + 1} of ${_menuPhotoFiles.length}…',
        );
        final b64 = await _fileToBase64(_menuPhotoFiles[i]);
        menuBase64List.add(b64);
      }

      setState(() => _uploadStatus = 'Updating user profile…');
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'is_caterer': true,
      });

      setState(() => _uploadStatus = 'Saving caterer profile…');

      final Map<String, dynamic> catererData = {
        'caterer_id': uid,
        'user_id': uid,
        'name': _businessNameCtrl.text.trim(),
        'owner_name': _ownerNameCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'service_area': _serviceAreaCtrl.text.trim(),
        'event_types': _selectedEventTypes.toList(),
        'menu_photos': menuBase64List, // Base64 strings
        'cover_photo': menuBase64List.isNotEmpty
            ? menuBase64List.first
            : null, // First photo = card cover
        'rating': 0.0,
        'review_count': 0,
        'is_verified': false,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (_pickedLatLng != null) {
        catererData['latitude'] = _pickedLatLng!.latitude;
        catererData['longitude'] = _pickedLatLng!.longitude;
      }
      if (permitBase64 != null) catererData['business_permit'] = permitBase64;
      if (idBase64 != null) catererData['valid_id'] = idBase64;

      await FirebaseFirestore.instance
          .collection('caterers')
          .doc(uid)
          .set(catererData, SetOptions(merge: true));

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
      backgroundColor: _bgPage,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildBusinessInfoCard(),
                        const SizedBox(height: 14),
                        _buildEventTypesCard(),
                        const SizedBox(height: 14),
                        _buildLocationCard(),
                        const SizedBox(height: 14),
                        _buildRequirementsCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
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
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          color: _primary,
                          strokeWidth: 3.5,
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

  // ── App Bar ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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

  // ── Card: Business Information ────────────────────────────
  Widget _buildBusinessInfoCard() {
    return _sectionCard(
      title: 'Business Information',
      icon: Icons.storefront_outlined,
      child: Column(
        children: [
          _inputField(
            icon: Icons.storefront_outlined,
            hint: 'Business Name',
            controller: _businessNameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Business name is required'
                : null,
          ),
          const SizedBox(height: 10),
          _inputField(
            icon: Icons.person_outline,
            hint: 'Owner Name',
            controller: _ownerNameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Owner name is required'
                : null,
          ),
          const SizedBox(height: 10),
          _inputField(
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
          _inputField(
            icon: Icons.email_outlined,
            hint: 'Email Address',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(
                r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
              ).hasMatch(v.trim()))
                return 'Enter a valid email';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Card: Event Types ─────────────────────────────────────
  Widget _buildEventTypesCard() {
    return _sectionCard(
      title: 'Event Types Served',
      icon: Icons.celebration_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select all event types your catering covers (shown as tags on your listing)',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF777777),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allEventTypes.map((type) {
              final selected = _selectedEventTypes.contains(type);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedEventTypes.remove(type);
                    } else {
                      _selectedEventTypes.add(type);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _primary : _primaryBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _primary : _primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedEventTypes.isEmpty) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: _primary),
                SizedBox(width: 6),
                Text(
                  'Select at least one event type',
                  style: TextStyle(fontSize: 11, color: _primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Card: Location ────────────────────────────────────────
  Widget _buildLocationCard() {
    const defaultCenter = LatLng(14.5995, 120.9842);

    return _sectionCard(
      title: 'Location',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                SizedBox(
                  height: 220,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: defaultCenter,
                      initialZoom: 12,
                      onTap: (tapPosition, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.celebreats.app',
                      ),
                      if (_pickedLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLatLng!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: _primary,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _goToMyLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _primary, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: _mapLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primary,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location,
                                  color: _primary,
                                  size: 15,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Use my location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                if (_pickedLatLng == null)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tap the map to pin your location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_pickedLatLng != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: _primary, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pinned: ${_pickedLatLng!.latitude.toStringAsFixed(5)}, '
                      '${_pickedLatLng!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _inputField(
            icon: Icons.location_on_outlined,
            hint: 'Address',
            helperText: 'Auto-filled when you pin the map, or type manually',
            controller: _locationCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Address is required' : null,
          ),
          const SizedBox(height: 10),
          _inputField(
            icon: Icons.map_outlined,
            hint: 'Service Area',
            helperText: 'e.g. Quezon City, Metro Manila',
            controller: _serviceAreaCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Service area is required'
                : null,
          ),
        ],
      ),
    );
  }

  // ── Card: Requirements ────────────────────────────────────
  Widget _buildRequirementsCard() {
    return _sectionCard(
      title: 'Requirements',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          _uploadTile(
            icon: Icons.verified_user_outlined,
            label: 'Business Permit',
            subtitle: 'Upload a photo of your permit',
            file: _businessPermitFile,
            buttonLabel: 'Upload Permit',
            onTap: () => _pickSingleFile('permit'),
          ),
          const SizedBox(height: 10),
          _uploadTile(
            icon: Icons.badge_outlined,
            label: 'Valid ID',
            subtitle: 'Government-issued ID',
            file: _validIdFile,
            buttonLabel: 'Upload ID',
            onTap: () => _pickSingleFile('id'),
          ),
          const SizedBox(height: 10),
          _uploadTile(
            icon: Icons.photo_library_outlined,
            label: 'Menu / Sample Photos',
            subtitle: _menuPhotoFiles.isEmpty
                ? 'Up to 3 photos (1st photo = your listing cover)'
                : '${_menuPhotoFiles.length} photo${_menuPhotoFiles.length > 1 ? 's' : ''} selected',
            file: _menuPhotoFiles.isNotEmpty ? _menuPhotoFiles.first : null,
            fileCount: _menuPhotoFiles.length,
            buttonLabel: 'Upload Photos',
            onTap: _pickMenuPhoto,
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: _textLight),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Images are compressed automatically. Max 3 photos.',
                  style: TextStyle(fontSize: 11, color: _textMid),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _primaryLight]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Submit Registration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primary, size: 18),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _inputField({
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 50,
                decoration: const BoxDecoration(
                  color: _primaryBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                ),
                child: Icon(icon, color: _primary, size: 19),
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

  Widget _uploadTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required File? file,
    required String buttonLabel,
    required VoidCallback onTap,
    int fileCount = 0,
  }) {
    final uploaded = file != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: uploaded ? _primaryBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: uploaded ? _primary.withOpacity(0.35) : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: uploaded ? _primary : _primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              uploaded ? Icons.check_rounded : icon,
              color: uploaded ? Colors.white : _primary,
              size: 19,
            ),
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
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: uploaded ? _primary : _textMid,
                    fontWeight: uploaded ? FontWeight.w600 : FontWeight.normal,
                  ),
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _primary, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    uploaded ? Icons.edit_outlined : Icons.upload_outlined,
                    color: uploaded ? Colors.white : _primary,
                    size: 13,
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
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
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
                                borderRadius: BorderRadius.circular(16),
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

// ─────────────────────────────────────────────────────────────
// HOMEPAGE CATERER CARD WIDGET
// ─────────────────────────────────────────────────────────────
class CatererCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorited;

  const CatererCard({
    super.key,
    required this.data,
    this.onTap,
    this.onFavorite,
    this.isFavorited = false,
  });

  static const Color _primary = Color(0xFFFF6B22);
  static const Color _primaryBg = Color(0xFFFFF3ED);

  // Decode Base64 string to image bytes
  Uint8List? _decodeBase64(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? 'Caterer';
    final double rating = (data['rating'] ?? 0.0).toDouble();
    final int reviewCount = data['review_count'] ?? 0;
    final String location = data['location'] ?? '';
    final List<dynamic> eventTypes = data['event_types'] ?? [];
    final Uint8List? coverBytes = _decodeBase64(data['cover_photo']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Photo ──────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: coverBytes != null
                      ? Image.memory(coverBytes, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              color: Color(0xFFCCCCCC),
                              size: 40,
                            ),
                          ),
                        ),
                ),
                // Favorite button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? _primary : const Color(0xFF999999),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Info section ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC107),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount reviews)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (eventTypes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: eventTypes.take(4).map((type) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
