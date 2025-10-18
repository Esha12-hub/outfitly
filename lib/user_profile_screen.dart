import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'fashion_content_screen.dart';
import 'settings_screen.dart';
import 'user_login_screen.dart';
import 'outfit_planner.dart';
import 'color_palette_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String name = 'Loading...';
  String email = 'Loading...';
  String birthday = 'Loading...';
  String? base64Image;
  bool isLoading = true;

  int itemsCount = 0;
  int notificationsCount = 0;
  int favoritesCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      name = data['name'] ?? 'No name';
      email = data['email'] ?? 'No email';
      birthday = data['birthday'] ?? 'No birthday';
      base64Image = data['image_base64'];
    }

    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wardrobe')
        .get();
    itemsCount = itemsSnapshot.size;

    final favoritesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();
    favoritesCount = favoritesSnapshot.size;

    final notificationsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .get();
    notificationsCount = notificationsSnapshot.size;

    setState(() {
      isLoading = false;
    });
  }

  Uint8List? _decodeBase64(String? base64String) {
    if (base64String == null) return null;
    try {
      return base64Decode(
        base64String.contains(',') ? base64String.split(',').last : base64String,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = base64Image != null
        ? MemoryImage(_decodeBase64(base64Image!)!)
        : const AssetImage("assets/images/user (1).png") as ImageProvider;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.only(top: 54, bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          "assets/images/white_back_btn.png",
                          height: 30,
                          width: 30,
                        ),
                      ),
                    ),
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(),
                            ),
                          );
                        },
                        child:
                        const Icon(Icons.settings, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileImage,
                ),
                const SizedBox(height: 8),
                Text(
                  '@${name.toLowerCase().replaceAll(" ", "")}',
                  style:
                  const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProfileStat(
                        icon: Icons.checkroom,
                        count: itemsCount.toString(),
                        label: "Items",
                      ),
                      _ProfileStat(
                        icon: Icons.notifications,
                        count: notificationsCount.toString(),
                        label: "Notifications",
                        iconSize: 22,
                      ),
                      _ProfileStat(
                        icon: Icons.favorite_border,
                        count: favoritesCount.toString(),
                        label: "Favorites",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const _SectionTitle(title: 'ACCOUNT DETAILS'),
                  _profileField("Name", name),
                  _profileField("Birthday", birthday),
                  _profileField("Email", email),
                  _profileField("Password", "********"),

                  const _SectionTitle(title: 'STYLE PREFERENCES'),
                  _preferenceOption(
                    "Outfit Schedule",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          OutfitCalendarScreen(),
                        ),
                      );
                    },
                  ),
                  _preferenceOption("Color Palette",onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const SkinColorPalettePage(),
                      ),
                    );
                  },),
                  _preferenceOption("Fabric Care Advise"),

                  const _SectionTitle(title: 'SOCIAL & COLLABORATIVE'),
                  _preferenceOption("Style Share"),
                  _preferenceOption(
                    "Fashion Articles/Videos",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const FashionStylingContentScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show confirmation dialog
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: const Text(
                              "Logout",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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

                        // If confirmed, logout
                        if (shouldLogout == true) {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                                  (route) => false,
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    "Version 1.1.1",
                    style:
                    TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _profileField(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _preferenceOption(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final double iconSize;

  const _ProfileStat({
    required this.icon,
    required this.count,
    required this.label,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: iconSize, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
