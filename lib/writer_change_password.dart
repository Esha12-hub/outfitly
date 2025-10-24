import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'writer_dashboard_screen.dart';

class WriterChangePasswordScreen extends StatefulWidget {
  const WriterChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<WriterChangePasswordScreen> createState() => _WriterChangePasswordScreenState();
}

class _WriterChangePasswordScreenState extends State<WriterChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isSmallScreen = width < 400;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: height * 0.07),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: width * 0.08,
                      width: width * 0.08,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "Change Password (Writer)",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 18 : width * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
                vertical: height * 0.03,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set a new password for your writer account",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    _buildPasswordField(
                      label: "New Password",
                      hint: "Enter your new password",
                      controller: _newPasswordController,
                      obscure: _obscureNew,
                      toggle: () => setState(() => _obscureNew = !_obscureNew),
                      width: width,
                      height: height,
                    ),
                    SizedBox(height: height * 0.02),
                    _buildPasswordField(
                      label: "Confirm Password",
                      hint: "Re-enter your new password",
                      controller: _confirmPasswordController,
                      obscure: _obscureConfirm,
                      toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      width: width,
                      height: height,
                    ),
                    SizedBox(height: height * 0.04),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _confirmPasswordChange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        minimumSize: Size(double.infinity, height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        height: height * 0.03,
                        width: height * 0.03,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text(
                        "Update Password",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : width * 0.045,
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
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    required double width,
    required double height,
  }) {
    final isSmallScreen = width < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : width * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: height * 0.01),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade200,
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                size: width * 0.055,
              ),
              onPressed: toggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.018,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPasswordChange() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("Please fill all fields");
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar("No writer is logged in");
        return;
      }

      await user.updatePassword(newPass);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'password': newPass,
        'role': 'Content Writer'
      });

      _showSnackBar("Password updated successfully!", bg: Colors.green);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WriterDashboardScreen()),
      );
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color bg = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bg),
    );
  }
}
