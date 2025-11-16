import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'manage_permissions_screen.dart';
import 'about_us_screen.dart';
import 'user_profile_screen.dart';
import 'smart_assistant_welcome.dart';
import 'terms.dart';
import 'writer_login_screen.dart';
import 'user_login_screen.dart';
import 'change_name_screen.dart';
import 'change_profile_img.dart';
import 'user_dashboard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool seasonBasedFiltering = false;
  bool occasionTags = true;
  bool outfitSuggestions = false;
  bool shoppingRecommendations = true;
  bool appLock = true;

  String username = "User Name";
  Uint8List? profilePhotoBytes;
  String? profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          username = data['name'] ?? "User Name";

          final base64Image = data['image_base64'];
          final urlImage = data['photoUrl'];

          if (base64Image != null && base64Image.toString().isNotEmpty) {
            profilePhotoBytes = base64Decode(
              base64Image.contains(',') ? base64Image.split(',').last : base64Image,
            );
            profilePhotoUrl = null;
          } else if (urlImage != null && urlImage.toString().isNotEmpty) {
            profilePhotoUrl = urlImage;
            profilePhotoBytes = null;
          }

          seasonBasedFiltering = data['seasonBasedFiltering'] ?? false;
          occasionTags = data['occasionTags'] ?? true;
          outfitSuggestions = data['outfitSuggestions'] ?? false;
          shoppingRecommendations = data['shoppingRecommendations'] ?? true;
          appLock = data['appLock'] ?? true;
        });
      } else {
        setState(() {
          username = user.displayName ?? "User Name";
          profilePhotoUrl = user.photoURL;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        username = user.displayName ?? "User Name";
        profilePhotoUrl = user.photoURL;
      });
    }
  }

  Future<void> _updatePreference(String field, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        field: value,
      });
    } catch (e) {
      print("Error updating $field: $e");
    }
  }

  Future<bool> _showLogoutDialog() async {
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

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserLoginScreen()),
              (route) => false,
        );
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height / 812;
    final w = size.width / 375;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WardrobeHomeScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.black)),
                Positioned(
                  top: 140 * h,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28 * w),
                        topRight: Radius.circular(28 * w),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16 * w, 20 * h, 16 * w, 16 * h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          SizedBox(height: 20 * h),

                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const UserProfileScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(16 * w),
                            child: Container(
                              padding: EdgeInsets.all(12 * w),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16 * w),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28 * w,
                                    backgroundImage: profilePhotoBytes != null
                                        ? MemoryImage(profilePhotoBytes!)
                                        : (profilePhotoUrl != null
                                        ? NetworkImage(profilePhotoUrl!)
                                        : const AssetImage(
                                        'assets/images/user (1).png')
                                    as ImageProvider),
                                  ),
                                  SizedBox(width: 12 * w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16 * w,
                                          ),
                                        ),
                                        Text(
                                          "Google Account, Apple ID & Wardrobe Details",
                                          style: TextStyle(fontSize: 12 * w),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 16 * w),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24 * h),

                          _sectionTitle("ACCOUNT SETTINGS", w),
                          _iconTile(Icons.person, "Change Username", w, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChangeNameScreen()),
                            );
                          }),
                          _iconTile(Icons.lock, "Change Password", w, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
                            );
                          }),
                          _iconTile(Icons.image, "Change Profile Image", w, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChangeProfileImageScreen()),
                            );
                          }),
                          _iconTile(Icons.delete_forever, "Delete Profile", w,
                              onTap: _confirmDeleteProfile),

                          SizedBox(height: 24 * h),

                          _sectionTitle("WARDROBE PREFERENCES", w),
                          _toggleTile(Icons.wb_sunny, "Season-Based Filtering",
                              seasonBasedFiltering, (val) {
                                setState(() => seasonBasedFiltering = val);
                                _updatePreference('seasonBasedFiltering', val);
                              }, w),

                          SizedBox(height: 24 * h),

                          _sectionTitle("NOTIFICATIONS", w),
                          _toggleTile(Icons.checkroom, "Outfit Suggestions",
                              outfitSuggestions, (val) {
                                setState(() => outfitSuggestions = val);
                                _updatePreference('outfitSuggestions', val);
                              }, w),
                          _toggleTile(Icons.shopping_bag, "Shopping Recommendations",
                              shoppingRecommendations, (val) {
                                setState(() => shoppingRecommendations = val);
                                _updatePreference('shoppingRecommendations', val);
                              }, w),

                          SizedBox(height: 24 * h),

                          _sectionTitle("PRIVACY AND SECURITY", w),
                          _iconTile(Icons.shield, "Manage Permissions", w, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ManagePermissionsScreen()),
                            );
                          }),

                          SizedBox(height: 24 * h),

                          _sectionTitle("ABOUT APP", w),
                          _iconTile(Icons.book, "Terms of Use", w, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TermsOfUseScreen()),
                            );
                          }),
                          _iconTile(Icons.warning_amber_outlined, "About App", w,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AboutUsScreen()),
                                );
                              }),
                          _iconTile(Icons.smart_toy_outlined, "User Support", w,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const SmartAssistantWelcomeScreen()),
                                );
                              }),

                          SizedBox(height: 24 * h),

                          ElevatedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text(
                              "Logout",
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
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
                          SizedBox(height: 16 * h),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 60 * h,
                  left: 0,
                  right: 0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 16 * w,
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WardrobeHomeScreen()),
                            );
                          },
                          icon: Image.asset(
                            "assets/images/white_back_btn.png",
                            height: 30 * w,
                            width: 30 * w,
                          ),
                        ),
                      ),
                      Text(
                        "Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20 * w,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, double w) => Padding(
    padding: EdgeInsets.only(bottom: 10 * w),
    child: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14 * w,
        color: Colors.grey[700],
      ),
    ),
  );

  Widget _iconTile(IconData icon, String title, double w, {VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16 * w),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6 * w),
          padding: EdgeInsets.symmetric(vertical: 14 * w, horizontal: 16 * w),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16 * w),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20 * w, color: Colors.black),
              SizedBox(width: 16 * w),
              Expanded(child: Text(title, style: TextStyle(fontSize: 14 * w))),
              Icon(Icons.arrow_forward_ios, size: 14 * w),
            ],
          ),
        ),
      );

  Widget _toggleTile(
      IconData icon, String title, bool value, Function(bool) onChanged, double w) =>
      Container(
        margin: EdgeInsets.symmetric(vertical: 6 * w),
        padding: EdgeInsets.symmetric(vertical: 10 * w, horizontal: 16 * w),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16 * w),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20 * w, color: Colors.black),
            SizedBox(width: 16 * w),
            Expanded(child: Text(title, style: TextStyle(fontSize: 14 * w))),
            Switch(value: value, onChanged: onChanged, activeColor: Colors.pink),
          ],
        ),
      );

  Future<void> _confirmDeleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 60, color: Colors.pink),
              const SizedBox(height: 15),
              const Text(
                "Delete Profile?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to permanently delete your account? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Cancel",
                        style:
                        TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Delete",
                        style:
                        TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
          await user.delete();

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WriterLoginScreen()),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting profile: $e")),
        );
      }
    }
  }
}
