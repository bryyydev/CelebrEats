import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// TERMS & CONDITIONS PAGE
// ─────────────────────────────────────────────────────────────

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  static const Color _orange = Color(0xFFFF6B22);
  int? _expandedSection;

  final List<Map<String, dynamic>> _sections = [
    {
      "title": "1. Acceptance of Terms",
      "icon": Icons.handshake_outlined,
      "content":
          "By downloading, accessing, or using the CelebrEats application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services. CelebrEats reserves the right to update these terms at any time, and continued use of the app constitutes acceptance of any changes.",
    },
    {
      "title": "2. User Accounts",
      "icon": Icons.person_outline,
      "content":
          "You must be at least 18 years old to create an account on CelebrEats. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to provide accurate, current, and complete information during registration and to update such information to keep it accurate.",
    },
    {
      "title": "3. Booking & Payments",
      "icon": Icons.receipt_long_outlined,
      "content":
          "All bookings made through CelebrEats are subject to availability and confirmation by the caterer. Payments are processed securely through our payment partners. CelebrEats charges a service fee on each transaction. Prices listed are in Philippine Peso (PHP) and inclusive of applicable taxes where stated.",
    },
    {
      "title": "4. Cancellation & Refund Policy",
      "icon": Icons.cancel_outlined,
      "content":
          "Cancellations made more than 48 hours before the scheduled event qualify for a full refund. Cancellations within 48 hours may be subject to a cancellation fee of up to 50% of the booking amount. Refunds are processed within 3–7 business days to the original payment method. In cases where the caterer cancels, a full refund is guaranteed.",
    },
    {
      "title": "5. Caterer Responsibilities",
      "icon": Icons.restaurant_menu_outlined,
      "content":
          "Caterers registered on CelebrEats are independent service providers. CelebrEats does not employ caterers and is not responsible for the quality of food or services provided. Caterers agree to maintain accurate menus, pricing, and availability. Misrepresentation of services may result in suspension or removal from the platform.",
    },
    {
      "title": "6. User Conduct",
      "icon": Icons.gavel_outlined,
      "content":
          "You agree not to use CelebrEats for any unlawful purpose or in any way that could damage, disable, or impair the service. Prohibited activities include posting false reviews, manipulating pricing, using the platform to distribute spam, or attempting to gain unauthorized access to other accounts or our systems.",
    },
    {
      "title": "7. Privacy & Data",
      "icon": Icons.lock_outline,
      "content":
          "CelebrEats collects and processes personal data in accordance with our Privacy Policy. By using our app, you consent to the collection of data such as your name, contact details, location, and payment information for the purpose of providing and improving our services. We do not sell your personal data to third parties.",
    },
    {
      "title": "8. Limitation of Liability",
      "icon": Icons.shield_outlined,
      "content":
          "CelebrEats shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the platform. Our total liability shall not exceed the amount paid by you for the specific booking in dispute. CelebrEats is not liable for any delays, cancellations, or failures caused by force majeure events.",
    },
    {
      "title": "9. Intellectual Property",
      "icon": Icons.copyright_outlined,
      "content":
          "All content on CelebrEats, including but not limited to logos, text, graphics, and software, is the property of CelebrEats or its licensors and is protected by applicable intellectual property laws. You may not reproduce, modify, or distribute any content without express written permission.",
    },
    {
      "title": "10. Governing Law",
      "icon": Icons.account_balance_outlined,
      "content":
          "These Terms and Conditions are governed by and construed in accordance with the laws of the Republic of the Philippines. Any disputes arising out of or in connection with these terms shall be subject to the exclusive jurisdiction of the courts of the Philippines.",
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A00), Color(0xFFFF3D3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CelebrEats",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Terms & Conditions\nEffective: January 1, 2025",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Intro text ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
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
            child: const Text(
              "Welcome to CelebrEats. Please read these Terms and Conditions carefully before using our platform. These terms outline your rights and responsibilities as a user, as well as ours as a service provider. Tap each section to expand it.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Expandable sections ───────────────────────────
          ..._sections.asMap().entries.map(
            (e) => _TermsSection(
              icon: e.value["icon"],
              title: e.value["title"],
              content: e.value["content"],
              isExpanded: _expandedSection == e.key,
              onTap: () => setState(() {
                _expandedSection = _expandedSection == e.key ? null : e.key;
              }),
            ),
          ),

          const SizedBox(height: 16),

          // ── Agreement footer ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD5B5)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: _orange,
                  size: 32,
                ),
                const SizedBox(height: 10),
                const Text(
                  "By using CelebrEats, you confirm that you have read and agree to these Terms and Conditions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Questions? Contact us at legal@celebreats.ph",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Terms Section Tile ────────────────────────────────────────
class _TermsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final bool isExpanded;
  final VoidCallback onTap;

  const _TermsSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFFFF6B22).withOpacity(0.4)
                : Colors.transparent,
          ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? const Color(0xFFFF6B22).withOpacity(0.1)
                          : const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isExpanded
                          ? const Color(0xFFFF6B22)
                          : Colors.black45,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isExpanded
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isExpanded
                        ? const Color(0xFFFF6B22)
                        : Colors.black38,
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.grey.shade100),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.7,
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
