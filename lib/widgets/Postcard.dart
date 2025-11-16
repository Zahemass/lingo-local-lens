import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';

void showDeleteGlassPopup(BuildContext context, VoidCallback onDelete) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          // FULLSCREEN BLUR BACKGROUND
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),

          // CENTERED DELETE DIALOG
          Center(
            child: GlassmorphicContainer(
              width: 300,
              height: 200,
              borderRadius: 20,
              blur: 20,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderGradient: LinearGradient(
                colors: [Colors.white24, Colors.white10],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sure! Do you want to delete the post?",
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none, // ✅ Remove underline
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel Button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: GlassmorphicContainer(
                            width: 100,
                            height: 40,
                            borderRadius: 12,
                            blur: 20,
                            alignment: Alignment.center,
                            border: 1,
                            linearGradient: LinearGradient(
                              colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.2)],
                            ),
                            borderGradient: LinearGradient(
                              colors: [Colors.white70, Colors.white38],
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 13, // ✅ Reduced font size
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        // Delete Button
                        GestureDetector(
                          onTap: () {
                            onDelete();
                            Navigator.of(context).pop();
                          },
                          child: GlassmorphicContainer(
                            width: 100,
                            height: 40,
                            borderRadius: 12,
                            blur: 20,
                            alignment: Alignment.center,
                            border: 1,
                            linearGradient: LinearGradient(
                              colors: [Colors.black87, Colors.black54],
                            ),
                            borderGradient: LinearGradient(
                              colors: [Colors.black54, Colors.black26],
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 13, // ✅ Reduced font size
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
