import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();

  String? _selectedRole;
  String? _selectedSecurityOption;
  bool _agreeTerms = false;
  bool _isLoading = false;
  File? _selectedImage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final List<String> _roles = ['User', 'Content Writer'];
  final List<String> _securityOptions = ['PIN', 'Security Question'];

  Future<void> _pickBirthday() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _birthdayController.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) setState(() => _selectedImage = File(pickedImage.path));
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to Terms & Conditions')),
      );
      return;
    }
    if (_selectedRole == null || _selectedSecurityOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all options')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      String? imageBase64;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        if (bytes.lengthInBytes > 900000) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image too large. Please pick a smaller image.')),
          );
          setState(() => _isLoading = false);
          return;
        }
        imageBase64 = base64Encode(bytes);
      }

      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'birthday': _birthdayController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'image_base64': imageBase64 ?? '',
          'status': 'Active',
          'securityMethod': _selectedSecurityOption,
          'pin': _selectedSecurityOption == 'PIN' ? _pinController.text.trim() : '',
          'securityAnswer': _selectedSecurityOption == 'Security Question'
              ? _securityAnswerController.text.trim()
              : '',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    FormFieldValidator<String>? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.03),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: screenHeight * 0.035,
                      width: screenHeight * 0.035,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenHeight * 0.028,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.1), // placeholder
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.03,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double formWidth = constraints.maxWidth > 600 ? 500 : constraints.maxWidth;
                    return Center(
                      child: SingleChildScrollView(
                        child: Container(
                          width: formWidth,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Profile Image Picker
                                Center(
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: screenHeight * 0.07,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                                        child: _selectedImage == null
                                            ? Icon(Icons.person, size: screenHeight * 0.07, color: Colors.white)
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: _pickImage,
                                          child: Container(
                                            padding: EdgeInsets.all(screenHeight * 0.01),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black,
                                            ),
                                            child: Icon(Icons.camera_alt, size: screenHeight * 0.025, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                _buildTextField(
                                  controller: _nameController,
                                  hint: 'Name',
                                  validator: (value) => value!.isEmpty ? 'Enter name' : null,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                _buildTextField(
                                  controller: _emailController,
                                  hint: 'Email',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Enter email';
                                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                _buildTextField(
                                  controller: _birthdayController,
                                  hint: 'Birthday',
                                  readOnly: true,
                                  onTap: _pickBirthday,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                                  onChanged: (value) => setState(() => _selectedRole = value),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 16),
                                    hintText: 'Select Role',
                                  ),
                                  validator: (value) => value == null ? 'Select a role' : null,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                DropdownButtonFormField<String>(
                                  value: _selectedSecurityOption,
                                  items: _securityOptions
                                      .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedSecurityOption = value),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 16),
                                    hintText: 'Select Security Option',
                                  ),
                                  validator: (value) => value == null ? 'Please select a security option' : null,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                if (_selectedSecurityOption == 'PIN')
                                  _buildTextField(
                                    controller: _pinController,
                                    hint: 'Enter 4-digit PIN',
                                    isPassword: true,
                                    validator: (value) {
                                      if (_selectedSecurityOption == 'PIN' && (value == null || value.length != 4)) {
                                        return 'PIN must be 4 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                if (_selectedSecurityOption == 'Security Question') ...[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Security Question: Favorite teacher\'s name?',
                                      style: TextStyle(fontSize: screenHeight * 0.022, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  _buildTextField(
                                    controller: _securityAnswerController,
                                    hint: 'Enter Answer',
                                    isPassword: true,
                                    validator: (value) => value!.isEmpty ? 'Enter answer' : null,
                                  ),
                                ],
                                SizedBox(height: screenHeight * 0.02),
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  isPassword: true,
                                  validator: (value) => value!.length < 6 ? 'Min 6 chars' : null,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  hint: 'Confirm Password',
                                  isPassword: true,
                                  validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _agreeTerms,
                                      onChanged: (value) => setState(() => _agreeTerms = value!),
                                    ),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: 'Agree with ',
                                          children: [
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style: TextStyle(color: Colors.pink.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.065,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink.shade600,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                      'Register',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenHeight * 0.022),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
