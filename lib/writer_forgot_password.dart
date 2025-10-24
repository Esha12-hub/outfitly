import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'writer_dashboard_screen.dart';
import 'writer_change_password.dart'; // create or reuse existing

class WriterForgotPasswordScreen extends StatefulWidget {
  const WriterForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<WriterForgotPasswordScreen> createState() => _WriterForgotPasswordScreenState();
}

class _WriterForgotPasswordScreenState extends State<WriterForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();
  bool _isLoading = false;

  void _showSnackBar(String message, {Color bg = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bg),
    );
  }

  // Verify email exists and role = Content Writer
  Future<void> _verifyEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter your email");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        _showSnackBar("No account found with this email");
      } else {
        final userDoc = userSnapshot.docs.first;
        final role = userDoc['role'] ?? '';

        if (role != 'Content Writer') {
          _showSnackBar("Access denied — this is not a Content Writer account");
        } else {
          _showVerificationOptions(userDoc);
        }
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Verification method sheet
  void _showVerificationOptions(DocumentSnapshot userDoc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Choose Verification Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _verificationOption(
                icon: Icons.lock_outline,
                color: Colors.pink,
                text: "Verify using PIN",
                onTap: () {
                  Navigator.pop(context);
                  _verifyWithPin(userDoc);
                },
              ),
              _verificationOption(
                icon: Icons.question_mark,
                color: Colors.blue,
                text: "Answer Security Question",
                onTap: () {
                  Navigator.pop(context);
                  _verifyWithSecurityQuestion(userDoc);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _verificationOption({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // Verify with PIN
  Future<void> _verifyWithPin(DocumentSnapshot userDoc) async {
    if (!userDoc.exists || userDoc['pin'] == null || userDoc['pin'].toString().isEmpty) {
      _showSnackBar("PIN not added for this account", bg: Colors.orange);
      return;
    }

    _showInputDialog(
      title: "Enter your PIN",
      hint: "Enter your PIN",
      controller: _pinController,
      obscureText: true,
      color: Colors.pink,
      onVerify: () async {
        if (_pinController.text.trim() == userDoc['pin'].toString()) {
          Navigator.pop(context);
          await _loginUser(userDoc);
        } else {
          _showSnackBar("Incorrect PIN!", bg: Colors.red);
        }
      },
    );
  }

  // Verify with Security Question
  Future<void> _verifyWithSecurityQuestion(DocumentSnapshot userDoc) async {
    if (!userDoc.exists || userDoc['securityAnswer'] == null || userDoc['securityAnswer'].toString().isEmpty) {
      _showSnackBar("Security question not added for this account", bg: Colors.orange);
      return;
    }

    _showInputDialog(
      title: "Answer Security Question",
      hint: "Enter your answer",
      controller: _securityAnswerController,
      obscureText: true,
      color: Colors.blue,
      questionText: "What is your favorite teacher's name?",
      onVerify: () async {
        if (_securityAnswerController.text.trim().toLowerCase() ==
            userDoc['securityAnswer'].toString().toLowerCase()) {
          Navigator.pop(context);
          await _loginUser(userDoc);
        } else {
          _showSnackBar("Incorrect answer!", bg: Colors.red);
        }
      },
    );
  }

  // Common input dialog
  void _showInputDialog({
    required String title,
    required String hint,
    required TextEditingController controller,
    required Color color,
    required VoidCallback onVerify,
    String? questionText,
    bool obscureText = false,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 16),
                  if (questionText != null)
                    Text(
                      questionText,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  if (questionText != null) const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: title.contains("PIN") ? TextInputType.number : TextInputType.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, letterSpacing: 2),
                    decoration: InputDecoration(
                      hintText: hint,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Verify",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Log in and redirect
  Future<void> _loginUser(DocumentSnapshot userDoc) async {
    try {
      String email = userDoc['email'];
      String password = userDoc['password'];

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _promptChangePassword();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WriterDashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar("Login failed: ${e.message}");
    }
  }

  // Prompt for change password
  void _promptChangePassword() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Verification Successful"),
          content: const Text("Do you want to change your password now?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WriterChangePasswordScreen()),
                );
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset("assets/images/white_back_btn.png", height: 30, width: 30),
                  ),
                ),
                const Center(
                  child: Text(
                    "Writer Forgot Password",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter your registered email to reset password.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Continue",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
