import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Safe image loader - won't crash if image is missing
  Widget safeImage(String path, {double? height, double? width, BoxFit? fit}) {
    return Image.asset(
      path,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: width,
          color: Colors.grey[300],
          child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --------------------------------------------------
              /// TOP BAR
              /// --------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
                        const Icon(Icons.notifications_none_rounded, size: 28),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showLogoutDialog(context),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// --------------------------------------------------
              /// BANNER + SEARCH
              /// --------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFCA06A), Color(0xFFEB4A42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Plan Your Perfect Event",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Choose from our professional catering services",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),

                      /// Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Search",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(Icons.search, color: Colors.black54),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// --------------------------------------------------
              /// EVENT TYPES
              /// --------------------------------------------------
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Event Type",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 95,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    eventCard("assets/birthday.png", "Birthday"),
                    eventCard("assets/wedding.png", "Wedding"),
                    eventCard("assets/reunion.png", "Reunion"),
                    eventCard("assets/baptism.png", "Baptism"),
                  ],
                ),
              ),

              /// --------------------------------------------------
              /// FEATURED PACKAGES
              /// --------------------------------------------------
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Our Featured Packages",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "View All",
                      style: TextStyle(color: Colors.deepOrange, fontSize: 14),
                    ),
                  ],
                ),
              ),

              /// ❤️ HERE I CHANGED THE IMAGE
              featuredCard(
                image: "assets/premium_bday.png", // ← your new image
                title: "Premium Birthday Package",
                rating: 4.9,
                price: "₱28,500",
                oldPrice: "₱35,500",
                guests: "for 80 - 100 guests",
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout(context);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------
  /// EVENT TYPE CARD WIDGET
  /// -------------------------------------------------------------
  Widget eventCard(String img, String title) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      width: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            img,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.celebration, color: Colors.orange[700]),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------
  /// FEATURED PACKAGE CARD
  /// -------------------------------------------------------------
  Widget featuredCard({
    required String image,
    required String title,
    required double rating,
    required String price,
    required String oldPrice,
    required String guests,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                Image.asset(
                  image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[200]!, Colors.orange[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.cake,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Full Service\nComplete Birthday celebration with food and decorations.",
                  style: TextStyle(color: Colors.black54, height: 1.3),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "$rating",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      oldPrice,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(guests, style: const TextStyle(color: Colors.black54)),

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Select"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
