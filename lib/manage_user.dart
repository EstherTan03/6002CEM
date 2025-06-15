import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_navigation.dart';
import 'shared.dart';

import 'manage_user_dialog.dart';
class ManageUser extends StatefulWidget{
  final User user;
  const ManageUser({Key? key, required this.user}) : super(key: key);

  @override
  State<ManageUser> createState() => _ManageUserState();
}

class _ManageUserState extends State<ManageUser> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final firestore = FirebaseFirestore.instance;

    // Fetch requests from 'request' collection (assuming this is what you mean by "request detail")
    final requestSnapshot = await firestore.collection('request').get();
    final requestUsers = requestSnapshot.docs.map((doc) {
      final request_data = doc.data();
      return {
        'name': request_data['name'] ?? '',
        'email': request_data['email'] ?? '',
        'role': request_data['role'] ?? 'user',
        'isRequest': true, // flag to mark as request
      };
    }).toList();

    // Fetch normal users from 'username' collection
    final userSnapshot = await firestore.collection('username').get();
    final normalUsers = userSnapshot.docs.map((doc) {
      final user_data = doc.data();
      return {
        'username': doc.id,
        'name': user_data['name'] ?? '',
        'role': user_data['role'] ?? '',
        'isRequest': false,
      };
    }).toList();

    // Combine lists, requests first
    final combinedList = [...requestUsers, ...normalUsers];

    setState(() {
      users = combinedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage User'),
        leading: Builder(
          builder: (context) =>
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        backgroundColor: Color(0xFFBBD8A3),
      ),
      drawer: AppDrawer(
        user: widget.user,
      ),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, index) {
          final user = users[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: user['isRequest'] ? Colors.yellow[100] : null,
            child: ListTile(
              title: Text('Name: ${user['name']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user['username'] != null && user['username'].toString().isNotEmpty)
                    Text('Username: ${user['username']}'),
                  Text('Role: ${user['role']}'),
                  if (user['isRequest'] == true)
                    Text('Request Pending', style: TextStyle(color: Colors.orange)),
                ],
              ),
              onTap: () => showEditDialog(context, user, fetchUsers, widget.user.email),
            ),
          );
        },
      ),
    );
  }
}