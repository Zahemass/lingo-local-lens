import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThumbnailSelector extends StatelessWidget {
  final File? thumbnail;
  final VoidCallback? onTap; // ✅ Add this

  const ThumbnailSelector({
    super.key,
    required this.thumbnail,
    this.onTap, // ✅ Constructor accepts it
  });

  @override
  Widget build(BuildContext context) {
    if (thumbnail == null) return const SizedBox();

    return GestureDetector( // ✅ Make it tappable
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thumbnail Preview:",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              thumbnail!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
