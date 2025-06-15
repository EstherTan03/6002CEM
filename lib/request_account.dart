import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class RequestAccountLink extends StatefulWidget {
  const RequestAccountLink({super.key});

  @override
  State<RequestAccountLink> createState() => _RequestAccountLinkState();
}

class _RequestAccountLinkState extends State<RequestAccountLink> {

  CollectionReference request = FirebaseFirestore.instance.collection('request');

  void showRequestDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Request Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();

              if (name.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Don't have name or email")),
                );
                return;
              }

              if (!email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid Email.')),
                );
                return;
              }

              Map<String, dynamic> eventData = {
                'name': name,
                'email': email,
                'role': 'user',
              };

              await request
                  .doc(name)
                  .set(eventData);

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request sent successfully')),
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showRequestDialog(context),
      child: Text(
        "If don't have account, press this link",
        style: TextStyle(
          color: Colors.lightBlue,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
