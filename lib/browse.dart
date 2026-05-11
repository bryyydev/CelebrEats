import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notifications_screen.dart';
import 'event_packages_screen.dart';
import 'home.dart';

class BrowsePage extends StatefulWidget {
  /// When non-null the Browse screen opens with this event type pre-selected.
  /// Comes from HomePage's event-type chip tap.
  final String? filterEventType;

  const BrowsePage({super.key, this.filterEventType});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final TextEditingController searchController = TextEditingController();

  // FIX: activeEventFilter drives the Firestore query directly.
  // Null / 'All' → no filter; any other string → arrayContains query.
  String? activeEventFilter;

  // Local text entered in the search box — applied client-side on top of
  // the Firestore snapshot so we only need one StreamBuilder.
  String _searchQuery = '';

  final List<Map<String, dynamic>> eventTypes = [
    {"label": "All", "emoji": "🍽️"},
    {"label": "Birthday", "emoji": "🎂"},
    {"label": "Wedding", "emoji": "💍"},
    {"label": "Reunion", "emoji": "🎉"},
    {"label": "Baptism", "emoji": "🕊️"},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select the event type passed from the home screen (if any)
    activeEventFilter = widget.filterEventType;
    searchController.addListener(() {
      setState(() => _searchQuery = searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // FIX: Returns the Firestore stream for the currently active filter.
  // Selecting "Wedding" triggers an arrayContains query so only caterers
  // whose event_types array contains "Wedding" are returned — this is what
  // was causing the original "0 found" bug (the old code filtered a local
  // static list that never contained any Firestore data).
  Stream<QuerySnapshot> _buildStream() {
    final collection = FirebaseFirestore.instance.collection('caterers');

    if (activeEventFilter == null || activeEventFilter == 'All') {
      return collection.snapshots();
    }

    return collection
        .where('event_types', arrayContains: activeEventFilter)
        .snapshots();
  }

  // Lightweight client-side name/location filter applied on top of the
  // already-filtered Firestore snapshot.
  List<QueryDocumentSnapshot> _applySearch(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      final location = (data['location'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        "assets/logo.png",
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.restaurant,
                          color: Colors.deepOrange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "CelebrEats",
                        style: GoogleFonts.pacifico(
                          fontSize: 20,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      "assets/icons/notification_ic.svg",
                      height: 26,
                      width: 26,
                      placeholderBuilder: (_) =>
                          const Icon(Icons.notifications_none, size: 26),
                    ),
                  ),
                ],
              ),
            ),

            /// CONTENT
            // FIX: A single StreamBuilder wraps the entire scrollable section.
            // Switching filter chips calls setState → _buildStream() returns a
            // new stream → StreamBuilder rebuilds with the Firestore results.
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  // Apply lightweight client-side name/location search
                  final filteredDocs = _applySearch(allDocs);

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      /// TITLE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activeEventFilter != null &&
                                      activeEventFilter != 'All'
                                  ? '$activeEventFilter Caterers'
                                  : 'Browse Catering',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.tune, color: Colors.grey[700]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// SEARCH BAR
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search caterers, events...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// EVENT TYPE FILTER CHIPS
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: eventTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final event = eventTypes[index];
                            final label = event['label'] as String;
                            final isActive =
                                activeEventFilter == label ||
                                (label == 'All' && activeEventFilter == null);

                            return GestureDetector(
                              // FIX: tapping a chip updates activeEventFilter
                              // which switches _buildStream() to the appropriate
                              // arrayContains (or unfiltered) Firestore query.
                              onTap: () => setState(() {
                                activeEventFilter = label == 'All'
                                    ? null
                                    : label;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.deepOrange
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.deepOrange
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      event['emoji'] as String,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isActive
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// RESULT COUNT — always reflects the live Firestore data
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "${filteredDocs.length} caterer${filteredDocs.length == 1 ? '' : 's'} found",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// CATERER CARDS
                      if (filteredDocs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                activeEventFilter != null
                                    ? 'No caterers found for\n"$activeEventFilter"'
                                    : 'No caterers found.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            children: filteredDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;

                              // ── Decode cover image (base64) ───────────
                              Uint8List? imageBytes;
                              if (data['cover_photo'] != null &&
                                  data['cover_photo'].toString().isNotEmpty) {
                                try {
                                  final raw = data['cover_photo'].toString();
                                  final b64 = raw.contains(',')
                                      ? raw.split(',').last
                                      : raw;
                                  imageBytes = base64Decode(b64);
                                } catch (_) {}
                              }
                              if (imageBytes == null) {
                                final photos = data['menu_photos'];
                                if (photos is List && photos.isNotEmpty) {
                                  try {
                                    final raw = photos.first.toString();
                                    final b64 = raw.contains(',')
                                        ? raw.split(',').last
                                        : raw;
                                    imageBytes = base64Decode(b64);
                                  } catch (_) {}
                                }
                              }

                              // ── Safe cast of event_types ──────────────
                              final List<String> eventTypesList =
                                  (data['event_types'] as List<dynamic>? ?? [])
                                      .map((e) => e.toString())
                                      .toList();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: CatererCard(
                                  // FIX: pass the Firestore document ID so
                                  // EventPackagesScreen can query the correct
                                  // caterer's packages.
                                  id: doc.id,
                                  title: data['name'] ?? 'No Name',
                                  location: data['location'] ?? 'No location',
                                  imageBytes: imageBytes,
                                  rating: (data['rating'] as num? ?? 0.0)
                                      .toDouble(),
                                  reviewCount:
                                      (data['review_count'] as num? ?? 0)
                                          .toInt(),
                                  eventTypes: eventTypesList,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
