import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sample_proj/screens/upload_screen.dart';
import 'package:sample_proj/screens/user_profile_screen.dart';
import 'package:sample_proj/components/app_bar.dart';

int _selectedIndex = 0;

class PlayPostScreen extends StatefulWidget {
  final String username;
  final String description;
  final int views;
  final double latitude;
  final double longitude;



  const PlayPostScreen({
    super.key,
    required this.username,
    required this.description,
    required this.views,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PlayPostScreen> createState() => _PlayPostScreenState();
}

class _PlayPostScreenState extends State<PlayPostScreen> {
  bool isLiked = false;
  bool showBigHeart = false;
  bool isPlaying = true;
  bool showControlIcon = false;
  bool isExpanded = false;
  IconData currentControlIcon = Icons.pause;

  String? imageUrl;        // From API
  String? audioUrl;        // From API
  late AudioPlayer audioPlayer;

  late FlutterTts flutterTts;      // For TTS
  bool isTtsMode = false;          // Tracks whether we’re in TTS mode
  String? translationText;         // Holds translation from API

  String? profileImageUrl;


  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    flutterTts = FlutterTts();
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);
    fetchSpotData();
    fetchUserProfile(widget.username);
  }

  String? summarySpotName;
  String? summaryDescription;
  String? summaryText;

  Future<void> fetchSummary() async {
    final apiUrl = Uri.parse(
        'http://10.184.180.35:4000/returnsummary?username=${widget.username}&lat=${widget.latitude}&lon=${widget.longitude}');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          summarySpotName = data['spotname'];
          summaryDescription = data['description'];
          summaryText = data['summary'];
        });
      } else {
        print('❌ Summary API Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Summary Fetch Exception: $e');
    }
  }

  Future<void> fetchUserProfile(String username) async {
    final url = Uri.parse("http://10.184.180.35:4000/return-profile");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // update the fields you want
          profileImageUrl = data['profileImage'];
        });
      } else {
        print("❌ Profile API Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error fetching profile: $e");
    }
  }



  Future<void> fetchSpotData() async {
    final apiUrl = Uri.parse(
        'http://10.184.180.35:4000/fullspot?username=${widget.username}&lat=${widget.latitude}&lon=${widget.longitude}');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          imageUrl = data['image'];
          audioUrl = data['audio'];
        });
        // Play audio automatically
        await audioPlayer.play(UrlSource(audioUrl!));
        await audioPlayer.setReleaseMode(ReleaseMode.loop); // 🔁 Loop audio

      } else {
        print('❌ API Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Fetch Exception: $e');
    }
  }

  Future<void> fetchTranslationAndSpeak() async {
    final apiUrl = Uri.parse(
        'http://10.249.129.35:4000/translation?username=${widget.username}&lat=${widget.latitude}&lon=${widget.longitude}&lang=${selectedLanguage.toLowerCase()}'
    );

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        translationText = data['translation'];
        isTtsMode = true;

        // Stop audio playback
        await audioPlayer.stop();

        // Speak the translation
        await flutterTts.speak(translationText!);
        setState(() {
          isPlaying = true;
          currentControlIcon = Icons.pause;
        });
      } else {
        print('❌ Translation API Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Translation Fetch Exception: $e');
    }
  }



  void _handleDoubleTap() {
    setState(() {
      isLiked = true;
      showBigHeart = true;
    });

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => showBigHeart = false);
      }
    });
  }

  void _handleSingleTap() async {
    setState(() {
      isPlaying = !isPlaying;
      currentControlIcon = isPlaying ? Icons.pause : Icons.play_arrow;
      showControlIcon = true;
    });

    if (isTtsMode) {
      if (isPlaying) {
        await flutterTts.speak(translationText!); // 🔥 Replay the TTS
      } else {
        await flutterTts.stop(); // 🔥 Stop speaking
      }
    }
    else {
      if (audioUrl != null) {
        if (isPlaying) {
          await audioPlayer.resume();
        } else {
          await audioPlayer.pause();
        }
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
    flutterTts.stop();
    super.dispose();
  }



  String selectedLanguage = "English";

  void _showLanguagePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: GlassmorphicContainer(
              width: 300,
              height: 250,
              borderRadius: 20,
              blur: 20,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
              ),
              borderGradient: LinearGradient(
                colors: [Colors.white24, Colors.white10],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Choose Language",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      decoration: TextDecoration.none, // No underline
                    ),
                  ),
                  const SizedBox(height: 20),
                  _languageOption("English"),
                  _languageOption("French"),
                  _languageOption("German"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _languageOption(String language) {
    final isSelected = selectedLanguage == language;
    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedLanguage = language;
          Navigator.pop(context); // close popup
        });

        if (selectedLanguage == "English") {
          // Back to Audio Mode
          if (isTtsMode) {
            await flutterTts.stop();
            isTtsMode = false;
            if (audioUrl != null) {
              await audioPlayer.play(UrlSource(audioUrl!));
              setState(() {
                isPlaying = true;
                currentControlIcon = Icons.pause;
              });
            }
          }
        } else {
          // Switch to TTS Mode
          await fetchTranslationAndSpeak();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          language,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            decoration: TextDecoration.none, // ✅ Ensures no underline on tap/select
          ),
        ),
      ),
    );
  }

  void _showSummaryPopup(BuildContext context) async {
    await fetchSummary(); // Fetch the summary first

    // 🔥 Stop any audio/TTS before showing summary
    if (isTtsMode) {
      await flutterTts.stop();
      setState(() => isTtsMode = false);
    }
    if (audioUrl != null) {
      await audioPlayer.pause();
    }

    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: GlassmorphicContainer(
              width: MediaQuery.of(context).size.width * 0.95, // 📐 Bigger width
              height: MediaQuery.of(context).size.height * 0.8, // 📐 Bigger height
              borderRadius: 25,
              blur: 25,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
              ),
              borderGradient: LinearGradient(
                colors: [Colors.white24, Colors.white10],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      "📖 Title: ${summarySpotName ?? 'Loading...'}",
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      "✨ Description: ${summaryDescription ?? 'Loading...'}",
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: Colors.white70,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary Text (Scrollable)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          "🌆 Summary:\n${summaryText ?? 'Loading summary...'}",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.6,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Close Button
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);

                          // 🔥 Resume audio if it was playing before
                          if (audioUrl != null) {
                            await audioPlayer.resume();
                          }
                        },
                        child: GlassmorphicContainer(
                          width: 120,
                          height: 40,
                          borderRadius: 20,
                          blur: 15,
                          alignment: Alignment.center,
                          border: 1,
                          linearGradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                          ),
                          borderGradient: LinearGradient(
                            colors: [Colors.white24, Colors.white10],
                          ),
                          child: Text(
                            "Close",
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
          // Background image
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleSingleTap,
              onDoubleTap: _handleDoubleTap,
              child: imageUrl != null
                  ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white70, size: 60),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                },
              )
                  : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            ),
          ),

          // Big Heart Animation
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: showBigHeart ? 1.0 : 0.0,
              child: Icon(
                Icons.favorite,
                size: 100,
                color: Colors.pinkAccent.withOpacity(0.9),
              ),
            ),
          ),

          // Play/Pause Icon
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
                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
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

          // Top Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Bottom Gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Glass AppBar
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
                colors: [Colors.white.withOpacity(0.1), Colors.white38.withOpacity(0.1)],
              ),
              borderGradient: LinearGradient(
                colors: [Colors.white24, Colors.white10],
              ),
              child: const GlassAppBar(),
            ),
          ),

          // Summary Icon
          Positioned(
            top: 110,
            right: 20,
            child: GestureDetector(
              onTap: () => _showSummaryPopup(context),
              child: GlassmorphicContainer(
                width: 45,
                height: 45,
                borderRadius: 12,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                ),
                borderGradient: LinearGradient(
                  colors: [Colors.white24, Colors.white10],
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),

          // Right Icons Stack
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => isLiked = !isLiked),
                  child: _glassIcon(
                    Iconsax.heart5,
                    iconColor: isLiked ? Colors.pinkAccent : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _glassIcon(Iconsax.location),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _showLanguagePopup(context),
                  child: _glassIcon(Iconsax.message_text),
                ),

              ],
            ),
          ),

          // Profile Info & See More Description
          Positioned(
            left: 16,
            right: 16,
            bottom: isExpanded ? MediaQuery.of(context).size.height * 0.4 : 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:  profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : const AssetImage('assets/profile.png') as ImageProvider,
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
                        fontSize: isExpanded ? 12 : 14, // Smaller when expanded
                      ),
                      children: [
                        TextSpan(
                          text: shortDescription,
                        ),
                        if (widget.description.length > 100)
                          TextSpan(
                            text: isExpanded ? '  see less' : '... see more',
                            style: const TextStyle(
                              color: Colors.pinkAccent, // 🎯 Make it stand out
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                if (!isExpanded)
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye, color: Colors.white70, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.views} views",
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Expanded Glass Panel
          // Expanded Glass Panel
          if (isExpanded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.4, // Mid-screen height
              child: Stack(
                children: [
                  // Background Image for blur
                  Positioned.fill(
                    child: Image.asset('assets/pop.png', fit: BoxFit.cover),
                  ),
                  // Blur + White Panel
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username + Direction
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.username,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.directions, size: 18, color: Colors.black87),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Direction",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.remove_red_eye, size: 20, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  "${widget.views} views",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Column(
                                children: [
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

      // Bottom Navigation
      bottomNavigationBar: isExpanded
          ? null // Hides the BottomNavBar when expanded
          : CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          // Navigation logic
          if (index == 1){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UploadScreen(username: widget.username)),
            );
          }else if (index == 2){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen(username: widget.username)),
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

  Widget _glassIcon(IconData icon, {Color iconColor = Colors.white}) {
    return GlassmorphicContainer(
      width: 50,
      height: 50,
      borderRadius: 25,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white24, Colors.white10],
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}
