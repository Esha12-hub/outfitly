import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsOfUseScreen extends StatefulWidget {
  const TermsOfUseScreen({super.key});

  @override
  State<TermsOfUseScreen> createState() => _TermsOfUseScreenState();
}

class _TermsOfUseScreenState extends State<TermsOfUseScreen> {
  bool _isAccepted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAcceptanceStatus();
  }

  Future<void> _loadAcceptanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('termsAccepted') ?? false;
    setState(() {
      _isAccepted = accepted;
      _isLoading = false;
    });
  }

  Future<void> _saveAcceptanceStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAccepted', value);
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
                    "Terms of Use",
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
                      child: Image.asset(
                        "assets/images/white_back_btn.png",
                        height: 30,
                        width: 30,
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
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Welcome to Our App!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Please read these Terms of Use carefully before using this application. "
                            "By accessing or using the app, you agree to be bound by these terms. "
                            "If you do not agree, please do not use the app.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "1. Acceptance of Terms",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "By using this app, you acknowledge that you have read, understood, "
                            "and agree to comply with these Terms of Use and all applicable laws and regulations.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "2. User Responsibilities",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "• You agree not to misuse or abuse any features of the app.\n"
                            "• You will not attempt to gain unauthorized access to our servers or networks.\n"
                            "• You are responsible for keeping your login credentials secure.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "3. Privacy & Data Usage",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your privacy is important to us. We only collect minimal data necessary for app functionality. "
                            "Please review our Privacy Policy for more information on how we handle your data.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "4. Intellectual Property",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "All content, including text, graphics, logos, and icons, is the property of the app developers "
                            "and protected under copyright law. Unauthorized use is prohibited.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "5. Limitation of Liability",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "We are not liable for any damages resulting from the use or inability to use the app, "
                            "including data loss, device damage, or performance issues.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "6. Modifications to Terms",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "We may update these terms from time to time. You are encouraged to review this page periodically "
                            "for any changes. Continued use of the app indicates acceptance of the new terms.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black87, height: 1.5),
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
                              "I have read and agree to the Terms of Use.",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
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
                            backgroundColor:
                            _isAccepted ? Colors.pink : Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
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
