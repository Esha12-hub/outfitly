import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class FeedbackSupportScreen extends StatefulWidget {
  const FeedbackSupportScreen({super.key});

  @override
  State<FeedbackSupportScreen> createState() => _FeedbackSupportScreenState();
}

class _FeedbackSupportScreenState extends State<FeedbackSupportScreen> {
  final List<Map<String, dynamic>> feedbackList = [
    {
      'user': 'User 123',
      'date': 'Apr 5, 2025, 10:30 AM',
      'message': 'I have a question about latest update.',
      'status': 'Open',
    },
    {
      'user': 'User 456',
      'date': 'Apr 5, 2025, 09:15 AM',
      'message': 'I have a question about latest update.',
      'status': 'Responded',
    },
    {
      'user': 'User 789',
      'date': 'Apr 4, 2025, 03:45 PM',
      'message': 'I have a question about latest update.',
      'status': 'Open',
    },
    {
      'user': 'User 445',
      'date': 'Apr 4, 2025, 02:20 PM',
      'message': 'I have a question about latest update.',
      'status': 'Responded',
    },
    {
      'user': 'User 123',
      'date': 'Apr 3, 2025, 11:10 AM',
      'message': 'I have a question about latest update.',
      'status': 'Open',
    },
  ];

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
                      'Feedback & Support',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  const SizedBox(width: 48),
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
                    // Feedback List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: feedbackList.length,
                        itemBuilder: (context, index) {
                          final feedback = feedbackList[index];
                          return _buildFeedbackCard(feedback, index);
                        },
                      ),
                    ),

                    // Bottom Action Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _markAsResolved(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Mark as Resolved',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback, int index) {
    final isOpen = feedback['status'] == 'Open';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.grey[300] : AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      feedback['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOpen ? Colors.grey[700] : AppColors.textWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _replyToFeedback(index),
                    child: Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback['message'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _replyToFeedback(int index) {
    Get.to(() => FeedbackSupportResponseScreen(
      feedbackList: feedbackList,
      selectedIndex: index,
    ));
  }

  void _markAsResolved() {
    Get.dialog(
      AlertDialog(
        title: const Text('Mark as Resolved'),
        content: const Text('Are you sure you want to mark all feedback as resolved?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              setState(() {
                for (var feedback in feedbackList) {
                  feedback['status'] = 'Responded';
                }
              });
              Get.snackbar(
                'Feedback Resolved',
                'All feedback has been marked as resolved.',
                backgroundColor: AppColors.success,
                colorText: AppColors.textWhite,
                snackPosition: SnackPosition.TOP,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Resolve', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }
}

class FeedbackSupportResponseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> feedbackList;
  final int selectedIndex;

  const FeedbackSupportResponseScreen({
    super.key,
    required this.feedbackList,
    required this.selectedIndex,
  });

  @override
  State<FeedbackSupportResponseScreen> createState() => _FeedbackSupportResponseScreenState();
}

class _FeedbackSupportResponseScreenState extends State<FeedbackSupportResponseScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
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
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Feedback & Support Response',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  const SizedBox(width: 48),
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
                    // Feedback List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: widget.feedbackList.length,
                        itemBuilder: (context, index) {
                          final feedback = widget.feedbackList[index];
                          final isSelected = index == widget.selectedIndex;
                          
                          return Column(
                            children: [
                              _buildFeedbackCard(feedback, index),
                              if (isSelected) _buildReplySection(),
                            ],
                          );
                        },
                      ),
                    ),

                    // Bottom Action Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _markAsResolved(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Mark as Resolved',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback, int index) {
    final isOpen = feedback['status'] == 'Open';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.grey[300] : AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      feedback['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOpen ? Colors.grey[700] : AppColors.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback['message'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplySection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original message bubble
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.feedbackList[widget.selectedIndex]['message'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Reply input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'Type your reply ....',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _sendReply(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendReply() {
    if (_replyController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a reply message.',
        backgroundColor: Colors.red,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      widget.feedbackList[widget.selectedIndex]['status'] = 'Responded';
    });

    Get.snackbar(
      'Reply Sent',
      'Your reply has been sent successfully.',
      backgroundColor: AppColors.success,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.TOP,
    );

    _replyController.clear();
  }

  void _markAsResolved() {
    Get.dialog(
      AlertDialog(
        title: const Text('Mark as Resolved'),
        content: const Text('Are you sure you want to mark all feedback as resolved?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              setState(() {
                for (var feedback in widget.feedbackList) {
                  feedback['status'] = 'Responded';
                }
              });
              Get.snackbar(
                'Feedback Resolved',
                'All feedback has been marked as resolved.',
                backgroundColor: AppColors.success,
                colorText: AppColors.textWhite,
                snackPosition: SnackPosition.TOP,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Resolve', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }
} 