import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/screens/simple_map_screen.dart';
import 'package:sample_proj/screens/upload_screen.dart';
import 'package:sample_proj/screens/user_profile_screen.dart';
import 'package:sample_proj/screens/journey_saved_memories_screen.dart';

class JourneyMemoriesScreen extends StatefulWidget {
  final String username;

  const JourneyMemoriesScreen({super.key, required this.username});

  @override
  State<JourneyMemoriesScreen> createState() => _JourneyMemoriesScreenState();
}

class _JourneyMemoriesScreenState extends State<JourneyMemoriesScreen> {
  int _selectedIndex = 3;

  List<Map<String, dynamic>> memories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJourneysList();
  }

  // Fetch journeys list from backend
  Future<void> _fetchJourneysList() async {
    final apiUrl = Uri.parse("http://10.184.180.35:4000/return-journeys-list");

    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": widget.username}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ Journeys List Response: $data");

        if (data['success'] == true) {
          List<String> journeyNames = List<String>.from(data['journeys'] ?? []);

          // Convert journey names to memory card format
          List<Map<String, dynamic>> fetchedMemories = journeyNames.asMap().entries.map((entry) {
            int index = entry.key;
            String journeyName = entry.value;

            return {
              'id': '${index + 1}',
              'title': journeyName,
              'date': DateTime.now().subtract(Duration(days: index * 2)).toString().split(' ')[0],
              'type': 'photo',
              'journey': journeyName,
            };
          }).toList();

          setState(() {
            memories = fetchedMemories;
            _isLoading = false;
          });
        } else {
          print("⚠️ No journeys found");
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Exception fetching journeys: $e");
      setState(() {
        _isLoading = false;
      });
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

          // Main Content
          Column(
            children: [
              // Custom App Bar with Back Button
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Title
                    Flexible(
                      child: Text(
                        'Journey Memories',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),

                    // Search/Filter Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Memories List
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.pinkAccent,
                  ),
                )
                    : memories.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.explore_off,
                        size: 64,
                        color: Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No journeys yet',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a journey to create memories',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    itemCount: memories.length,
                    itemBuilder: (context, index) {
                      final memory = memories[index];
                      return _buildMemoryCard(memory);
                    },
                  ),
                ),
              ),
            ],
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

  Widget _buildMemoryCard(Map<String, dynamic> memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Memory Type Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: memory['type'] == 'photo'
                      ? Colors.pinkAccent.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  memory['type'] == 'photo'
                      ? Icons.photo_camera
                      : Icons.directions_run,
                  color: memory['type'] == 'photo'
                      ? Colors.pinkAccent
                      : Colors.black87,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory['title'],
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(memory['date']),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // More Options
              Icon(
                Icons.more_vert,
                color: Colors.black54,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Journey Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              memory['journey'],
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Row (only Share + View Details)
          Row(
            children: [
              _buildActionButton(Icons.share_outlined, 'Share'),
              const Spacer(),
              GestureDetector(
                onTap: () => _navigateToJourneyMapView(memory),
                child: Row(
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.pinkAccent,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black54,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Navigate to the map view with selected journey
  void _navigateToJourneyMapView(Map<String, dynamic> memory) {
    String journeyName = memory['journey'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneySavedMemoriesScreen(
          username: widget.username,
          selectedJourneyName: journeyName, // Pass journey name
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}