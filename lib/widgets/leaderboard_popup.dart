import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class DynamicLeaderboardPopup extends StatefulWidget {
  final String areaName;
  final List<dynamic> leaderboardData;
  final VoidCallback onClose;

  const DynamicLeaderboardPopup({
    super.key,
    required this.areaName,
    required this.leaderboardData,
    required this.onClose,
  });

  @override
  State<DynamicLeaderboardPopup> createState() => _DynamicLeaderboardPopupState();
}

class _DynamicLeaderboardPopupState extends State<DynamicLeaderboardPopup> {
  Map<String, String?> profileImages = {};

  @override
  void initState() {
    super.initState();
    _fetchAllProfileImages();
  }

  Future<void> _fetchAllProfileImages() async {
    for (var user in widget.leaderboardData) {
      final username = user['username'];
      final image = await _fetchProfileImage(username);
      setState(() {
        profileImages[username] = image;
      });
    }
  }

  Future<String?> _fetchProfileImage(String username) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.184.180.35:4000/return-profile"), // Replace with your API base URL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['profile_image'];
      } else {
        print("⚠️ Failed to fetch profile image for $username");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching profile for $username: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text("Lead Board",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.black87,
                          decoration: TextDecoration.none,
                        )),
                    const Spacer(),
                    GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.areaName,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        color: Colors.black54,
                        decoration: TextDecoration.none,
                      )),
                ),
                const SizedBox(height: 20),
                ...widget.leaderboardData.asMap().entries.map((entry) {
                  final int rank = entry.key + 1;
                  final user = entry.value;
                  final imageUrl = profileImages[user['username']];
                  return Column(
                    children: [
                      _buildLeaderboardItem(rank, user['username'], user['scores'].toString(), imageUrl),
                      const SizedBox(height: 10),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, String pointsStr, String? profileImageUrl) {
    final int points = int.tryParse(pointsStr) ?? 0;

    String badgeTitle = points >= 30 ? "LOCAL GURU" : "STREET FACER";
    String badgeIcon = points >= 30
        ? 'assets/images/LocalGuru.png'
        : 'assets/images/points_icon.png';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          Text(
            "$rank",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                ? NetworkImage(profileImageUrl)
                : const AssetImage("assets/images/profile_dummy.jpg") as ImageProvider,
            radius: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.0,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  "$points points",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Image.asset(badgeIcon, width: 14, height: 14, color: Colors.orange),
                const SizedBox(width: 5),
                Text(
                  badgeTitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
