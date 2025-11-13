import 'package:flutter/material.dart';

/// Builds a simple read-only text field with a label.
Widget buildReadOnlyField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ).copyWith(labelText: label),
    ),
  );
}

/// Builds an editable text field with an Edit → Confirm toggle button.
/// 
/// When [isEditing] is true, the text field becomes editable and
/// the icon changes to a confirm checkmark.
Widget buildEditableField({
  required String label,
  required TextEditingController controller,
  required bool isEditing,
  required VoidCallback onEditTap,
  required VoidCallback onConfirmTap,
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
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit),
          color: isEditing ? Colors.green : null,
          tooltip: isEditing ? 'Confirm' : 'Edit',
          onPressed: isEditing ? onConfirmTap : onEditTap,
        ),
      ],
    ),
  );
}
