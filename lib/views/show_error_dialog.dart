import 'package:flutter/material.dart';

Future<void> showErrorDialoge(BuildContext context, String text) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("An error accured"),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              // Overlays are better in this case, but we will use Navigator for beginner
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}