// TOP BAR IS NOW SCROLLABLE — it lives at index 0 of the ListView,
// so "unread notification" and "Mark all as read" scroll with the list.

import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Color orange = const Color(0xFFFF8A00);

  List<Map<String, dynamic>> notifications = [
    {
      "id": 1,
      "title": "Booking Confirmed!",
      "body":
          "Your booking with Manang Anna's Catering for Dec 28 has been confirmed.",
      "time": "2 min ago",
      "unread": true,
      "icon": Icons.calendar_month,
      "iconBg": const Color(0xFFE9F7EF),
      "iconColor": const Color(0xFF2ECC71),
    },
    {
      "id": 2,
      "title": "New Message",
      "body":
          "Xian's Catering Services sent you a message about your upcoming event.",
      "time": "5 hours ago",
      "unread": true,
      "icon": Icons.chat_bubble_outline,
      "iconBg": const Color(0xFFEAF4FF),
      "iconColor": const Color(0xFF3498DB),
    },
    {
      "id": 3,
      "title": "20% Off Holiday Special!",
      "body": "Book any wedding package this month and get 20% discount.",
      "time": "1 day ago",
      "unread": false,
      "icon": Icons.card_giftcard,
      "iconBg": const Color(0xFFFFF3E0),
      "iconColor": const Color(0xFFFF8A00),
    },
    {
      "id": 4,
      "title": "Leave a Review",
      "body":
          "How was your experience with the Handaan Express? Share your feedback!",
      "time": "2 days ago",
      "unread": false,
      "icon": Icons.star,
      "iconBg": const Color(0xFFFFFDE7),
      "iconColor": const Color(0xFFFFC107),
    },
    {
      "id": 5,
      "title": "Payment Received",
      "body":
          "Payment of Php 45,000 for your birthday celebration has been received.",
      "time": "3 days ago",
      "unread": false,
      "icon": Icons.check_circle,
      "iconBg": const Color(0xFFE9F7EF),
      "iconColor": const Color(0xFF27AE60),
    },
    {
      "id": 6,
      "title": "Welcome to CelebrEats!",
      "body": "Start exploring caterers for your next celebration.",
      "time": "1 week ago",
      "unread": false,
      "icon": Icons.info_outline,
      "iconBg": const Color(0xFFF3F3F3),
      "iconColor": const Color(0xFF9E9E9E),
    },
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────

  int get _unreadCount =>
      notifications.where((n) => n["unread"] == true).length;

  // ── Actions ───────────────────────────────────────────────────────────────

  void _markAllAsRead() {
    setState(() {
      for (final n in notifications) {
        n["unread"] = false;
      }
    });
  }

  void _markAsRead(int id) {
    setState(() {
      final index = notifications.indexWhere((n) => n["id"] == id);
      if (index != -1) notifications[index]["unread"] = false;
    });
  }

  void _deleteNotification(int id) {
    final removedItem = Map<String, dynamic>.from(
      notifications.firstWhere((n) => n["id"] == id),
    );
    final removedIndex = notifications.indexWhere((n) => n["id"] == id);

    setState(() {
      notifications.removeWhere((n) => n["id"] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Notification removed"),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Undo",
          textColor: orange,
          onPressed: () {
            setState(() {
              notifications.insert(removedIndex, removedItem);
            });
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          "Notification",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              // index 0 → scrollable top bar; rest → notification cards
              itemCount: notifications.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildScrollableTopBar();
                return _buildNotificationCard(notifications[index - 1]);
              },
            ),
    );
  }

  // ── Scrollable top bar (scrolls with the list) ────────────────────────────

  Widget _buildScrollableTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Orange badge + "unread notification"
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  "$_unreadCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "unread notification",
                style: TextStyle(
                  color: orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Mark all as read
          GestureDetector(
            onTap: _unreadCount > 0 ? _markAllAsRead : null,
            child: Text(
              "Mark all as read",
              style: TextStyle(
                color: _unreadCount > 0 ? orange : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification card ─────────────────────────────────────────────────────

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final bool isUnread = item["unread"] == true;

    return GestureDetector(
      onTap: () => _markAsRead(item["id"]),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isUnread ? const Color(0xFFFFF5EC) : Colors.white,
          border: Border.all(
            color: isUnread ? const Color(0xFFFFD6A0) : const Color(0xFFEEEEEE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item["iconBg"],
                shape: BoxShape.circle,
              ),
              child: Icon(item["icon"], color: item["iconColor"], size: 26),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + unread dot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item["title"],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Body
                  Text(
                    item["body"],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Time + delete icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item["time"],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteNotification(item["id"]),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.grey,
                          ),
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
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You're all caught up!",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
