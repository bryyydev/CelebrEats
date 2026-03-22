import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        backgroundColor: Colors.orange.withOpacity(0.15),
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
        activeColor: Colors.orange,
        onChanged: onChanged,
      ),
    );
  }
}

/// MY BOOKINGS PAGE AND COMPONENTS

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF6B22);

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
              Navigator.pop(context); // Navigates back to the profile page
            },
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
          bottom: const TabBar(
            indicatorColor: primaryOrange,
            labelColor: primaryOrange,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Upcoming (2)'),
              Tab(text: 'Past (0)'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [UpcomingBookingsTab(), PastBookingsTab()],
        ),
      ),
    );
  }
}

class UpcomingBookingsTab extends StatelessWidget {
  const UpcomingBookingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        BookingCard(
          title: "Manang Anna's Catering",
          subtitle: "Birthday",
          date: "2024-03-15 at 8:00 am",
          location: "San Vicente East, Urdaneta City, Pang.",
          guests: "100 guests",
          amount: "Php 50,000",
          status: "pending",
          statusBgColor: Color(0xFFFFF4D6),
          statusTextColor: Color(0xFFFFB020),
        ),
        SizedBox(height: 16),
        BookingCard(
          title: "Xian's Catering Services",
          subtitle: "Wedding Package",
          date: "2024-03-15 at 8:00 am",
          location: "Grand Ballroom, Downtown Hotel",
          guests: "120 guests",
          amount: "Php 70,000",
          status: "confirmed",
          statusBgColor: Color(0xFFD1F4CE),
          statusTextColor: Color(0xFF28A745),
        ),
      ],
    );
  }
}

class PastBookingsTab extends StatelessWidget {
  const PastBookingsTab({Key? key}) : super(key: key);

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
            child: const Icon(Icons.history, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Past Booking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your completed events will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey),
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

  const BookingCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.location,
    required this.guests,
    required this.amount,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
  }) : super(key: key);

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
                    color: primaryOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    color: primaryOrange,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
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
