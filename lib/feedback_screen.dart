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
  bool _showFeedbacks = false;
  List<Map<String, dynamic>> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> tempList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'message': data['message'] ?? '',
          'timestamp': data['timestamp'],
          'replies': data['replies'] ?? [],
        };
      }).toList();

      setState(() => _feedbackList = tempList);
    } catch (e) {
      print("Error loading feedback: $e");
    }
  }

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
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userName = userDoc.data()?['name'] ?? 'User';

      final feedbackData = {
        'user': userName,
        'message': feedbackText,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Unread',
        'userId': user.uid,
        'replies': [],
      };

      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('feedback')
          .add(feedbackData);

      _feedbackController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Feedback submitted!")));

      await _loadFeedback();
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
      body: Column(
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
                        fontSize: 18 * textScale,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    SizedBox(height: height * 0.03),
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Submit Feedback",
                        style: TextStyle(
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showFeedbacks = !_showFeedbacks;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        minimumSize: Size.fromHeight(height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _showFeedbacks ? "Hide My Feedbacks" : "My Feedbacks",
                        style: TextStyle(
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    if (_showFeedbacks && _feedbackList.isNotEmpty)
                      ..._feedbackList.map((fb) {
                        final replies = fb['replies'] as List;
                        return Padding(
                          padding: EdgeInsets.only(bottom: height * 0.03),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Feedback:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16 * textScale),
                              ),
                              SizedBox(height: height * 0.005),
                              Text(
                                fb['message'],
                                style: TextStyle(fontSize: 15 * textScale),
                              ),
                              if (replies.isNotEmpty)
                                ...replies.map((r) {
                                  final ts = (r['timestamp'] as Timestamp).toDate();
                                  return Container(
                                    margin: EdgeInsets.only(top: height * 0.015),
                                    padding: EdgeInsets.all(width * 0.03),
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
                                            fontSize: 15 * textScale,
                                            color: Colors.pinkAccent,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          r['message'],
                                          style: TextStyle(fontSize: 14 * textScale),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            "${ts.day}-${ts.month}-${ts.year}, ${ts.hour}:${ts.minute.toString().padLeft(2,'0')}",
                                            style: TextStyle(
                                              fontSize: 12 * textScale,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
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
