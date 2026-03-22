import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────
// CATERER REGISTRATION PAGE
// Multi-step form inspired by Grab / Shopee / Foodpanda onboarding
// Step 1: Business Info  |  Step 2: Cuisine & Location  |  Step 3: Photos
// ─────────────────────────────────────────────────────────────

class CatererRegistrationPage extends StatefulWidget {
  const CatererRegistrationPage({super.key});

  @override
  State<CatererRegistrationPage> createState() =>
      _CatererRegistrationPageState();
}

class _CatererRegistrationPageState extends State<CatererRegistrationPage>
    with TickerProviderStateMixin {
  // ── Step control ──────────────────────────────────────────
  int _currentStep = 0;
  final int _totalSteps = 3;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // ── Form keys per step ────────────────────────────────────
  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────
  final _businessNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _serviceAreaCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _minGuestsCtrl = TextEditingController(text: '30');
  final _maxGuestsCtrl = TextEditingController(text: '200');

  // ── Images ────────────────────────────────────────────────
  File? _logoFile;
  final List<File> _photoFiles = [];
  final ImagePicker _picker = ImagePicker();

  // ── Cuisine tags ──────────────────────────────────────────
  final List<Map<String, dynamic>> _cuisineOptions = [
    {'label': 'Filipino', 'icon': '🍚'},
    {'label': 'BBQ', 'icon': '🔥'},
    {'label': 'Asian', 'icon': '🥢'},
    {'label': 'Western', 'icon': '🥩'},
    {'label': 'Seafood', 'icon': '🦐'},
    {'label': 'Desserts', 'icon': '🍰'},
    {'label': 'Vegan', 'icon': '🥗'},
    {'label': 'Halal', 'icon': '☪️'},
    {'label': 'Buffet', 'icon': '🍽️'},
    {'label': 'Lechon', 'icon': '🐷'},
  ];
  final Set<String> _selectedCuisines = {};

  // ── Event types ───────────────────────────────────────────
  final List<String> _eventTypes = [
    'Birthday',
    'Wedding',
    'Corporate',
    'Debut',
    'Baptismal',
    'Anniversary',
    'Graduation',
    'Others',
  ];
  final Set<String> _selectedEvents = {};

  // ── Loading ───────────────────────────────────────────────
  bool _isLoading = false;

  // ── Colors ────────────────────────────────────────────────
  static const Color _primary = Color(0xFFFF6B22);
  static const Color _primaryLight = Color(0xFFFF8C5A);
  static const Color _primaryBg = Color(0x1AFF6B22);
  static const Color _surface = Color(0xFFF8F8F8);
  static const Color _border = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1 / _totalSteps).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _businessNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _serviceAreaCtrl.dispose();
    _contactCtrl.dispose();
    _minGuestsCtrl.dispose();
    _maxGuestsCtrl.dispose();
    super.dispose();
  }

  // ── Step navigation ───────────────────────────────────────
  void _nextStep() {
    if (_currentStep == 0 && !(_step0Key.currentState?.validate() ?? false))
      return;
    if (_currentStep == 1) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
      if (_selectedCuisines.isEmpty) {
        _showSnack('Please select at least one cuisine type.');
        return;
      }
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      final target = (_currentStep + 1) / _totalSteps;
      _progressAnimation =
          Tween<double>(begin: _currentStep / _totalSteps, end: target).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeInOut,
            ),
          );
      _progressController
        ..reset()
        ..forward();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      final target = _currentStep / _totalSteps;
      _progressAnimation =
          Tween<double>(
            begin: (_currentStep + 1) / _totalSteps,
            end: target,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeInOut,
            ),
          );
      _progressController
        ..reset()
        ..forward();
    } else {
      Navigator.pop(context);
    }
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

  // ── Image pickers ─────────────────────────────────────────
  Future<void> _pickLogo() async {
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) setState(() => _logoFile = File(img.path));
  }

  Future<void> _pickPhoto() async {
    if (_photoFiles.length >= 6) {
      _showSnack('Maximum 6 photos allowed');
      return;
    }
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) setState(() => _photoFiles.add(File(img.path)));
  }

  void _removePhoto(int i) => setState(() => _photoFiles.removeAt(i));

  // ── Submit to Firestore ───────────────────────────────────
  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'is_caterer': true,
        });
        await FirebaseFirestore.instance.collection('caterers').doc(uid).set({
          'caterer_id': uid,
          'user_id': uid,
          'name': _businessNameCtrl.text.trim(),
          'description': _descriptionCtrl.text.trim(),
          'location': _serviceAreaCtrl.text.trim(),
          'contact': _contactCtrl.text.trim(),
          'cuisine_types': _selectedCuisines.toList(),
          'event_types': _selectedEvents.toList(),
          'min_guests': int.tryParse(_minGuestsCtrl.text) ?? 30,
          'max_guests': int.tryParse(_maxGuestsCtrl.text) ?? 200,
          'rating': 0.0,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      setState(() => _isLoading = false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CatererSuccessPage(businessName: _businessNameCtrl.text.trim()),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildStepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    final stepTitles = [
      'Business Info',
      'Cuisine & Location',
      'Photos & Review',
    ];
    final stepSubs = [
      'Tell us about your catering business',
      'What do you serve and where?',
      'Add photos to attract more customers',
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _prevStep,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepTitles[_currentStep],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stepSubs[_currentStep],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step progress bar ─────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (i) {
              final done = i < _currentStep;
              final active = i == _currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 4,
                    decoration: BoxDecoration(
                      color: done || active
                          ? _primary
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stepDot(0, 'Business'),
              _stepDot(1, 'Cuisine'),
              _stepDot(2, 'Photos'),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _border),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final done = step < _currentStep;
    final active = step == _currentStep;
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done
                ? _primary
                : active
                ? _primary
                : const Color(0xFFEEEEEE),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 13)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFFAAAAAA),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active
                ? _primary
                : done
                ? const Color(0xFF888888)
                : const Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }

  // ── Current step body ─────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────
  // STEP 0 — Business Info
  // ─────────────────────────────────────────────────────────
  Widget _buildStep0() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _step0Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo upload — Grab-style centered card ──
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _logoFile != null ? _primary : _border,
                          width: _logoFile != null ? 2 : 1,
                        ),
                        image: _logoFile != null
                            ? DecorationImage(
                                image: FileImage(_logoFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _logoFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _primaryBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: _primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Upload Logo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _logoFile != null
                        ? 'Tap to change logo'
                        : 'Business logo (optional)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionLabel('BUSINESS DETAILS'),
            const SizedBox(height: 10),

            _buildField(
              controller: _businessNameCtrl,
              label: 'Business Name',
              hint: 'e.g. Santos Catering Co.',
              icon: Icons.storefront_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Business name is required';
                if (v.trim().length < 3) return 'Must be at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _descriptionCtrl,
              label: 'Business Description',
              hint:
                  'Describe your catering style, specialties, and what sets you apart...',
              icon: Icons.notes_outlined,
              maxLines: 4,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Description is required';
                if (v.trim().length < 20)
                  return 'Please write at least 20 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _contactCtrl,
              label: 'Contact Number',
              hint: 'e.g. 09XX XXX XXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Contact number is required';
                if (v.trim().length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),

            const SizedBox(height: 20),
            _sectionLabel('GUEST CAPACITY'),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _minGuestsCtrl,
                    label: 'Minimum Guests',
                    hint: '30',
                    icon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _maxGuestsCtrl,
                    label: 'Maximum Guests',
                    hint: '200',
                    icon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _sectionLabel('EVENTS YOU CATER'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _eventTypes
                  .map(
                    (e) => _buildSelectChip(
                      label: e,
                      selected: _selectedEvents.contains(e),
                      onTap: () => setState(() {
                        _selectedEvents.contains(e)
                            ? _selectedEvents.remove(e)
                            : _selectedEvents.add(e);
                      }),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STEP 1 — Cuisine & Location
  // ─────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('CUISINE TYPE'),
            const SizedBox(height: 4),
            Text(
              'Select all that apply',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),

            // Cuisine grid — Shopee-style icon chips
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _cuisineOptions.length,
              itemBuilder: (_, i) {
                final item = _cuisineOptions[i];
                final selected = _selectedCuisines.contains(item['label']);
                return GestureDetector(
                  onTap: () => setState(() {
                    selected
                        ? _selectedCuisines.remove(item['label'])
                        : _selectedCuisines.add(item['label']);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected ? _primaryBg : _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _primary : _border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['icon'],
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected
                                ? _primary
                                : const Color(0xFF555555),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            _sectionLabel('SERVICE LOCATION'),
            const SizedBox(height: 10),

            _buildField(
              controller: _serviceAreaCtrl,
              label: 'Service Area',
              hint: 'e.g. Quezon City, Metro Manila',
              icon: Icons.location_on_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Service area is required'
                  : null,
            ),

            const SizedBox(height: 16),

            // Coverage info card — Grab-style tip card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFDDD0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'List the cities or areas you are willing to travel to for catering events. Be specific so customers can find you.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STEP 2 — Photos & Review
  // ─────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('FOOD PHOTOS'),
          const SizedBox(height: 4),
          Text(
            'Add up to 6 photos to showcase your best dishes',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 14),

          // Photo grid — Foodpanda-style
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _photoFiles.length < 6 ? _photoFiles.length + 1 : 6,
            itemBuilder: (_, i) {
              if (i == _photoFiles.length) {
                return GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: _primary,
                          size: 28,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 11,
                            color: _primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_photoFiles[i], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Cover',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          _sectionLabel('REVIEW YOUR PROFILE'),
          const SizedBox(height: 12),

          // Summary review card — Shopee-style summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _reviewRow(
                  Icons.storefront_outlined,
                  'Business',
                  _businessNameCtrl.text.trim().isEmpty
                      ? '—'
                      : _businessNameCtrl.text.trim(),
                ),
                const Divider(height: 16, color: _border),
                _reviewRow(
                  Icons.phone_outlined,
                  'Contact',
                  _contactCtrl.text.trim().isEmpty
                      ? '—'
                      : _contactCtrl.text.trim(),
                ),
                const Divider(height: 16, color: _border),
                _reviewRow(
                  Icons.location_on_outlined,
                  'Location',
                  _serviceAreaCtrl.text.trim().isEmpty
                      ? '—'
                      : _serviceAreaCtrl.text.trim(),
                ),
                const Divider(height: 16, color: _border),
                _reviewRow(
                  Icons.restaurant_outlined,
                  'Cuisines',
                  _selectedCuisines.isEmpty
                      ? '—'
                      : _selectedCuisines.take(3).join(', ') +
                            (_selectedCuisines.length > 3
                                ? ' +${_selectedCuisines.length - 3}'
                                : ''),
                ),
                const Divider(height: 16, color: _border),
                _reviewRow(
                  Icons.people_outline,
                  'Capacity',
                  '${_minGuestsCtrl.text}–${_maxGuestsCtrl.text} guests',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Terms note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_outlined, color: _primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'By submitting, you agree to CelebrEats\' Caterer Terms of Service and confirm that all information provided is accurate.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _primary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Bottom action bar ─────────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (isLast ? _handleSubmit : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Submit Registration' : 'Continue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!isLast) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFFAAAAAA),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSelectChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryBg : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? _primary : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUCCESS PAGE
// Returns true to ProfilePage to activate catererMode toggle
// ─────────────────────────────────────────────────────────────

class CatererSuccessPage extends StatelessWidget {
  final String businessName;
  const CatererSuccessPage({super.key, required this.businessName});

  static const Color _primary = Color(0xFFFF6B22);
  static const Color _primaryLight = Color(0xFFFF8C5A);
  static const Color _primaryBg = Color(0x1AFF6B22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Orange band
          Container(
            height: MediaQuery.of(context).padding.top + 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'CelebrEats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Animated check
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

                      // Business badge
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

                      // Next steps
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

                      // CTA — pops all the way back to ProfilePage with result = true
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
                            onPressed: () {
                              // Pop back to ProfilePage and signal success = true
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
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
