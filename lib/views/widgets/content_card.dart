import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../screens/article_detail_screen.dart';

class ContentCard extends StatelessWidget {
  final String title;
  final String author;
  final String date;
  final Uint8List? imageBytes;
  final Uint8List? authorImageBytes;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback onView;
  final String content;

  const ContentCard({
    super.key,
    required this.title,
    required this.author,
    required this.date,
    this.imageBytes,
    this.authorImageBytes,
    this.onAccept,
    this.onReject,
    required this.onView,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.05,
                  backgroundColor: AppColors.primary,
                  backgroundImage: authorImageBytes != null
                      ? MemoryImage(authorImageBytes!)
                      : null,
                  child: authorImageBytes == null
                      ? Icon(Icons.person,
                      color: AppColors.textWhite,
                      size: screenWidth * 0.05)
                      : null,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author,
                          style: AppTextStyles.h4
                              .copyWith(fontSize: screenWidth * 0.04)),
                      Text(date,
                          style: AppTextStyles.caption
                              .copyWith(fontSize: screenWidth * 0.03)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.005),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    'Review',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: screenWidth * 0.028,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: screenHeight * 0.25,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageBytes != null
                  ? Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: screenHeight * 0.25,
              )
                  : Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: screenHeight * 0.015,
                      left: screenWidth * 0.03,
                      right: screenWidth * 0.03,
                      child: Text(
                        title,
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.textWhite,
                          fontSize: screenWidth * 0.045,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: Icon(Icons.check, size: screenWidth * 0.045),
                    label: Text('Accept',
                        style:
                        TextStyle(fontSize: screenWidth * 0.035)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: Icon(Icons.close, size: screenWidth * 0.045),
                    label: Text('Reject',
                        style:
                        TextStyle(fontSize: screenWidth * 0.035)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: IconButton(
                    onPressed: () {
                      onView();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(
                            title: title,
                            description: content,
                            author: author,
                            date: date,
                            authorImageBytes: authorImageBytes,
                            readTime: '2 min read',
                            imageBytes: imageBytes,
                            articleId: '',
                            authorUid: '',
                            onBackPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.visibility,
                      color: AppColors.textSecondary,
                      size: screenWidth * 0.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
