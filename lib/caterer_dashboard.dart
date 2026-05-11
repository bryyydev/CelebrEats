import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────
// CATERER DASHBOARD PAGE
//
// KEY FIXES vs original
// ─────────────────────
// 1. _showPackageSheet now has a category_tab dropdown
//    ('Package A' / 'Package B' / 'Package C') and saves that
//    value to Firestore so EventPackagesScreen can filter by tab.
// 2. The "Add Package" payload also includes 'description' and
//    'inclusions' (parsed from a comma-separated text field) so
//    the consumer screen can display them correctly.
// 3. All other UI, colours, and layout are unchanged.
// ─────────────────────────────────────────────────────────────

class CatererDashboardPage extends StatefulWidget {
  const CatererDashboardPage({super.key});

  @override
  State<CatererDashboardPage> createState() => _CatererDashboardPageState();
}

class _CatererDashboardPageState extends State<CatererDashboardPage> {
  int _selectedTab = 0;

  static const Color _primary = Color(0xFFFF6B22);
  static const Color _primaryLight = Color(0xFFFFAA55);
  static const Color _primaryBg = Color(0xFFFFF3ED);
  static const Color _border = Color(0xFFEEEEEE);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMid = Color(0xFF666666);
  static const Color _textLight = Color(0xFFAAAAAA);
  static const Color _success = Color(0xFF22C55E);

  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final List<String> _tabs = ['Overview', 'Packages', 'Add-ons', 'Booking'];

  // ── Tab labels that must match Firestore `category_tab` values ──────────
  static const List<String> _categoryTabs = [
    'Package A',
    'Package B',
    'Package C',
  ];

  // ── Safe back navigation ──────────────────────────────────
  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ── Toggle availability ───────────────────────────────────
  Future<void> _toggleAvailability(bool current) async {
    await FirebaseFirestore.instance.collection('caterers').doc(uid).update({
      'is_active': !current,
    });
  }

  // ── Exit caterer mode ─────────────────────────────────────
  Future<void> _exitCatererMode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Exit Caterer Mode',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'You will be switched back to customer mode. '
          'You can re-enable caterer mode from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textMid)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'is_caterer': false,
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('caterers')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          final isActive = data['is_active'] as bool? ?? true;

          return Scaffold(
            backgroundColor: const Color(0xFFF2F2F2),
            body: Column(
              children: [
                _buildHeader(data, isActive),
                _buildTabBar(),
                Expanded(child: _buildTabContent(data)),
                _buildExitButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Gradient header ───────────────────────────────────────
  Widget _buildHeader(Map<String, dynamic> data, bool isActive) {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: _goBack,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Caterer Dashboard',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Text(
                      'Manage your business',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Available toggle
              Row(
                children: [
                  Text(
                    isActive ? 'Available' : 'Unavailable',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _toggleAvailability(isActive),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _success
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        alignment: isActive
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
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

  // ── Tab bar ───────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? _primary : _border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _textMid,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> catererData) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(catererData);
      case 1:
        return _buildPackagesTab();
      case 2:
        return _buildAddonsTab();
      case 3:
        return _buildBookingTab();
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────
  // TAB 0 — OVERVIEW
  // ─────────────────────────────────────────────────────────
  Widget _buildOverviewTab(Map<String, dynamic> data) {
    final isActive = data['is_active'] as bool? ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile card ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildCoverImage(data),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _buildLogoWidget(data),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? 'Your Business',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFC107),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${(data['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}'
                                  ' (${data['review_count'] ?? 0} reviews)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _textMid,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: isActive ? _success : _textLight,
                          size: 8,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isActive
                              ? 'Available for Booking'
                              : 'Currently Unavailable',
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? _success : _textLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Stats row ─────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('caterer_id', isEqualTo: uid)
                .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              final total = docs.length;
              final upcoming = docs
                  .where((d) => (d.data() as Map)['status'] == 'accepted')
                  .length;
              final earnings = docs
                  .where((d) => (d.data() as Map)['status'] == 'completed')
                  .fold<num>(
                    0,
                    (s, d) => s + ((d.data() as Map)['total'] as num? ?? 0),
                  );
              return Row(
                children: [
                  _statCard(
                    Icons.calendar_today_outlined,
                    '$total',
                    'Total\nBookings',
                    _primaryBg,
                    _primary,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    Icons.access_time_outlined,
                    '$upcoming',
                    'Upcoming',
                    const Color(0xFFEFF6FF),
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    Icons.attach_money_outlined,
                    '₱${_formatNum(earnings.toInt())}',
                    'Earnings',
                    const Color(0xFFF0FDF4),
                    _success,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Recent bookings ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 3),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('caterer_id', isEqualTo: uid)
                .limit(5)
                .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return _emptyState(
                  Icons.calendar_today_outlined,
                  'No Bookings Yet',
                  'Your bookings will appear here',
                );
              }
              return Column(
                children: docs
                    .map(
                      (d) => _bookingListItem(d.data() as Map<String, dynamic>),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(Map<String, dynamic> data) {
    final photos = data['menu_photos'] as List?;
    if (photos != null && photos.isNotEmpty) {
      try {
        final raw = photos.first as String;
        final str = raw.contains(',') ? raw.split(',').last : raw;
        final bytes = base64Decode(str);
        return Image.memory(
          bytes,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _coverPlaceholder(),
        );
      } catch (_) {}
    }
    return _coverPlaceholder();
  }

  Widget _coverPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: _primaryBg,
      child: const Icon(Icons.restaurant, color: _primary, size: 48),
    );
  }

  Widget _buildLogoWidget(Map<String, dynamic> data) {
    final logoRaw = data['logo_photo'] as String?;
    if (logoRaw != null && logoRaw.isNotEmpty) {
      try {
        final str = logoRaw.contains(',') ? logoRaw.split(',').last : logoRaw;
        final bytes = base64Decode(str);
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _logoFallback(),
            ),
          ),
        );
      } catch (_) {}
    }
    return _logoFallback();
  }

  Widget _logoFallback() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _primaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary, width: 2),
      ),
      child: const Icon(Icons.storefront, color: _primary, size: 26),
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
    Color bg,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: _textMid,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 1 — PACKAGES
  // ─────────────────────────────────────────────────────────
  Widget _buildPackagesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Packages',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddPackageSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text(
                  'Add Package',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('packages')
                .where('caterer_id', isEqualTo: uid)
                .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return _emptyState(
                  Icons.inventory_2_outlined,
                  'No Packages Yet',
                  'Tap "+ Add Package" to create your first package',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _packageCard(docs[i].id, d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _packageCard(String docId, Map<String, dynamic> d) {
    final active = d['active'] as bool? ?? true;
    // Show which tab this package belongs to
    final categoryTab = d['category_tab'] as String? ?? '';

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    if (categoryTab.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          categoryTab,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _toggle(active, (val) async {
                await FirebaseFirestore.instance
                    .collection('packages')
                    .doc(docId)
                    .update({'active': val});
              }),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            d['description'] ?? '',
            style: const TextStyle(fontSize: 12, color: _textMid),
          ),
          const SizedBox(height: 10),
          Text(
            'Php ${_formatNum((d['price_per_person'] as num?)?.toInt() ?? 0)} / person',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _textLight,
              ),
              const SizedBox(width: 6),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('package_id', isEqualTo: docId)
                    .snapshots(),
                builder: (ctx, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return Text(
                    '$count bookings',
                    style: const TextStyle(fontSize: 12, color: _textMid),
                  );
                },
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showEditPackageSheet(docId, d),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: _textMid,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteDoc('packages', docId),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 2 — ADD-ONS
  // ─────────────────────────────────────────────────────────
  Widget _buildAddonsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('addons')
          .where('caterer_id', isEqualTo: uid)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];

        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (final doc in docs) {
          final cat = (doc.data() as Map)['category'] as String? ?? 'Others';
          grouped.putIfAbsent(cat, () => []).add(doc);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add-ons & Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddAddonSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            docs.isEmpty
                ? Expanded(
                    child: _emptyState(
                      Icons.extension_outlined,
                      'No Add-ons Yet',
                      'Tap "Add" to create your first add-on',
                    ),
                  )
                : Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: grouped.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                              const Divider(height: 1, color: _border),
                              ...entry.value.map((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                return _addonRow(doc.id, d);
                              }),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _addonRow(String docId, Map<String, dynamic> d) {
    final active = d['active'] as bool? ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                Text(
                  'Php ${_formatNum((d['price'] as num?)?.toInt() ?? 0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _toggle(active, (val) async {
            await FirebaseFirestore.instance
                .collection('addons')
                .doc(docId)
                .update({'active': val});
          }),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _showEditAddonSheet(docId, d);
              if (v == 'delete') _deleteDoc('addons', docId);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
            icon: const Icon(Icons.more_vert, size: 18, color: _textLight),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 3 — BOOKING
  // ─────────────────────────────────────────────────────────
  Widget _buildBookingTab() {
    return StatefulBuilder(
      builder: (context, setFilter) {
        String selectedFilter = 'All';
        final filters = [
          'All',
          'Pending',
          'Accepted',
          'Completed',
          'Cancelled',
        ];
        return StatefulBuilder(
          builder: (context, setInner) {
            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: filters.map((f) {
                      final active = f == selectedFilter;
                      return GestureDetector(
                        onTap: () => setInner(() => selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: active ? _primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? _primary : _border,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : _textMid,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: selectedFilter == 'All'
                        ? FirebaseFirestore.instance
                              .collection('bookings')
                              .where('caterer_id', isEqualTo: uid)
                              .snapshots()
                        : FirebaseFirestore.instance
                              .collection('bookings')
                              .where('caterer_id', isEqualTo: uid)
                              .where(
                                'status',
                                isEqualTo: selectedFilter.toLowerCase(),
                              )
                              .snapshots(),
                    builder: (ctx, snap) {
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return _emptyState(
                          Icons.history_outlined,
                          'No ${selectedFilter == 'All' ? '' : selectedFilter} Bookings',
                          'Your bookings will appear here',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          return _bookingCard(docs[i].id, d);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _bookingCard(String docId, Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'pending';
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _primaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: _primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['customer_name'] ?? 'Customer',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      '${d['date'] ?? '—'} • ${d['guests'] ?? 0} guests',
                      style: const TextStyle(fontSize: 11, color: _textMid),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateBookingStatus(docId, 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateBookingStatus(docId, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bookingListItem(Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _primaryBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: _primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['customer_name'] ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                Text(
                  '${d['date'] ?? '—'} • ${d['guests'] ?? 0} guests',
                  style: const TextStyle(fontSize: 11, color: _textMid),
                ),
              ],
            ),
          ),
          _statusBadge(status),
        ],
      ),
    );
  }

  // ── Exit button ───────────────────────────────────────────
  Widget _buildExitButton() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: GestureDetector(
        onTap: _exitCatererMode,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_outlined, color: _textMid, size: 18),
              SizedBox(width: 8),
              Text(
                'Exit Caterer Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BOTTOM SHEETS
  // ─────────────────────────────────────────────────────────

  void _showAddPackageSheet() => _showPackageSheet(null, null);
  void _showEditPackageSheet(String id, Map<String, dynamic> d) =>
      _showPackageSheet(id, d);

  /// FIX: Sheet now includes a category_tab dropdown so the caterer can choose
  /// which tab (Package A / B / C) this package belongs to. That value is
  /// saved to Firestore and consumed by EventPackagesScreen's StreamBuilder.
  void _showPackageSheet(String? docId, Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final descCtrl = TextEditingController(
      text: existing?['description'] ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?['price_per_person']?.toString() ?? '',
    );
    // Pre-fill inclusions as a comma-separated string for easy editing
    final inclusionsCtrl = TextEditingController(
      text: existing != null
          ? ((existing['inclusions'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .join(', '))
          : '',
    );
    // Default category_tab to the first option if none stored yet
    String selectedCategoryTab =
        (existing?['category_tab'] as String?)?.isNotEmpty == true
        ? existing!['category_tab'] as String
        : _categoryTabs.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => _bottomSheet(
            title: docId == null ? 'Add Package' : 'Edit Package',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package name
                _sheetField(
                  nameCtrl,
                  'Package Name',
                  Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 12),

                // Description
                _sheetField(
                  descCtrl,
                  'Description',
                  Icons.notes_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Price per person
                _sheetField(
                  priceCtrl,
                  'Price per Person (₱)',
                  Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Inclusions (comma-separated)
                _sheetField(
                  inclusionsCtrl,
                  'Inclusions (comma separated)',
                  Icons.checklist_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // ── FIX: Category tab dropdown ─────────────────────────
                // The selected value becomes the `category_tab` field in
                // Firestore. EventPackagesScreen filters by this exact string.
                const Text(
                  'Package Tab',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategoryTab,
                      isExpanded: true,
                      items: _categoryTabs
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setSheet(
                        () => selectedCategoryTab = v ?? selectedCategoryTab,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _sheetSubmitButton(
                  label: docId == null ? 'Add Package' : 'Save Changes',
                  onTap: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        priceCtrl.text.trim().isEmpty)
                      return;

                    // Parse comma-separated inclusions into a List<String>
                    final inclusions = inclusionsCtrl.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    final payload = {
                      'caterer_id': uid,
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'price_per_person':
                          num.tryParse(priceCtrl.text.trim()) ?? 0,
                      'inclusions': inclusions,
                      // Saved to Firestore so EventPackagesScreen can filter
                      // packages into the correct TabBarView tab.
                      'category_tab': selectedCategoryTab,
                      'active': true,
                    };

                    if (docId == null) {
                      await FirebaseFirestore.instance
                          .collection('packages')
                          .add(payload);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('packages')
                          .doc(docId)
                          .update(payload);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAddonSheet() => _showAddonSheet(null, null);
  void _showEditAddonSheet(String id, Map<String, dynamic> d) =>
      _showAddonSheet(id, d);

  void _showAddonSheet(String? docId, Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final priceCtrl = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );
    String category = existing?['category'] ?? 'Decorations';
    final categories = [
      'Decorations',
      'Extra Services',
      'Food Add-ons',
      'Others',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => _bottomSheet(
            title: docId == null ? 'Add Add-on' : 'Edit Add-on',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetField(nameCtrl, 'Add-on Name', Icons.extension_outlined),
                const SizedBox(height: 12),
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setSheet(() => category = v ?? category),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _sheetField(
                  priceCtrl,
                  'Price (₱)',
                  Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                _sheetSubmitButton(
                  label: docId == null ? 'Add Add-on' : 'Save Changes',
                  onTap: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        priceCtrl.text.trim().isEmpty)
                      return;
                    final payload = {
                      'caterer_id': uid,
                      'name': nameCtrl.text.trim(),
                      'category': category,
                      'price': num.tryParse(priceCtrl.text.trim()) ?? 0,
                      'active': true,
                    };
                    if (docId == null) {
                      await FirebaseFirestore.instance
                          .collection('addons')
                          .add(payload);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('addons')
                          .doc(docId)
                          .update(payload);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FIRESTORE ACTIONS
  // ─────────────────────────────────────────────────────────
  Future<void> _deleteDoc(String collection, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();
    }
  }

  Future<void> _updateBookingStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
      'status': status,
    });
  }

  // ─────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────
  Widget _toggle(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? _success : const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final map = {
      'pending': [const Color(0xFFFFF7ED), const Color(0xFFEA580C)],
      'accepted': [const Color(0xFFEFF6FF), const Color(0xFF2563EB)],
      'confirmed': [const Color(0xFFF0FDF4), _success],
      'completed': [const Color(0xFFF5F3FF), const Color(0xFF7C3AED)],
      'cancelled': [const Color(0xFFFFF1F2), const Color(0xFFE11D48)],
    };
    final colors = map[status] ?? [const Color(0xFFF5F5F5), _textMid];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors[1],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFFDDDDDD)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textMid,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _textLight),
          ),
        ],
      ),
    );
  }

  Widget _bottomSheet({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 48,
            decoration: const BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                bottomLeft: Radius.circular(9),
              ),
            ),
            child: Icon(icon, color: _primary, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 13, color: _textDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 13, color: _textLight),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetSubmitButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primary, _primaryLight]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────
  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}
