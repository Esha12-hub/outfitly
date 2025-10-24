import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid; // User UID
  final String name;
  final String email;
  final String role;
  final String status;
  final Color avatarColor;
  final IconData? avatarIcon;

  const UserProfileScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.avatarColor,
    this.avatarIcon,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<String>> wardrobeItems = {};
  int totalArticles = 0;
  bool _isLoadingMetric = true;
  late String _status;
  ImageProvider? profileImage;

  @override
  void initState() {
    super.initState();
    _status = widget.status.toLowerCase();
    fetchProfileImage();
    if (widget.role.toLowerCase() == 'content writer') {
      fetchTotalArticles();
    } else {
      fetchWardrobeItems();
    }
  }

  Future<void> fetchProfileImage() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.uid).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final imageBase64 = data['image_base64'];
      final imageUrl = data['imageUrl'];
      final photoUrl = data['photoUrl'];

      ImageProvider? fetchedImage;

      if (imageBase64 != null && imageBase64.toString().isNotEmpty) {
        try {
          final bytes = base64Decode(imageBase64.toString().split(',').last);
          fetchedImage = MemoryImage(bytes);
        } catch (_) {
          fetchedImage = null;
        }
      } else if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        fetchedImage = NetworkImage(imageUrl);
      } else if (photoUrl != null && photoUrl.toString().isNotEmpty) {
        fetchedImage = NetworkImage(photoUrl);
      }

      setState(() => profileImage = fetchedImage);
    } catch (e) {
      debugPrint('Error fetching profile image: $e');
    }
  }

  Future<void> fetchWardrobeItems() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('wardrobe')
          .get();

      Map<String, List<String>> fetched = {};
      for (var doc in snapshot.docs) {
        final category = doc['category'] ?? 'Uncategorized';
        final itemName = doc['item_name'] ?? '';
        if (fetched.containsKey(category)) {
          fetched[category]!.add(itemName);
        } else {
          fetched[category] = [itemName];
        }
      }

      setState(() {
        wardrobeItems = fetched;
        _isLoadingMetric = false;
      });
    } catch (e) {
      debugPrint('Error fetching wardrobe items: $e');
      setState(() => _isLoadingMetric = false);
    }
  }

  Future<void> fetchTotalArticles() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('articles')
          .get();

      setState(() {
        totalArticles = snapshot.docs.length;
        _isLoadingMetric = false;
      });
    } catch (e) {
      debugPrint('Error fetching articles: $e');
      setState(() => _isLoadingMetric = false);
    }
  }

  Future<void> _updateUserStatus(String newStatus) async {
    try {
      await _firestore.collection('users').doc(widget.uid).update({'status': newStatus});
      setState(() {
        _status = newStatus.toLowerCase();
      });
      _showMessage('User status updated to $newStatus');
    } catch (e) {
      _showMessage('Failed to update status: $e');
    }
  }

  Future<void> _deleteUser() async {
    try {
      await _firestore.collection('users').doc(widget.uid).delete();
      _showMessage('User deleted successfully');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to delete user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final totalWardrobeItems = wardrobeItems.values.fold(0, (prev, list) => prev + list.length);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset(
                      'assets/images/white_back_btn.png',
                      width: screenWidth * 0.07,
                      height: screenWidth * 0.07,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'User Profile',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading.copyWith(fontSize: screenWidth * 0.05),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        // Just rebuild to refresh the stream
                      });
                    },
                    icon: const Icon(Icons.refresh, color: AppColors.textWhite),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoCard(totalWardrobeItems, screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.03),
                      _buildActionButtons(),
                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(int totalItems, double screenWidth, double screenHeight) {
    final isContentWriter = widget.role.toLowerCase() == 'content writer';
    final metricValue = isContentWriter ? totalArticles.toString() : totalItems.toString();
    final metricLabel = isContentWriter ? 'Articles' : 'Wardrobe Items';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: screenWidth * 0.15,
            backgroundColor: widget.avatarColor.withOpacity(0.3),
            backgroundImage: profileImage, // ✅ Display fetched image
            child: profileImage == null
                ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.avatarColor, width: 3),
              ),
              child: CircleAvatar(
                radius: screenWidth * 0.143,
                backgroundColor: widget.avatarColor,
                child: Icon(widget.avatarIcon ?? Icons.person,
                    color: Colors.white, size: screenWidth * 0.1),
              ),
            )
                : null,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(widget.name,
              style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          SizedBox(height: screenHeight * 0.005),
          Text(widget.email,
              style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey[600])),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusChip(widget.role, screenWidth),
              SizedBox(width: screenWidth * 0.02),
              _buildStatusChip(_status, screenWidth),
            ],
          ),
          SizedBox(height: screenHeight * 0.03),
          _isLoadingMetric
              ? const CircularProgressIndicator()
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMetric(metricValue, metricLabel, screenWidth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
              color: Colors.black87)),
    );
  }

  Widget _buildMetric(String value, String label, double screenWidth) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color backgroundColor, Color textColor,
      VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: textColor),
        label: Text(text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_status == 'blocked') {
      return Column(
        children: [
          _buildActionButton('Unblock User', Icons.lock_open, Colors.grey[200]!,
              Colors.black, () => _updateUserStatus('Active')),
          const SizedBox(height: 12),
          _buildActionButton('Delete Account', Icons.delete, Colors.pink, Colors.white,
              _deleteUser),
        ],
      );
    } else {
      return Column(
        children: [
          _buildActionButton('Block User', Icons.block, Colors.grey[200]!,
              Colors.black87, () => _updateUserStatus('Blocked')),
          const SizedBox(height: 12),
          _buildActionButton('Delete Account', Icons.delete, Colors.pink, Colors.white,
              _deleteUser),
        ],
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
