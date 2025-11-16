import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sample_proj/components/app_bar.dart';
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/screens/upload_screen.dart';
import 'package:sample_proj/screens/user_profile_screen.dart';
import 'package:sample_proj/screens/journey_details.dart';
import 'package:sample_proj/screens/simple_map_screen.dart';
import 'package:sample_proj/screens/journey_start_screen.dart';
import 'package:sample_proj/screens/journey_memories.dart'; // ✅ Import memories screen

class JourneyScreen extends StatefulWidget {
  final String username;
  const JourneyScreen({super.key, required this.username});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  int _selectedIndex = 3;

  bool isLoading = true; // 🌀 Show loading while checking status
  bool journeyActive = false;

  @override
  void initState() {
    super.initState();
    _checkJourneyStatus(); // 🔥 Call API on load
  }

  Future<void> _checkJourneyStatus() async {
    final apiUrl = Uri.parse("http://10.184.180.35:4000/journey-status");
    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": widget.username}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bool isActive = data['journeyStatus'] ?? false;

        if (isActive) {
          // ✅ Directly navigate to JourneyStartScreen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => JourneyStartScreen(
                  username: widget.username,
                  // 👉 Pass actual longitude if needed
                ),
              ),
            );
          });
        } else {
          setState(() {
            journeyActive = false;
            isLoading = false;
          });
        }
      } else {
        print('❌ Status API Error: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7F2F7), Color(0xFFF8D4DE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // GlassAppBar at the top
          const GlassAppBar(),

          // Center Card with Title and Buttons
          Center(
            child: isLoading
                ? const CircularProgressIndicator() // 🌀 Show loader
                : Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Journey Mode',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ).copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Create Journey Button (Black)
                  ElevatedButton(
                    onPressed: journeyActive
                        ? null // 🚫 Disabled if journeyActive
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              JourneyDetailsScreen(
                                  username: widget.username),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 6,
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(
                      journeyActive
                          ? 'Active Journey'
                          : 'Create Journey',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Memories Button (Pink) - Updated with Navigation
                  ElevatedButton(
                    onPressed: () {
                      // ✅ Navigate to Journey Memories Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JourneyMemoriesScreen(
                            username: widget.username,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 6,
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Memories'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SimpleMapScreen(username: widget.username),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UploadScreen(username: widget.username),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UserProfileScreen(username: widget.username),
              ),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
    );
  }
}