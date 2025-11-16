import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BadgePopup extends StatelessWidget {
  final VoidCallback onClose;
  final int score;

  const BadgePopup({
    super.key,
    required this.onClose,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final isLocalGuru = score >= 30;
    final badgeTitle = isLocalGuru ? 'LOCAL GURU' : 'STREET FACER';
    final badgeMessage = isLocalGuru
        ? 'Hurray! You achived $score points\nso you earned LOCAL GURU BADGE!'
        : 'You got $score points\nso you earned STREET FACER BADGE!';
    final badgeIcon = isLocalGuru
        ? 'assets/images/LocalGuru.png'
        : 'assets/images/post_points.png';

    return Stack(
      children: [
        // Background blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),

        // Centered popup card
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: onClose,
                        child: const Icon(Icons.close, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(badgeIcon, width: 50, height: 50),
                    const SizedBox(height: 18),
                    Text(
                      badgeTitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        decoration: TextDecoration.none, // ✅ No underline
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      badgeMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        decoration: TextDecoration.none, // ✅ No underline
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: [
                              Colors.pinkAccent.withOpacity(0.7),
                              Colors.pink.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            decoration: TextDecoration.none, // ✅ No underline
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
