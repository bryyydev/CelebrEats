import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// PAYMENT METHODS PAGE
// ─────────────────────────────────────────────────────────────

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  static const Color _orange = Color(0xFFFF6B22);

  final List<Map<String, dynamic>> _cards = [
    {
      "type": "Visa",
      "last4": "4242",
      "expiry": "08/27",
      "isDefault": true,
      "color1": const Color(0xFF1A1A2E),
      "color2": const Color(0xFF16213E),
      "icon": Icons.credit_card,
    },
    {
      "type": "Mastercard",
      "last4": "8765",
      "expiry": "03/26",
      "isDefault": false,
      "color1": const Color(0xFF2D3561),
      "color2": const Color(0xFF1E2140),
      "icon": Icons.credit_card,
    },
  ];

  final List<Map<String, dynamic>> _eWallets = [
    {
      "name": "GCash",
      "number": "09XX XXX 1234",
      "linked": true,
      "color": const Color(0xFF007DFF),
      "icon": Icons.account_balance_wallet,
    },
    {
      "name": "Maya",
      "number": "Not linked",
      "linked": false,
      "color": const Color(0xFF00B140),
      "icon": Icons.account_balance_wallet_outlined,
    },
    {
      "name": "ShopeePay",
      "number": "Not linked",
      "linked": false,
      "color": const Color(0xFFEE4D2D),
      "icon": Icons.shopping_bag_outlined,
    },
  ];

  void _showAddCardDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddCardSheet(onAdd: (card) => setState(() => _cards.add(card))),
    );
  }

  void _setDefault(int index) {
    setState(() {
      for (int i = 0; i < _cards.length; i++) {
        _cards[i]["isDefault"] = i == index;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("•••• ${_cards[index]['last4']} set as default"),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeCard(int index) {
    final removed = _cards[index];
    setState(() => _cards.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Card ending in ${removed['last4']} removed"),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "Undo",
          textColor: _orange,
          onPressed: () => setState(() => _cards.insert(index, removed)),
        ),
      ),
    );
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
          'Payment Methods',
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
          // ── Section: Cards ────────────────────────────────
          _SectionHeader(title: "Credit / Debit Cards"),
          const SizedBox(height: 12),
          ..._cards.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CreditCardTile(
                card: e.value,
                onSetDefault: () => _setDefault(e.key),
                onRemove: () => _removeCard(e.key),
              ),
            ),
          ),
          // Add Card button
          GestureDetector(
            onTap: _showAddCardDialog,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _orange.withOpacity(0.4),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: _orange, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    "Add New Card",
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Section: E-Wallets ────────────────────────────
          _SectionHeader(title: "E-Wallets"),
          const SizedBox(height: 12),
          ..._eWallets.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EWalletTile(wallet: w),
            ),
          ),

          const SizedBox(height: 24),

          // ── Cash on Delivery ──────────────────────────────
          _SectionHeader(title: "Other Methods"),
          const SizedBox(height: 12),
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
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cash on Delivery",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Pay when your caterer arrives",
                        style: TextStyle(fontSize: 13, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Available",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

// ── Credit Card Tile ──────────────────────────────────────────
class _CreditCardTile extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  const _CreditCardTile({
    required this.card,
    required this.onSetDefault,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [card["color1"], card["color2"]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (card["color1"] as Color).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card["type"],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              if (card["isDefault"] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Default",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "**** **** **** ${card['last4']}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Expires ${card['expiry']}",
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (card["isDefault"] != true)
                _CardAction(
                  label: "Set Default",
                  icon: Icons.check_circle_outline,
                  onTap: onSetDefault,
                ),
              if (card["isDefault"] != true) const SizedBox(width: 12),
              _CardAction(
                label: "Remove",
                icon: Icons.delete_outline,
                onTap: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CardAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── E-Wallet Tile ─────────────────────────────────────────────
class _EWalletTile extends StatelessWidget {
  final Map<String, dynamic> wallet;
  const _EWalletTile({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final bool linked = wallet["linked"] == true;
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (wallet["color"] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(wallet["icon"], color: wallet["color"], size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet["name"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wallet["number"],
                  style: const TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: linked ? const Color(0xFFE8F5E9) : const Color(0xFFFFF4EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              linked ? "Linked" : "Link",
              style: TextStyle(
                color: linked
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFFF6B22),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Card Bottom Sheet ─────────────────────────────────────
class _AddCardSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const _AddCardSheet({required this.onAdd});

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  static const Color _orange = Color(0xFFFF6B22);

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add New Card",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _SheetField(
            controller: _numberCtrl,
            label: "Card Number",
            hint: "1234 5678 9012 3456",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _SheetField(
            controller: _nameCtrl,
            label: "Cardholder Name",
            hint: "Juan dela Cruz",
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SheetField(
                  controller: _expiryCtrl,
                  label: "Expiry",
                  hint: "MM/YY",
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetField(
                  controller: _cvvCtrl,
                  label: "CVV",
                  hint: "•••",
                  keyboardType: TextInputType.number,
                  obscure: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_numberCtrl.text.length >= 4) {
                  widget.onAdd({
                    "type": "Visa",
                    "last4": _numberCtrl.text.length >= 4
                        ? _numberCtrl.text
                              .replaceAll(' ', '')
                              .substring(
                                _numberCtrl.text.replaceAll(' ', '').length - 4,
                              )
                        : "0000",
                    "expiry": _expiryCtrl.text,
                    "isDefault": false,
                    "color1": const Color(0xFF1A1A2E),
                    "color2": const Color(0xFF16213E),
                    "icon": Icons.credit_card,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Card added successfully!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Add Card",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF6B22)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared Section Header ─────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
