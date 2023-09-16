import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Color? backgroundColor;
  final BorderRadius? shape;
  const CustomElevatedButton(
      {super.key,
      required this.text,
      required this.onPressed,
      this.backgroundColor,
      this.shape});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? darkBlueGray,
        foregroundColor: blankColor,
        shape: shape == null
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
            : RoundedRectangleBorder(borderRadius: shape!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
