import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/booking_service.dart'; // Ensure this path is correct
import 'booking_confirmed.dart'; // Ensure this path is correct

class PaymentPage extends StatefulWidget {
  final int guests;
  final String eventType;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final double totalAmount;
  final Set<String> selectedDecorations;
  final Set<String> selectedExtras;

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
    required this.guests,
    required this.eventType,
    required this.selectedDate,
    this.selectedTime,
    required this.totalAmount,
    required this.selectedDecorations,
    required this.selectedExtras,
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
                  borderRadius: BorderRadius.circular(8.0),
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
      if (widget.selectedDate != null) {
        final conflict = await BookingService.instance.hasConflict(
          catererId: widget.catererId,
          date: widget.selectedDate!,
        );
        if (conflict && mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This caterer is already booked on that date.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      await BookingService.instance.createBooking(
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

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmedPage(
            eventType: widget.eventType,
            selectedDate: widget.selectedDate,
            selectedTime: widget.selectedTime,
            guests: widget.guests,
            totalAmount: widget.downPayment,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm booking: $e'),
          backgroundColor: Colors.red,
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
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        leading: const BackButton(color: Colors.black),
        title: Text(
          'Payment',
          style: GoogleFonts.pacifico(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
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
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _summaryRow('Caterer', widget.catererName),
                        _summaryRow('Package', widget.packageName),
                        _summaryRow('Event Type', widget.eventType),
                        _summaryRow('Date', formattedDate),
                        _summaryRow('Guests', widget.guests.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                        _paymentOption(
                          value: 'gcash',
                          icon: Icons.wallet_outlined,
                          title: 'Gcash',
                          subtitle: 'Pay with GCash e-wallet',
                        ),
                        _paymentOption(
                          value: 'maya',
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Maya',
                          subtitle: 'Pay with Maya e-wallet',
                        ),
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
                  if (selectedPayment == 'credit')
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Card Number',
                            style: TextStyle(fontSize: 12),
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
                            style: TextStyle(fontSize: 12),
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
                                      style: TextStyle(fontSize: 12),
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
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    _inputField(
                                      controller: _cvvController,
                                      hint: '123',
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
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
                  _totalBanner(),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Icon(Icons.lock, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Secure encrypted payment.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _payButton(),
        ],
      ),
    );
  }

  double get _amountToPay => widget.downPayment;

  Widget _payButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _onPay,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.credit_card, color: Colors.white, size: 18),
            label: Text(
              _isLoading
                  ? 'Processing...'
                  : 'Pay Php ${_formatAmount(_amountToPay)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6400),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _totalBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            'Php ${_formatAmount(_amountToPay)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            softWrap: true,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1E9) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? const Color(0xFFFF6400) : Colors.grey.shade300,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF6400)
                      : Colors.grey.shade300,
                  width: 1.3,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6400),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFF6400)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.black54,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (recommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD8C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              color: Color(0xFFFF6400),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, height: 1.45),
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
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF4F4F4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black12),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: child,
  );
}
