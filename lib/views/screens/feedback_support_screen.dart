import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'admin_settings_screen.dart';

class FeedbackSupportScreen extends StatefulWidget {
  const FeedbackSupportScreen({super.key});

  @override
  State<FeedbackSupportScreen> createState() => _FeedbackSupportScreenState();
}

class _FeedbackSupportScreenState extends State<FeedbackSupportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> feedbackList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() => _isLoading = true);

    try {
      final usersSnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> tempList = [];

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final feedbackSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('feedback')
            .orderBy('timestamp', descending: true)
            .get();

        for (var feedbackDoc in feedbackSnapshot.docs) {
          final data = feedbackDoc.data();
          tempList.add({
            'user': userDoc['name'] ?? 'User',
            'message': data['feedback'] ?? '',
            'timestamp': data['timestamp'],
            'status': 'Open',
            'userId': userId,
            'feedbackId': feedbackDoc.id,
          });
        }
      }

      setState(() {
        feedbackList = tempList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching feedback: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.pink))
            : Column(
          children: [
            // Header with back button
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const AdminSettingsScreen()),
                      );
                    },
                    child: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: screenHeight * 0.04,
                      width: screenHeight * 0.04,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Feedback & Support',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.whiteHeading.copyWith(
                            fontSize: screenHeight * 0.028),
                      ),
                    ),
                  ),
                  SizedBox(width: screenHeight * 0.04),
                ],
              ),
            ),

            // Feedback List
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
                child: feedbackList.isEmpty
                    ? Center(
                  child: Text(
                    'No feedback submitted yet.',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenHeight * 0.02),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  itemCount: feedbackList.length,
                  itemBuilder: (context, index) {
                    final feedback = feedbackList[index];
                    return _buildFeedbackCard(
                        feedback, screenHeight);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(
      Map<String, dynamic> feedback, double screenHeight) {
    final isOpen = feedback['status'] == 'Open';
    final timestamp = (feedback['timestamp'] as Timestamp?)?.toDate();
    final dateString = timestamp != null
        ? '${timestamp.day}-${timestamp.month}-${timestamp.year}, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
        : 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      padding: EdgeInsets.all(screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback['user'],
                      style: TextStyle(
                        fontSize: screenHeight * 0.022,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      dateString,
                      style: TextStyle(
                        fontSize: screenHeight * 0.015,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: screenHeight * 0.01, vertical: screenHeight * 0.004),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.grey[300] : AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  feedback['status'],
                  style: TextStyle(
                    fontSize: screenHeight * 0.012,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? Colors.grey[700] : AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            feedback['message'],
            style: TextStyle(
              fontSize: screenHeight * 0.018,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
