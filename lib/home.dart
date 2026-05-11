import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notifications_screen.dart';
import 'event_packages_screen.dart';
import 'browse.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Cleared after navigation returns so chips revert to idle
  String? selectedEventType;

  // Live search query — drives _matchesCaterer()
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> eventTypes = [
    {"label": "Birthday", "emoji": "🎂"},
    {"label": "Wedding", "emoji": "💍"},
    {"label": "Reunion", "emoji": "🎉"},
    {"label": "Baptism", "emoji": "🕊️"},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns true when a caterer document matches the current search query.
  /// Checks name (case-insensitive) and every entry in event_types.
  bool _matchesCaterer(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final q = _searchQuery.toLowerCase();

    // Match against caterer name
    final name = (data['name'] ?? '').toString().toLowerCase();
    if (name.contains(q)) return true;

    // Match against any of the caterer's event types
    final types = data['event_types'];
    if (types is List) {
      for (final t in types) {
        if (t.toString().toLowerCase().contains(q)) return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// ── TOP BAR ──
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    child: SvgPicture.asset(
                      "assets/icons/notification_ic.svg",
                      height: 26,
                      width: 26,
                      placeholderBuilder: (_) =>
                          const Icon(Icons.notifications_none),
                    ),
                  ),
                ],
              ),
            ),

            /// ── MAIN CONTENT ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Find Perfect Catering",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "For Your Special Celebration",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// ── SEARCH BAR ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value.trim());
                          },
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: "Search caterers, events...",
                            border: InputBorder.none,
                            // Clear (×) button — only shown when there's input
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.black45,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// EVENT TYPE CHIPS
                    /// Hidden while searching to keep UI focused
                    if (_searchQuery.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Event Type",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildEventTypeChips(),
                      const SizedBox(height: 25),
                    ] else
                      const SizedBox(height: 5),

                    /// ── SECTION HEADER ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Search Results'
                                : 'Featured Caterers',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_searchQuery.isEmpty)
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BrowsePage(),
                                ),
                              ),
                              child: const Text(
                                "View All",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildCatererList(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EVENT TYPE CHIPS
  // ─────────────────────────────────────────────────────────────

  Widget _buildEventTypeChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: eventTypes.map((event) {
          final label = event["label"] as String;
          final isSelected = selectedEventType == label;

          return _EventTypeChip(
            label: label,
            emoji: event["emoji"] as String,
            isSelected: isSelected,
            onTap: () async {
              setState(() => selectedEventType = label);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrowsePage(filterEventType: label),
                ),
              );

              if (mounted) {
                setState(() => selectedEventType = null);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATERER LIST — filtered in real-time by _searchQuery
  // ─────────────────────────────────────────────────────────────

  Widget _buildCatererList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('caterers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Apply client-side search filter
        final allDocs = snapshot.data!.docs;
        final caterers = allDocs.where((doc) {
          return _matchesCaterer(doc.data() as Map<String, dynamic>);
        }).toList();

        if (caterers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 44, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No caterers matched "$_searchQuery".'
                        : 'No caterers found.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: caterers.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // ── Decode cover image (base64) ──────────────────────────────
            Uint8List? imageBytes;
            if (data['cover_photo'] != null &&
                data['cover_photo'].toString().isNotEmpty) {
              try {
                final raw = data['cover_photo'].toString();
                final b64 = raw.contains(',') ? raw.split(',').last : raw;
                imageBytes = base64Decode(b64);
              } catch (_) {}
            }
            if (imageBytes == null) {
              final photos = data['menu_photos'];
              if (photos is List && photos.isNotEmpty) {
                try {
                  final raw = photos.first.toString();
                  final b64 = raw.contains(',') ? raw.split(',').last : raw;
                  imageBytes = base64Decode(b64);
                } catch (_) {}
              }
            }

            final List<String> eventTypesList =
                (data['event_types'] as List<dynamic>? ?? [])
                    .map((e) => e.toString())
                    .toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CatererCard(
                id: doc.id,
                title: data['name'] ?? 'No Name',
                location: data['location'] ?? 'No location',
                imageBytes: imageBytes,
                rating: (data['rating'] as num? ?? 0.0).toDouble(),
                reviewCount: (data['review_count'] as num? ?? 0).toInt(),
                eventTypes: eventTypesList,
                // Passed down so the card can highlight matched text
                searchQuery: _searchQuery,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EVENT TYPE CHIP
// ─────────────────────────────────────────────────────────────

class _EventTypeChip extends StatefulWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _EventTypeChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_EventTypeChip> createState() => _EventTypeChipState();
}

class _EventTypeChipState extends State<_EventTypeChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.88,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_EventTypeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected && !widget.isSelected) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    _controller.reset();
    await _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.deepOrange.withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected ? Colors.deepOrange : Colors.transparent,
              width: 1.4,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: widget.isSelected ? Colors.deepOrange : Colors.black87,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HIGHLIGHTED TEXT
// Renders plain text normally; highlights matched substrings in
// deepOrange bold when a search query is active.
// ─────────────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + lowerQuery.length),
          style: baseStyle.copyWith(
            color: Colors.deepOrange,
            fontWeight: FontWeight.w700,
            backgroundColor: Colors.deepOrange.withOpacity(0.08),
          ),
        ),
      );
      start = index + lowerQuery.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATERER CARD
// ─────────────────────────────────────────────────────────────

class CatererCard extends StatefulWidget {
  final String id;
  final String title;
  final String location;
  final Uint8List? imageBytes;
  final double rating;
  final int reviewCount;
  final List<String> eventTypes;
  final String searchQuery;

  const CatererCard({
    super.key,
    required this.id,
    required this.title,
    required this.location,
    this.imageBytes,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.eventTypes = const [],
    this.searchQuery = '',
  });

  @override
  State<CatererCard> createState() => _CatererCardState();
}

class _CatererCardState extends State<CatererCard> {
  bool _isFavorited = false;

  void _handleCardTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventPackagesScreen(catererId: widget.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleCardTap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Image + Favorite Button ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: widget.imageBytes != null
                      ? Image.memory(
                          widget.imageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => setState(() => _isFavorited = !_isFavorited),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorited
                            ? Colors.deepOrange
                            : Colors.grey[400],
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Info Section ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title — highlights matched text when searching
                  _HighlightedText(
                    text: widget.title,
                    query: widget.searchQuery,
                    baseStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC107),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.reviewCount} reviews)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.eventTypes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.eventTypes.take(4).map((type) {
                        // Highlight the pill when this event type matches
                        final isMatch =
                            widget.searchQuery.isNotEmpty &&
                            type.toLowerCase().contains(
                              widget.searchQuery.toLowerCase(),
                            );
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isMatch
                                ? Colors.deepOrange.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isMatch
                                  ? Colors.deepOrange
                                  : Colors.deepOrange.withOpacity(0.5),
                              width: isMatch ? 1.4 : 1.0,
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isMatch
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
