import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'content_detail_screen.dart';
import 'writer_login_screen.dart';

class WriterContentScreen extends StatefulWidget {
  const WriterContentScreen({super.key});

  @override
  State<WriterContentScreen> createState() => _WriterContentScreenState();
}

class _WriterContentScreenState extends State<WriterContentScreen> {
  String selectedFilter = 'All';
  String selectedStatus = 'Accepted';
  String? writerId;

  final List<String> filters = ['All', 'Casual', 'Formal', 'Streetwear', 'Trends'];
  final List<String> statuses = ['Accepted', 'Pending', 'Rejected', 'Draft']; // Added Draft

  @override
  void initState() {
    super.initState();
    writerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final basePadding = screenWidth * 0.04;
    final cardHeight = screenHeight * 0.25;
    final iconSize = screenWidth * 0.06;
    final chipFontSize = screenWidth * 0.035;
    final titleFontSize = screenWidth * 0.045;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
                top: screenHeight * 0.03,
                left: basePadding,
                right: basePadding,
                bottom: screenHeight * 0.015),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Image.asset('assets/images/white_back_btn.png', width: 28, height: 28),
                    ),
                    Text(
                      'My Submitted Styles',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {}),
                      child: Icon(Icons.refresh, color: Colors.white, size: iconSize),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.015),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((label) {
                      return FilterChipWidget(
                        label: label,
                        fontSize: chipFontSize,
                        selected: selectedFilter == label,
                        onTap: () => setState(() => selectedFilter = label),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.015),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: statuses.map((status) {
                      final bool isSelected = selectedStatus == status;
                      return GestureDetector(
                        onTap: () => setState(() => selectedStatus = status),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: basePadding, vertical: screenHeight * 0.008),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.pink : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? Colors.pink : Colors.grey.shade400),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: chipFontSize,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Expanded(
                    child: writerId == null
                        ? const Center(child: Text("Not signed in"))
                        : FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchWriterArticles(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final articles = snapshot.data ?? [];
                        final filteredByCategory = selectedFilter == 'All'
                            ? articles
                            : articles.where((a) => a['category']?.toString().toLowerCase().contains(selectedFilter.toLowerCase()) ?? false).toList();

                        final filtered = filteredByCategory.where((a) {
                          switch (selectedStatus) {
                            case 'Accepted':
                              return a['status'] == 'approved';
                            case 'Rejected':
                              return a['status'] == 'rejected';
                            case 'Pending':
                              return a['status'] == 'pending';
                            case 'Draft':
                              return a['status'] == 'draft';
                            default:
                              return true;
                          }
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              "No ${selectedStatus.toLowerCase()} content found.",
                              style: TextStyle(color: Colors.grey, fontSize: chipFontSize),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.all(basePadding),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final article = filtered[index];
                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WriterContentDetailScreen(article: article),
                                      ),
                                    );
                                  },
                                  child: ContentCard(
                                    imageBase64: article['mediaBase64'] ?? '',
                                    title: article['title'] ?? '',
                                    author: 'You',
                                    time: formatTimestamp(article['timestamp']),
                                    description: article['description'] ?? '',
                                    cardHeight: cardHeight,
                                    titleFontSize: titleFontSize,
                                    textFontSize: chipFontSize,
                                    status: article['status'] ?? '',
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                              ],
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
          MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchWriterArticles() async {
    if (writerId == null) return [];
    final articlesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(writerId)
        .collection('articles')
        .orderBy('timestamp', descending: true)
        .get();

    return articlesSnapshot.docs.map((doc) {
      final data = doc.data();
      data['articleId'] = doc.id;
      return data;
    }).toList();
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime time;
    if (timestamp is Timestamp) time = timestamp.toDate();
    else if (timestamp is DateTime) time = timestamp;
    else return '';

    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.yMMMd().format(time);
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double fontSize;

  const FilterChipWidget({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.pink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class ContentCard extends StatelessWidget {
  final String imageBase64;
  final String title;
  final String author;
  final String time;
  final String description;
  final double cardHeight;
  final double titleFontSize;
  final double textFontSize;
  final String status;

  const ContentCard({
    super.key,
    required this.imageBase64,
    required this.title,
    required this.author,
    required this.time,
    required this.description,
    this.cardHeight = 160,
    this.titleFontSize = 16,
    this.textFontSize = 12,
    this.status = '',
  });

  @override
  Widget build(BuildContext context) {
    final bytes = (imageBase64.isNotEmpty) ? base64Decode(imageBase64.split(',').last) : null;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[100],
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bytes != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  child: Image.memory(
                    bytes,
                    height: cardHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(cardHeight * 0.075),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold)),
                    SizedBox(height: cardHeight * 0.025),
                    Row(
                      children: [
                        Text(author, style: TextStyle(color: Colors.grey, fontSize: textFontSize)),
                        SizedBox(width: cardHeight * 0.02),
                        Text('•', style: TextStyle(color: Colors.grey, fontSize: textFontSize)),
                        SizedBox(width: cardHeight * 0.02),
                        Text(time, style: TextStyle(color: Colors.grey, fontSize: textFontSize)),
                      ],
                    ),
                    SizedBox(height: cardHeight * 0.03),
                    Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textFontSize)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Draft label overlay
        if (status.toLowerCase() == 'draft')
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'DRAFT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
