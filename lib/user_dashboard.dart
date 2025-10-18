import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final List<Widget> _pages = [
    Center(child: Text('Home Screen')),
    WardrobeScreen(),
    AddItemScreen(),
    AiOutfitSuggestionsScreen(),
    const UserProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchUserProfile());
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
              // Google user – use photoUrl
              if (data.containsKey('photoUrl') && data['photoUrl'] != null) {
                _profileImageBase64 = "url::" + data['photoUrl'];
              } else {
                _profileImageBase64 = null;
              }
            } else {
              // Email/password user – use base64 image
              if (data.containsKey('image_base64') && data['image_base64'] != null) {
                _profileImageBase64 = data['image_base64'];
              } else {
                _profileImageBase64 = null;
              }
            }
          });
        }
      } else {
        print("No user logged in.");
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  /// 🔹 Fetch the most recent wardrobe item
  Future<DocumentSnapshot?> fetchRecentWardrobeItem() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wardrobe')
          .orderBy('createdAt', descending: true) // latest first
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _currentIndex == 0 ? _buildDashboard() : _pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavKey,
        index: _currentIndex,
        height: 60.0,
        items: const <Widget>[
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 🔹 Header Section
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 380,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: _profileImageBase64 != null
                                  ? (_profileImageBase64!.startsWith("url::")
                                  ? Image.network(
                                _profileImageBase64!.substring(5),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                                  : Image.memory(
                                base64Decode(_profileImageBase64!.split(',').last),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ))
                                  : Image.asset(
                                "assets/images/user (1).png",
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Hi, $_username',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const Spacer(),
                          // Top-right Notification Icon with Red Dot
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('notifications')
                                .where('read', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int unreadCount = 0;
                              if (snapshot.hasData) {
                                unreadCount = snapshot.data!.docs.length;
                              }

                              return Stack(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.notifications, color: Colors.white, size: 30),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 12,
                                      top: 6,
                                      child: Container(
                                        width: 10,
                                        height: 10,
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
                    const SizedBox(height: 6),
                    const Text(
                      "Find Your Wardrobe\nItems here",
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                bottom: -60,
                left: 20,
                right: 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FeatureCard(
                        icon: Icons.favorite_border,
                        label: 'Favorites',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FavoritesScreen()),
                          );
                        },
                      ),
                      FeatureCard(
                        icon: Icons.smart_toy_outlined,
                        label: 'AI Assistant',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SmartAssistantWelcomeScreen()),
                          );
                        },
                      ),
                      FeatureCard(
                        icon: Icons.checkroom_outlined,
                        label: 'Fashion Feed',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FashionStylingContentScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 80),

          // 🔹 Category Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select a Category",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                categoryCard("Add Items to Wardrobe", 'assets/images/wardrobe1.png', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddItemScreen()),
                  );
                }),
                const SizedBox(width: 12),
                categoryCard("AI Outfit Suggestions", 'assets/images/outfit.png'),
                const SizedBox(width: 12),
                categoryCard("Weather based Suggestions", 'assets/images/weather.png', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WeatherPage()),
                  );
                }),
                const SizedBox(width: 12),
                categoryCard("Smart Shopping", 'assets/images/smart shopping.png'),
                const SizedBox(width: 12),
                categoryCard("Outfit Planner", 'assets/images/Outfit-Planner.jpg', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OutfitCalendarScreen()),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 Recent Activity Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Activity",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          FutureBuilder<DocumentSnapshot?>(
            future: fetchRecentWardrobeItem(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No item added recently."),
                );
              }

              final item = snapshot.data!.data() as Map<String, dynamic>;
              final itemName = item['item_name'] ?? 'Unknown Item';
              final imageBase64 = item['image_base64'];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: imageBase64 != null
                              ? MemoryImage(base64Decode(imageBase64.split(',').last))
                              : const AssetImage('assets/images/shirt 1.png') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text("Recently Added: $itemName", style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 70),
        ],
      ),
    );
  }

  static Widget categoryCard(String title, String imagePath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            SizedBox(
              width: 220,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
            ),
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

  const FeatureCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                icon,
                color: Colors.pinkAccent,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
