import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔹 Local imports
import 'favorite_screen.dart';
import 'weather.dart';
import 'user_profile_screen.dart';
import 'outfit_planner.dart';
import 'add_item_screen.dart';
import 'user_notification_center.dart';
import 'wardrobe_screen.dart';
import 'ai_outfit_suggestions.dart';
import 'fashion_content_screen.dart';
import 'smart_assistant_welcome.dart';
import 'user_login_screen.dart';
import 'smart_shopping_screen.dart';
import 'virtual_try.dart';

class WardrobeHomeScreen extends StatefulWidget {
  const WardrobeHomeScreen({super.key});

  @override
  State<WardrobeHomeScreen> createState() => _WardrobeHomeScreenState();
}

class _WardrobeHomeScreenState extends State<WardrobeHomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavKey = GlobalKey();

  String? _profileImageBase64;
  String _username = "User";
  DocumentSnapshot? _recentItem;

  final List<Widget> _pages = [
    const Center(child: Text('Home Screen')),
    const WardrobeScreen(),
    AddItemScreen(),
    const OutfitScreen(),
    const UserProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboardData());
  }

  Future<void> _loadDashboardData() async {
    await fetchUserProfile();
    await fetchRecentWardrobeItem();
  }

  Future<void> fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final isGoogleUser = user.providerData.any((info) => info.providerId == 'google.com');
          setState(() {
            _username = data['name'] ?? user.displayName ?? 'User';
            if (isGoogleUser) {
              _profileImageBase64 = data['photoUrl'] != null ? "url::${data['photoUrl']}" : null;
            } else {
              _profileImageBase64 = data['image_base64'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  Future<void> fetchRecentWardrobeItem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wardrobe')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        setState(() => _recentItem = snapshot.docs.first);
      } else {
        setState(() => _recentItem = null);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            child: const Text("No", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserLoginScreen()),
              (route) => false,
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _currentIndex == 0
            ? _buildDashboard(height, width)
            : _pages[_currentIndex],
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavKey,
          index: _currentIndex,
          height: height * 0.075,
          items: const [
            Icon(Icons.home, size: 30, color: Colors.white),
            FaIcon(FontAwesomeIcons.shirt, size: 24, color: Colors.white),
            Icon(Icons.add, size: 30, color: Colors.white),
            Icon(Icons.checkroom, size: 30, color: Colors.white),
            Icon(Icons.person, size: 30, color: Colors.white),
          ],
          color: Colors.pink,
          buttonBackgroundColor: Colors.pinkAccent,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 600),
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  Widget _buildDashboard(double height, double width) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: Colors.pinkAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: height * 0.45,
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: height * 0.14,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: width * 0.07,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: _profileImageBase64 != null
                                    ? (_profileImageBase64!.startsWith("url::")
                                    ? Image.network(
                                  _profileImageBase64!.substring(5),
                                  width: width * 0.14,
                                  height: width * 0.14,
                                  fit: BoxFit.cover,
                                )
                                    : Image.memory(
                                  base64Decode(_profileImageBase64!.split(',').last),
                                  width: width * 0.14,
                                  height: width * 0.14,
                                  fit: BoxFit.cover,
                                ))
                                    : Image.asset(
                                  "assets/images/user (1).png",
                                  width: width * 0.14,
                                  height: width * 0.14,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.03),
                            Text('Hi, $_username',
                                style: TextStyle(color: Colors.white, fontSize: width * 0.045)),
                            const Spacer(),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .collection('notifications')
                                  .where('read', isEqualTo: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int unreadCount = snapshot.data?.docs.length ?? 0;
                                return Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => const NotificationScreen()),
                                        );
                                      },
                                      icon: Icon(Icons.notifications,
                                          color: Colors.white, size: width * 0.07),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: width * 0.04,
                                        top: height * 0.012,
                                        child: Container(
                                          width: width * 0.025,
                                          height: width * 0.025,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.001),
                      Text(
                        "Find Your Wardrobe\nItems here",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: height * 0.015),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(width * 0.05),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: "Search...",
                            border: InputBorder.none,
                            icon: Icon(Icons.search),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -height * 0.09,
                  left: width * 0.05,
                  right: width * 0.05,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FeatureCard(
                        icon: Icons.favorite_border,
                        label: 'Favorites',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FavoritesScreen()),
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.smart_toy_outlined,
                        label: 'AI Assistant',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SmartAssistantWelcomeScreen()),
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.checkroom_outlined,
                        label: 'Fashion Feed',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FashionStylingContentScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text("Select a Category",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: height * 0.015),
            SizedBox(
              height: height * 0.26,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                children: [
                  categoryCard("Add Items to Wardrobe", 'assets/images/wardrobe1.png',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => AddItemScreen()))),
                  SizedBox(width: width * 0.03),
                  categoryCard("AI Outfit Suggestions", 'assets/images/outfit.png',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const OutfitScreen()))),
                  SizedBox(width: width * 0.03),
                  categoryCard("Virtual Try-On", 'assets/images/virtual try-on.png',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const VirtualTryOnScreen()))),
                  SizedBox(width: width * 0.03),
                  categoryCard("Weather based Suggestions", 'assets/images/weather.png',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const WeatherPage()))),
                  SizedBox(width: width * 0.03),
                  categoryCard("Smart Shopping", 'assets/images/smart shopping.png',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const SmartShoppingScreen()))),
                  SizedBox(width: width * 0.03),
                  categoryCard("Outfit Planner", 'assets/images/Outfit-Planner.jpg',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => OutfitCalendarScreen()))),
                ],
              ),
            ),
            SizedBox(height: height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent Activity",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: height * 0.015),
            _recentItem == null
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No item added recently."),
            )
                : Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: Row(
                children: [
                  Container(
                    width: width * 0.2,
                    height: height * 0.12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: (_recentItem!['image_base64'] != null)
                            ? MemoryImage(base64Decode(
                            _recentItem!['image_base64'].split(',').last))
                            : const AssetImage('assets/images/shirt 1.png')
                        as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Text(
                      "Recently Added: ${_recentItem!['item_name'] ?? 'Unknown Item'}",
                      style: TextStyle(fontSize: width * 0.035),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: height * 0.08),
          ],
        ),
      ),
    );
  }

  static Widget categoryCard(String title, String imagePath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(7, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(imagePath, height: 140, width: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const FeatureCard({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width * 0.25,
        height: width * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * 0.05),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(3, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration:
              BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
              padding: EdgeInsets.all(width * 0.05),
              child: Icon(icon, color: Colors.pinkAccent, size: width * 0.08),
            ),
            SizedBox(height: width * 0.03),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: width * 0.035,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
