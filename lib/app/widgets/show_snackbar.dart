import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

showSnackbar(BuildContext context, String? message) {
  if (kDebugMode) {
    print(message);
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 3), content: Text("$message")));
}
