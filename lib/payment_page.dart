import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Payment',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _summaryRow('Caterer', widget.catererName),
                        _summaryRow('Package', widget.packageName),
                        _summaryRow('Event', widget.eventName),
                        _summaryRow('Date', formattedDate),
                        const Divider(),
                        _summaryRow(
                          'Down Payment',
                          'Php ${_formatAmount(widget.downPayment)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _paymentOption(
                    value: 'credit',
                    icon: Icons.credit_card,
                    title: 'Card',
                    subtitle: 'Visa/Mastercard',
                    recommended: true,
                  ),
                  _paymentOption(
                    value: 'gcash',
                    icon: Icons.account_balance_wallet,
                    title: 'GCash',
                    subtitle: 'E-wallet',
                  ),
                  const SizedBox(height: 12),
                  if (selectedPayment == 'credit')
                    _card(
                      child: Column(
                        children: [
                          _inputField(
                            controller: _cardNumberController,
                            hint: 'Card Number',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          _inputField(
                            controller: _cardholderController,
                            hint: 'Cardholder Name',
                          ),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onPay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Pay Php ${_formatAmount(_amountToPay)}',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            softWrap: true,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.deepOrange : Colors.grey),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
    ),
    child: child,
  );
}
