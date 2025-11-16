import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadSubmit extends StatelessWidget {
  final VoidCallback onSubmit;
  final bool isUploading;

  const UploadSubmit({super.key, required this.onSubmit, required this.isUploading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: isUploading ? null : onSubmit,
          icon: const Icon(Icons.upload, size: 18),
          label: Text("Upload", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0048),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        if (isUploading) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink),
              ),
              const SizedBox(width: 10),
              Text("Uploading...", style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
            ],
          ),
        ]
      ],
    );
  }
}
