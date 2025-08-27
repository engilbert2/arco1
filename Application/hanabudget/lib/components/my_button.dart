import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text; // Add this field

  const MyButton({super.key, required this.onTap, this.text = "Sign In"}); // Update constructor

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(25.0),
        margin: EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: Color(0xFF1ED891),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text, // Use the text field
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16
            ),
          ),
        ),
      ),
    );
  }
}