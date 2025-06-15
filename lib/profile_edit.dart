// profile_page
import 'package:flutter/material.dart';

Widget buildReadOnlyField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    ),
  );
}

Widget buildEditableField({
  required String label,
  required TextEditingController controller,
  required bool isEditing,
  required VoidCallback onEditTap,
  bool obscure = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: !isEditing,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: onEditTap,
        ),
      ],
    ),
  );
}