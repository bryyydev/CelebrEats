import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page.dart';

class CustomizePackagePage extends StatefulWidget {
  const CustomizePackagePage({super.key});

  @override
  State<CustomizePackagePage> createState() => _CustomizePackagePageState();
}

class _CustomizePackagePageState extends State<CustomizePackagePage> {
  int guests = 100;
  String selectedEventType = 'Birthday';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String additionalNotes = '';

  final List<String> eventTypes = [
    'Birthday',
    'Anniversary',
    'Wedding',
    'Baptism',
    'Other',
  ];

  final List<String> decorationItems = [
    'Balloon Arch',
    'Table Centerpieces',
    'Photo Booth',
    'Backdrop',
    'Chair covers',
    'Lighting',
  ];

  final List<String> extraServiceItems = [
    'Sound System',
    'DJ',
    'Emcee / Host',
    'Photographer',
    'Videographer',
    'Live Band',
  ];

  final Set<String> selectedDecorations = {'Balloon Arch'};
  final Set<String> selectedExtras = {
    'Sound System',
    'DJ',
    'Photographer',
    'Live Band',
  };

  final double pricePerPerson = 500;
  final int addOnPrice = 1000;

  double get totalAmount {
    double base = pricePerPerson * guests;
    double addOns =
        (selectedDecorations.length + selectedExtras.length) *
        addOnPrice.toDouble();
    return base + addOns;
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  /// Check Firebase Auth before proceeding to Payment
  void _onBookNow() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in — show dialog prompting login
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Login Required",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "You need to be logged in to book. Please log in or create an account to continue.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // TODO: Navigate to your login page, e.g.:
                // Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Log In"),
            ),
          ],
        ),
      );
      return;
    }

    // Logged in — proceed to payment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          guests: guests,
          eventType: selectedEventType,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          totalAmount: totalAmount,
          selectedDecorations: selectedDecorations,
          selectedExtras: selectedExtras,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Event Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // ── Event Type ──
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Event Type",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEventTypeGrid(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Event Date & Time ──
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Event Date & Time",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _dateTimeRow(
                          label: selectedDate == null
                              ? "dd/mm/yyyy"
                              : "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}",
                          leftIcon: Icons.calendar_today_outlined,
                          rightIcon: Icons.calendar_month_outlined,
                          onTap: _pickDate,
                          hasValue: selectedDate != null,
                        ),
                        const SizedBox(height: 10),
                        _dateTimeRow(
                          label: selectedTime == null
                              ? "--:-- --"
                              : selectedTime!.format(context),
                          leftIcon: Icons.access_time_outlined,
                          rightIcon: Icons.access_time_outlined,
                          onTap: _pickTime,
                          hasValue: selectedTime != null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Number of Guests ──
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Number of Guests",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (guests > 1) setState(() => guests--);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  guests.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "guests",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => setState(() => guests++),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.deepOrange,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Event Venue ──
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Event Venue",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey.shade500,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Enter venue address",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0B2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.map_outlined,
                                color: Colors.deepOrange,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "View on Map",
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Decoration & Extras ──
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Decoration & Extras",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const Text(
                          "Optional - additional charges may apply",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "DECORATIONS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...decorationItems.map((item) {
                          bool selected = selectedDecorations.contains(item);
                          return _addonRow(
                            label: item,
                            selected: selected,
                            onTap: () => setState(() {
                              selected
                                  ? selectedDecorations.remove(item)
                                  : selectedDecorations.add(item);
                            }),
                          );
                        }),
                        const SizedBox(height: 16),
                        const Text(
                          "EXTRA SERVICES",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...extraServiceItems.map((item) {
                          bool selected = selectedExtras.contains(item);
                          return _addonRow(
                            label: item,
                            selected: selected,
                            onTap: () => setState(() {
                              selected
                                  ? selectedExtras.remove(item)
                                  : selectedExtras.add(item);
                            }),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Additional Notes ──
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Addittional Notes (optional)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            maxLines: 4,
                            onChanged: (v) =>
                                setState(() => additionalNotes = v),
                            decoration: const InputDecoration(
                              hintText:
                                  "Any special request or dietary requirements...",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Price Summary ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Price Summary",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Price per person",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "Php ${pricePerPerson.toInt()}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Number of guest",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              guests.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Colors.white38, thickness: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total amount",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Php ${_formatAmount(totalAmount)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Book Now ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onBookNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white, // ← fixes purple text
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Book Now",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _buildEventTypeGrid() {
    final pairs = <Widget>[];
    for (int i = 0; i < eventTypes.length; i += 2) {
      final first = eventTypes[i];
      final second = i + 1 < eventTypes.length ? eventTypes[i + 1] : null;
      pairs.add(
        Row(
          children: [
            Expanded(child: _eventChip(first)),
            const SizedBox(width: 10),
            second != null
                ? Expanded(child: _eventChip(second))
                : const Expanded(child: SizedBox()),
          ],
        ),
      );
      pairs.add(const SizedBox(height: 10));
    }
    return Column(children: pairs);
  }

  Widget _eventChip(String type) {
    bool selected = selectedEventType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedEventType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.deepOrange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _dateTimeRow({
    required String label,
    required IconData leftIcon,
    required IconData rightIcon,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(leftIcon, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: hasValue ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
            Icon(rightIcon, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _addonRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3EE) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? Colors.deepOrange : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star_border_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.deepOrange : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "+ 1,000",
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.deepOrange : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? Colors.deepOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? Colors.deepOrange : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
}
