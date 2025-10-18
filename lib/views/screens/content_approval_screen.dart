import 'dart:convert'; // for base64Decode
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/color_utils.dart';
import '../widgets/content_card.dart';
import 'dashboard_screen.dart';

class ContentApprovalScreen extends StatefulWidget {
  const ContentApprovalScreen({super.key});

  @override
  State<ContentApprovalScreen> createState() => _ContentApprovalScreenState();
}

class _ContentApprovalScreenState extends State<ContentApprovalScreen> {
  int selectedFilterIndex = 0;
  bool showAcceptanceOverlay = false;
  bool showRejectionDialog = false;
  String rejectionReason = '';
  DocumentReference? selectedDocRef; // Changed from String? to DocumentReference?

  final List<String> filterTabs = [
    'pending',
    'approved',
    'rejected',
  ];

  void _onFilterTapped(int index) {
    setState(() {
      selectedFilterIndex = index;
    });
  }

  Future<void> _acceptContent(DocumentReference docRef) async {
    print('Attempting to update document at path: ${docRef.path}');
    print('Current user UID: ${FirebaseAuth.instance.currentUser?.uid}');
    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    print('Is current user admin? ${adminDoc.exists}');
    print('Logged in email: ${FirebaseAuth.instance.currentUser?.email}');
    print('Logged in UID: ${FirebaseAuth.instance.currentUser?.uid}');

    try {
      await docRef.update({'status': 'approved'});
      _showAcceptanceOverlay();
    } catch (e, stacktrace) {
      print('Firestore update error: $e');
      print(stacktrace);
      Get.snackbar('Error', 'Failed to accept content: $e',
          backgroundColor: AppColors.error, colorText: AppColors.textWhite);
    }
  }



  void _showAcceptanceOverlay() {
    setState(() {
      showAcceptanceOverlay = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showAcceptanceOverlay = false;
        });
      }
    });
  }

  void _showRejectionDialog(DocumentReference docRef) {
    setState(() {
      selectedDocRef = docRef;
      showRejectionDialog = true;
    });
  }

  void _hideRejectionDialog() {
    setState(() {
      showRejectionDialog = false;
      rejectionReason = '';
      selectedDocRef = null;
    });
  }

  Future<void> _submitRejection() async {
    if (rejectionReason.trim().isNotEmpty && selectedDocRef != null) {
      try {
        await selectedDocRef!.update({
          'status': 'rejected',
          'rejectionReason': rejectionReason.trim(),
        });
        Get.snackbar(
          'Content Rejected',
          'Content has been rejected with reason: $rejectionReason',
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
        );
        _hideRejectionDialog();
      } catch (e) {
        Get.snackbar('Error', 'Failed to reject content: $e',
            backgroundColor: AppColors.error, colorText: AppColors.textWhite);
      }
    } else {
      Get.snackbar(
        'Error',
        'Please enter a rejection reason',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.offAll(() => const DashboardScreen());
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Content Management',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.whiteHeading,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Get.snackbar(
                            'Search',
                            'Search functionality coming soon!',
                            backgroundColor: AppColors.primary,
                            colorText: AppColors.textWhite,
                          );
                        },
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.textWhite,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Get.snackbar(
                            'Filter',
                            'Filter options coming soon!',
                            backgroundColor: AppColors.primary,
                            colorText: AppColors.textWhite,
                          );
                        },
                        icon: const Icon(
                          Icons.filter_list,
                          color: AppColors.textWhite,
                        ),
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
                    child: Column(
                      children: [
                        // Filter Tabs
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: filterTabs.asMap().entries.map((entry) {
                              int index = entry.key;
                              String label = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < filterTabs.length - 1 ? 16 : 0,
                                ),
                                child: _buildFilterTab(
                                  label[0].toUpperCase() + label.substring(1),
                                  selectedFilterIndex == index,
                                      () => _onFilterTapped(index),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Sort By Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                'Sort by:',
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'Date Submitted',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Content List from Firestore
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collectionGroup('articles')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final allDocs = snapshot.data!.docs;

                              // Filter by status
                              final filteredDocs = allDocs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final status = data['status'] as String?;
                                return status == filterTabs[selectedFilterIndex];
                              }).toList();

                              if (filteredDocs.isEmpty) {
                                return const Center(child: Text('No articles found.'));
                              }

                              return ListView.separated(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredDocs.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final articleDoc = filteredDocs[index];
                                  final data =
                                  articleDoc.data() as Map<String, dynamic>;

                                  final String? base64Image =
                                  data['mediaBase64'] as String?;
                                  final Uint8List? imageBytes =
                                  base64Image != null
                                      ? base64Decode(base64Image)
                                      : null;

                                  // Get article timestamp
                                  final String articleDate = data['timestamp'] != null
                                      ? (data['timestamp'] as Timestamp)
                                      .toDate()
                                      .toString()
                                      : '';

                                  // Get reference to the parent user document
                                  final userRef = articleDoc.reference.parent.parent;

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: userRef?.get(),
                                    builder: (context, userSnapshot) {
                                      if (!userSnapshot.hasData) {
                                        return const SizedBox(); // Placeholder
                                      }
                                      final userData =
                                      userSnapshot.data!.data() as Map<String, dynamic>;
                                      final String authorName = userData['name'] ?? '';
                                      final String? profileBase64 =
                                      userData['image_base64'];
                                      final Uint8List? profileImageBytes =
                                      profileBase64 != null
                                          ? base64Decode(profileBase64)
                                          : null;

                                      return ContentCard(
                                        title: data['title'] ?? '',
                                        author: authorName,
                                        authorImageBytes: profileImageBytes,
                                        date: articleDate,
                                        imageBytes: imageBytes,
                                        onAccept: () =>
                                            _acceptContent(articleDoc.reference),
                                        onReject: () =>
                                            _showRejectionDialog(articleDoc.reference),
                                        onView: () {},
                                        content: data['content'] ?? '',
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Acceptance Overlay
          if (showAcceptanceOverlay)
            Container(
              color: ColorUtils.withOpacity(Colors.black, 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.textWhite,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Content accepted successfully',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Rejection Dialog
          if (showRejectionDialog)
            Container(
              color: ColorUtils.withOpacity(Colors.black, 0.7),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Reason for Rejection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter rejection reason...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            rejectionReason = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _hideRejectionDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.cardBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitRejection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Submit'),
                            ),
                          ),
                        ],
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

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
