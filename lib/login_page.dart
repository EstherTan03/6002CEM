// lib/login_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

import 'home_page.dart';
import 'shared.dart';
import 'request_account.dart';
import 'services/audit_logger.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final CollectionReference users = FirebaseFirestore.instance.collection('username');

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';

  Future<void> loginUser() async {
    final typedUsername = usernameController.text.trim();
    final typedPassword = passwordController.text.trim();

    if (typedUsername.isEmpty || typedPassword.isEmpty) {
      setState(() => errorMessage = 'Please enter both username and password');
      return;
    }

    try {
      // ✅ Fetch user by username only
      final QuerySnapshot query = await users
          .where('username', isEqualTo: typedUsername)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => errorMessage = 'Invalid username or password');

        await AuditLogger.logPerDay(
          action: 'LOGIN_FAILED',
          meta: {
            'screen': 'LoginPage',
            'reason': 'username_not_found',
            'username_entered': typedUsername,
          },
        );
        return;
      }

      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>? ?? {};

      if (data.isEmpty || !data.containsKey('password')) {
        setState(() => errorMessage = 'Invalid username or password');

        await AuditLogger.logPerDay(
          action: 'LOGIN_FAILED',
          meta: {
            'screen': 'LoginPage',
            'reason': 'user_record_missing_password',
            'username_entered': typedUsername,
          },
        );
        return;
      }

      final storedPassword = data['password'] as String? ?? '';
      bool verified = false;

      // ✅ Detect if stored password is hashed or plaintext
      final bool isHashed = storedPassword.startsWith(r'$2a$') || storedPassword.startsWith(r'$2b$');

      if (isHashed) {
        // Compare hashed password
        verified = BCrypt.checkpw(typedPassword, storedPassword);
      } else {
        // Compare plaintext password
        if (typedPassword == storedPassword) {
          verified = true;

          // 🔥 Auto-upgrade to bcrypt hashed password
          final newHash = BCrypt.hashpw(typedPassword, BCrypt.gensalt());
          await users.doc(doc.id).update({'password': newHash});
        }
      }

      if (!verified) {
        setState(() => errorMessage = 'Invalid username or password');

        await AuditLogger.logPerDay(
          action: 'LOGIN_FAILED',
          meta: {
            'screen': 'LoginPage',
            'reason': 'password_mismatch',
            'username_entered': typedUsername,
          },
        );
        return;
      }

      // ===== ✅ Login Success =====
      final username = data['username'] ?? '';
      final name = data['name'] ?? '';
      final role = data['role'] ?? 'user';
      final email = data['email'] ?? '';
      final password = storedPassword; // hashed (safe in memory)

      await AuditLogger.logPerDay(
        action: 'LOGIN_SUCCESS',
        uid: username,
        email: email.isNotEmpty ? email : null,
        meta: {
          'screen': 'LoginPage',
          'username_entered': typedUsername,
        },
      );

      if (!mounted) return;

      // ✅ Show success dialog
      showDialog(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Login Successful'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop(); // Close dialog first

                  final user = User(
                    username: username,
                    name: name,
                    role: role,
                    email: email,
                    password: password,
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomePage(user: user)),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      setState(() => errorMessage = 'Something went wrong. Please try again.');

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
            const RequestAccountLink(),
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
