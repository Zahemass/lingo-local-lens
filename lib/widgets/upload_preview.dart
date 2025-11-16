import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadPreview extends StatelessWidget {
  final File? uploadedAudio;
  final String? recordedAudioPath;

  const UploadPreview({super.key, this.uploadedAudio, this.recordedAudioPath});

  @override
  Widget build(BuildContext context) {
    if (recordedAudioPath != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recorded Audio:", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("🎤 ${recordedAudioPath!.split('/').last}", style: GoogleFonts.montserrat()),
          const SizedBox(height: 16),
        ],
      );
    } else if (uploadedAudio != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Uploaded Audio:", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("🎵 ${uploadedAudio!.path.split('/').last}", style: GoogleFonts.montserrat()),
          const SizedBox(height: 16),
        ],
      );
    }
    return const SizedBox();
  }
}
