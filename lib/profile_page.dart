import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_navigation.dart';
import 'shared.dart';

import 'profile_edit.dart';

class ProfilePage extends StatefulWidget{
  final User user;
  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  bool isEditingEmail = false;
  bool isEditingPassword = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.user.email ?? '');
    passwordController = TextEditingController(text: widget.user.password ?? '');
  }

  Future<void> saveChanges() async {
    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('username')
          .doc(widget.user.username) // Assuming username is used as the document ID
          .update({
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );

      setState(() {
        isEditingEmail = false;
        isEditingPassword = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
        );
      }
      setState(() => isSaving = false);
    }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: Builder(
          builder: (context) =>
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        backgroundColor: Color(0xFF94B4C1),
      ),
      drawer: AppDrawer(
        user: widget.user,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildReadOnlyField('Username', widget.user.username),
            buildReadOnlyField('Name', widget.user.name),
            buildReadOnlyField('Role', widget.user.role),

            buildEditableField(
              label: 'Email',
              controller: emailController,
              isEditing: isEditingEmail,
              onEditTap: () => setState(() => isEditingEmail = true),
            ),
            buildEditableField(
              label: 'Password',
              controller: passwordController,
              isEditing: isEditingPassword,
              obscure: true,
              onEditTap: () => setState(() => isEditingPassword = true),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : saveChanges,
              child: isSaving
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
