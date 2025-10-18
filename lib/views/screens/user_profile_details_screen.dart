import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class UserProfileDetailsScreen extends StatefulWidget {
  const UserProfileDetailsScreen({super.key});

  @override
  State<UserProfileDetailsScreen> createState() => _UserProfileDetailsScreenState();
}

class _UserProfileDetailsScreenState extends State<UserProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'John Doe');
  final _emailController = TextEditingController(text: 'john.doe@example.com');
  final _phoneController = TextEditingController(text: '+1 (555) 123-4567');
  final _bioController = TextEditingController(text: 'Fashion enthusiast and style lover');
  final _locationController = TextEditingController(text: 'New York, NY');
  final _websiteController = TextEditingController(text: 'https://johndoe.com');
  
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

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
                      'Profile Details',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleEditMode,
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: AppColors.textWhite,
                    ),
                  ),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.blue[400],
                                    child: const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isEditing)
                                TextButton(
                                  onPressed: _changeProfilePicture,
                                  child: const Text(
                                    'Change Profile Picture',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Personal Information Section
                        _buildSectionTitle('Personal Information'),
                        const SizedBox(height: 16),
                        _buildFormField(
                          'Full Name',
                          _nameController,
                          Icons.person,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          'Email Address',
                          _emailController,
                          Icons.email,
                          enabled: _isEditing,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          'Phone Number',
                          _phoneController,
                          Icons.phone,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),

                        // Additional Information Section
                        _buildSectionTitle('Additional Information'),
                        const SizedBox(height: 16),
                        _buildFormField(
                          'Bio',
                          _bioController,
                          Icons.info,
                          enabled: _isEditing,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          'Location',
                          _locationController,
                          Icons.location_on,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          'Website',
                          _websiteController,
                          Icons.link,
                          enabled: _isEditing,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 32),

                        // Account Information Section
                        _buildSectionTitle('Account Information'),
                        const SizedBox(height: 16),
                        _buildInfoCard('Account Type', 'Premium User', Icons.star),
                        const SizedBox(height: 8),
                        _buildInfoCard('Member Since', 'January 2024', Icons.calendar_today),
                        const SizedBox(height: 8),
                        _buildInfoCard('Last Login', '2 hours ago', Icons.access_time),
                        const SizedBox(height: 32),

                        // Action Buttons
                        if (_isEditing) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
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
                                      'Save Changes',
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
                              onPressed: _cancelEdit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Email Address' && !GetUtils.isEmail(value)) {
          return 'Please enter a valid email';
        }
        if (label == 'Website' && value.isNotEmpty && !GetUtils.isURL(value)) {
          return 'Please enter a valid URL';
        }
        return null;
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _changeProfilePicture() {
    Get.snackbar(
      'Profile Picture',
      'Profile picture change functionality coming soon!',
      backgroundColor: AppColors.primary,
      colorText: AppColors.textWhite,
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    Get.snackbar(
      'Profile Updated',
      'Your profile has been updated successfully!',
      backgroundColor: AppColors.success,
      colorText: AppColors.textWhite,
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
  }
}