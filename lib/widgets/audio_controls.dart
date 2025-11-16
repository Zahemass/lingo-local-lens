import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sample_proj/widgets/rounded_button.dart';

class AudioControls extends StatelessWidget {
  final bool isRecording;
  final int recordedSeconds;
  final VoidCallback onAudioOptions;
  final VoidCallback onStopRecording;
  final VoidCallback onAddThumbnail; // ✅ NEW

  const AudioControls({
    super.key,
    required this.isRecording,
    required this.recordedSeconds,
    required this.onAudioOptions,
    required this.onStopRecording,
    required this.onAddThumbnail, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    return isRecording
        ? Column(
      children: [
        Stack(
          children: [
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.pink, width: 3),
              ),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.stop_circle, color: Colors.red),
                label: Text("Stop Recording", style: GoogleFonts.montserrat()),
                onPressed: onStopRecording,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: recordedSeconds / 45.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.pink.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text("⏱ $recordedSeconds seconds",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      ],
    )
        : Row(
      children: [
        Expanded(
          child: roundedButton(
            icon: Iconsax.microphone,
            text: "Audio Options",
            onTap: onAudioOptions,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: roundedButton(
            icon: Icons.image,
            text: "Add Thumbnail",
            onTap: onAddThumbnail,
          ),
        ),
      ],
    );
  }
}


