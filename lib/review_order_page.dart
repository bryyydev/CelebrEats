import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW ORDER PAGE
// ─────────────────────────────────────────────────────────────────────────────
// Changes from original:
//   - Added 5 new required params: catererId, catererName, packageId,
//     packageName, pricePerPerson.
//   - Caterer row now uses catererName (was hardcoded 'Golden Spoon Events').
//   - Added Package row to event details.
//   - basePrice now uses pricePerPerson instead of hardcoded 500.
//   - Confirm button navigates to PaymentPage (was showing success dialog).
//   - All UI layout/styling unchanged.
// ─────────────────────────────────────────────────────────────────────────────

class ReviewOrderPage extends StatelessWidget {
  // ── Original params ───────────────────────────────────────────────────────
  final Map<String, dynamic> selectedItems;
  final String eventName;
  final String eventType;
  final DateTime selectedDate;
  final String selectedTime;
  final String venue;
  final String location;
  final String contactNumber;
  final String numberOfGuests;

  // ── New: booking context ──────────────────────────────────────────────────
  final String catererId;
  final String catererName;
  final String packageId;
  final String packageName;
  final double pricePerPerson;

  const ReviewOrderPage({
    super.key,
    // Original
    required this.selectedItems,
    required this.eventName,
    required this.eventType,
    required this.selectedDate,
    required this.selectedTime,
    required this.venue,
    required this.location,
    required this.contactNumber,
    required this.numberOfGuests,
    // New
    required this.catererId,
    required this.catererName,
    required this.packageId,
    required this.packageName,
    required this.pricePerPerson,
  });

  // ── Pricing helpers ───────────────────────────────────────────────────────

  int get _totalItems {
    int count = 0;
    selectedItems.forEach((_, v) {
      if (v is List) count += v.length;
    });
    return count;
  }

  int get _guestsCount => int.tryParse(numberOfGuests) ?? 50;

  double get _basePrice => _guestsCount * pricePerPerson;
  double get _itemsPrice => _totalItems * 200.0;
  double get _subtotal => _basePrice + _itemsPrice;
  double get _discount => _subtotal * 0.05;
  double get _total => _subtotal - _discount;
  double get _downPayment => _total * 0.3;

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goToPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          // Original PaymentPage params
          guests: _guestsCount,
          eventType: eventType,
          selectedDate: selectedDate,
          selectedTime: TimeOfDay(
            hour: int.tryParse(selectedTime.split(':').first) ?? 12,
            minute:
                int.tryParse(
                  selectedTime
                      .split(':')
                      .last
                      .replaceAll(RegExp(r'[^0-9]'), '')
                      .substring(0, 2),
                ) ??
                0,
          ),
          totalAmount: _total,
          selectedDecorations: Set<String>.from(_getItems('decorations')),
          selectedExtras: Set<String>.from(_getItems('extraServices')),
          // New booking context params
          catererId: catererId,
          catererName: catererName,
          packageId: packageId,
          packageName: packageName,
          eventName: eventName,
          eventTime: selectedTime,
          venue: venue,
          location: location,
          contactNumber: contactNumber,
          selectedItems: Map<String, List<String>>.from(
            selectedItems.map(
              (k, v) =>
                  MapEntry(k, v is List ? List<String>.from(v) : <String>[]),
            ),
          ),
          pricePerPerson: pricePerPerson,
          downPayment: _downPayment,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Order',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // EVENT DETAILS
                  _section(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Event Details'),
                        const SizedBox(height: 15),
                        _buildDetailRow('Event Name:', eventName),
                        _buildDetailRow('Event Type:', eventType),
                        _buildDetailRow('Guests:', '$numberOfGuests people'),
                        _buildDetailRow(
                          'Date:',
                          DateFormat('MMMM dd, yyyy').format(selectedDate),
                        ),
                        _buildDetailRow('Time:', selectedTime),
                        _buildDetailRow('Venue:', venue),
                        _buildDetailRow('Location:', location),
                        _buildDetailRow('Contact:', contactNumber),
                        const SizedBox(height: 15),
                        _buildDetailRow(
                          'Caterer:',
                          catererName,
                          valueColor: Colors.deepOrange,
                        ),
                        _buildDetailRow(
                          'Package:',
                          packageName,
                          valueColor: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // MENU ITEMS
                  _section(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Selected Items'),
                        const SizedBox(height: 15),
                        if (_getItems('appetizers').isNotEmpty) ...[
                          _buildMenuCategory(
                            'Appetizers',
                            _getItems('appetizers'),
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_getItems('mainCourse').isNotEmpty) ...[
                          _buildMenuCategory(
                            'Main Course',
                            _getItems('mainCourse'),
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_getItems('desserts').isNotEmpty) ...[
                          _buildMenuCategory('Desserts', _getItems('desserts')),
                          const SizedBox(height: 15),
                        ],
                        if (_getItems('drinks').isNotEmpty) ...[
                          _buildMenuCategory('Drinks', _getItems('drinks')),
                          const SizedBox(height: 15),
                        ],
                        if (_getItems('decorations').isNotEmpty) ...[
                          _buildMenuCategory(
                            'Decorations',
                            _getItems('decorations'),
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_getItems('extraServices').isNotEmpty) ...[
                          _buildMenuCategory(
                            'Extra Services',
                            _getItems('extraServices'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PRICE SUMMARY
                  _section(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Price Summary'),
                        const SizedBox(height: 15),
                        _priceRow(
                          'Base ($_guestsCount guests × ₱${NumberFormat('#,###').format(pricePerPerson)}):',
                          '₱${NumberFormat('#,###').format(_basePrice)}',
                        ),
                        const SizedBox(height: 10),
                        _priceRow(
                          'Items ($_totalItems × ₱200):',
                          '₱${NumberFormat('#,###').format(_itemsPrice)}',
                        ),
                        const SizedBox(height: 10),
                        _priceRow(
                          'Subtotal:',
                          '₱${NumberFormat('#,###').format(_subtotal)}',
                          bold: true,
                        ),
                        const SizedBox(height: 10),
                        _priceRow(
                          'Discount (5%):',
                          '-₱${NumberFormat('#,###').format(_discount)}',
                          color: Colors.green,
                        ),
                        const Divider(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '₱${NumberFormat('#,###').format(_total)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // IMPORTANT NOTES
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Important Notes:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildNotePoint(
                          'Down payment of ₱${NumberFormat('#,###').format(_downPayment)} (30%) required to confirm booking',
                        ),
                        _buildNotePoint('Final payment due 1 day before event'),
                        _buildNotePoint(
                          'Free cancellation up to 48 hours before event',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // BOTTOM BUTTON
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _goToPayment(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Proceed to Payment — ₱${NumberFormat('#,###').format(_total)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  // ── Widget helpers ────────────────────────────────────────────────────────

  List<String> _getItems(String category) {
    final items = selectedItems[category];
    if (items is List) return items.cast<String>();
    return [];
  }

  Widget _section({required Widget child}) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF2C3E50),
    ),
  );

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    final style = TextStyle(
      fontSize: 14,
      color: color ?? (bold ? Colors.black87 : Colors.black54),
      fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }

  Widget _buildMenuCategory(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotePoint(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 14)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
