import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/database_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Color orange = const Color(0xFFFF8A00);
  final DatabaseService _database = DatabaseService();

  int _unreadCount(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['read'] != true;
    }).length;
  }

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final unreadIds = docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['read'] != true;
        })
        .map((doc) => doc.id);

    await _database.markNotificationsRead(unreadIds);
  }

  Future<void> _markAsRead(String id) async {
    await _database.markNotificationRead(id);
  }

  Future<void> _deleteNotification(String id, Map<String, dynamic> data) async {
    await _database.deleteNotification(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Notification removed"),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Undo",
          textColor: orange,
          onPressed: () => _database.restoreNotification(id, data),
        ),
      ),
    );
  }

  String _timeAgo(dynamic value) {
    if (value is! Timestamp) return "Just now";

    final diff = DateTime.now().difference(value.toDate());
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${(diff.inDays / 7).floor()} weeks ago";
  }

  ({IconData icon, Color bg, Color color}) _styleForType(String? type) {
    switch (type) {
      case 'booking':
        return (
          icon: Icons.calendar_month,
          bg: const Color(0xFFE9F7EF),
          color: const Color(0xFF2ECC71),
        );
      case 'message':
        return (
          icon: Icons.chat_bubble_outline,
          bg: const Color(0xFFEAF4FF),
          color: const Color(0xFF3498DB),
        );
      case 'payment':
        return (
          icon: Icons.check_circle,
          bg: const Color(0xFFE9F7EF),
          color: const Color(0xFF27AE60),
        );
      case 'promo':
        return (
          icon: Icons.card_giftcard,
          bg: const Color(0xFFFFF3E0),
          color: const Color(0xFFFF8A00),
        );
      default:
        return (
          icon: Icons.info_outline,
          bg: const Color(0xFFF3F3F3),
          color: const Color(0xFF9E9E9E),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notification",
          style: GoogleFonts.pacifico(color: Colors.black, fontSize: 26),
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE6E6E6), width: 1),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _database.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildMessageState(
              icon: Icons.error_outline,
              title: "Notifications unavailable",
              subtitle: "Please try again later.",
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildScrollableTopBar(docs);

              final doc = docs[index - 1];
              final data = doc.data() as Map<String, dynamic>;
              return _buildNotificationCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildScrollableTopBar(List<QueryDocumentSnapshot> docs) {
    final unreadCount = _unreadCount(docs);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  "$unreadCount",
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
          GestureDetector(
            onTap: unreadCount > 0 ? () => _markAllAsRead(docs) : null,
            child: Text(
              "Mark all as read",
              style: TextStyle(
                color: unreadCount > 0 ? orange : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String id, Map<String, dynamic> item) {
    final isUnread = item["read"] != true;
    final style = _styleForType(item["type"] as String?);

    return GestureDetector(
      onTap: () => _markAsRead(id),
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: style.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item["title"] as String? ?? "Notification",
                          style: GoogleFonts.pacifico(
                            fontSize: 18,
                            fontWeight: isUnread
                                ? FontWeight.w700
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
                  Text(
                    item["body"] as String? ?? "",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _timeAgo(item["timestamp"]),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteNotification(id, item),
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

  Widget _buildEmptyState() {
    return _buildMessageState(
      icon: Icons.notifications_off_outlined,
      title: "No notifications yet",
      subtitle: "You're all caught up!",
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
