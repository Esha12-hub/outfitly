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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    "Writer Terms of Use",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
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
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome, Writer!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "By creating content on this platform, you agree to comply with these terms. "
                            "Please read carefully and ensure your content follows guidelines. "
                            "If you do not agree, do not continue using this writer account.",
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "1. Content Ownership & Licensing",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "All content you create remains your intellectual property, "
                            "but by submitting content here, you grant us the right to publish and distribute it.",
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "2. Quality & Originality",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "• Ensure your submissions are original and free from plagiarism.\n"
                            "• Avoid offensive, inappropriate, or illegal content.\n"
                            "• Follow the style and format guidelines provided in the writer dashboard.",
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "3. Privacy & Data Handling",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "We handle your personal data responsibly. Minimal data is collected to manage your writer account and content contributions.",
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "4. Termination",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Violation of these terms may lead to account suspension or termination.",
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "5. Updates",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "These terms may be updated periodically. Continuing to use your writer account implies acceptance of new terms.",
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 30),

                      // Checkbox for Acceptance
                      Row(
                        children: [
                          Checkbox(
                            value: _isAccepted,
                            activeColor: Colors.pink,
                            onChanged: (value) async {
                              setState(() {
                                _isAccepted = value ?? false;
                              });
                              await _saveAcceptanceStatus(_isAccepted);
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I have read and agree to the Writer Terms of Use.",
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Continue Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _isAccepted
                              ? () {
                            Navigator.pop(context);
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAccepted ? Colors.pink : Colors.grey,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Continue",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
}
