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

  /// Create a caterer profile.
  ///
  /// [uid]             — the caterer's Firebase Auth UID (used as doc ID).
  /// [businessName]    — display name shown on listing cards.
  /// [description]     — short bio shown on the profile.
  /// [locationAddress] — human-readable address stored in `location` field.
  /// [eventTypes]      — list of event labels (e.g. ['Wedding', 'Birthday']).
  ///                     Stored as an array so Browse can use arrayContains queries.
  /// [minimumGuests]   — minimum headcount the caterer accepts.
  Future<void> createCaterer({
    required String uid,
    required String businessName,
    required String description,
    required String locationAddress,
    required List<String> eventTypes,
    required int minimumGuests,
  }) async {
    await _db.collection('caterers').doc(uid).set({
      'caterer_id': uid,
      'user_id': uid,
      'name': businessName,
      'description': description,
      // Stored under 'location' so Browse cards can display it directly.
      'location': locationAddress,
      // Stored as an array — enables .where('event_types', arrayContains: x)
      'event_types': eventTypes,
      'rating': 0.0,
      'review_count': 0,
      'minimum_guests': minimumGuests,
      'is_active': true,
      'is_verified': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get all caterers (for Browse screen — no filter)
  Stream<QuerySnapshot> getCaterers() {
    return _db.collection('caterers').snapshots();
  }

  /// Get caterers whose event_types array contains [eventType].
  ///
  /// Used by BrowsePage when the user taps an event-type chip so that
  /// only matching caterers are fetched from Firestore (no client-side
  /// filtering needed, which was the root cause of the "0 found" bug).
  Stream<QuerySnapshot> getCaterersByEventType(String eventType) {
    return _db
        .collection('caterers')
        .where('event_types', arrayContains: eventType)
        .snapshots();
  }

  /// Get a single caterer document by ID
  Future<Map<String, dynamic>?> getCaterer(String catererId) async {
    final doc = await _db.collection('caterers').doc(catererId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Update caterer profile fields
  Future<void> updateCaterer(
    String catererId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('caterers').doc(catererId).update(data);
  }

  // ─────────────────────────────────────────────
  // PACKAGES COLLECTION
  // ─────────────────────────────────────────────

  /// Create a package for a caterer.
  ///
  /// [catererId]     — Firestore document ID of the owning caterer.
  /// [name]          — Package display name (e.g. "Silver Package").
  /// [pricePerPerson]— Cost per guest head in PHP.
  /// [eventType]     — Which event this package is designed for.
  /// [categoryTab]   — Tab label in EventPackagesScreen: must be exactly
  ///                   'Package A', 'Package B', or 'Package C'.
  ///                   This value is used in a Firestore equality filter so
  ///                   the correct packages appear under the correct tab.
  /// [inclusions]    — List of items included in the package.
  /// [active]        — Whether the package is visible to customers.
  Future<void> createPackage({
    required String catererId,
    required String name,
    required double pricePerPerson,
    required String eventType,
    required String categoryTab, // 'Package A' | 'Package B' | 'Package C'
    required List<String> inclusions,
    required bool active,
  }) async {
    await _db.collection('packages').add({
      'caterer_id': catererId,
      'name': name,
      'price_per_person': pricePerPerson,
      'event_type': eventType,
      // Used by EventPackagesScreen TabBarView to route packages into the
      // correct tab. Must match the tab label strings exactly.
      'category_tab': categoryTab,
      'inclusions': inclusions,
      'active': active,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get all active packages for a caterer (all tabs combined).
  Stream<QuerySnapshot> getPackages(String catererId) {
    return _db
        .collection('packages')
        .where('caterer_id', isEqualTo: catererId)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  /// Get active packages for a caterer filtered by [categoryTab].
  ///
  /// Called once per tab in EventPackagesScreen so each tab only loads
  /// the packages that belong to it.
  Stream<QuerySnapshot> getPackagesByTab(String catererId, String categoryTab) {
    return _db
        .collection('packages')
        .where('caterer_id', isEqualTo: catererId)
        .where('category_tab', isEqualTo: categoryTab)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // ADDONS COLLECTION
  // ─────────────────────────────────────────────

  /// Create an add-on item for a caterer
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

  /// Get all active add-ons for a caterer
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

  /// Create a new booking document and return its generated ID
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

  /// Stream of all bookings belonging to the currently logged-in user
  Stream<QuerySnapshot> getUserBookings() {
    if (currentUserId == null) return const Stream.empty();
    return _db
        .collection('bookings')
        .where('user_id', isEqualTo: currentUserId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Stream of all bookings for a specific caterer
  Stream<QuerySnapshot> getCatererBookings(String catererId) {
    return _db
        .collection('bookings')
        .where('caterer_id', isEqualTo: catererId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Update booking status — accepted / confirmed / completed / cancelled
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // PAYMENTS COLLECTION
  // ─────────────────────────────────────────────

  /// Record a payment against a booking
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

  /// Send a message tied to a specific booking
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

  /// Real-time stream of messages for a booking, oldest first
  Stream<QuerySnapshot> getMessages(String bookingId) {
    return _db
        .collection('messages')
        .where('booking_id', isEqualTo: bookingId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Mark a single message document as read
  Future<void> markMessageRead(String messageId) async {
    await _db.collection('messages').doc(messageId).update({'read': true});
  }

  // ─────────────────────────────────────────────
  // REVIEWS COLLECTION
  // ─────────────────────────────────────────────

  /// Submit a review for a completed booking
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

  /// Real-time stream of all reviews for a caterer, newest first
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

  /// Real-time stream of all notifications for the current user, newest first
  Stream<QuerySnapshot> getNotifications() {
    if (currentUserId == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Mark a notification document as read
  Future<void> markNotificationRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'read': true});
  }

  /// Push a notification to any user by their UID
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

  /// Save a caterer to the current user's favorites
  Future<void> addFavorite(String catererId) async {
    if (currentUserId == null) return;
    await _db.collection('favorites').add({
      'user_id': currentUserId,
      'caterer_id': catererId,
      'saved_at': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a caterer from the current user's favorites
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

  /// Real-time stream of the current user's favorited caterers
  Stream<QuerySnapshot> getFavorites() {
    if (currentUserId == null) return const Stream.empty();
    return _db
        .collection('favorites')
        .where('user_id', isEqualTo: currentUserId)
        .snapshots();
  }

  /// Returns true if [catererId] is already in the current user's favorites
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
