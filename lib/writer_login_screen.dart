import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'writer_dashboard_screen.dart';
import 'user_register_screen.dart';

class WriterLoginScreen extends StatefulWidget {
  const WriterLoginScreen({Key? key}) : super(key: key);

  @override
  State<WriterLoginScreen> createState() => _WriterLoginScreenState();
}

class _WriterLoginScreenState extends State<WriterLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ========================= EMAIL/PASSWORD LOGIN =========================
  Future<void> _login() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

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

  // ========================= GOOGLE LOGIN =========================
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // user canceled login
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

  // ========================= CHECK ROLE =========================
  Future<void> _checkRoleAndNavigate(String? uid,
      [GoogleSignInAccount? googleUser]) async {
    if (uid == null) throw Exception('User ID is null.');

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();

    // Prepare user data for Google login
    if (googleUser != null) {
      final userData = {
        'uid': uid,
        'name': googleUser.displayName ?? 'Unknown',
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
        'role': 'Content Writer', // force content writer
        'status': 'Active',
        'authProvider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(userData, SetOptions(merge: true));
    }

    final updatedDoc = await docRef.get();
    final data = updatedDoc.data();
    final role = data?['role'];

    if (role != null &&
        role.toString().trim().toLowerCase() == 'content writer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WriterDashboardScreen()),
      );
    } else {
      await FirebaseAuth.instance.signOut();
      throw Exception('Access denied: Not a content writer.');
    }
  }

  // ========================= ERROR SNACKBAR =========================
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  "assets/images/back btn.png",
                  height: 30,
                  width: 30,
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/writer_img1.png'),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Content Writer',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forget Password?',
                    style: TextStyle(color: Colors.pink, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
              const Center(child: Text("Or")),
              const SizedBox(height: 20),

              // ========================= GOOGLE BUTTON =========================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: Image.asset(
                    'assets/images/google icon.png',
                    width: 25,
                    height: 25,
                  ),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Not a writer yet? ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterScreen()),
                      );
                    },
                    child: const Text('Register now!',
                        style: TextStyle(color: Colors.pink)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text.rich(
                    TextSpan(
                      text: "By clicking continue, you agree to our ",
                      children: [
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
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
