import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forgot_password.dart';
import 'continue_as_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({Key? key}) : super(key: key);

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ========================= EMAIL/PASSWORD LOGIN =========================
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        _showErrorSnackBar("Login failed: user not found");
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        _showErrorSnackBar("User data not found");
        await FirebaseAuth.instance.signOut();
        return;
      }

      final role = userDoc['role']?.toString().toLowerCase() ?? 'user';

      if (role != 'admin' && role != 'user') {
        _showErrorSnackBar("You are not allowed to login");
        await FirebaseAuth.instance.signOut();
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WardrobeHomeScreen()),
      );

    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Login failed.');
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========================= GOOGLE LOGIN =========================
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return;

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        await userDocRef.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName,
          'photoURL': user.photoURL,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final role = (docSnapshot['role'] ?? 'user').toString().toLowerCase();
      if (role != 'admin' && role != 'user') {
        _showErrorSnackBar("You are not allowed to login");
        await FirebaseAuth.instance.signOut();
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WardrobeHomeScreen()),
      );
    } catch (e) {
      _showErrorSnackBar("Google sign-in failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery for responsive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final buttonHeight = screenHeight * 0.07;
    final spacing = screenHeight * 0.02;
    final titleFontSize = screenHeight * 0.035;
    final inputFontSize = screenHeight * 0.02;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  height: screenHeight * 0.04,
                  width: screenHeight * 0.04,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ContinueAsScreen()),
                      );
                    },
                    child: SizedBox(
                      height: screenHeight * 0.04,
                      width: screenHeight * 0.04,
                      child: Image.asset("assets/images/back btn.png"),
                    ),
                  ),

                ),
              ),
              SizedBox(height: spacing),
              Text(
                'Welcome back! Glad to\nSee you, Again!',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: spacing * 1.5),
              _buildTextField(
                controller: _emailController,
                hint: 'Enter your email',
                fontSize: inputFontSize,
              ),
              SizedBox(height: spacing),
              _buildTextField(
                controller: _passwordController,
                hint: 'Password',
                fontSize: inputFontSize,
                isPassword: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen()));
                  },
                  child: const Text(
                    'Forget Password?',
                    style: TextStyle(color: Colors.pink),
                  ),
                ),
              ),
              SizedBox(height: spacing / 2),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: inputFontSize),
                  ),
                ),
              ),
              SizedBox(height: spacing * 2),
              Center(child: Text("Or", style: TextStyle(fontSize: inputFontSize))),
              SizedBox(height: spacing),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
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
                      fontSize: inputFontSize,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: spacing / 2),
                  ),
                ),
              ),
              SizedBox(height: spacing * 3),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        'Register now!',
                        style: TextStyle(color: Colors.pink),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing / 2),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Text.rich(
                    TextSpan(
                      text: "By clicking continue, you agree to our ",
                      children: const [
                        TextSpan(
                          text: "Terms of Service",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: inputFontSize * 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    double fontSize = 16,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: fontSize * 1.2, horizontal: fontSize),
      ),
      style: TextStyle(fontSize: fontSize),
    );
  }
}
