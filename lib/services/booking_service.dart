import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<bool> hasConflict({
    required String catererId,
    required DateTime date,
  }) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('caterer_id', isEqualTo: catererId)
          .where('status', whereIn: ['pending', 'confirmed', 'accepted'])
          .get();

      final requestedDate = _formatDate(date);

      for (final doc in snap.docs) {
        final data = doc.data();
        final existingDate = data['date'];
        if (existingDate == requestedDate) return true;

        final ts = data['event_date'];
        if (ts is Timestamp) {
          final existing = ts.toDate();
          if (existing.year == date.year &&
              existing.month == date.month &&
              existing.day == date.day) {
            return true;
          }
        }
      }
      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }

  Future<String> createBooking({
    required String catererId,
    required String catererName,
    required String packageId,
    required String packageName,
    required double pricePerPerson,
    required String eventName,
    required String eventType,
    required DateTime eventDate,
    required String eventTime,
    required String venue,
    required String location,
    required String contactNumber,
    required int numberOfGuests,
    required Map<String, List<String>> selectedItems,
    required double totalAmount,
    required double downPayment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final formattedDate = _formatDate(eventDate);
    final docRef = await _db.collection('bookings').add({
      'user_id': user.uid,
      'user_email': user.email ?? '',
      'customer_name': user.displayName ?? user.email ?? 'Customer',
      'caterer_id': catererId,
      'caterer_name': catererName,
      'package_id': packageId,
      'package_name': packageName,
      'price_per_person': pricePerPerson,
      'event_name': eventName,
      'event_type': eventType,
      'event_date': Timestamp.fromDate(eventDate),
      'date': formattedDate,
      'event_time': eventTime,
      'venue': venue,
      'location': location,
      'contact_number': contactNumber,
      'guests': numberOfGuests,
      'selected_items': selectedItems,
      'total': totalAmount,
      'total_amount': totalAmount,
      'down_payment': downPayment,
      'payment_status': 'down_payment_paid',
      'status': 'pending',
      'paid_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    try {
      await _db.collection('notifications').add({
        'user_id': user.uid,
        'type': 'booking',
        'title': 'Booking Confirmed!',
        'body':
            'Your booking with $catererName for $formattedDate has been confirmed.',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'booking_id': docRef.id,
      });
    } on FirebaseException {
      // Notification writes should not block a successful booking.
    }

    return docRef.id;
  }

  Future<void> markDownPaymentPaid(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'paymentStatus': 'down_payment_paid',
      'status': 'confirmed',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
