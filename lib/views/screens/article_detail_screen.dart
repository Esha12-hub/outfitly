import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String title;
  final String description;
  final String author;
  final String date;
  final String readTime;
  final Uint8List? imageBytes;
  final Uint8List? authorImageBytes;
  final String articleId;
  final String authorUid;
  final VoidCallback? onBackPressed;

  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.author,
    required this.date,
    required this.readTime,
    required this.articleId,
    required this.authorUid,
    this.authorImageBytes,
    this.imageBytes,
    this.onBackPressed,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  int likesCount = 0;
  int commentsCount = 0;
  bool isBookmarked = false;
  bool _isLoadingMetrics = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.articleId.isNotEmpty) {
      _listenArticleMetrics();
    } else {
      _isLoadingMetrics = false;
    }
  }

  void _listenArticleMetrics() {
    final articleRef = _firestore.collection('articles').doc(widget.articleId);

    // Listen for changes in the article document
    articleRef.snapshots().listen((doc) async {
      if (!doc.exists) return;

      final data = doc.data()!;
      final likes = data['likes'] ?? 0;
      final bookmarkedUsers = List<String>.from(data['bookmarkedBy'] ?? []);

      // Fetch comments count
      int commentsLen = 0;
      try {
        final commentsSnapshot = await articleRef.collection('comments').get();
        commentsLen = commentsSnapshot.docs.length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          likesCount = likes;
          commentsCount = commentsLen;
          isBookmarked = bookmarkedUsers.contains(currentUserId);
          _isLoadingMetrics = false;
        });
      }
    });
  }

  Future<void> toggleBookmark() async {
    if (widget.articleId.isEmpty) return;
    final articleRef = _firestore.collection('articles').doc(widget.articleId);

    setState(() => isBookmarked = !isBookmarked);

    try {
      if (isBookmarked) {
        await articleRef.update({
          'bookmarkedBy': FieldValue.arrayUnion([currentUserId])
        });
      } else {
        await articleRef.update({
          'bookmarkedBy': FieldValue.arrayRemove([currentUserId])
        });
      }
    } catch (e) {
      debugPrint('Error updating bookmark: $e');
      setState(() => isBookmarked = !isBookmarked); // revert on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
                    icon: Image.asset('assets/images/white_back_btn.png', width: 28, height: 28),
                  ),
                  Expanded(
                    child: Text(
                      'Fashion Articles',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading.copyWith(fontSize: screenWidth * 0.05),
                    ),
                  ),
                  IconButton(
                    onPressed: toggleBookmark,
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.pink : AppColors.textWhite,
                    ),
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
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Image
                        SizedBox(
                          height: screenHeight * 0.35,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: widget.imageBytes != null
                                ? Image.memory(widget.imageBytes!, fit: BoxFit.cover)
                                : Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Text(
                                  widget.title,
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
                        SizedBox(height: screenHeight * 0.02),

                        // Title
                        Text(
                          widget.title,
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: screenWidth * 0.05,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        // Author Info + Likes/Comments
                        Row(
                          children: [
                            CircleAvatar(
                              radius: screenWidth * 0.04,
                              backgroundColor: Colors.transparent,
                              backgroundImage: widget.authorImageBytes != null
                                  ? MemoryImage(widget.authorImageBytes!)
                                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.author,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: screenWidth * 0.038,
                                    )),
                                Text(widget.date,
                                    style: AppTextStyles.caption.copyWith(fontSize: screenWidth * 0.03)),
                              ],
                            ),
                            const Spacer(),
                            _isLoadingMetrics
                                ? const CircularProgressIndicator()
                                : Row(
                              children: [
                                Icon(Icons.thumb_up,
                                    color: Colors.blueGrey, size: screenWidth * 0.045),
                                SizedBox(width: screenWidth * 0.01),
                                Text('$likesCount'),
                                SizedBox(width: screenWidth * 0.04),
                                Icon(Icons.comment,
                                    color: Colors.blueGrey, size: screenWidth * 0.045),
                                SizedBox(width: screenWidth * 0.01),
                                Text('$commentsCount'),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Article Body
                        Text(
                          widget.description.isNotEmpty
                              ? widget.description
                              : "No content available for this article.",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.black87,
                            fontSize: screenWidth * 0.04,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Read Time
                        Text(
                          'Read Time: ${widget.readTime}',
                          style: AppTextStyles.caption.copyWith(fontSize: screenWidth * 0.03),
                        ),
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
}
