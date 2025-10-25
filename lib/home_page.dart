import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_navigation.dart';
import 'shared.dart';
import 'home_page_card.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPasswordAndPrompt());
  }

  bool _isWeak(String? pw) {
    final p = (pw ?? '').trim();
    final hasMinLen = p.length >= 8;
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];~+=]').hasMatch(p);
    return !(hasMinLen && hasSpecial);
  }

  Future<void> _checkPasswordAndPrompt() async {
    if (_isWeak(widget.user.password)) {
      _showChangePasswordDialog();
    }
  }

  void _showChangePasswordDialog() {
    final pw1 = TextEditingController();
    final pw2 = TextEditingController();
    String? err1;
    String? err2;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> save() async {
              final a = pw1.text.trim();
              final b = pw2.text.trim();
              final okLen = a.length >= 8;
              final okSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];~+=]').hasMatch(a);
              final match = a == b;

                  setState(() {
                err1 = (!okLen || !okSpecial)
                    ? 'Min 8 chars and at least 1 special character.'
                    : null;
                err2 = match ? null : 'Passwords do not match.';
              });
              if (err1 != null || err2 != null) return;

              try {
              setState(() => saving = true);
              await FirebaseFirestore.instance
                  .collection('username')
                  .doc(widget.user.username)
                  .update({'password': a});
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password updated')),
              );
              } catch (e) {
              setState(() {
              err1 = 'Failed to update password. Please try again.';
              });
              } finally {
              if (ctx.mounted) setState(() => saving = false);
              }
            }

            return AlertDialog(
              title: const Text('Update Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Password must be at least 8 characters and include a special character.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pw1,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      errorText: err1,
                    ),
                    onSubmitted: (_) => save(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pw2,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      errorText: err2,
                    ),
                    onSubmitted: (_) => save(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Keep dialog non-skip
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: const Color(0xFFDBFFCB),
      ),
      drawer: AppDrawer(user: widget.user),
      body: HomePageCard(currentUser: widget.user),
    );
  }
}
