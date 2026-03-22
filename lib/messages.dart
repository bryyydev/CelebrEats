import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_screen.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  Widget safeImage(String assetPath, {double? height, double? width}) {
    return Image.asset(
      assetPath,
      height: height,
      width: width,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.restaurant_menu,
          size: height ?? 32,
          color: Colors.deepOrange,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --------------------------------------------------
            /// TOP BAR
            /// --------------------------------------------------
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
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

                  // Notification Icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      "assets/icons/notification_ic.svg",
                      height: 26,
                      width: 26,
                      placeholderBuilder: (context) =>
                          const Icon(Icons.notifications_none, size: 26),
                    ),
                  ),
                ],
              ),
            ),

            /// --------------------------------------------------
            /// MESSAGES TITLE
            /// --------------------------------------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Text(
                "Messages",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            /// --------------------------------------------------
            /// MESSAGES LIST
            /// --------------------------------------------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildMessageCard(
                    name: "Catering Services Team",
                    message: "Thank you for your inquiry! How can we help?",
                    time: "2m ago",
                    unread: true,
                    avatar: Icons.support_agent,
                  ),
                  _buildMessageCard(
                    name: "Birthday Package",
                    message: "Your package details have been updated",
                    time: "1h ago",
                    unread: true,
                    avatar: Icons.cake,
                  ),
                  _buildMessageCard(
                    name: "Wedding Coordinator",
                    message: "We've received your booking request",
                    time: "3h ago",
                    unread: false,
                    avatar: Icons.favorite,
                  ),
                  _buildMessageCard(
                    name: "Payment Confirmation",
                    message: "Your payment has been confirmed",
                    time: "Yesterday",
                    unread: false,
                    avatar: Icons.check_circle,
                  ),
                  _buildMessageCard(
                    name: "Event Reminder",
                    message: "Your event is coming up in 3 days",
                    time: "2 days ago",
                    unread: false,
                    avatar: Icons.event,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard({
    required String name,
    required String message,
    required String time,
    required bool unread,
    required IconData avatar,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          /// AVATAR
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(avatar, color: Colors.deepOrange, size: 28),
          ),
          const SizedBox(width: 12),

          /// MESSAGE CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: unread ? Colors.black87 : Colors.grey[600],
                          fontWeight: unread
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
