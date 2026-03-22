import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // HELPER — get current user ID
  // ─────────────────────────────────────────────
  String? get currentUserId => _auth.currentUser?.uid;

  // ─────────────────────────────────────────────
  // USERS COLLECTION
  // ─────────────────────────────────────────────

  /// Create a new user document in Firestore
  Future<void> createUser({
    required String uid,
    required String username,
    required String email,
    bool isCaterer = false,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': username,
      'email': email,
      'is_caterer': isCaterer,
      'photo': '',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get a single user document by UID
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// Update current user's fields
  Future<void> updateUser(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    await _db.collection('users').doc(currentUserId).update(data);
  }

  // ─────────────────────────────────────────────
  // CATERERS COLLECTION
  // ─────────────────────────────────────────────

  /// Create a caterer profile
  Future<void> createCaterer({
    required String userId,
    required String businessName,
    required String description,
    required String location,
    required int minimumGuests,
  }) async {
    await _db.collection('caterers').doc(userId).set({
      'caterer_id': userId,
      'user_id': userId,
      'name': businessName,
      'description': description,
      'location': location,
      'rating': 0.0,
      'minimum_guests': minimumGuests,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get all caterers (for Browse screen)
  Stream<QuerySnapshot> getCaterers() {
    return _db.collection('caterers').snapshots();
  }

  /// Get a single caterer by ID
  Future<Map<String, dynamic>?> getCaterer(String catererId) async {
    final doc = await _db.collection('caterers').doc(catererId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Update caterer profile
  Future<void> updateCaterer(
    String catererId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('caterers').doc(catererId).update(data);
  }

  // ─────────────────────────────────────────────
  // PACKAGES COLLECTION
  // ─────────────────────────────────────────────

  /// Create a package for a caterer
  Future<void> createPackage({
    required String catererId,
    required String name,
    required double pricePerPerson,
    required bool active,
  }) async {
    await _db.collection('packages').add({
      'caterer_id': catererId,
      'name': name,
      'price_per_person': pricePerPerson,
      'active': active,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get all packages for a caterer
  Stream<QuerySnapshot> getPackages(String catererId) {
    return _db
        .collection('packages')
        .where('caterer_id', isEqualTo: catererId)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // ADDONS COLLECTION
  // ─────────────────────────────────────────────

  /// Create an add-on for a caterer
  Future<void> createAddon({
    required String catererId,
    required String name,
    required String category,
    required double price,
    required bool active,
  }) async {
    await _db.collection('addons').add({
      'caterer_id': catererId,
      'name': name,
      'category': category,
      'price': price,
      'active': active,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get all add-ons for a caterer
  Stream<QuerySnapshot> getAddons(String catererId) {
    return _db
        .collection('addons')
        .where('caterer_id', isEqualTo: catererId)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // BOOKINGS COLLECTION
  // ─────────────────────────────────────────────

  /// Create a new booking
  Future<String> createBooking({
    required String catererId,
    required String packageId,
    required String eventType,
    required String date,
    required int guests,
    required String venue,
    required double total,
  }) async {
    if (currentUserId == null) throw Exception("User not logged in");
    final doc = await _db.collection('bookings').add({
      'user_id': currentUserId,
      'caterer_id': catererId,
      'package_id': packageId,
      'event_type': eventType,
      'date': date,
      'guests': guests,
      'venue': venue,
      'status': 'pending',
      'total': total,
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Get all bookings for current user
  Stream<QuerySnapshot> getUserBookings() {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    return _db
        .collection('bookings')
        .where('user_id', isEqualTo: currentUserId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Get all bookings for a caterer
  Stream<QuerySnapshot> getCatererBookings(String catererId) {
    return _db
        .collection('bookings')
        .where('caterer_id', isEqualTo: catererId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Update booking status (accept / confirm / complete)
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // PAYMENTS COLLECTION
  // ─────────────────────────────────────────────

  /// Record a payment
  Future<void> createPayment({
    required String bookingId,
    required String method,
    required double amount,
    required String status,
    required String ref,
  }) async {
    await _db.collection('payments').add({
      'booking_id': bookingId,
      'method': method,
      'amount': amount,
      'status': status,
      'ref': ref,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // MESSAGES COLLECTION
  // ─────────────────────────────────────────────

  /// Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String bookingId,
    required String content,
  }) async {
    if (currentUserId == null) throw Exception("User not logged in");
    await _db.collection('messages').add({
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'booking_id': bookingId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Get real-time messages for a booking
  Stream<QuerySnapshot> getMessages(String bookingId) {
    return _db
        .collection('messages')
        .where('booking_id', isEqualTo: bookingId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Mark message as read
  Future<void> markMessageRead(String messageId) async {
    await _db.collection('messages').doc(messageId).update({'read': true});
  }

  // ─────────────────────────────────────────────
  // REVIEWS COLLECTION
  // ─────────────────────────────────────────────

  /// Submit a review
  Future<void> createReview({
    required String catererId,
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    if (currentUserId == null) throw Exception("User not logged in");
    await _db.collection('reviews').add({
      'user_id': currentUserId,
      'caterer_id': catererId,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get all reviews for a caterer
  Stream<QuerySnapshot> getCatererReviews(String catererId) {
    return _db
        .collection('reviews')
        .where('caterer_id', isEqualTo: catererId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // NOTIFICATIONS COLLECTION
  // ─────────────────────────────────────────────

  /// Get all notifications for current user
  Stream<QuerySnapshot> getNotifications() {
    if (currentUserId == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'read': true});
  }

  /// Send a notification to a user
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
  }) async {
    await _db.collection('notifications').add({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // FAVORITES COLLECTION
  // ─────────────────────────────────────────────

  /// Add a caterer to favorites
  Future<void> addFavorite(String catererId) async {
    if (currentUserId == null) return;
    await _db.collection('favorites').add({
      'user_id': currentUserId,
      'caterer_id': catererId,
      'saved_at': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a caterer from favorites
  Future<void> removeFavorite(String catererId) async {
    if (currentUserId == null) return;
    final snapshot = await _db
        .collection('favorites')
        .where('user_id', isEqualTo: currentUserId)
        .where('caterer_id', isEqualTo: catererId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Get all favorites for current user
  Stream<QuerySnapshot> getFavorites() {
    if (currentUserId == null) return const Stream.empty();
    return _db
        .collection('favorites')
        .where('user_id', isEqualTo: currentUserId)
        .snapshots();
  }

  /// Check if a caterer is already favorited
  Future<bool> isFavorite(String catererId) async {
    if (currentUserId == null) return false;
    final snapshot = await _db
        .collection('favorites')
        .where('user_id', isEqualTo: currentUserId)
        .where('caterer_id', isEqualTo: catererId)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
