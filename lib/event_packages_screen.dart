import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_helper.dart';
import 'datetime_picker_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EVENT PACKAGES SCREEN  (Caterer Profile → Packages)
// ─────────────────────────────────────────────────────────────────────────────
//
// Changes from original (all UI preserved):
//   - _BookingSheet._proceed() now navigates to DateTimePickerPage with the
//     full booking context instead of showing a stub Snackbar
//   - requireLogin() auth guard applied before opening the booking sheet
//   - _BookingSheet now receives catererName (fetched from header FutureBuilder
//     and passed down) so DateTimePickerPage can display it
//   - DateTimePickerPage constructor extended to accept catererId, catererName,
//     packageId, packageName, pricePerPerson, and pre-selected event type /
//     date / time / guests from the quick-booking sheet
//   - All other UI, animations, shimmer, inclusions, tab bar — UNCHANGED
// ─────────────────────────────────────────────────────────────────────────────

// ─── Theme constants (unchanged) ─────────────────────────────────────────────
class _T {
  static const primary = Color(0xFFFF6B22);
  static const primaryLt = Color(0xFFFF9A56);
  static const amber = Color(0xFFFFC107);
  static const bg = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const dark = Color(0xFF1C1C1E);
  static const mid = Color(0xFF6C6C70);
  static const light = Color(0xFFAEAEB2);
  static const border = Color(0xFFF2F2F7);
}

// ─────────────────────────────────────────────────────────────────────────────
class EventPackagesScreen extends StatefulWidget {
  final String catererId;

  const EventPackagesScreen({super.key, required this.catererId});

  @override
  State<EventPackagesScreen> createState() => _EventPackagesScreenState();
}

class _EventPackagesScreenState extends State<EventPackagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _tabs = ['Package A', 'Package B', 'Package C'];

  // Caterer name resolved once from the header FutureBuilder so we can pass
  // it down to _BookingSheet without an extra Firestore read.
  String _catererName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _packagesStream(String categoryTab) {
    return FirebaseFirestore.instance
        .collection('packages')
        .where('caterer_id', isEqualTo: widget.catererId)
        .where('category_tab', isEqualTo: categoryTab)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map(_buildTab).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient header (unchanged UI, adds _catererName side-effect) ─────────
  Widget _buildHeader(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('caterers')
          .doc(widget.catererId)
          .get(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] as String? ?? 'Catering Packages';
        final location = data['location'] as String? ?? '';
        final rating = (data['rating'] as num? ?? 0.0).toDouble();
        final reviewCount = (data['review_count'] as num? ?? 0).toInt();
        final isVerified = data['verified'] == true;

        // Cache the caterer name so _PackageCard can pass it to _BookingSheet
        if (name.isNotEmpty && _catererName != name) {
          // Use addPostFrameCallback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _catererName != name) {
              setState(() => _catererName = name);
            }
          });
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_T.primary, _T.primaryLt],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + share row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.ios_share_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Caterer name + verified badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Location + rating
                  Row(
                    children: [
                      if (location.isNotEmpty) ...[
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: _T.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviewCount reviews)',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Choose a package for your event',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab bar (unchanged) ───────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _T.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: _T.primary,
        unselectedLabelColor: _T.mid,
        indicatorColor: _T.primary,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ── One tab (unchanged) ───────────────────────────────────────────────────
  Widget _buildTab(String categoryTab) {
    return StreamBuilder<QuerySnapshot>(
      stream: _packagesStream(categoryTab),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) return _buildEmpty(categoryTab);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _PackageCard(
              docId: docs[i].id,
              data: data,
              catererId: widget.catererId,
              catererName: _catererName,
            );
          },
        );
      },
    );
  }

  Widget _buildShimmer() => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: 3,
    separatorBuilder: (_, __) => const SizedBox(height: 16),
    itemBuilder: (_, __) => _ShimmerPackageCard(),
  );

  Widget _buildEmpty(String tab) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDE6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: _T.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No $tab Packages',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _T.dark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'This caterer hasn\'t added packages\nfor this category yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _T.mid, height: 1.5),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PACKAGE CARD  (UI completely unchanged — catererName added as passthrough)
// ─────────────────────────────────────────────────────────────────────────────
class _PackageCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String catererId;
  final String catererName; // NEW: passed through to _BookingSheet

  const _PackageCard({
    required this.docId,
    required this.data,
    required this.catererId,
    required this.catererName,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] as String? ?? 'Package';
    final description = widget.data['description'] as String? ?? '';
    final price = (widget.data['price_per_person'] as num? ?? 0).toDouble();
    final inclusions = (widget.data['inclusions'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final minGuests = (widget.data['min_guests'] as num? ?? 0).toInt();
    final maxGuests = (widget.data['max_guests'] as num? ?? 0).toInt();
    final isPopular = widget.data['popular'] == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPopular ? _T.primary.withOpacity(0.4) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPopular)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_T.primary, _T.primaryLt],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '⭐ Most Popular',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _T.dark,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _T.mid,
                            height: 1.4,
                          ),
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Php ${_fmt(price)}',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _T.primary,
                      ),
                    ),
                    const Text(
                      '/ person',
                      style: TextStyle(fontSize: 10, color: _T.mid),
                    ),
                  ],
                ),
              ],
            ),

            // Guest capacity
            if (maxGuests > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 14,
                    color: _T.mid,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    minGuests > 0
                        ? '$minGuests–$maxGuests guests'
                        : 'Up to $maxGuests guests',
                    style: const TextStyle(fontSize: 12, color: _T.mid),
                  ),
                ],
              ),
            ],

            // Inclusions
            if (inclusions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: _T.border),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Text(
                      'Inclusions',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _T.dark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _expanded ? 'Show less' : 'Show all',
                      style: const TextStyle(fontSize: 11, color: _T.primary),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: _T.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              ...(_expanded ? inclusions : inclusions.take(3)).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDE6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: _T.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _T.mid,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              if (!_expanded && inclusions.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${inclusions.length - 3} more inclusions',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _T.light,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // CTA button — auth guard wraps the sheet
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_T.primary, _T.primaryLt],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _T.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _handleBookTap(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Book This Package',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Auth guard → booking sheet ────────────────────────────────────────────
  void _handleBookTap(BuildContext context) {
    requireLogin(context, onLoggedIn: () => _showBookingSheet(context));
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(
        packageId: widget.docId,
        packageName: widget.data['name'] as String? ?? 'Package',
        pricePerPerson: (widget.data['price_per_person'] as num? ?? 0)
            .toDouble(),
        catererId: widget.catererId,
        catererName: widget.catererName,
      ),
    );
  }

  String _fmt(double price) => price
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
//
// FIX: _proceed() now navigates to DateTimePickerPage with the full package
// context instead of showing a stub Snackbar. The sheet closes first, then
// the full DateTimePickerPage flow begins. All UI inside the sheet is
// preserved exactly — only _proceed() is changed.
// ─────────────────────────────────────────────────────────────────────────────
class _BookingSheet extends StatefulWidget {
  final String packageId;
  final String packageName;
  final double pricePerPerson;
  final String catererId;
  final String catererName; // NEW: needed for DateTimePickerPage

  const _BookingSheet({
    required this.packageId,
    required this.packageName,
    required this.pricePerPerson,
    required this.catererId,
    required this.catererName,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  int _guests = 50;
  DateTime? _date;
  TimeOfDay? _time;
  String? _eventType;

  final List<String> _eventTypes = [
    'Birthday',
    'Wedding',
    'Reunion',
    'Baptism',
    'Corporate',
    'Debut',
  ];

  double get _total => _guests * widget.pricePerPerson;

  bool get _canProceed => _eventType != null && _date != null && _time != null;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String _fmtPrice(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  // ── FIX: real navigation instead of stub Snackbar ─────────────────────────
  void _proceed() {
    if (!_canProceed) return;

    // Close the bottom sheet, then push DateTimePickerPage with full context.
    // Using the parent context (from showModalBottomSheet) ensures the push
    // lands on the NavigatorState that owns EventPackagesScreen.
    Navigator.pop(context);

    // selectedItems is empty at this stage — CustomizePackage / the
    // DateTimePickerPage form collects them. Pass an empty map that
    // DateTimePickerPage will forward through the chain.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DateTimePickerPage(
          // Existing param
          selectedItems: const {},
          // New params wired into the Firestore booking document
          catererId: widget.catererId,
          catererName: widget.catererName,
          packageId: widget.packageId,
          packageName: widget.packageName,
          pricePerPerson: widget.pricePerPerson,
          // Pre-fill from the quick-booking sheet so the user doesn't have
          // to re-enter what they already selected here
          preselectedEventType: _eventType,
          preselectedDate: _date,
          preselectedTime: _time,
          preselectedGuests: _guests,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _T.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              Text(
                'Book Package',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _T.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.packageName,
                style: const TextStyle(fontSize: 13, color: _T.mid),
              ),

              const SizedBox(height: 20),

              // Event type chips
              _label('Event Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eventTypes.map((t) {
                  final sel = _eventType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _eventType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? _T.primary : _T.border,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : _T.dark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Date picker
              _label('Event Date'),
              const SizedBox(height: 8),
              _PickerTile(
                icon: Icons.calendar_today_rounded,
                text: _date != null ? _fmtDate(_date!) : 'Select date',
                hasValue: _date != null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: _T.primary,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),

              const SizedBox(height: 12),

              // Time picker
              _label('Event Time'),
              const SizedBox(height: 8),
              _PickerTile(
                icon: Icons.access_time_rounded,
                text: _time != null ? _fmtTime(_time!) : 'Select time',
                hasValue: _time != null,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: _T.primary,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _time = picked);
                },
              ),

              const SizedBox(height: 20),

              // Guests stepper
              _label('Number of Guests'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _T.border,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 18,
                      color: _T.mid,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_guests guests',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: _T.dark,
                        ),
                      ),
                    ),
                    _stepBtn(
                      Icons.remove_rounded,
                      () => setState(
                        () => _guests = (_guests - 10).clamp(10, 9999),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _stepBtn(
                      Icons.add_rounded,
                      () => setState(() => _guests += 10),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Price summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDE6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Total',
                            style: TextStyle(fontSize: 12, color: _T.mid),
                          ),
                          Text(
                            'Php ${_fmtPrice(_total)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _T.primary,
                            ),
                          ),
                          Text(
                            'Php ${_fmtPrice(widget.pricePerPerson)} × $_guests guests',
                            style: const TextStyle(fontSize: 11, color: _T.mid),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: _T.primary,
                      size: 32,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_T.primary, _T.primaryLt],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _T.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _canProceed ? _proceed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue to Event Details',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              if (!_canProceed) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Please fill in all fields to continue',
                    style: const TextStyle(fontSize: 11, color: _T.light),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _T.dark,
    ),
  );

  Widget _stepBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
        ],
      ),
      child: Icon(icon, size: 16, color: _T.primary),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PICKER TILE  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool hasValue;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.text,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _T.border,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? _T.primary.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: hasValue ? _T.primary : _T.mid),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                color: hasValue ? _T.dark : _T.light,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _T.mid),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER PACKAGE CARD  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerPackageCard extends StatefulWidget {
  @override
  State<_ShimmerPackageCard> createState() => _ShimmerPackageCardState();
}

class _ShimmerPackageCardState extends State<_ShimmerPackageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween(begin: -2.0, end: 2.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double r = 8}) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value, 0),
          colors: const [
            Color(0xFFEEEEEE),
            Color(0xFFF8F8F8),
            Color(0xFFEEEEEE),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _box(double.infinity, 16)),
              const SizedBox(width: 24),
              _box(80, 20),
            ],
          ),
          const SizedBox(height: 10),
          _box(200, 10),
          const SizedBox(height: 16),
          _box(double.infinity, 44, r: 12),
        ],
      ),
    );
  }
}
