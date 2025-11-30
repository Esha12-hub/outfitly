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
  String? selectedFeedbackId;

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
            'message': data['message'] ?? '',
            'timestamp': data['timestamp'],
            'status': data['status'] ?? 'Unread',
            'replies': data['replies'] ?? [],
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

  Future<void> _markAsRead(int index) async {
    try {
      final feedback = feedbackList[index];
      final userId = feedback['userId'];
      final feedbackId = feedback['feedbackId'];

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('feedback')
          .doc(feedbackId)
          .update({'status': 'Read'});

      setState(() {
        feedbackList[index]['status'] = 'Read';
      });
    } catch (e) {
      print('Error updating feedback status: $e');
    }
  }

  Future<void> _sendReply(
      String userId,
      String feedbackId,
      String replyMessage,
      ) async {
    try {
      final feedbackRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('feedback')
          .doc(feedbackId);

      final feedbackDoc = await feedbackRef.get();
      final List replies = feedbackDoc.data()?['replies'] ?? [];

      replies.add({
        'message': replyMessage,
        'timestamp': Timestamp.now(),
      });

      await feedbackRef.update({
        'replies': replies,
        'status': 'Read',
      });

      _loadFeedback();
    } catch (e) {
      print("Error sending reply: $e");
    }
  }

  void _showReplyDialog(Map<String, dynamic> feedback) {
    TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Reply to Feedback",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: replyController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Enter your reply...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (replyController.text.trim().isEmpty) return;

                await _sendReply(
                  feedback['userId'],
                  feedback['feedbackId'],
                  replyController.text.trim(),
                );

                Navigator.pop(context);
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
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
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          fontSize: screenHeight * 0.025,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await _loadFeedback();
                    },
                    child: Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: screenHeight * 0.035,
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
                    final isExpanded =
                        selectedFeedbackId ==
                            feedback['feedbackId'];

                    return GestureDetector(
                      onTap: () async {
                        if (feedback['status'] == 'Unread') {
                          await _markAsRead(index);
                        }
                        setState(() {
                          selectedFeedbackId = isExpanded
                              ? null
                              : feedback['feedbackId'];
                        });
                      },
                      child: _buildFeedbackCard(
                          feedback, screenHeight, isExpanded),
                    );
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
      Map<String, dynamic> feedback, double screenHeight, bool isExpanded) {
    final status = feedback['status'];
    final isUnread = status == 'Unread';
    final timestamp = (feedback['timestamp'] as Timestamp?)?.toDate();
    final dateString = timestamp != null
        ? '${timestamp.day}-${timestamp.month}-${timestamp.year}, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
        : 'N/A';

    final message = feedback['message'] ?? '';
    final previewLength = 80;
    final isLong = message.length > previewLength;
    final previewText =
    isLong ? '${message.substring(0, previewLength)}...' : message;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      padding: EdgeInsets.all(screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? Colors.pinkAccent : Colors.grey[400]!,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          if (isUnread)
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    horizontal: screenHeight * 0.01,
                    vertical: screenHeight * 0.004),
                decoration: BoxDecoration(
                  color: isUnread ? Colors.pinkAccent : Colors.grey[600],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: screenHeight * 0.013,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.012),
          Text(
            isExpanded ? message : previewText,
            style: TextStyle(
              fontSize: screenHeight * 0.018,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          if (isLong && !isExpanded)
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.008),
              child: Text(
                "Tap to view full feedback",
                style: TextStyle(
                  fontSize: screenHeight * 0.016,
                  color: Colors.pinkAccent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (isExpanded) ...[
            SizedBox(height: screenHeight * 0.015),
            const Divider(),
            SizedBox(height: screenHeight * 0.005),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Status: ${feedback['status']}",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: screenHeight * 0.016,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),
            if (feedback['replies'] != null && (feedback['replies'] as List).isNotEmpty)
              ...List<Widget>.from((feedback['replies'] as List).map((r) {
                final ts = (r['timestamp'] as Timestamp).toDate();
                return Container(
                  margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                  padding: EdgeInsets.all(screenHeight * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Admin Reply:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenHeight * 0.018,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        r['message'],
                        style: TextStyle(fontSize: screenHeight * 0.017),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${ts.day}-${ts.month}-${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2,'0')}",
                          style: TextStyle(
                              fontSize: screenHeight * 0.014,
                              color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                );
              })),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _showReplyDialog(feedback),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text("Reply",style: TextStyle(color: Colors.white),),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
