import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// HELP & SUPPORT PAGE
// ─────────────────────────────────────────────────────────────

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  static const Color _orange = Color(0xFFFF6B22);
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      "q": "How do I book a caterer?",
      "a":
          "Browse caterers from the Home or Browse tab, tap on a caterer you like, choose a package, select your event date and details, then tap 'Book Now'. You'll receive a confirmation once the caterer accepts.",
    },
    {
      "q": "Can I cancel or reschedule my booking?",
      "a":
          "Yes. Go to Profile → My Booking, select the booking you want to modify, and tap 'Cancel' or 'Reschedule'. Cancellations made 48 hours before the event are fully refunded.",
    },
    {
      "q": "How do I pay for a booking?",
      "a":
          "We accept credit/debit cards, GCash, Maya, ShopeePay, and Cash on Delivery. You can manage your payment methods under Profile → Payment Methods.",
    },
    {
      "q": "What if the caterer cancels on me?",
      "a":
          "In the rare event a caterer cancels, you will be notified immediately and receive a full refund within 3–5 business days. We'll also suggest alternative caterers for your date.",
    },
    {
      "q": "How do I leave a review?",
      "a":
          "After your event, you'll receive a notification asking for your feedback. You can also go to My Bookings → Past, select the booking, and tap 'Leave a Review'.",
    },
    {
      "q": "How do I become a caterer on CelebrEats?",
      "a":
          "Go to Profile and toggle on 'Caterer Mode'. You'll be guided through registering your business, adding your menu packages, and setting your availability.",
    },
    {
      "q": "Is my payment information secure?",
      "a":
          "Yes. CelebrEats uses industry-standard encryption for all transactions. We never store your full card details on our servers.",
    },
    {
      "q": "How do I update my profile photo?",
      "a":
          "Go to Profile → Edit Profile and tap the camera icon on your avatar. You can choose a photo from your gallery or take a new one.",
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs
        .where(
          (faq) =>
              faq["q"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              faq["a"]!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ContactSheet(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
          'Help & Support',
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
          // ── Hero banner ───────────────────────────────────
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 36),
                const SizedBox(height: 10),
                const Text(
                  "Hi! How can we help?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Search our FAQs or contact our team.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _expandedIndex = null;
                    }),
                    decoration: const InputDecoration(
                      hintText: "Search FAQs...",
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.black38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Quick contact options ─────────────────────────
          const Text(
            "Contact Us",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContactCard(
                  icon: Icons.chat_bubble_outline,
                  label: "Live Chat",
                  sub: "Avg. 2 min reply",
                  color: _orange,
                  onTap: _showContactSheet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactCard(
                  icon: Icons.email_outlined,
                  label: "Email Us",
                  sub: "support@celebreats.ph",
                  color: const Color(0xFF3498DB),
                  onTap: _showContactSheet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactCard(
                  icon: Icons.phone_outlined,
                  label: "Call Us",
                  sub: "+63 900 000 0000",
                  color: const Color(0xFF2ECC71),
                  onTap: _showContactSheet,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── FAQs ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Frequently Asked Questions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                "${_filteredFaqs.length} results",
                style: const TextStyle(fontSize: 13, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_filteredFaqs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No results for \"$_searchQuery\"",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._filteredFaqs.asMap().entries.map(
              (e) => _FaqTile(
                question: e.value["q"]!,
                answer: e.value["a"]!,
                isExpanded: _expandedIndex == e.key,
                onTap: () => setState(() {
                  _expandedIndex = _expandedIndex == e.key ? null : e.key;
                }),
              ),
            ),

          const SizedBox(height: 24),

          // ── Still need help ───────────────────────────────
          GestureDetector(
            onTap: _showContactSheet,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD5B5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: _orange, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Still need help?",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Our support team is available Mon–Sat, 8am–6pm.",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── FAQ Tile ──────────────────────────────────────────────────
class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqTile({
    required this.question,
    required this.answer,
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
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? const Color(0xFFFF6B22).withOpacity(0.1)
                          : const Color(0xFFF3F3F3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      size: 16,
                      color: isExpanded
                          ? const Color(0xFFFF6B22)
                          : Colors.black45,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontWeight: isExpanded
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 16, 16),
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Contact Quick Card ────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact Bottom Sheet ──────────────────────────────────────
class _ContactSheet extends StatelessWidget {
  const _ContactSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contact Support",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Choose how you'd like to reach us:",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _ContactOption(
            icon: Icons.chat_bubble_outline,
            color: const Color(0xFFFF6B22),
            title: "Live Chat",
            subtitle: "Chat with a support agent now",
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          _ContactOption(
            icon: Icons.email_outlined,
            color: const Color(0xFF3498DB),
            title: "Email Support",
            subtitle: "support@celebreats.ph",
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          _ContactOption(
            icon: Icons.phone_outlined,
            color: const Color(0xFF2ECC71),
            title: "Call Us",
            subtitle: "+63 900 000 0000 • Mon–Sat 8am–6pm",
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
