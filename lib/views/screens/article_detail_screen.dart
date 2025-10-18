import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'dashboard_screen.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String title;
  final String description; // Full article content from Firestore
  final String author;
  final String date;
  final String readTime;
  final Uint8List? imageBytes;
  final VoidCallback? onBackPressed;
  final Uint8List? authorImageBytes;

  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.author,
    required this.date,
    required this.readTime,
    this.authorImageBytes,
    this.imageBytes,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBackPressed ??
                            () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DashboardScreen(),
                            ),
                          );
                        },
                    icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                  ),
                  const Expanded(
                    child: Text(
                      'Fashion Articles',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Article bookmarked!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_border, color: AppColors.textWhite),
                  ),
                ],
              ),
            ),

            // ===== Main Content =====
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== Hero Image =====
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: imageBytes != null
                              ? Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 300,
                          )
                              : Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Text(
                                title,
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ===== Article Content =====
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Bar
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                title,
                                style: AppTextStyles.h2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Author Info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: authorImageBytes != null
                                      ? MemoryImage(authorImageBytes!)
                                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                                ),

                                const SizedBox(width: 8),
                                Text(
                                  author,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(date, style: AppTextStyles.caption),
                                const SizedBox(width: 10),
                                Text(readTime, style: AppTextStyles.caption),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Article Body (Dynamic from Firestore)
                            Text(
                              description.isNotEmpty
                                  ? description
                                  : "No content available for this article.",
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.black87,
                                height: 1.5, // better readability
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
