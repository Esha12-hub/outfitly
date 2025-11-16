import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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
                          "Change Password",
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
                          "Set a new password",
                          style: TextStyle(
                            fontSize: 18 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: height * 0.03),
                        _buildPasswordField(
                          label: "New Password",
                          hint: "Enter your new password",
                          controller: _newPasswordController,
                          obscure: _obscureNew,
                          toggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          width: width,
                          textScale: textScale,
                        ),
                        SizedBox(height: height * 0.02),
                        _buildPasswordField(
                          label: "Confirm Password",
                          hint: "Re-enter your new password",
                          controller: _confirmPasswordController,
                          obscure: _obscureConfirm,
                          toggle: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          width: width,
                          textScale: textScale,
                        ),
                        SizedBox(height: height * 0.05),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _confirmPasswordChange,
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
                            "Confirm Change",
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

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    required double width,
    required double textScale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15 * textScale,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: width * 0.02),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14 * textScale),
            filled: true,
            fillColor: Colors.grey.shade200,
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: toggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: width * 0.04,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user is logged in")),
        );
        return;
      }

      await user.updatePassword(newPass);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'password': newPass});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error changing password")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
