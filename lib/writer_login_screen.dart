import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'writer_dashboard_screen.dart';
import 'user_register_screen.dart';
import 'writer_forgot_password.dart';
import 'continue_as_screen.dart';

class WriterLoginScreen extends StatefulWidget {
  const WriterLoginScreen({Key? key}) : super(key: key);

  @override
  State<WriterLoginScreen> createState() => _WriterLoginScreenState();
}

class _WriterLoginScreenState extends State<WriterLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // 👁️ Added for show/hide password

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ✅ Restrict to outfitly.com domain
    if (!email.toLowerCase().endsWith('@outfitly.com')) {
      _showErrorSnackBar('Only @outfitly.com emails are allowed for writers.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _checkRoleAndNavigate(userCredential.user?.uid);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Authentication error');
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();

      // Allow account selection again
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // User canceled login

      // ✅ Restrict to outfitly.com domain
      if (!googleUser.email.toLowerCase().endsWith('@outfitly.com')) {
        await googleSignIn.signOut();
        _showErrorSnackBar(
            'Only @outfitly.com accounts are allowed for writers.');
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      await _checkRoleAndNavigate(userCredential.user?.uid, googleUser);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkRoleAndNavigate(String? uid,
      [GoogleSignInAccount? googleUser]) async {
    if (uid == null) throw Exception('User ID is null.');

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();

    final data = doc.data();

    if (data != null) {
      final role = data['role']?.toString().trim().toLowerCase();

      if (role != 'content writer') {
        await FirebaseAuth.instance.signOut();
        throw Exception(
            'Access denied: This account is registered as a User, not a Content Writer.');
      }
    } else if (googleUser != null) {
      // New Google Content Writer
      final userData = {
        'uid': uid,
        'name': googleUser.displayName ?? 'Unknown',
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
        'role': 'Content Writer',
        'status': 'Active',
        'authProvider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(userData);
    } else {
      // No document exists for non-Google login
      await FirebaseAuth.instance.signOut();
      throw Exception(
          'Access denied: User not registered as a Content Writer.');
    }

    // Navigate to dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WriterDashboardScreen()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final paddingH = screenWidth * 0.06;
    final spacingV = screenHeight * 0.02;
    final avatarRadius = screenHeight * 0.07;
    final inputFontSize = screenHeight * 0.018;
    final titleFontSize = screenHeight * 0.03;
    final buttonHeight = screenHeight * 0.065;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          EdgeInsets.symmetric(horizontal: paddingH, vertical: spacingV),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ContinueAsScreen()),
                  );
                },
                child: SizedBox(
                  height: spacingV * 1.5,
                  width: spacingV * 1.5,
                  child: Image.asset("assets/images/back btn.png"),
                ),
              ),
              SizedBox(height: spacingV),
              Center(
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage:
                  const AssetImage('assets/images/writer_img1.png'),
                ),
              ),
              SizedBox(height: spacingV),
              Center(
                child: Text(
                  'Content Writer',
                  style: TextStyle(
                      fontSize: titleFontSize, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: inputFontSize, color: Colors.grey),
                ),
              ),
              SizedBox(height: spacingV),
              _buildTextField(
                  _emailController, 'Enter your email', inputFontSize),
              SizedBox(height: spacingV),
              _buildTextField(_passwordController, 'Password', inputFontSize,
                  isPassword: true),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                WriterForgotPasswordScreen()));
                  },
                  child: Text(
                    'Forget Password?',
                    style:
                    TextStyle(color: Colors.pink, fontSize: inputFontSize),
                  ),
                ),
              ),
              SizedBox(height: spacingV),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Login',
                      style: TextStyle(
                          color: Colors.white, fontSize: inputFontSize)),
                ),
              ),
              SizedBox(height: spacingV * 2),
              Center(
                  child: Text("Or", style: TextStyle(fontSize: inputFontSize))),
              SizedBox(height: spacingV),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: Image.asset(
                    'assets/images/google icon.png',
                    width: screenWidth * 0.07,
                    height: screenWidth * 0.07,
                  ),
                  label: Text(
                    "Continue with Google",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: inputFontSize),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: spacingV / 2),
                  ),
                ),
              ),
              SizedBox(height: spacingV * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Not a writer yet? ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: inputFontSize),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterScreen()),
                      );
                    },
                    child: Text('Register now!',
                        style: TextStyle(
                            color: Colors.pink, fontSize: inputFontSize)),
                  ),
                ],
              ),
              SizedBox(height: spacingV / 2),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingH / 2),
                  child: Text.rich(
                    TextSpan(
                      text: "By clicking continue, you agree to our ",
                      children: const [
                        TextSpan(
                            text: "Terms of Service",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: " and "),
                        TextSpan(
                            text: "Privacy Policy",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: inputFontSize * 0.8),
                  ),
                ),
              ),
              SizedBox(height: spacingV),
            ],
          ),
        ),
      ),
    );
  }

  // 👇 Updated text field builder with show/hide password icon
  Widget _buildTextField(
      TextEditingController controller, String hint, double fontSize,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
        EdgeInsets.symmetric(vertical: fontSize * 1.5, horizontal: fontSize),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
            : null,
      ),
      style: TextStyle(fontSize: fontSize),
    );
  }
}
