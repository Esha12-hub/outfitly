import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'settings_screen.dart';

class VerifyEmailPhoneScreen extends StatefulWidget {
  const VerifyEmailPhoneScreen({super.key});

  @override
  State<VerifyEmailPhoneScreen> createState() => _VerifyEmailPhoneScreenState();
}

class _VerifyEmailPhoneScreenState extends State<VerifyEmailPhoneScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _phoneCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _isEmailCodeSent = false;
  bool _isPhoneCodeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailCodeController.dispose();
    _phoneCodeController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r"^\+?[0-9]{7,15}$");
    return phoneRegex.hasMatch(phone);
  }

  void _showSnackBar(String message, {Color? bgColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor ?? AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                  ),
                  const Expanded(
                    child: Text(
                      'Verify Email/Phone',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verify Your Contact Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure your account by verifying your email and phone number.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Email Verification Section
                        _buildVerificationSection(
                          'Email Verification',
                          Icons.email,
                          _emailController,
                          'Enter your email address',
                          'Email',
                          _isEmailVerified,
                          _isEmailCodeSent,
                          _emailCodeController,
                          _sendEmailCode,
                          _verifyEmailCode,
                        ),
                        const SizedBox(height: 24),

                        // Phone Verification Section
                        _buildVerificationSection(
                          'Phone Verification',
                          Icons.phone,
                          _phoneController,
                          'Enter your phone number',
                          'Phone',
                          _isPhoneVerified,
                          _isPhoneCodeSent,
                          _phoneCodeController,
                          _sendPhoneCode,
                          _verifyPhoneCode,
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveVerification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textWhite,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Save Verification Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection(
      String title,
      IconData icon,
      TextEditingController controller,
      String hint,
      String label,
      bool isVerified,
      bool isCodeSent,
      TextEditingController codeController,
      VoidCallback onSendCode,
      VoidCallback onVerifyCode,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? AppColors.success : Colors.grey[300]!,
          width: isVerified ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (!isVerified) ...[
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your $label';
                }
                if (label == 'Email' && !_isValidEmail(value)) {
                  return 'Please enter a valid email';
                }
                if (label == 'Phone' && !_isValidPhone(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            if (isCodeSent) ...[
              TextFormField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter 6-digit code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                if (!isCodeSent)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Send Code'),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onVerifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Verify Code'),
                    ),
                  ),
                const SizedBox(width: 12),
                if (isCodeSent)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSendCode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Resend'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _sendEmailCode() {
    if (_emailController.text.isEmpty || !_isValidEmail(_emailController.text)) {
      _showSnackBar('Please enter a valid email address', bgColor: Colors.red);
      return;
    }

    setState(() => _isEmailCodeSent = true);
    _showSnackBar('Verification code sent to ${_emailController.text}', bgColor: AppColors.success);
  }

  void _sendPhoneCode() {
    if (_phoneController.text.isEmpty || !_isValidPhone(_phoneController.text)) {
      _showSnackBar('Please enter a valid phone number', bgColor: Colors.red);
      return;
    }

    setState(() => _isPhoneCodeSent = true);
    _showSnackBar('Verification code sent to ${_phoneController.text}', bgColor: AppColors.success);
  }

  void _verifyEmailCode() {
    if (_emailCodeController.text.length != 6) {
      _showSnackBar('Please enter a valid 6-digit code', bgColor: Colors.red);
      return;
    }

    setState(() => _isEmailVerified = true);
    _showSnackBar('Your email has been successfully verified!', bgColor: AppColors.success);
  }

  void _verifyPhoneCode() {
    if (_phoneCodeController.text.length != 6) {
      _showSnackBar('Please enter a valid 6-digit code', bgColor: Colors.red);
      return;
    }

    setState(() => _isPhoneVerified = true);
    _showSnackBar('Your phone number has been successfully verified!', bgColor: AppColors.success);
  }

  void _saveVerification() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);
    _showSnackBar('Verification status saved successfully!', bgColor: AppColors.success);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
          (route) => false,
    );
  }
}
