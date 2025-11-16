import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:sample_proj/screens/upload_screen.dart';
import 'package:sample_proj/screens/user_profile_screen.dart';
import 'package:sample_proj/components/app_bar.dart';
import 'package:sample_proj/screens/simple_map_screen.dart';

int _selectedIndex = 3;

class JourneyPlayPostScreen extends StatefulWidget {
  final String username;
  final String description;

  const JourneyPlayPostScreen({
    super.key,
    required this.username,
    required this.description,
  });

  @override
  State<JourneyPlayPostScreen> createState() => _JourneyPlayPostScreenState();
}

class _JourneyPlayPostScreenState extends State<JourneyPlayPostScreen> {
  bool isPlaying = true;
  bool showControlIcon = false;
  bool isExpanded = false;
  IconData currentControlIcon = Icons.pause;

  String? imageUrl;
  String? audioUrl;
  late AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    fetchSpotData();
  }

  Future<void> fetchSpotData() async {
    final apiUrl = Uri.parse(
        'http://10.184.180.35:4000/fullspot?username=${widget.username}');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          imageUrl = data['image'];
          audioUrl = data['audio'];
        });
        await audioPlayer.play(UrlSource(audioUrl!));
        await audioPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        print('❌ API Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Fetch Exception: $e');
    }
  }

  void _handleSingleTap() async {
    setState(() {
      isPlaying = !isPlaying;
      currentControlIcon = isPlaying ? Icons.pause : Icons.play_arrow;
      showControlIcon = true;
    });

    if (audioUrl != null) {
      if (isPlaying) {
        await audioPlayer.resume();
      } else {
        await audioPlayer.pause();
      }
    }

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => showControlIcon = false);
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String shortDescription = widget.description.length > 100
        ? widget.description.substring(0, 100)
        : widget.description;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleSingleTap,
              child: imageUrl != null
                  ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.white70, size: 60),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              )
                  : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: showControlIcon ? 1.0 : 0.0,
              child: GlassmorphicContainer(
                width: 100,
                height: 100,
                borderRadius: 50,
                blur: 20,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05)
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [Colors.white24, Colors.white10],
                ),
                child: Icon(
                  currentControlIcon,
                  size: 50,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 60,
              borderRadius: 16,
              blur: 10,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white38.withOpacity(0.1)
                ],
              ),
              borderGradient: LinearGradient(
                colors: [Colors.white24, Colors.white10],
              ),
              child: const GlassAppBar(),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: isExpanded ? MediaQuery.of(context).size.height * 0.4 : 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.username,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: isExpanded ? 12 : 14,
                      ),
                      children: [
                        TextSpan(text: shortDescription),
                        if (widget.description.length > 100)
                          TextSpan(
                            text: isExpanded ? '  see less' : '... see more',
                            style: const TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isExpanded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset('assets/pop.png', fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white30,
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.username,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  widget.description,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: GestureDetector(
                                onTap: () => setState(() => isExpanded = false),
                                child: Text(
                                  "see less",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.pinkAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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