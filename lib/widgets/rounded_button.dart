// rounded_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget roundedButton({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, color: Colors.black),
    label: Text(
      text,
      style: GoogleFonts.montserrat(
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
    ),
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
