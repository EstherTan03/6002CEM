// lib/login_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'home_page.dart';
import 'shared.dart';
import 'request_account.dart';
import 'services/audit_logger.dart'; // 👈 add this

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  CollectionReference users = FirebaseFirestore.instance.collection('username');

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';

  Future<void> loginUser() async {
    final typedUsername = usernameController.text.trim();
    final typedPassword = passwordController.text.trim();

    try {
      final result = await users
          .where('username', isEqualTo: typedUsername)
          .where('password', isEqualTo: typedPassword)
          .get();

      if (result.docs.isNotEmpty) {
        // ===== Login successful =====
        final doc = result.docs.first;
        final username = doc.get('username') as String? ?? '';
        final name     = doc.get('name')     as String? ?? '';
        final role     = doc.get('role')     as String? ?? 'user';
        final email    = doc.get('email')    as String? ?? '';
        final password = doc.get('password') as String? ?? ''; // (stored plaintext—consider hashing later)

        // 🔎 Write audit log (per-day structure)
        await AuditLogger.logPerDay(
          action: 'LOGIN_SUCCESS',
          uid: username,                 // use uid as doc id
          email: email.isNotEmpty ? email : null,
          meta: {
            'screen': 'LoginPage',
            'username_entered': typedUsername, // DO NOT log the password
          },
        );

        // UI dialog & navigation
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Login Successful'),
              actions: [
                TextButton(
                  onPressed: () {
                    final user = User(
                      username: username,
                      name: name,
                      role: role,
                      email: email,
                      password: password,
                    );
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (child) => HomePage(user: user)),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // ===== Invalid credentials =====
        setState(() {
          errorMessage = 'Invalid username or password';
        });

        // 🔎 Audit log for failed attempt
        await AuditLogger.logPerDay(
          action: 'LOGIN_FAILED',
          meta: {
            'screen': 'LoginPage',
            'username_entered': typedUsername,
          },
        );
      }
    } catch (e) {
      // ===== Error path =====
      setState(() {
        errorMessage = 'Error occurred during login';
      });

      // 🔎 Audit log for unexpected error
      await AuditLogger.logPerDay(
        action: 'LOGIN_ERROR',
        meta: {
          'screen': 'LoginPage',
          'username_entered': typedUsername,
          'error': e.toString(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Page')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            Column(
              children: const [
                SizedBox(height: 20),
                RequestAccountLink(),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginUser,
              child: const Text('Login'),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
