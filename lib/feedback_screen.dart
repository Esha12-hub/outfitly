import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final feedbackText = _feedbackController.text.trim();
    if (feedbackText.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter feedback")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('feedback')
          .add({
        'feedback': feedbackText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _feedbackController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Feedback submitted!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              SizedBox(height: height * 0.07),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset(
                          "assets/images/white_back_btn.png",
                          height: width * 0.07,
                          width: width * 0.07,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Feedback",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0,
                      child: IconButton(
                        onPressed: () {},
                        icon: Image.asset(
                          "assets/images/white_back_btn.png",
                          height: width * 0.07,
                          width: width * 0.07,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.02),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06,
                    vertical: height * 0.04,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "We value your feedback! Please share your thoughts below:",
                          style: TextStyle(
                            fontSize: 18 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: height * 0.03),
                        _buildFeedbackField(
                          controller: _feedbackController,
                          width: width,
                          textScale: textScale,
                        ),
                        SizedBox(height: height * 0.05),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade600,
                            minimumSize: Size.fromHeight(height * 0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : Text(
                            "Submit Feedback",
                            style: TextStyle(
                              fontSize: 16 * textScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedbackField({
    required TextEditingController controller,
    required double width,
    required double textScale,
  }) {
    return TextField(
      controller: controller,
      maxLines: 6,
      decoration: InputDecoration(
        hintText: "Enter your feedback...",
        hintStyle: TextStyle(fontSize: 14 * textScale),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: width * 0.04,
        ),
      ),
    );
  }
}
