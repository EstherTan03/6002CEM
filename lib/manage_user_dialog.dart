// lib/manage_user.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

import 'manage_send_email.dart';
import 'services/audit_logger.dart';

/// Show dialog for editing a user or handling a user request
Future<void> showEditDialog(
    BuildContext context,
    Map<String, dynamic> userData,
    VoidCallback fetchUsers,
    String adminEmail,
    ) async {
  // If it's a request (user pending approval)
  if (userData['isRequest'] == true) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Request from ${userData['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${userData['name']}'),
              Text('Email: ${userData['email']}'),
              Text('Role: ${userData['role']}'),
              const SizedBox(height: 20),
              const Text('Do you want to accept this user request?'),
            ],
          ),
          actions: [
            // ✅ Accept
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showAcceptDialog(context, userData, fetchUsers, adminEmail);
              },
              child: const Text('Accept'),
            ),

            // ❌ Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            // 🗑 Delete Request
            TextButton(
              onPressed: () async {
                final confirm = await showConfirmDeleteDialog(context);

                if (confirm == true) {
                  await FirebaseFirestore.instance
                      .collection('request')
                      .doc(userData['username'])
                      .delete();

                  // ✅ Log deletion of request
                  await AuditLogger.logPerDay(
                    action: 'REQUEST_DELETED',
                    uid: userData['username'],
                    email: userData['email'],
                    meta: {
                      'name': userData['name'],
                      'performed_by': adminEmail,
                    },
                  );

                  Navigator.pop(context);
                  fetchUsers();
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ================== Normal User Editing ==================
  else {
    String selectedRole = userData['role'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit ${userData['username']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: ${userData['name']}'),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedRole,
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                    items: ['user', 'admin', 'super_admin']
                        .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                  ),
                ],
              ),
              actions: [
                // 💾 Save updated role
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('username')
                        .doc(userData['username'])
                        .update({'role': selectedRole});

                    // ✅ Log role change
                    await AuditLogger.logPerDay(
                      action: 'ROLE_CHANGED',
                      uid: userData['username'],
                      email: userData['email'],
                      meta: {
                        'from': userData['role'],
                        'to': selectedRole,
                        'performed_by': adminEmail,
                      },
                    );

                    Navigator.pop(context);
                    fetchUsers();
                  },
                  child: const Text('Save'),
                ),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                // 🗑 Delete user
                TextButton(
                  onPressed: () async {
                    final confirm = await showConfirmDeleteDialog(context);

                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('username')
                          .doc(userData['username'])
                          .delete();

                      // ✅ Log user deletion
                      await AuditLogger.logPerDay(
                        action: 'USER_DELETED',
                        uid: userData['username'],
                        email: userData['email'],
                        meta: {
                          'name': userData['name'],
                          'role': userData['role'],
                          'performed_by': adminEmail,
                        },
                      );

                      Navigator.pop(context);
                      fetchUsers();
                    }
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Accept Request Dialog
Future<void> showAcceptDialog(
    BuildContext context,
    Map<String, dynamic> requestData,
    VoidCallback fetchUsers,
    String adminEmail,
    ) async {
  final usernameController = TextEditingController();
  String selectedRole = requestData['role'];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Accept User Request'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: ${requestData['name']}'),
                  const SizedBox(height: 10),
                  Text('Email: ${requestData['email']}'),
                  const SizedBox(height: 10),

                  // Username field
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Dropdown role
                  DropdownButton<String>(
                    value: selectedRole,
                    onChanged: (value) => setState(() => selectedRole = value!),
                    items: ['user', 'admin', 'super_admin']
                        .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),

                  const Text('Password is set to default: Sample123@'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final username = usernameController.text.trim();
                  if (username.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Please enter a username')));
                    return;
                  }

                  final firestore = FirebaseFirestore.instance;
                  final existingDoc = await firestore.collection('username').doc(username).get();

                  if (existingDoc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username already exists. Choose another.')),
                    );
                    return;
                  }

                  // Remove request entry
                  await firestore.collection('request').doc(requestData['name']).delete();

                  // Create new user with hashed default pwd
                  const defaultPassword = 'Sample123@';
                  final hashedPassword = BCrypt.hashpw(defaultPassword, BCrypt.gensalt());

                  await firestore.collection('username').doc(username).set({
                    'username': username,
                    'name': requestData['name'],
                    'email': requestData['email'],
                    'role': selectedRole,
                    'password': hashedPassword,
                  });

                  // ✅ Log accepted request
                  await AuditLogger.logPerDay(
                    action: 'USER_CREATED',
                    uid: username,
                    email: requestData['email'],
                    meta: {
                      'name': requestData['name'],
                      'role': selectedRole,
                      'performed_by': adminEmail,
                      'source': 'request_accept',
                    },
                  );

                  Navigator.pop(context);
                  fetchUsers();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User ${requestData['name']} accepted successfully")),
                  );

                  sendEmail(username, requestData['email']);
                },
                child: const Text('Submit'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Confirm delete dialog reusable
Future<bool?> showConfirmDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}
