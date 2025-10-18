import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'writer_login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about_us_screen.dart';
import 'writer_terms.dart';
import 'writer_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool feedbackNotifications = false;
  bool submissionAlerts = true;
  bool twoFactorAuth = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  /// Load saved notification states
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      feedbackNotifications = prefs.getBool('feedbackNotifications') ?? false;
      submissionAlerts = prefs.getBool('submissionAlerts') ?? true;
      twoFactorAuth = prefs.getBool('twoFactorAuth') ?? true;
    });
  }

  /// Save specific notification setting
  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  children: [
                    _buildSearchBar(),
                    _buildUserProfileTile(),
                    const SizedBox(height: 20),

                    /// Account Section
                    _buildSectionTitle('ACCOUNT SETTINGS'),
                    _buildTile(Icons.email, 'Email/Phone Number Details'),
                    _buildTile(Icons.lock, 'Change Password'),
                    _buildTile(Icons.delete, 'Delete Profile', onTap: _confirmDeleteProfile),
                    const SizedBox(height: 20),

                    /// Notifications
                    _buildSectionTitle('NOTIFICATIONS'),
                    _buildToggleTile(Icons.feedback, 'Feedback Notifications', feedbackNotifications, (val) {
                      setState(() => feedbackNotifications = val);
                      _saveNotificationSetting('feedbackNotifications', val);
                    }),
                    _buildToggleTile(Icons.notifications_active, 'Submission Alerts', submissionAlerts, (val) {
                      setState(() => submissionAlerts = val);
                      _saveNotificationSetting('submissionAlerts', val);
                    }),
                    const SizedBox(height: 20),


                    /// About
                    _buildSectionTitle('ABOUT APP'),
                    _buildTile(Icons.menu_book, 'Terms of Use', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WriterTermsOfUseScreen()),
                      );
                    }),
                    _buildTile(Icons.info_outline, 'About App', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                      );
                    }),


                    /// Logout
                    const SizedBox(height: 5),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _confirmLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white, // White icon
                        ),
                        label: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white, // White text
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD71D5C), // Pink background
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded corners
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        "Version 1.1.1",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ------------------ UI COMPONENTS ------------------ ///

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const Center(
            child: Text(
              "Settings",
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search),
          hintText: "Search...",
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUserProfileTile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("User data not found");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'User Name';
        final role = data['role'] ?? 'Writer';
        final imageBase64 = data['image_base64'];

        // Profile picture
        Widget avatar;
        if (imageBase64 != null && imageBase64.isNotEmpty) {
          try {
            final bytes = base64Decode(imageBase64.split(',').last);
            avatar = CircleAvatar(radius: 26, backgroundImage: MemoryImage(bytes));
          } catch (_) {
            avatar = _buildFallbackAvatar(name);
          }
        } else {
          avatar = _buildFallbackAvatar(name);
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WriterProfileScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(role, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildFallbackAvatar(String name) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.grey.shade400,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.black),
        title: Text(title),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.pink,
      ),
    );
  }

  /// ------------------ DELETE PROFILE ------------------ ///
  Future<void> _confirmDeleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Profile"),
        content: const Text("Are you sure you want to permanently delete your account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Delete")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();
        await user.delete();

        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const WriterLoginScreen()));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting profile: $e")));
      }
    }
  }

  /// ------------------ LOGOUT ------------------ ///
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
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
            child: const Text(
              "No",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
        );
      }
    }
  }
}
