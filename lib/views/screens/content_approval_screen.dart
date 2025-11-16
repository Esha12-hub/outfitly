import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/color_utils.dart';
import '../widgets/content_card.dart';
import 'admin_login_screen.dart';

class ContentApprovalScreen extends StatefulWidget {
  const ContentApprovalScreen({super.key});

  @override
  State<ContentApprovalScreen> createState() => _ContentApprovalScreenState();
}

enum SortOption { newestFirst, oldestFirst }

class _ContentApprovalScreenState extends State<ContentApprovalScreen> {
  int selectedFilterIndex = 0;
  bool showAcceptanceOverlay = false;
  bool showRejectionDialog = false;
  bool showSearchBar = false;
  String rejectionReason = '';
  String searchQuery = '';
  DocumentReference? selectedDocRef;
  SortOption selectedSortOption = SortOption.newestFirst;
  final TextEditingController searchController = TextEditingController();
  final List<String> filterTabs = ['pending', 'approved', 'rejected'];

  QuerySnapshot? lastSnapshot;
  final Map<String, Map<String, dynamic>> userCache = {};

  void _onFilterTapped(int index) {
    setState(() => selectedFilterIndex = index);
  }

  void _toggleSearchBar() {
    setState(() {
      showSearchBar = !showSearchBar;
      if (!showSearchBar) {
        searchQuery = '';
        searchController.clear();
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() => searchQuery = value.trim().toLowerCase());
  }

  Future<void> _acceptContent(DocumentReference docRef) async {
    try {
      await docRef.update({'status': 'approved'});
      _showAcceptanceOverlay();
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept content: $e',
          backgroundColor: AppColors.error, colorText: AppColors.textWhite);
    }
  }

  void _showAcceptanceOverlay() {
    setState(() => showAcceptanceOverlay = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => showAcceptanceOverlay = false);
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
    if (rejectionReason.trim().isEmpty || selectedDocRef == null) {
      Get.snackbar(
        'Error',
        'Please enter a rejection reason',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      return;
    }

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
  }

  Future<Map<String, dynamic>?> _getUserData(DocumentReference? ref) async {
    if (ref == null) return null;
    if (userCache.containsKey(ref.id)) return userCache[ref.id];

    final snapshot = await ref.get();
    if (snapshot.exists) {
      userCache[ref.id] = snapshot.data() as Map<String, dynamic>;
      return userCache[ref.id];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _handleLogout,
                        icon: Image.asset('assets/images/white_back_btn.png', width: 28, height: 28),
                      ),
                      Expanded(
                        child: Text(
                          'Content Management',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.whiteHeading.copyWith(fontSize: width * 0.05),
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleSearchBar,
                        icon: const Icon(Icons.search, color: AppColors.textWhite),
                      ),
                    ],
                  ),
                ),

                if (showSearchBar)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    child: TextField(
                      controller: searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search articles...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: showSearchBar ? height * 0.015 : 0),
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
                        SizedBox(height: 10),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                          child: Row(
                            children: filterTabs.asMap().entries.map((entry) {
                              int index = entry.key;
                              String label = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(right: index < filterTabs.length - 1 ? width * 0.03 : 0),
                                child: _buildFilterTab(
                                  label[0].toUpperCase() + label.substring(1),
                                  selectedFilterIndex == index,
                                      () => _onFilterTapped(index),
                                  width,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        SizedBox(height: height * 0.02),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                          child: Row(
                            children: [
                              const Text('Sort by:', style: AppTextStyles.bodyMedium),
                              SizedBox(width: width * 0.02),
                              DropdownButton<SortOption>(
                                value: selectedSortOption,
                                dropdownColor: AppColors.surface,
                                underline: Container(),
                                items: const [
                                  DropdownMenuItem(
                                      value: SortOption.newestFirst, child: Text('Newest First')),
                                  DropdownMenuItem(
                                      value: SortOption.oldestFirst, child: Text('Oldest First')),
                                ],
                                onChanged: (SortOption? newValue) {
                                  if (newValue != null) {
                                    setState(() => selectedSortOption = newValue);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: height * 0.02),

                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collectionGroup('articles')
                                .orderBy('timestamp',
                                descending:
                                selectedSortOption == SortOption.newestFirst)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) lastSnapshot = snapshot.data;

                              final docs = snapshot.hasData
                                  ? snapshot.data!.docs
                                  : lastSnapshot?.docs ?? [];

                              final filteredDocs = docs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final status = data['status'] as String?;
                                final title = (data['title'] ?? '').toString().toLowerCase();
                                final matchesStatus = status == filterTabs[selectedFilterIndex];
                                final matchesSearch = searchQuery.isEmpty || title.contains(searchQuery);
                                return matchesStatus && matchesSearch;
                              }).toList();

                              if (filteredDocs.isEmpty) return const Center(child: Text('No articles found.'));

                              return ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                                itemCount: filteredDocs.length,
                                separatorBuilder: (_, __) => SizedBox(height: height * 0.02),
                                itemBuilder: (context, index) {
                                  final articleDoc = filteredDocs[index];
                                  final data = articleDoc.data() as Map<String, dynamic>;

                                  final imageBytes = data['mediaBase64'] != null
                                      ? base64Decode(data['mediaBase64'])
                                      : null;
                                  final articleDate = data['timestamp'] != null
                                      ? (data['timestamp'] as Timestamp).toDate().toString()
                                      : '';

                                  final userRef = articleDoc.reference.parent.parent;

                                  return FutureBuilder<Map<String, dynamic>?>(
                                    future: _getUserData(userRef),
                                    builder: (context, userSnapshot) {
                                      final userData = userSnapshot.data;
                                      final authorName = userData?['name'] ?? 'Unknown';
                                      final profileImageBytes = userData?['image_base64'] != null
                                          ? base64Decode(userData!['image_base64'])
                                          : null;

                                      return ContentCard(
                                        title: data['title'] ?? '',
                                        author: authorName,
                                        authorImageBytes: profileImageBytes,
                                        date: articleDate,
                                        imageBytes: imageBytes,
                                        onAccept: () => _acceptContent(articleDoc.reference),
                                        onReject: () => _showRejectionDialog(articleDoc.reference),
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

          if (showAcceptanceOverlay)
            Container(
              color: ColorUtils.withOpacity(Colors.black, 0.7),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(width * 0.08),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(width * 0.04),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: width * 0.18,
                        height: width * 0.18,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: AppColors.textWhite, size: 40),
                      ),
                      SizedBox(height: height * 0.02),
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

          if (showRejectionDialog)
            Container(
              color: ColorUtils.withOpacity(Colors.black, 0.7),
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(width * 0.08),
                  padding: EdgeInsets.all(width * 0.06),
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
                      SizedBox(height: height * 0.02),
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
                        onChanged: (value) => setState(() => rejectionReason = value),
                      ),
                      SizedBox(height: height * 0.03),
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
                          SizedBox(width: width * 0.02),
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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout"),
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
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap, double width) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: width * 0.03),
        margin: EdgeInsets.symmetric(vertical: width * 0.01),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(width * 0.05),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textPrimary, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: width * 0.032,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
