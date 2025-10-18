import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class ManagePermissionsScreen extends StatefulWidget {
  const ManagePermissionsScreen({super.key});

  @override
  State<ManagePermissionsScreen> createState() => _ManagePermissionsScreenState();
}

class _ManagePermissionsScreenState extends State<ManagePermissionsScreen> {
  final Map<String, bool> _permissions = {
    'Camera Access': true,
    'Photo Library': true,
    'Location Services': false,
    'Push Notifications': true,
    'Microphone': false,
    'Contacts': false,
    'Calendar': false,
    'Health Data': false,
    'Biometric Authentication': true,
    'Analytics & Crash Reports': true,
  };

  final Map<String, String> _permissionDescriptions = {
    'Camera Access': 'Take photos of your outfits and items',
    'Photo Library': 'Access your existing photos for wardrobe',
    'Location Services': 'Get location-based fashion recommendations',
    'Push Notifications': 'Receive updates about new features and trends',
    'Microphone': 'Voice commands for hands-free navigation',
    'Contacts': 'Share outfits with friends and family',
    'Calendar': 'Plan outfits for upcoming events',
    'Health Data': 'Track fitness and wellness goals',
    'Biometric Authentication': 'Secure login with fingerprint or face ID',
    'Analytics & Crash Reports': 'Help improve app performance',
  };

  final Map<String, IconData> _permissionIcons = {
    'Camera Access': Icons.camera_alt,
    'Photo Library': Icons.photo_library,
    'Location Services': Icons.location_on,
    'Push Notifications': Icons.notifications,
    'Microphone': Icons.mic,
    'Contacts': Icons.contacts,
    'Calendar': Icons.calendar_today,
    'Health Data': Icons.favorite,
    'Biometric Authentication': Icons.fingerprint,
    'Analytics & Crash Reports': Icons.analytics,
  };

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Manage Permissions',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'App Permissions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Control what information and features the app can access on your device.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Permissions List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _permissions.length,
                        itemBuilder: (context, index) {
                          final permission = _permissions.keys.elementAt(index);
                          final isEnabled = _permissions[permission]!;
                          final description = _permissionDescriptions[permission]!;
                          final icon = _permissionIcons[permission]!;

                          return _buildPermissionCard(
                            permission,
                            description,
                            icon,
                            isEnabled,
                            (value) => _togglePermission(permission, value),
                          );
                        },
                      ),
                    ),

                    // Bottom Action Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _savePermissions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Save Permissions',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _resetToDefaults,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Reset to Defaults',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    String permission,
    String description,
    IconData icon,
    bool isEnabled,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? AppColors.primary.withOpacity(0.3) : Colors.grey[300]!,
          width: isEnabled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isEnabled ? AppColors.primary : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  void _togglePermission(String permission, bool value) {
    setState(() {
      _permissions[permission] = value;
    });

    Get.snackbar(
      value ? 'Permission Enabled' : 'Permission Disabled',
      '$permission has been ${value ? 'enabled' : 'disabled'}.',
      backgroundColor: value ? AppColors.success : Colors.orange,
      colorText: AppColors.textWhite,
      duration: const Duration(seconds: 2),
    );
  }

  void _savePermissions() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    Get.snackbar(
      'Permissions Saved',
      'Your permission settings have been saved successfully!',
      backgroundColor: AppColors.success,
      colorText: AppColors.textWhite,
    );
  }

  void _resetToDefaults() {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Permissions'),
        content: const Text(
          'Are you sure you want to reset all permissions to their default settings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              setState(() {
                _permissions['Camera Access'] = true;
                _permissions['Photo Library'] = true;
                _permissions['Location Services'] = false;
                _permissions['Push Notifications'] = true;
                _permissions['Microphone'] = false;
                _permissions['Contacts'] = false;
                _permissions['Calendar'] = false;
                _permissions['Health Data'] = false;
                _permissions['Biometric Authentication'] = true;
                _permissions['Analytics & Crash Reports'] = true;
              });
              Get.snackbar(
                'Permissions Reset',
                'All permissions have been reset to default settings.',
                backgroundColor: AppColors.success,
                colorText: AppColors.textWhite,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}