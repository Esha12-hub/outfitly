import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../main.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../screens/dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      final adminDoc =
      await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      if (!adminDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not authorized as an admin')),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = width * 0.06;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyApp()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MyApp()),
                        );
                      },
                      child: Image.asset(
                        "assets/images/back btn.png",
                        height: width * 0.07,
                        width: width * 0.07,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Admin Login',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: width * 0.06,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: width * 0.12),
                  ],
                ),
                SizedBox(height: width * 0.06),
                Center(
                  child: Container(
                    width: width * 0.25,
                    height: width * 0.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.person,
                      size: width * 0.125,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: width * 0.05),
                Center(
                  child: Text(
                    'Welcome Back!',
                    style: AppTextStyles.h2.copyWith(fontSize: width * 0.05),
                  ),
                ),
                SizedBox(height: width * 0.06),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: width * 0.04),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Password',
                  obscureText: !_isPasswordVisible,
                  suffixWidget: IconButton(
                    onPressed: _togglePasswordVisibility,
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: width * 0.05,
                    ),
                  ),
                ),
                SizedBox(height: width * 0.06),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isLoading ? 'Logging in...' : 'Login',
                    onPressed: _isLoading ? null : _handleLogin,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
