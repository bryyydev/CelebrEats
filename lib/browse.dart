import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'event_packages_screen.dart';

class BrowsePage extends StatefulWidget {
  final String? filterEventType;

  const BrowsePage({super.key, this.filterEventType});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  String selectedType = 'All';

  final List<Map<String, dynamic>> eventTypes = [
    {"label": "All", "emoji": "✨"},
    {"label": "Wedding", "emoji": "💍"},
    {"label": "Birthday", "emoji": "🎂"},
    {"label": "Reunion", "emoji": "🎉"},
    {"label": "Baptism", "emoji": "🕊️"},
  ];

  @override
  void initState() {
    super.initState();

    selectedType = widget.filterEventType ?? 'All';
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collectionGroup('packages');

    if (selectedType != 'All') {
      query = query.where('event_type', isEqualTo: selectedType);
    }

    return query.orderBy('created_at', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Browse Packages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
        children: [
          /// FILTERS
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: eventTypes.length,
              itemBuilder: (context, index) {
                final event = eventTypes[index];

                final type = event["label"];
                final emoji = event["emoji"];

                final selected = selectedType == type;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = type;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),

                      curve: Curves.easeInOut,

                      width: 82,

                      padding: const EdgeInsets.symmetric(vertical: 10),

                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.deepOrange.withOpacity(0.12)
                            : Colors.grey[100],

                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(
                          color: selected
                              ? Colors.deepOrange
                              : Colors.transparent,
                          width: 1.4,
                        ),

                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 28)),

                          const SizedBox(height: 6),

                          Text(
                            type,

                            style: TextStyle(
                              fontSize: 12,

                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,

                              color: selected
                                  ? Colors.deepOrange
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// PACKAGE FEED
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final packages = snapshot.data!.docs;

                if (packages.isEmpty) {
                  return const Center(child: Text('No packages found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package = packages[index];

                    final data = package.data() as Map<String, dynamic>;

                    return _PackageCard(
                      packageId: package.id,
                      packageName: data['name'] ?? '',
                      catererId: data['caterer_id'],
                      catererName: data['caterer_name'] ?? '',
                      price: data['price'] ?? 0,
                      eventType: data['event_type'] ?? '',
                      imageUrl: data['image_url'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String packageId;
  final String packageName;
  final String catererId;
  final String catererName;
  final double price;
  final String eventType;
  final String? imageUrl;

  const _PackageCard({
    required this.packageId,
    required this.packageName,
    required this.catererId,
    required this.catererName,
    required this.price,
    required this.eventType,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventPackagesScreen(catererId: catererId),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(height: 200, color: Colors.grey[200]),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    packageName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    catererName,
                    style: const TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          eventType,
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        '₱${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
