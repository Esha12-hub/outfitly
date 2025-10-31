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
import 'writer_change_password.dart';
import 'change_name_screen.dart';
import 'change_profile_img.dart';

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

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      feedbackNotifications = prefs.getBool('feedbackNotifications') ?? false;
      submissionAlerts = prefs.getBool('submissionAlerts') ?? true;
      twoFactorAuth = prefs.getBool('twoFactorAuth') ?? true;
    });
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final fontSize = screenWidth * 0.045;
    final padding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildAppBar(screenWidth, fontSize),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(padding),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildUserProfileTile(fontSize),
                                  SizedBox(height: screenHeight * 0.02),

                                  /// ACCOUNT SETTINGS
                                  _buildSectionTitle('ACCOUNT SETTINGS', fontSize),
                                  Padding(
                                    padding: EdgeInsets.only(left: fontSize * 0.2),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildTile(Icons.person, 'Change Username', fontSize, onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const ChangeNameScreen()),
                                          );
                                        }),
                                        _buildTile(Icons.image, 'Change Profile Image', fontSize, onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const ChangeProfileImageScreen()),
                                          );
                                        }),
                                        _buildTile(Icons.lock, 'Change Password', fontSize, onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const WriterChangePasswordScreen()),
                                          );
                                        }),
                                        _buildTile(Icons.delete, 'Delete Profile', fontSize, onTap: _confirmDeleteProfile),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),

                                  /// NOTIFICATIONS
                                  _buildSectionTitle('NOTIFICATIONS', fontSize),
                                  Padding(
                                    padding: EdgeInsets.only(left: fontSize * 0.2),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildToggleTile(Icons.feedback, 'Feedback Notifications', feedbackNotifications, fontSize, (val) {
                                          setState(() => feedbackNotifications = val);
                                          _saveNotificationSetting('feedbackNotifications', val);
                                        }),
                                        _buildToggleTile(Icons.notifications_active, 'Submission Alerts', submissionAlerts, fontSize, (val) {
                                          setState(() => submissionAlerts = val);
                                          _saveNotificationSetting('submissionAlerts', val);
                                        }),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),

                                  /// ABOUT
                                  _buildSectionTitle('ABOUT APP', fontSize),
                                  Padding(
                                    padding: EdgeInsets.only(left: fontSize * 0.2),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildTile(Icons.menu_book, 'Terms of Use', fontSize, onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const WriterTermsOfUseScreen()),
                                          );
                                        }),
                                        _buildTile(Icons.info_outline, 'About App', fontSize, onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),

                                  /// LOGOUT BUTTON
                                  Center(
                                    child: Container(
                                      width: screenWidth * 0.6,
                                      margin: EdgeInsets.only(top: screenHeight * 0.02),
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.pink,
                                          padding: EdgeInsets.symmetric(vertical: fontSize * 0.5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        onPressed: _confirmLogout,
                                        icon: Icon(Icons.logout, color: Colors.white, size: fontSize * 0.9),
                                        label: Text(
                                          'Logout',
                                          style: TextStyle(
                                            fontSize: fontSize * 0.9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(double width, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.07),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset('assets/images/white_back_btn.png', width: fontSize * 1.5, height: fontSize * 1.5),
            ),
          ),
          Center(
            child: Text(
              "Settings",
              style: TextStyle(fontSize: fontSize * 1.1, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileTile(double fontSize) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String name = user.displayName ?? 'User Name';
        String role = 'Writer';
        String? imageBase64;
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          role = data['role'] ?? role;
          imageBase64 = data['image_base64'];
        }

        photoUrl = user.photoURL;

        Widget avatar;

        if (imageBase64 != null && imageBase64.isNotEmpty) {
          try {
            final bytes = base64Decode(imageBase64.split(',').last);
            avatar = CircleAvatar(radius: fontSize * 1.3, backgroundImage: MemoryImage(bytes));
          } catch (_) {
            avatar = _buildFallbackAvatar(name, fontSize);
          }
        } else if (photoUrl != null && photoUrl.isNotEmpty) {
          avatar = CircleAvatar(radius: fontSize * 1.3, backgroundImage: NetworkImage(photoUrl));
        } else {
          avatar = _buildFallbackAvatar(name, fontSize);
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const WriterProfileScreen()));
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                avatar,
                SizedBox(width: fontSize),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                    SizedBox(height: fontSize * 0.3),
                    Text(role, style: TextStyle(fontSize: fontSize * 0.8, color: Colors.black54)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: fontSize * 0.8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackAvatar(String name, double fontSize) {
    return CircleAvatar(
      radius: fontSize * 1.3,
      backgroundColor: Colors.grey.shade400,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: fontSize)),
    );
  }

  Widget _buildSectionTitle(String title, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(bottom: fontSize * 0.5),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize * 0.9)),
    );
  }

  Widget _buildTile(IconData icon, String title, double fontSize, {VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: fontSize * 0.8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black, size: fontSize),
        title: Text(title, style: TextStyle(fontSize: fontSize * 0.9)),
        trailing: Icon(Icons.arrow_forward_ios, size: fontSize * 0.7),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, bool value, double fontSize, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: fontSize * 0.8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.black, size: fontSize),
        title: Text(title, style: TextStyle(fontSize: fontSize * 0.9)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.pink,
      ),
    );
  }

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
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();
        await user.delete();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting profile: $e")),
        );
      }
    }
  }

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
