import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EventPackagesScreen extends StatefulWidget {
  final String? catererId;
  final String? catererName;

  const EventPackagesScreen({super.key, this.catererId, this.catererName});

  @override
  State<EventPackagesScreen> createState() => _EventPackagesScreenState();
}

class _EventPackagesScreenState extends State<EventPackagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFavorited = false;

  final List<String> tags = [
    "Appetizers",
    "Main Course",
    "Dessert",
    "Drinks",
    "Setup",
    "Decoration",
  ];

  @override
  void initState() {
    super.initState();
    // Length must be 3 to match your UI tabs
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🔄 LOADING DIALOG
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7A22)),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// 🚀 MAIN BOOKING LOGIC
  Future<void> _navigateToBooking() async {
    _showLoadingDialog();
    await Future.delayed(const Duration(milliseconds: 400));

    // Fix for the connectivity list error
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());

    if (!mounted) return;

    if (connectivityResult.contains(ConnectivityResult.none)) {
      _hideLoadingDialog();
      _showErrorDialog(
        "You are offline",
        "Please connect to the internet to proceed.",
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _hideLoadingDialog();
      _showLoginRequiredDialog();
      return;
    }

    _hideLoadingDialog();
    Navigator.pushNamed(
      context,
      '/customize-package',
      arguments: {
        'catererId': widget.catererId,
        'catererName': widget.catererName,
      },
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFFFF7A22),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Login Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A22),
                      ),
                      child: const Text(
                        'Log In Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- RESTORING YOUR ORIGINAL UI DESIGN ---

  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Image.asset(
              "assets/manang_anna.png",
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(height: 250, color: Colors.grey[200]),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.catererName ?? "Caterer Details",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _navigateToBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A22),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Book Now",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavBar(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildHeaderContent()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFF7A22),
                labelColor: const Color(0xFFFF7A22),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Package A"),
                  Tab(text: "Package B"),
                  Tab(text: "Package C"),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPackageList(), // Your package design
            const Center(child: Text("Package B Content")),
            const Center(child: Text("Package C Content")),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Items included in this package:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...tags.map(
          (tag) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(tag),
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(context, shrinkOffset, overlapsContent) =>
      Container(color: Colors.white, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
