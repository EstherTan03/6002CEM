import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'profile_edit.dart';
import 'shared.dart'; // contains the User model

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController emailController;
  late TextEditingController passwordController;

  bool isEditingEmail = false;
  bool isEditingPassword = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.user.email);
    passwordController = TextEditingController(text: '********');
  }

  Future<void> _loadUser() async {
    try {
      final doc = await _firestore
          .collection('username')
          .doc(widget.user.username)
          .get();
      final data = doc.data()!;
      setState(() {
        emailController.text = data['email'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      await _firestore
          .collection('username')
          .doc(widget.user.username)
          .update({'email': newEmail});

      setState(() {
        emailController.text = newEmail;
        isEditingEmail = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated successfully.')),
      );
      await _loadUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating email: $e')),
      );
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      final hashed = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await _firestore
          .collection('username')
          .doc(widget.user.username)
          .update({'password': hashed});

      setState(() {
        isEditingPassword = false;
        passwordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildReadOnlyField('Username', widget.user.username),
            buildReadOnlyField('Name', widget.user.name),
            buildReadOnlyField('Role', widget.user.role),

            // Email editable field
            buildEditableField(
              label: 'Email',
              controller: emailController,
              isEditing: isEditingEmail,
              onEditTap: () => setState(() => isEditingEmail = true),
              onConfirmTap: () async {
                final newEmail = emailController.text.trim();
                if (newEmail.isNotEmpty) {
                  await _updateEmail(newEmail);
                } else {
                  setState(() => isEditingEmail = false);
                }
              },
            ),

            buildEditableField(
              label: 'Password',
              controller: passwordController,
              isEditing: isEditingPassword,
              obscure: true,
              onEditTap: () {
                setState(() {
                  isEditingPassword = !isEditingPassword;
                  if (isEditingPassword) passwordController.clear();
                });
              },
              onConfirmTap: () async {
                final newPass = passwordController.text.trim();
                if (newPass.isNotEmpty) {
                  await _updatePassword(newPass);
                  setState(() {
                    isEditingPassword = false;
                    passwordController.text = '********'; // show masked placeholder
                  });
                } else {
                  setState(() {
                    isEditingPassword = false;
                    passwordController.text = '********'; // also show placeholder if cancelled
                  });
                }
              },

            ),
          ],
        ),
      ),
    );
  }
}
