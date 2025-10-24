import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WriterTermsOfUseScreen extends StatefulWidget {
  const WriterTermsOfUseScreen({super.key});

  @override
  State<WriterTermsOfUseScreen> createState() => _WriterTermsOfUseScreenState();
}

class _WriterTermsOfUseScreenState extends State<WriterTermsOfUseScreen> {
  bool _isAccepted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAcceptanceStatus();
  }

  Future<void> _loadAcceptanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('writerTermsAccepted') ?? false;
    setState(() {
      _isAccepted = accepted;
      _isLoading = false;
    });
  }

  Future<void> _saveAcceptanceStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('writerTermsAccepted', value);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = screenWidth * 0.04; // Responsive text size

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    "Writer Terms of Use",
                    style: TextStyle(
                      fontSize: fontSize + 2,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        "assets/images/white_back_btn.png",
                        height: screenWidth * 0.07,
                        width: screenWidth * 0.07,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.08),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome, Writer!",
                        style: TextStyle(
                          fontSize: fontSize + 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        "By creating content on this platform, you agree to comply with these terms. "
                            "Please read carefully and ensure your content follows guidelines. "
                            "If you do not agree, do not continue using this writer account.",
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      _sectionTitle("1. Content Ownership & Licensing", fontSize),
                      _sectionText(
                        "All content you create remains your intellectual property, "
                            "but by submitting content here, you grant us the right to publish and distribute it.",
                        fontSize,
                      ),

                      _sectionTitle("2. Quality & Originality", fontSize),
                      _sectionText(
                        "• Ensure your submissions are original and free from plagiarism.\n"
                            "• Avoid offensive, inappropriate, or illegal content.\n"
                            "• Follow the style and format guidelines provided in the writer dashboard.",
                        fontSize,
                      ),

                      _sectionTitle("3. Privacy & Data Handling", fontSize),
                      _sectionText(
                        "We handle your personal data responsibly. Minimal data is collected to manage your writer account and content contributions.",
                        fontSize,
                      ),

                      _sectionTitle("4. Termination", fontSize),
                      _sectionText(
                        "Violation of these terms may lead to account suspension or termination.",
                        fontSize,
                      ),

                      _sectionTitle("5. Updates", fontSize),
                      _sectionText(
                        "These terms may be updated periodically. Continuing to use your writer account implies acceptance of new terms.",
                        fontSize,
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.05,
                            height: screenWidth * 0.05,
                            child: Checkbox(
                              value: _isAccepted,
                              activeColor: Colors.pink,
                              onChanged: (value) async {
                                setState(() {
                                  _isAccepted = value ?? false;
                                });
                                await _saveAcceptanceStatus(_isAccepted);
                              },
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: Text(
                              "I have read and agree to the Writer Terms of Use.",
                              style: TextStyle(
                                fontSize: fontSize,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _isAccepted ? () => Navigator.pop(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAccepted ? Colors.pink : Colors.grey,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1,
                              vertical: screenHeight * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: fontSize + 1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize + 1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionText(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }
}
