import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fashion_content_screen.dart';
import 'settings_screen.dart';
import 'user_login_screen.dart';
import 'outfit_planner.dart';
import 'color_palette_screen.dart';
import 'fabric_care.dart';
import 'user_dashboard.dart';
import 'feedback_screen.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String name = 'Loading...';
  String email = 'Loading...';
  String birthday = 'Loading...';
  String createdAt = 'Loading...';
  String? base64Image;
  bool isLoading = true;

  int itemsCount = 0;
  int notificationsCount = 0;
  int favoritesCount = 0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      name = data['name'] ?? user.displayName ?? 'No name';
      email = data['email'] ?? user.email ?? 'No email';
      birthday = data['birthday'] ?? 'No birthday';

      if (data['createdAt'] != null) {
        try {
          final timestamp = data['createdAt'];
          DateTime createdDate = timestamp is Timestamp
              ? timestamp.toDate()
              : DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
          createdAt = DateFormat('dd MMM yyyy').format(createdDate);
        } catch (_) {
          createdAt = 'Unknown';
        }
      } else {
        createdAt = DateFormat('dd MMM yyyy')
            .format(user.metadata.creationTime ?? DateTime.now());
      }

      if (data['image_base64'] != null &&
          data['image_base64'].toString().isNotEmpty) {
        base64Image = data['image_base64'];
      } else if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        base64Image = user.photoURL;
      }
    } else {
      name = user.displayName ?? 'No name';
      email = user.email ?? 'No email';
      birthday = 'No birthday';
      createdAt = DateFormat('dd MMM yyyy, hh:mm a')
          .format(user.metadata.creationTime ?? DateTime.now());
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        base64Image = user.photoURL;
      }
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
    late ImageProvider profileImage;

    if (base64Image == null || base64Image!.isEmpty) {
      profileImage = const AssetImage("assets/images/user (1).png");
    } else if (base64Image!.startsWith('http')) {
      profileImage = NetworkImage(base64Image!);
    } else {
      final decoded = _decodeBase64(base64Image!);
      profileImage = decoded != null
          ? MemoryImage(decoded)
          : const AssetImage("assets/images/user (1).png");
    }

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    double fontScale(double base) => base * (width / 390).clamp(0.8, 1.4);
    double spacing(double base) => base * (height / 844).clamp(0.8, 1.3);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + spacing(8),
              bottom: spacing(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: spacing(14)),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const WardrobeHomeScreen(),
                            ),
                          );
                        },
                        child: Image.asset(
                          "assets/images/white_back_btn.png",
                          height: spacing(32),
                          width: spacing(32),
                        ),
                      ),
                    ),
                    Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: fontScale(20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: spacing(12)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(),
                            ),
                          );
                        },
                        child: Icon(Icons.settings,
                            color: Colors.white, size: fontScale(28)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing(12)),
                CircleAvatar(
                  radius: spacing(50),
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileImage,
                ),
                SizedBox(height: spacing(8)),
                Text(
                  '@${name.toLowerCase().replaceAll(" ", "")}',
                  style: TextStyle(
                    fontSize: fontScale(18),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: spacing(12)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProfileStat(
                        icon: Icons.checkroom,
                        count: itemsCount.toString(),
                        label: "Items",
                        iconSize: fontScale(26),
                      ),
                      _ProfileStat(
                        icon: Icons.notifications,
                        count: notificationsCount.toString(),
                        label: "Notifications",
                        iconSize: fontScale(22),
                      ),
                      _ProfileStat(
                        icon: Icons.favorite_border,
                        count: favoritesCount.toString(),
                        label: "Favorites",
                        iconSize: fontScale(26),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(bottom: spacing(30)),
                child: Column(
                  children: [
                    const _SectionTitle(title: 'ACCOUNT DETAILS'),
                    _profileField("Name", name, fontScale),
                    _profileField("Birthday", birthday, fontScale),
                    _profileField("Email", email, fontScale),
                    _profileField("Created At", createdAt, fontScale),

                    const _SectionTitle(title: 'STYLE PREFERENCES'),
                    _preferenceOption("Outfit Schedule", fontScale,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OutfitCalendarScreen()),
                          );
                        }),
                    _preferenceOption("Color Palette", fontScale,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const SkinColorPalettePage()),
                          );
                        }),
                    _preferenceOption("Fabric Care Advise", fontScale,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const FabricCareAdvisorScreen()),
                          );
                        }),

                    const _SectionTitle(title: 'SOCIAL & COLLABORATIVE'),
                    _preferenceOption("Feedback", fontScale, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const FeedbackScreen()),
                      );
                    }),
                    _preferenceOption("Fashion Articles/Videos",
                        fontScale, onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const FashionStylingContentScreen()),
                          );
                        }),

                    SizedBox(height: spacing(30)),
                    Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: spacing(30)),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12)),
                              title: const Text(
                                "Logout",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              content:
                              const Text("Do you want to logout?"),
                              actions: [
                                TextButton(
                                  child: const Text("No",
                                      style:
                                      TextStyle(color: Colors.black)),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                ),
                                TextButton(
                                  child: const Text("Yes",
                                      style:
                                      TextStyle(color: Colors.red)),
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const UserLoginScreen()),
                                    (route) => false,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout,
                            color: Colors.white),
                        label: Text(
                          "Logout",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: fontScale(16)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: spacing(14)),
                          minimumSize:
                          Size(double.infinity, spacing(50)),
                        ),
                      ),
                    ),

                    SizedBox(height: spacing(16)),
                    Text(
                      "Version 1.0.0",
                      style: TextStyle(
                          fontSize: fontScale(12),
                          color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _profileField(
      String title, String value, double Function(double) fontScale) {
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
              style: TextStyle(
                  fontSize: fontScale(14), fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: fontScale(14))),
        ],
      ),
    );
  }

  Widget _preferenceOption(String title, double Function(double) fontScale,
      {VoidCallback? onTap}) {
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
              style: TextStyle(
                fontSize: fontScale(14),
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
    final width = MediaQuery.of(context).size.width;
    double fontScale(double base) => base * (width / 390).clamp(0.8, 1.4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style:
          TextStyle(fontWeight: FontWeight.bold, fontSize: fontScale(14)),
        ),
      ),
    );
  }
}
