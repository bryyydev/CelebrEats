import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notifications_screen.dart';
import 'data/caterers_data.dart';
import 'home.dart'; // CatererCard lives here

class BrowsePage extends StatefulWidget {
  final String? filterEventType; // received from HomePage event type tap

  const BrowsePage({super.key, this.filterEventType});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredCaterers = [];
  String? activeEventFilter;

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
    // Pre-select the event type passed from HomePage
    activeEventFilter = widget.filterEventType;
    _applyFilters();
  }

  void _applyFilters({String searchQuery = ""}) {
    final allCaterers = List<Map<String, dynamic>>.from(CaterersData.caterers);

    setState(() {
      filteredCaterers = allCaterers.where((caterer) {
        // Search filter
        final title = (caterer["title"] as String).toLowerCase();
        final tags = (caterer["tags"] as List).join(" ").toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            title.contains(searchQuery.toLowerCase()) ||
            tags.contains(searchQuery.toLowerCase());

        // Event type filter
        final matchesEvent =
            activeEventFilter == null ||
            activeEventFilter == "All" ||
            tags.contains(activeEventFilter!.toLowerCase());

        return matchesSearch && matchesEvent;
      }).toList();
    });
  }

  void searchCaterers(String query) {
    _applyFilters(searchQuery: query);
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
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
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      "assets/icons/notification_ic.svg",
                      height: 26,
                      width: 26,
                      placeholderBuilder: (context) =>
                          const Icon(Icons.notifications_none, size: 26),
                    ),
                  ),
                ],
              ),
            ),

            /// CONTENT
            Expanded(
              child: ListView(
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
                                  activeEventFilter != "All"
                              ? "$activeEventFilter Caterers"
                              : "Browse Catering",
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
                        onChanged: searchCaterers,
                        decoration: const InputDecoration(
                          hintText: "Search caterers, events...",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                        final isActive =
                            activeEventFilter == event["label"] ||
                            (event["label"] == "All" &&
                                activeEventFilter == null);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              activeEventFilter = event["label"] == "All"
                                  ? null
                                  : event["label"] as String;
                            });
                            _applyFilters(searchQuery: searchController.text);
                          },
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
                                  event["emoji"] as String,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  event["label"] as String,
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

                  /// RESULT COUNT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "${filteredCaterers.length} caterer${filteredCaterers.length == 1 ? '' : 's'} found",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// CATERER CARDS
                  filteredCaterers.isEmpty
                      ? Padding(
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
                                "No caterers found for\n\"$activeEventFilter\"",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            children: filteredCaterers.map((caterer) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: CatererCard(
                                  id: caterer["id"],
                                  image: caterer["image"],
                                  title: caterer["title"],
                                  rating: (caterer["rating"] as num).toDouble(),
                                  reviews: caterer["reviews"].toString(),
                                  location: caterer["location"],
                                  tags: List<String>.from(caterer["tags"]),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
