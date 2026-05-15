import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING SERVICE
// ─────────────────────────────────────────────────────────────────────────────
// Saves bookings to Firestore under the `bookings` collection.
// Each document is auto-ID'd and stores all booking context.
//
// Usage:
//   final id = await BookingService.instance.createBooking(...);
// ─────────────────────────────────────────────────────────────────────────────

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Returns true if the caterer already has a confirmed booking on [date].
  Future<bool> hasConflict({
    required String catererId,
    required DateTime date,
  }) async {
    final snap = await _db
        .collection('bookings')
        .where('catererId', isEqualTo: catererId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    for (final doc in snap.docs) {
      final ts = doc['eventDate'];
      if (ts == null) continue;
      final existing = (ts as Timestamp).toDate();
      if (existing.year == date.year &&
          existing.month == date.month &&
          existing.day == date.day) {
        return true;
      }
    }
    return false;
  }

  /// Creates a booking document and returns its Firestore document ID.
  /// Throws if the user is not authenticated.
  Future<String> createBooking({
    // Caterer / package context
    required String catererId,
    required String catererName,
    required String packageId,
    required String packageName,
    required double pricePerPerson,

    // Event details
    required String eventName,
    required String eventType,
    required DateTime eventDate,
    required String eventTime,
    required String venue,
    required String location,
    required String contactNumber,
    required int numberOfGuests,

    // Selected menu items  { 'mainCourse': ['Lechon', ...], ... }
    required Map<String, List<String>> selectedItems,

    // Computed totals
    required double totalAmount,
    required double downPayment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = await _db.collection('bookings').add({
      // Who booked
      'userId': user.uid,
      'userEmail': user.email ?? '',

      // Caterer / package
      'catererId': catererId,
      'catererName': catererName,
      'packageId': packageId,
      'packageName': packageName,
      'pricePerPerson': pricePerPerson,

      // Event
      'eventName': eventName,
      'eventType': eventType,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventTime': eventTime,
      'venue': venue,
      'location': location,
      'contactNumber': contactNumber,
      'numberOfGuests': numberOfGuests,

      // Menu
      'selectedItems': selectedItems,

      // Financials
      'totalAmount': totalAmount,
      'downPayment': downPayment,
      'paymentStatus': 'unpaid',

      // Booking state
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Updates payment status after successful payment.
  Future<void> markDownPaymentPaid(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'paymentStatus': 'down_payment_paid',
      'status': 'confirmed',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }
}
