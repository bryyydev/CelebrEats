import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_service.dart';
import 'booking_confirmed.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT PAGE
// ─────────────────────────────────────────────────────────────────────────────
// Changes from original:
//   - Added booking context params: catererId, catererName, packageId,
//     packageName, eventName, eventTime, venue, location, contactNumber,
//     selectedItems, pricePerPerson, downPayment.
//   - Booking summary card now shows real catererName and packageName.
//   - _onPay() saves booking to Firestore via BookingService, then navigates
//     to BookingConfirmedPage passing the new bookingId.
//   - Added loading state while saving so the button shows a spinner.
//   - All UI layout/styling unchanged.
// ─────────────────────────────────────────────────────────────────────────────

class PaymentPage extends StatefulWidget {
  // ── Original params ───────────────────────────────────────────────────────
  final int guests;
  final String eventType;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final double totalAmount;
  final Set<String> selectedDecorations;
  final Set<String> selectedExtras;

  // ── New: booking context ──────────────────────────────────────────────────
  final String catererId;
  final String catererName;
  final String packageId;
  final String packageName;
  final String eventName;
  final String eventTime;
  final String venue;
  final String location;
  final String contactNumber;
  final Map<String, List<String>> selectedItems;
  final double pricePerPerson;
  final double downPayment;

  const PaymentPage({
    super.key,
    // Original
    required this.guests,
    required this.eventType,
    required this.selectedDate,
    this.selectedTime,
    required this.totalAmount,
    required this.selectedDecorations,
    required this.selectedExtras,
    // New
    required this.catererId,
    required this.catererName,
    required this.packageId,
    required this.packageName,
    required this.eventName,
    required this.eventTime,
    required this.venue,
    required this.location,
    required this.contactNumber,
    required this.selectedItems,
    required this.pricePerPerson,
    required this.downPayment,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPayment = 'credit';
  bool _isLoading = false;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardholderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get formattedDate {
    if (widget.selectedDate == null) return 'N/A';
    return '${widget.selectedDate!.year}-'
        '${widget.selectedDate!.month.toString().padLeft(2, '0')}-'
        '${widget.selectedDate!.day.toString().padLeft(2, '0')}';
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

  Future<void> _onPay() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Login Required',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Your session has expired. Please log in again to complete your booking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // TODO: Navigate to your LoginPage
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Log In'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check for date conflicts first
      if (widget.selectedDate != null) {
        final conflict = await BookingService.instance.hasConflict(
          catererId: widget.catererId,
          date: widget.selectedDate!,
        );
        if (conflict && mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This caterer is already booked on that date. Please choose another date.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      // Save booking to Firestore
      final bookingId = await BookingService.instance.createBooking(
        catererId: widget.catererId,
        catererName: widget.catererName,
        packageId: widget.packageId,
        packageName: widget.packageName,
        pricePerPerson: widget.pricePerPerson,
        eventName: widget.eventName,
        eventType: widget.eventType,
        eventDate: widget.selectedDate ?? DateTime.now(),
        eventTime: widget.eventTime,
        venue: widget.venue,
        location: widget.location,
        contactNumber: widget.contactNumber,
        numberOfGuests: widget.guests,
        selectedItems: widget.selectedItems,
        totalAmount: widget.totalAmount,
        downPayment: widget.downPayment,
      );

      // Mark down payment paid
      await BookingService.instance.markDownPaymentPaid(bookingId);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmedPage(
            eventType: widget.eventType,
            selectedDate: widget.selectedDate,
            selectedTime: widget.selectedTime,
            guests: widget.guests,
            totalAmount: widget.totalAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm booking: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Payment',
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
                  // ── Booking Summary ──
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _summaryRow('Caterer', widget.catererName),
                        _summaryRow('Package', widget.packageName),
                        _summaryRow('Event', widget.eventName),
                        _summaryRow('Event Type', widget.eventType),
                        _summaryRow('Date', formattedDate),
                        _summaryRow('Guests', widget.guests.toString()),
                        const Divider(height: 20),
                        _summaryRow(
                          'Down Payment (30%)',
                          'Php ${_formatAmount(widget.downPayment)}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Payment Method ──
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _paymentOption(
                          value: 'credit',
                          icon: Icons.credit_card,
                          title: 'Credit /\nDebit Card',
                          subtitle: 'Visa\nMastercard\nJCB',
                          recommended: true,
                        ),
                        const SizedBox(height: 10),
                        _paymentOption(
                          value: 'gcash',
                          icon: Icons.receipt_long_outlined,
                          title: 'Gcash',
                          subtitle: 'Pay with GCash e-wallet',
                        ),
                        const SizedBox(height: 10),
                        _paymentOption(
                          value: 'maya',
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Maya',
                          subtitle: 'Pay with Maya e-wallet',
                        ),
                        const SizedBox(height: 10),
                        _paymentOption(
                          value: 'bank',
                          icon: Icons.account_balance_outlined,
                          title: 'Bank Transfer',
                          subtitle: 'BDO, BPI, Metrobank, etc',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Card Details ──
                  if (selectedPayment == 'credit')
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Card Number',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _inputField(
                            controller: _cardNumberController,
                            hint: '1213 4563 3455 6785',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Cardholder Name',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _inputField(
                            controller: _cardholderController,
                            hint: 'Juan Dela Cruz',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Expiry Date',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _inputField(
                                      controller: _expiryController,
                                      hint: 'MM/YY',
                                      keyboardType: TextInputType.datetime,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CVV',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _inputField(
                                      controller: _cvvController,
                                      hint: '123',
                                      keyboardType: TextInputType.number,
                                      obscure: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── Total Amount banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Php ${_formatAmount(widget.totalAmount)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Security note ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment information is encrypted and secure. We never store your card details.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Pay Button ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _onPay,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.credit_card, color: Colors.white),
                  label: Text(
                    _isLoading
                        ? 'Processing...'
                        : 'Pay Php ${_formatAmount(widget.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers (unchanged from original) ──────────────────────────────

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _paymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool recommended = false,
  }) {
    bool selected = selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.deepOrange : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? Colors.deepOrange : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.grey.shade600,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected ? Colors.deepOrange : Colors.black87,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0CC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      height: 1.4,
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscure,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _card({required Widget child}) => Container(
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
