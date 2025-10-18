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

  // Load saved permission states
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

  // Save permission state locally
  Future<void> _savePermissionStatus(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 50),
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
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 40),
                  child: Text(
                    'Manage Permissions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(28),
                  topLeft: Radius.circular(28),
                ),
              ),
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
                  const SizedBox(height: 12),

                  // Camera Access
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

                  // Media & Storage
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

                  // Notifications
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


                  // Microphone Access
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

                  const Spacer(),
                  const Center(
                    child: Text(
                      "Version 1.1.1",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Permission switch tile
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
