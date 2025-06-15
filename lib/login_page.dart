import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'home_page.dart';
import 'shared.dart';
import 'request_account.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  CollectionReference users = FirebaseFirestore.instance.collection('username');

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String errorMessage = '';

  Future<void> loginUser() async {
    try {
      QuerySnapshot result = await users
          .where('username', isEqualTo: usernameController.text)
          .where('password', isEqualTo: passwordController.text)
          .get();

      if (result.docs.isNotEmpty) {
        // Login successful
        var username = result.docs.first.get('username');
        var name = result.docs.first.get('name');
        var role = result.docs.first.get('role');
        var email = result.docs.first.get('email');
        var password = result.docs.first.get('password');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Login Successful'),
              actions: [
                TextButton(
                  onPressed: () {
                    // After login validation
                    final user = User(username: username, name: name, role: role, email: email, password: password);
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (child) => HomePage(user: user),
                      ),
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );

        // Navigate to next screen or dashboard
      } else {
        setState(() {
          errorMessage = 'Invalid username or password';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error occurred during login';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            Column(
              children: [
                // your other widgets
                SizedBox(height: 20),
                RequestAccountLink(),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginUser,
              child: Text('Login'),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
