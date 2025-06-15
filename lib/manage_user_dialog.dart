// manage user
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'manage_send_email.dart';

Future<void> showEditDialog(
    BuildContext context,
    Map<String, dynamic> userData,
    VoidCallback fetchUsers,
    String admin_email,
    ) async {
  if (userData['isRequest'] == true) {
    // Request dialog with Accept/Cancel buttons
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
              SizedBox(height: 20),
              Text('Do you want to accept this user request?'),
            ],

          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showAcceptDialog(context, userData, fetchUsers, admin_email);
              },
              child: Text('Accept'),
            ),
            TextButton(
              onPressed: () {
                // Just close the dialog without deleting
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm Deletion'),
                      content: Text('Are you sure you want to delete this user?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  await FirebaseFirestore.instance
                      .collection('request')
                      .doc(userData['username'])
                      .delete();
                  Navigator.pop(context);
                  fetchUsers();
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  } else {
    // Normal user edit dialog
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
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                    items: ['user', 'super_admin', 'admin']
                        .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('username')
                        .doc(userData['username'])
                        .update({'role': selectedRole});
                    Navigator.pop(context);
                    fetchUsers();
                  },
                  child: Text('Save'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirm Deletion'),
                          content: Text('Are you sure you want to delete this user?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('username')
                          .doc(userData['username'])
                          .delete();
                      Navigator.pop(context);
                      fetchUsers();
                    }
                  },
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

Future<void> showAcceptDialog(
    BuildContext context,
    Map<String, dynamic> requestData,
    VoidCallback fetchUsers,
    String admin_email,
    ) async {
  final _usernameController = TextEditingController();
  String selectedRole = requestData['role'];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Accept User Request'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: ${requestData['name']}'),
                  SizedBox(height: 10),
                  Text('Email: ${requestData['email']}'),
                  SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                    items: ['user', 'super_admin', 'admin']
                        .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 10),
                  Text('Password is set to default: 123'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final username = _usernameController.text.trim();
                  if (username.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a username')),
                    );
                    return;
                  }

                  final firestore = FirebaseFirestore.instance;
                  final existingDoc =
                  await firestore.collection('username').doc(username).get();

                  if (existingDoc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Username already exists. Choose another.')),
                    );
                    return;
                  }

                  await firestore.collection('request').doc(requestData['name']).delete();

                  await firestore.collection('username').doc(username).set({
                    'username' : _usernameController.text,
                    'name': requestData['name'],
                    'email': requestData['email'],
                    'role': selectedRole,
                    'password': '123', // default password
                  });

                  Navigator.pop(context);
                  fetchUsers();
                  String name = requestData['name'];

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User $name accepted successfully")),
                  );

                  sendEmail(_usernameController.text,admin_email,requestData['email'],);
                  print('Sfewrwerwer');

                },
                child: Text('Submit'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    },
  );
}
