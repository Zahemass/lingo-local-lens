import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassMapPin extends StatelessWidget {
  final String distance;
  final String emoji;
  final String label;

  const GlassMapPin({
    Key? key,
    required this.distance,
    required this.emoji,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 📏 Distance label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.pinkAccent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            distance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 5),

        // 📍 Glass marker
        GlassmorphicContainer(
          width: 50,
          height: 50,
          borderRadius: 25,
          blur: 20,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderGradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.white.withOpacity(0.1),
            ],
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),

        const SizedBox(height: 4),

        // 🏷️ Label
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
