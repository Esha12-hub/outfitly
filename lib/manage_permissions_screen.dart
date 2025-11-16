import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagePermissionsScreen extends StatefulWidget {
  @override
  _ManagePermissionsScreenState createState() =>
      _ManagePermissionsScreenState();
}

class _ManagePermissionsScreenState extends State<ManagePermissionsScreen> {
  bool cameraAccess = false;
  bool mediaStorage = true;
  bool notifications = true;
  bool locationAccess = false;
  bool microphoneAccess = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cameraAccess = prefs.getBool('cameraAccess') ?? false;
      mediaStorage = prefs.getBool('mediaStorage') ?? true;
      notifications = prefs.getBool('notifications') ?? true;
      locationAccess = prefs.getBool('locationAccess') ?? false;
      microphoneAccess = prefs.getBool('microphoneAccess') ?? true;
    });
  }

  Future<void> _savePermissionStatus(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: height * 0.06),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Image.asset(
                    "assets/images/white_back_btn.png",
                    height: 30,
                    width: 30,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Manage Permissions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: height * 0.02),
              padding: EdgeInsets.all(width * 0.04),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(28),
                  topLeft: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PERMISSIONS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: height * 0.015),

                    _permissionTile(
                      icon: Icons.camera_alt,
                      title: "Camera Access",
                      subtitle:
                      "Allow app to use your camera for taking pictures.",
                      value: cameraAccess,
                      onChanged: (val) async {
                        setState(() => cameraAccess = val);
                        await _savePermissionStatus('cameraAccess', val);
                      },
                    ),

                    _permissionTile(
                      icon: Icons.sd_storage,
                      title: "Media & Storage",
                      subtitle: "Access your gallery to upload wardrobe items.",
                      value: mediaStorage,
                      onChanged: (val) async {
                        setState(() => mediaStorage = val);
                        await _savePermissionStatus('mediaStorage', val);
                      },
                    ),

                    _permissionTile(
                      icon: Icons.notifications,
                      title: "Notifications",
                      subtitle:
                      "Get updates for outfit suggestions and reminders.",
                      value: notifications,
                      onChanged: (val) async {
                        setState(() => notifications = val);
                        await _savePermissionStatus('notifications', val);
                      },
                    ),

                    _permissionTile(
                      icon: Icons.mic,
                      title: "Microphone Access",
                      subtitle: "Enable voice commands for your AI Assistant.",
                      value: microphoneAccess,
                      onChanged: (val) async {
                        setState(() => microphoneAccess = val);
                        await _savePermissionStatus('microphoneAccess', val);
                      },
                    ),

                    SizedBox(height: height * 0.05),
                    Center(
                      child: Text(
                        "Version 1.1.1",
                        style: TextStyle(color: Colors.black54, fontSize: width * 0.035),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) => onChanged(val),
            activeColor: Colors.pink,
          ),
        ],
      ),
    );
  }
}
