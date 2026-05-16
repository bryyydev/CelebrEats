import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'review_order_page.dart';
import 'real_time_map.dart';

import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATE TIME PICKER PAGE
// ─────────────────────────────────────────────────────────────────────────────
//
// Changes from original (all UI preserved exactly):
//   - Constructor accepts new required booking-context args:
//       catererId, catererName, packageId, packageName, pricePerPerson
//   - Constructor accepts optional pre-selected values from _BookingSheet:
//       preselectedEventType, preselectedDate, preselectedTime, preselectedGuests
//     When provided these pre-fill the form so the user's quick-booking
//     selections aren't lost.
//   - _proceedToReview() now passes all booking context to ReviewOrderPage
//     so ReviewOrderPage can call BookingService with full data.
//   - No UI components, styling, or animations changed.
// ─────────────────────────────────────────────────────────────────────────────

class DateTimePickerPage extends StatefulWidget {
  // ── Existing param (preserved) ────────────────────────────────────────────
  final Map<String, List<String>> selectedItems;

  // ── New: Firestore booking context ────────────────────────────────────────
  final String catererId;
  final String catererName;
  final String packageId;
  final String packageName;
  final double pricePerPerson;

  // ── Optional pre-fills from _BookingSheet quick-booking ───────────────────
  final String? preselectedEventType;
  final DateTime? preselectedDate;
  final TimeOfDay? preselectedTime;
  final int? preselectedGuests;

  const DateTimePickerPage({
    super.key,
    // Original
    required this.selectedItems,
    // New required
    required this.catererId,
    required this.catererName,
    required this.packageId,
    required this.packageName,
    required this.pricePerPerson,
    // New optional pre-fills
    this.preselectedEventType,
    this.preselectedDate,
    this.preselectedTime,
    this.preselectedGuests,
  });

  @override
  State<DateTimePickerPage> createState() => _DateTimePickerPageState();
}

class _DateTimePickerPageState extends State<DateTimePickerPage> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  LatLng? _pinnedLatLng;

  late DateTime? selectedDate;
  late TimeOfDay? selectedTime;
  late String eventType;
  late int numberOfGuests;

  final List<String> eventTypes = [
    'Birthday',
    'Wedding',
    'Corporate Event',
    'Anniversary',
    'Graduation',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill from quick-booking sheet if provided, otherwise use defaults
    selectedDate = widget.preselectedDate;
    selectedTime = widget.preselectedTime;
    numberOfGuests = widget.preselectedGuests ?? 50;

    // Map _BookingSheet event type names to the dropdown list.
    // Both lists share Birthday/Wedding/etc. — only 'Reunion'/'Baptism' differ.
    eventType = _mapEventType(widget.preselectedEventType) ?? 'Birthday';
  }

  /// Maps _BookingSheet event type strings to DateTimePickerPage dropdown values.
  String? _mapEventType(String? raw) {
    if (raw == null) return null;
    // Exact match first
    if (eventTypes.contains(raw)) return raw;
    // Fuzzy: 'Debut' → 'Other', 'Baptism' → 'Other', 'Reunion' → 'Other'
    return 'Other';
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _venueController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepOrange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 14, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepOrange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  bool get canProceed {
    return _eventNameController.text.isNotEmpty &&
        selectedDate != null &&
        selectedTime != null &&
        _venueController.text.isNotEmpty &&
        _locationController.text.isNotEmpty &&
        _contactController.text.isNotEmpty &&
        numberOfGuests > 0;
  }

  void _usePinnedLocation(LatLng point) {
    setState(() => _pinnedLatLng = point);

    // Since we don't have geocoding in this flow, store coordinates in the field.
    // This still satisfies "user can pin the location" without extra services.
    _locationController.text =
        '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  // ── FIX: passes full booking context to ReviewOrderPage ──────────────────
  void _proceedToReview() {
    if (!canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewOrderPage(
          // Original params
          selectedItems: widget.selectedItems,
          eventName: _eventNameController.text,
          eventType: eventType,
          selectedDate: selectedDate!,
          selectedTime: _formatTime(selectedTime!),
          venue: _venueController.text,
          location: _locationController.text,
          contactNumber: _contactController.text,
          numberOfGuests: numberOfGuests.toString(),
          // New params forwarded from constructor
          catererId: widget.catererId,
          catererName: widget.catererName,
          packageId: widget.packageId,
          packageName: widget.packageName,
          pricePerPerson: widget.pricePerPerson,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD  (all UI unchanged from original)
  // ─────────────────────────────────────────────────────────────────────────

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
        title: Text(
          'Event Details',
          style: GoogleFonts.pacifico(color: Colors.black, fontSize: 26),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fill in your event details below',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    // Event Name
                    _buildModernTextField(
                      controller: _eventNameController,
                      label: 'Event Name',
                      icon: Icons.celebration,
                      hint: "e.g., John's 25th Birthday",
                    ),
                    const SizedBox(height: 16),

                    // Event Type Dropdown
                    _buildModernDropdown(),
                    const SizedBox(height: 16),

                    // Date Picker
                    _buildModernDateTimePicker(
                      label: 'Event Date',
                      icon: Icons.calendar_today,
                      value: selectedDate != null
                          ? DateFormat(
                              'EEEE, MMMM d, yyyy',
                            ).format(selectedDate!)
                          : null,
                      hint: 'Select event date',
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),

                    // Time Picker
                    _buildModernDateTimePicker(
                      label: 'Event Time',
                      icon: Icons.access_time,
                      value: selectedTime != null
                          ? _formatTime(selectedTime!)
                          : null,
                      hint: 'Select event time',
                      onTap: () => _selectTime(context),
                    ),
                    const SizedBox(height: 16),

                    // Venue
                    _buildModernTextField(
                      controller: _venueController,
                      label: 'Venue',
                      icon: Icons.location_city,
                      hint: 'e.g., Grand Ballroom, Garden Venue',
                    ),
                    const SizedBox(height: 16),

                    // Location
                    _buildModernTextField(
                      controller: _locationController,
                      label: 'Location/Address',
                      icon: Icons.location_on,
                      hint:
                          'Pin the location on the map (coordinates will be saved)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Real-time map with pin-to-select
                    SizedBox(
                      height: 260,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.white,
                          child: Stack(
                            children: [
                              RealTimeMap(
                                allowPin: true,
                                zoom: 15.0,
                                onLocationChanged: (latLng) {
                                  _usePinnedLocation(latLng);
                                },
                              ),

                              // Overlay prompt + pinned coordinates (optional)
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Tap on the map to pin your location',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _pinnedLatLng == null
                                            ? 'No pin selected yet'
                                            : 'Pinned: ${_pinnedLatLng!.latitude.toStringAsFixed(6)}, ${_pinnedLatLng!.longitude.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // "Use this pin" button is helpful if future logic changes
                                      // (and avoids accidental selection if user taps briefly).
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _pinnedLatLng == null
                                              ? null
                                              : () {
                                                  _usePinnedLocation(
                                                    _pinnedLatLng!,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Location pinned!',
                                                      ),
                                                      backgroundColor:
                                                          Colors.deepOrange,
                                                    ),
                                                  );
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepOrange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Use this pin',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contact Number
                    _buildModernTextField(
                      controller: _contactController,
                      label: 'Contact Number',
                      icon: Icons.phone,
                      hint: 'e.g., 09XX XXX XXXX',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Number of Guests
                    _buildGuestsSection(),
                    const SizedBox(height: 30),

                    // Summary Card
                    if (canProceed) _buildSummaryCard(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed
                        ? Colors.deepOrange
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: canProceed ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        canProceed ? 'Review Order' : 'Fill in all fields',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (canProceed) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers (all unchanged from original) ──────────────────────────

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.deepOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: eventType,
        decoration: InputDecoration(
          labelText: 'Event Type',
          prefixIcon: const Icon(Icons.event, color: Colors.deepOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: eventTypes.map((String type) {
          return DropdownMenuItem<String>(value: type, child: Text(type));
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) setState(() => eventType = newValue);
        },
      ),
    );
  }

  Widget _buildModernDateTimePicker({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null ? Colors.deepOrange : Colors.grey.shade300,
            width: value != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: value != null
                    ? Colors.deepOrange.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: value != null ? Colors.deepOrange : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: value != null
                          ? Colors.deepOrange
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: value != null ? Colors.deepOrange : Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.deepOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Number of Guests',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Expected attendees',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (numberOfGuests > 10) {
                    setState(() => numberOfGuests -= 10);
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
              ),
              Text(
                '$numberOfGuests guests',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (numberOfGuests < 500) {
                    setState(() => numberOfGuests += 10);
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'All fields completed!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Event', _eventNameController.text),
          _buildSummaryRow('Type', eventType),
          _buildSummaryRow(
            'Date',
            DateFormat('MMMM d, yyyy').format(selectedDate!),
          ),
          _buildSummaryRow('Time', _formatTime(selectedTime!)),
          _buildSummaryRow('Venue', _venueController.text),
          _buildSummaryRow('Guests', '$numberOfGuests people'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.deepOrange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
