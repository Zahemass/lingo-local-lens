import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sample_proj/components/app_bar.dart';
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/screens/upload_screen.dart';
import 'package:sample_proj/screens/user_profile_screen.dart';
import 'package:sample_proj/screens/simple_map_screen.dart';
import 'package:sample_proj/screens/journey_start_screen.dart';

class JourneyDetailsScreen extends StatefulWidget {
  final String username;
  const JourneyDetailsScreen({super.key, required this.username});

  @override
  State<JourneyDetailsScreen> createState() => _JourneyDetailsScreenState();
}

class _JourneyDetailsScreenState extends State<JourneyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _journeyNameController = TextEditingController();
  final TextEditingController _yourLocationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  int _selectedIndex = 3;

  double? selectedLat;
  double? selectedLon;

  bool showSuggestions = false;
  bool isLoading = false; // ✅ loading state for API
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    _locationFocusNode.addListener(() {
      if (_locationFocusNode.hasFocus) {
        setState(() {
          showSuggestions = true;
        });
      } else {
        setState(() {
          showSuggestions = false;
        });
      }
    });
    _getCurrentLocation(); // Pre-fetch user location
  }

  Future<void> _fetchLocationSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=8';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'FlutterApp'
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        searchResults = data
            .map((item) => {
          'display_name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
        })
            .toList();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      selectedLat = position.latitude;
      selectedLon = position.longitude;
    });
  }

  void _useCurrentLocation() {
    setState(() {
      _yourLocationController.text = 'Current Location';
      searchResults = [];
      FocusScope.of(context).unfocus();
    });
  }

  void _onPlaceSelected(Map<String, dynamic> place) {
    setState(() {
      _yourLocationController.text = place['display_name'];
      selectedLat = place['lat'];
      selectedLon = place['lon'];
      searchResults = [];
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _startJourney() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedLat == null || selectedLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location")),
      );
      return;
    }

    setState(() => isLoading = true);

    final apiUrl = Uri.parse("http://10.184.180.35:4000/start-journey");
    final body = json.encode({
      "username": widget.username,
      "source": {
        "lat": selectedLat,
        "lon": selectedLon,
      },
      "journeyname": _journeyNameController.text,
    });

    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        print('✅ Journey started: ${response.body}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => JourneyStartScreen(
              username: widget.username,
            ),
          ),
        );
      } else {
        print('❌ API Error: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start journey")),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
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

          // GlassAppBar
          const GlassAppBar(),

          // Center Card with Form
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journey Details',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Journey Name Field
                    GlassmorphicContainer(
                      width: double.infinity,
                      height: 60,
                      borderRadius: 10,
                      blur: 20,
                      border: 0,
                      linearGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      child: TextFormField(
                        controller: _journeyNameController,
                        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Journey Name',
                          hintStyle: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a journey name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Your Location Field
                    GlassmorphicContainer(
                      width: double.infinity,
                      height: 60,
                      borderRadius: 10,
                      blur: 20,
                      border: 0,
                      linearGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      child: TextFormField(
                        controller: _yourLocationController,
                        focusNode: _locationFocusNode,
                        onChanged: _fetchLocationSuggestions,
                        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Your Location',
                          hintStyle: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 12),
                        ),
                      ),
                    ),

                    if (showSuggestions)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 150,
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: 150,
                          borderRadius: 10,
                          blur: 20,
                          border: 0,
                          linearGradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
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
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.my_location, size: 18),
                                title: Text('Use Current Location',
                                    style: GoogleFonts.montserrat(fontSize: 13)),
                                onTap: _useCurrentLocation,
                              ),
                              const Divider(height: 1),
                              ...searchResults.take(3).map((place) => ListTile(
                                title: Text(place['display_name'],
                                    style: GoogleFonts.montserrat(fontSize: 13)),
                                onTap: () => _onPlaceSelected(place),
                              )),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 25),

                    // Start Button
                    Center(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _startJourney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 6,
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Start'),
                      ),
                    ),
                  ],
                ),
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
