import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';


class UpdateFaqScreen extends StatefulWidget {
  const UpdateFaqScreen({super.key});

  @override
  State<UpdateFaqScreen> createState() => _UpdateFaqScreenState();
}

class _UpdateFaqScreenState extends State<UpdateFaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> faqList = [
    {
      'id': 1,
      'question': 'How do I create a new outfit?',
      'answer': 'To create a new outfit, go to the wardrobe section and tap the "+" button. You can then select items from your closet or add new ones.',
      'isExpanded': false,
      'isEditing': false,
    },
    {
      'id': 2,
      'question': 'Can I share my outfits with friends?',
      'answer': 'Yes, you can share your outfits by tapping the share button on any outfit card. This will generate a link that you can send to friends.',
      'isExpanded': true,
      'isEditing': false,
    },
    {
      'id': 3,
      'question': 'How does the AI styling work?',
      'answer': 'Our AI analyzes your preferences and suggests outfits based on your style history, current trends, and the occasion.',
      'isExpanded': false,
      'isEditing': false,
    },
    {
      'id': 4,
      'question': 'How do I reset my password?',
      'answer': 'Go to Settings > Account > Change Password. You will receive a verification code to reset your password.',
      'isExpanded': false,
      'isEditing': false,
    },
  ];

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _questionController.dispose();
    _answerController.dispose();
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
                      'Update FAQ Section',
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
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _filterFaqs(value),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),

                    // FAQ List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: faqList.length,
                        itemBuilder: (context, index) {
                          final faq = faqList[index];
                          return _buildFaqCard(faq, index);
                        },
                      ),
                    ),

                    // Bottom Action Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddFaqDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add New FAQ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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

  Widget _buildFaqCard(Map<String, dynamic> faq, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Question Header
          ListTile(
            title: faq['isEditing']
                ? TextField(
                    controller: _questionController..text = faq['question'],
                    decoration: const InputDecoration(
                      hintText: 'Enter question',
                      border: InputBorder.none,
                    ),
                  )
                : Text(
                    faq['question'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _editFaq(index),
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                ),
                IconButton(
                  onPressed: () => _deleteFaq(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            onTap: () => _toggleFaq(index),
          ),

          // Answer Section (if expanded)
          if (faq['isExpanded'])
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Answer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  faq['isEditing']
                      ? TextField(
                          controller: _answerController..text = faq['answer'],
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter answer',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        )
                      : Text(
                          faq['answer'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                  if (faq['isEditing']) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _saveFaq(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textWhite,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _cancelEdit(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: AppColors.primary),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _toggleFaq(int index) {
    setState(() {
      faqList[index]['isExpanded'] = !faqList[index]['isExpanded'];
    });
  }

  void _editFaq(int index) {
    setState(() {
      faqList[index]['isEditing'] = true;
      _questionController.text = faqList[index]['question'];
      _answerController.text = faqList[index]['answer'];
    });
  }

  void _saveFaq(int index) {
    if (_questionController.text.trim().isEmpty || _answerController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in both question and answer fields.',
        backgroundColor: Colors.red,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      faqList[index]['question'] = _questionController.text.trim();
      faqList[index]['answer'] = _answerController.text.trim();
      faqList[index]['isEditing'] = false;
    });

    Get.snackbar(
      'FAQ Updated',
      'FAQ has been updated successfully.',
      backgroundColor: AppColors.success,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _cancelEdit(int index) {
    setState(() {
      faqList[index]['isEditing'] = false;
    });
  }

  void _deleteFaq(int index) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete FAQ'),
        content: const Text('Are you sure you want to delete this FAQ? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              setState(() {
                faqList.removeAt(index);
              });
              Get.snackbar(
                'FAQ Deleted',
                'FAQ has been deleted successfully.',
                backgroundColor: AppColors.success,
                colorText: AppColors.textWhite,
                snackPosition: SnackPosition.TOP,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _filterFaqs(String query) {
    // This would typically filter the FAQ list based on the search query
    // For now, we'll just show a snackbar
    if (query.isNotEmpty) {
      Get.snackbar(
        'Search',
        'Searching for: $query',
        backgroundColor: AppColors.info,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
      );
    }
  }

  void _showAddFaqDialog() {
    _questionController.clear();
    _answerController.clear();

    Get.dialog(
      AlertDialog(
        title: const Text('Add New FAQ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Answer',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_questionController.text.trim().isEmpty || _answerController.text.trim().isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please fill in both question and answer fields.',
                  backgroundColor: Colors.red,
                  colorText: AppColors.textWhite,
                  snackPosition: SnackPosition.TOP,
                );
                return;
              }

              setState(() {
                faqList.add({
                  'id': faqList.length + 1,
                  'question': _questionController.text.trim(),
                  'answer': _answerController.text.trim(),
                  'isExpanded': false,
                  'isEditing': false,
                });
              });

              Get.back();
              Get.snackbar(
                'FAQ Added',
                'New FAQ has been added successfully.',
                backgroundColor: AppColors.success,
                colorText: AppColors.textWhite,
                snackPosition: SnackPosition.TOP,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }
} 