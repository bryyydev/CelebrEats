import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'bottom_navigation.dart';
import 'services/database_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool catererMode = false;

  Widget svgIcon(String assetPath, {double size = 24, Color? color}) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  Widget safeImage(String assetPath, {double? height, double? width}) {
    return Image.asset(
      assetPath,
      height: height,
      width: width,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.restaurant_menu,
          size: 32,
          color: Colors.deepOrange,
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      safeImage("assets/logo.png", height: 32),
                      const SizedBox(width: 8),
                      const Text(
                        "Catering Services",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      svgIcon(
                        "assets/icons/notification_ic.svg",
                        size: 26,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showLogoutDialog(context),
                        child: svgIcon(
                          "assets/icons/person_ic.svg",
                          size: 26,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// CONTENT
            Expanded(
              child: ListView(
                children: [
                  /// PROFILE HEADER
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
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "John Doe",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "john.doe@example.com",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _StatItem(value: "12", label: "Bookings"),
                            _StatItem(value: "8", label: "Reviews"),
                            _StatItem(value: "5", label: "Favorites"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// MENU (SVG ICONS)
                  _SwitchTile(
                    iconPath: "assets/icons/help_support_ic.svg",
                    title: "Caterer Mode",
                    subtitle: "Manage your catering business",
                    value: catererMode,
                    onChanged: (value) {
                      setState(() => catererMode = value);
                    },
                  ),
                  _MenuTile(
                    iconPath: "assets/icons/mybooking_ic.svg",
                    title: "My Booking",
                    // Added navigation logic here:
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyBookingsPage(),
                        ),
                      );
                    },
                  ),
                  _MenuTile(
                    iconPath: "assets/icons/person_ic.svg",
                    title: "Edit Profile",
                  ),
                  _MenuTile(
                    iconPath: "assets/icons/changepassword_ic.svg",
                    title: "Change Password",
                  ),
                  _MenuTile(
                    iconPath: "assets/icons/notification_ic.svg",
                    title: "Notification",
                  ),
                  _MenuTile(
                    iconPath: "assets/icons/favorites_ic.svg",
                    title: "Favorites",
                  ),
                  _MenuTile(
                    iconPath: "assets/icons/payment_method_ic.svg",
                    title: "Payment Methods",
                  ),
                  _MenuTile(
                    iconPath: "assets/icons/help_support_ic.svg",
                    title: "Help & Support",
                  ),
                  _MenuTile(
                    iconPath: "assets/icons/terms_condition_ic.svg",
                    title: "Terms & Conditions",
                  ),

                  /// LOGOUT
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// COMPONENTS

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

class _MenuTile extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback? onTap; // Added this property to handle taps

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
      onTap: onTap ?? () {}, // Modified to trigger the passed function
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withValues(alpha: 0.15),
        child: SvgPicture.asset(
          iconPath,
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        activeThumbColor: Colors.orange,
        onChanged: onChanged,
      ),
    );
  }
}

/// MY BOOKINGS PAGE AND COMPONENTS

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF6B22);

    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getUserBookings(),
      builder: (context, snapshot) {
        final docs = _sortedBookings(snapshot.data?.docs ?? []);
        final upcoming = docs.where(_isUpcomingBooking).toList();
        final past = docs.where((doc) => !_isUpcomingBooking(doc)).toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => _goBack(context),
              ),
              title: const Text(
                'My Bookings',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              bottom: TabBar(
                indicatorColor: primaryOrange,
                labelColor: primaryOrange,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Upcoming (${upcoming.length})'),
                  Tab(text: 'Past (${past.length})'),
                ],
              ),
            ),
            body: _buildBody(snapshot, upcoming, past),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<QuerySnapshot> snapshot,
    List<QueryDocumentSnapshot> upcoming,
    List<QueryDocumentSnapshot> past,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError && upcoming.isEmpty && past.isEmpty) {
      return _BookingEmptyState(
        icon: Icons.error_outline,
        title: 'Could not load bookings',
        subtitle: _bookingErrorMessage(snapshot.error),
      );
    }

    return TabBarView(
      children: [
        BookingsList(docs: upcoming, emptyPast: false),
        BookingsList(docs: past, emptyPast: true),
      ],
    );
  }

  void _goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 3)),
    );
  }

  bool _isUpcomingBooking(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] ?? '').toString().toLowerCase();
    return !{'completed', 'cancelled', 'declined'}.contains(status);
  }

  List<QueryDocumentSnapshot> _sortedBookings(
    List<QueryDocumentSnapshot> docs,
  ) {
    final sorted = [...docs];
    sorted.sort((a, b) {
      final aDate = _sortDate(a.data() as Map<String, dynamic>);
      final bDate = _sortDate(b.data() as Map<String, dynamic>);
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  DateTime _sortDate(Map<String, dynamic> data) {
    final createdAt = data['created_at'] ?? data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();

    final eventDate = data['event_date'] ?? data['eventDate'];
    if (eventDate is Timestamp) return eventDate.toDate();

    final date = DateTime.tryParse((data['date'] ?? '').toString());
    return date ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _bookingErrorMessage(Object? error) {
    final text = error.toString().toLowerCase();
    if (text.contains('permission-denied')) {
      return 'Your account does not have permission to read these bookings yet.';
    }
    if (text.contains('index')) {
      return 'Firestore needs an index for this bookings query.';
    }
    return 'Please check your connection and try again.';
  }
}

class BookingsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final bool emptyPast;

  const BookingsList({super.key, required this.docs, required this.emptyPast});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return _BookingEmptyState(
        icon: emptyPast ? Icons.history : Icons.event_busy,
        title: emptyPast ? 'No Past Booking' : 'No Upcoming Booking',
        subtitle: emptyPast
            ? 'Your completed events will appear here'
            : 'Your confirmed bookings will appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return BookingCard.fromData(
          data,
          onChat: () => _goToMessages(context),
          onViewDetails: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookingDetailsPage(data: data)),
          ),
        );
      },
    );
  }

  void _goToMessages(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 2)),
      (_) => false,
    );
  }
}

class _BookingEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BookingEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String location;
  final String guests;
  final String amount;
  final String status;
  final Color statusBgColor;
  final Color statusTextColor;
  final VoidCallback onChat;
  final VoidCallback onViewDetails;

  const BookingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.location,
    required this.guests,
    required this.amount,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.onChat,
    required this.onViewDetails,
  });

  factory BookingCard.fromData(
    Map<String, dynamic> data, {
    required VoidCallback onChat,
    required VoidCallback onViewDetails,
  }) {
    final status = (data['status'] ?? 'pending').toString();
    final colors = _statusColors(status);
    final date = _formatDate(data);
    final total = _asDouble(data['total'] ?? data['total_amount']);
    final guests = data['guests'] ?? data['numberOfGuests'] ?? 0;

    return BookingCard(
      title: (data['caterer_name'] ?? data['catererName'] ?? 'Caterer')
          .toString(),
      subtitle: (data['event_type'] ?? data['eventType'] ?? 'Event').toString(),
      date: date,
      location: (data['location'] ?? data['venue'] ?? 'No location').toString(),
      guests: '$guests guests',
      amount: 'Php ${_formatAmount(total)}',
      status: status,
      statusBgColor: colors.$1,
      statusTextColor: colors.$2,
      onChat: onChat,
      onViewDetails: onViewDetails,
    );
  }

  static (Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return (const Color(0xFFD1F4CE), const Color(0xFF28A745));
      case 'completed':
        return (const Color(0xFFEAF4FF), const Color(0xFF3498DB));
      case 'cancelled':
      case 'declined':
        return (const Color(0xFFFFE6E6), const Color(0xFFE53935));
      default:
        return (const Color(0xFFFFF4D6), const Color(0xFFFFB020));
    }
  }

  static String _formatDate(Map<String, dynamic> data) {
    final date = data['date'];
    final time = data['event_time'] ?? data['eventTime'];
    if (date != null && time != null) return '$date at $time';
    if (date != null) return date.toString();

    final timestamp = data['event_date'] ?? data['eventDate'];
    if (timestamp is Timestamp) {
      final value = timestamp.toDate();
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    return 'No date';
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF6B22);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today_outlined, date),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.location_on_outlined, location),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.people_outline, guests),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: primaryOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    color: primaryOrange,
                    onPressed: onChat,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class BookingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const BookingDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString();
    final colors = BookingCard._statusColors(status);
    final total = BookingCard._asDouble(data['total'] ?? data['total_amount']);
    final downPayment = BookingCard._asDouble(
      data['down_payment'] ?? data['downPayment'],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _text('caterer_name', fallback: 'Caterer'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.$1,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: colors.$2,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detail('Package', _text('package_name', fallback: 'Package')),
                _detail('Event', _text('event_name', fallback: 'Event')),
                _detail('Type', _text('event_type', fallback: 'Event')),
                _detail('Date & Time', BookingCard._formatDate(data)),
                _detail('Venue', _text('venue', fallback: 'No venue')),
                _detail('Location', _text('location', fallback: 'No location')),
                _detail('Guests', '${data['guests'] ?? 0} guests'),
                _detail(
                  'Contact',
                  _text('contact_number', fallback: 'No contact number'),
                ),
                const Divider(height: 28),
                _detail('Total', 'Php ${BookingCard._formatAmount(total)}'),
                _detail(
                  'Down Payment',
                  'Php ${BookingCard._formatAmount(downPayment)}',
                ),
                _detail('Payment', _text('payment_status', fallback: 'unpaid')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _text(String key, {required String fallback}) {
    return (data[key] ?? data[_camelCase(key)] ?? fallback).toString();
  }

  String _camelCase(String key) {
    final parts = key.split('_');
    if (parts.isEmpty) return key;
    return parts.first +
        parts.skip(1).map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        }).join();
  }
}
