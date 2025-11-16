import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangeNameScreen extends StatefulWidget {
  const ChangeNameScreen({super.key});

  @override
  State<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updateName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': newName,
      });
      await user.updateDisplayName(newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating name: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
              SizedBox(height: height * 0.06),
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
                          "Change Name",
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
                          "Update your display name",
                          style: TextStyle(
                            fontSize: 18 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: height * 0.03),
                        Text(
                          "New Name",
                          style: TextStyle(
                            fontSize: 15 * textScale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: width * 0.02),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: "Enter your new name",
                            hintStyle: TextStyle(fontSize: 14 * textScale),
                            filled: true,
                            fillColor: Colors.grey.shade200,
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
                        SizedBox(height: height * 0.05),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _updateName,
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
                            "Save Changes",
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
}
