import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassDetailBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final int views;
  final VoidCallback onDirectionTap;
  final VoidCallback onPlayTap;
  final VoidCallback onCloseTap;

  const GlassDetailBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.views,
    required this.onDirectionTap,
    required this.onPlayTap,
    required this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 220,
      borderRadius: 30,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.2), Colors.white38.withOpacity(0.2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.2), Colors.white24.withOpacity(0.2)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Direction
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDirectionTap,
                  child: GlassmorphicContainer(
                    width: 100,
                    height: 35,
                    borderRadius: 12,
                    blur: 10,
                    alignment: Alignment.center,
                    border: 1,
                    linearGradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                    ),
                    borderGradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.2), Colors.white24.withOpacity(0.2)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Direction",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                        SizedBox(width: 5),
                        Icon(Icons.navigation, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCloseTap,
                  child: const Icon(Icons.close, size: 22, color: Colors.black),
                ),
              ],
            ),


            const SizedBox(height: 12),

            // Description
            Text(
              description.length > 150 ? '${description.substring(0, 101)}...' : description,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),


            const Spacer(),

            // View Count & Play Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(views.toString()),
                  ],
                ),
                GestureDetector(
                  onTap: onPlayTap,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Text("PLAY",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 5),
                        Icon(Icons.play_circle, color: Colors.white),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
