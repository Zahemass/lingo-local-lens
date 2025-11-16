import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sample_proj/components/app_bar.dart'; // GlassAppBar
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/screens/journey_upload_screen.dart';
import 'package:sample_proj/screens/upload_screen.dart';
import 'package:sample_proj/screens/user_profile_screen.dart';
import 'package:sample_proj/screens/simple_map_screen.dart';
import 'package:sample_proj/components/journeyDetailBottomSheet.dart';
import 'journey_PlayPostScreen.dart';
import 'journey_screen.dart'; // ✅ Import JourneyScreen

class JourneyStartScreen extends StatefulWidget {
  final String username;

  const JourneyStartScreen({super.key, required this.username});

  @override
  State<JourneyStartScreen> createState() => _JourneyStartScreenState();
}

class _JourneyStartScreenState extends State<JourneyStartScreen> {
  GoogleMapController? _mapController;
  int _selectedIndex = 3;

  LatLng? _currentLatLng;
  LatLng? _sourceLatLng;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isMapReady = false;
  bool _isEndingJourney = false;

  BitmapDescriptor? _spotIcon; // 🔥 Custom spot pin icon

  // For Bottom Sheet
  String? _selectedTitle;
  String? _selectedDescription;
  LatLng? _selectedCoordinates;
  String? _selectedSpotUsername;

  // Add your Google Maps API key here
  static const String _googleMapsApiKey = '';

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // Load custom marker first
    _getCurrentLocation();
  }

  Future<void> _loadCustomMarker() async {
    _spotIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/journey_pin.png',
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("📍 Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("📍 Location permissions denied.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });

    if (_mapController != null && _currentLatLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 14),
      );
    }

    _fetchJourneyPins(); // Fetch pins after location is ready
  }

  // 🔥 NEW: Function to get route between waypoints using Google Directions API
  Future<List<LatLng>> _getRouteCoordinates(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    String origin = "${waypoints.first.latitude},${waypoints.first.longitude}";
    String destination = "${waypoints.last.latitude},${waypoints.last.longitude}";

    String waypointsStr = "";
    if (waypoints.length > 2) {
      List<String> waypointList = waypoints
          .sublist(1, waypoints.length - 1)
          .map((point) => "${point.latitude},${point.longitude}")
          .toList();
      waypointsStr = "&waypoints=${waypointList.join('|')}";
    }

    String url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=$origin"
        "&destination=$destination"
        "$waypointsStr"
        "&key=$_googleMapsApiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          List<LatLng> routeCoordinates = [];

          // Extract all points from all legs of the route
          for (var leg in data['routes'][0]['legs']) {
            for (var step in leg['steps']) {
              // Decode polyline points
              String polylinePoints = step['polyline']['points'];
              List<LatLng> stepCoordinates = _decodePolyline(polylinePoints);
              routeCoordinates.addAll(stepCoordinates);
            }
          }

          return routeCoordinates;
        }
      }

      print("⚠️ Directions API failed, using straight line");
      return waypoints; // Fallback to straight line
    } catch (e) {
      print("❌ Route fetching error: $e");
      return waypoints; // Fallback to straight line
    }
  }

  // 🔥 NEW: Function to decode Google's polyline algorithm
  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> coordinates = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      coordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return coordinates;
  }

  Future<void> _fetchJourneyPins() async {
    final apiUrl = Uri.parse("http://10.184.180.35:4000/return-journey-pins");
    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": widget.username}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ API Data: $data");

        if (data['success'] == true) {
          List<dynamic> spotpins = data['spotpins'] ?? [];
          LatLng source = _parseLatLng(data['source']);
          print("📍 Source pin at $source");

          Set<Marker> newMarkers = {
            Marker(
              markerId: const MarkerId('source'),
              position: source,
              infoWindow: const InfoWindow(title: "Source Location"),
            ),
          };

          List<LatLng> waypoints = [source]; // 🔥 CHANGED: Start with source

          // Add spot pins
          for (int i = 0; i < spotpins.length; i++) {
            var spot = spotpins[i];
            try {
              LatLng spotLatLng = LatLng(
                double.parse(spot['latitude'].toString()),
                double.parse(spot['longitude'].toString()),
              );
              String title = spot['title'] ?? 'Spot $i';
              String description = spot['description'] ?? '';

              print("📍 Adding spot pin: $title at $spotLatLng");

              newMarkers.add(
                Marker(
                  markerId: MarkerId('spot_$i'),
                  position: spotLatLng,
                  icon: _spotIcon ?? BitmapDescriptor.defaultMarker, // 🔥 Use custom icon
                  infoWindow: InfoWindow(title: title),
                  onTap: () {
                    setState(() {
                      _selectedTitle = title;
                      _selectedDescription = description;
                      _selectedCoordinates = spotLatLng;
                      _selectedSpotUsername = widget.username;
                    });
                  },
                ),
              );

              waypoints.add(spotLatLng); // 🔥 CHANGED: Add to waypoints
            } catch (e) {
              print("⚠️ Invalid spot coordinates: ${spot['latitude']}, ${spot['longitude']}");
            }
          }

          // Add destination pin if present
          if (data['destination'] != null) {
            try {
              LatLng destLatLng = _parseLatLng(data['destination']);
              newMarkers.add(
                Marker(
                  markerId: const MarkerId('destination'),
                  position: destLatLng,
                  infoWindow: const InfoWindow(title: "Destination"),
                ),
              );
              waypoints.add(destLatLng); // 🔥 CHANGED: Add to waypoints
              print("📍 Destination pin at $destLatLng");
            } catch (e) {
              print("⚠️ Invalid destination coordinates: ${data['destination']}");
            }
          }

          // 🔥 NEW: Get route coordinates instead of straight lines
          List<LatLng> routeCoordinates = await _getRouteCoordinates(waypoints);

          setState(() {
            _sourceLatLng = source;
            _markers = newMarkers;
            _polylines = {
              Polyline(
                polylineId: const PolylineId('journeyRoute'),
                color: Colors.pinkAccent,
                width: 5,
                points: routeCoordinates, // 🔥 CHANGED: Use route coordinates
              ),
            };
          });

          if (_mapController != null && _isMapReady) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(source, 14),
            );
          }
        } else {
          print("⚠️ API Response Error: ${data['message']}");
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }
  }

  Future<void> _endJourney() async {
    if (_isEndingJourney) return; // Prevent multiple taps
    setState(() {
      _isEndingJourney = true;
    });

    final apiUrl = Uri.parse("http://10.184.180.35:4000/end-journey");
    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": widget.username}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        print("✅ Journey Ended: ${data['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Journey ended successfully")),
        );
        // ✅ Navigate to JourneyScreen after ending journey
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => JourneyScreen(username: widget.username),
          ),
        );
      } else {
        print("⚠️ End Journey Failed: ${data['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${data['message']}")),
        );
      }
    } catch (e) {
      print("❌ End Journey Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to end journey")),
      );
    } finally {
      setState(() {
        _isEndingJourney = false;
      });
    }
  }

  LatLng _parseLatLng(dynamic data) {
    if (data is Map) {
      return LatLng(
        double.parse(data['lat'].toString()),
        double.parse(data['lon'].toString()),
      );
    }
    throw Exception("Invalid LatLng format: $data");
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });

    if (_currentLatLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _currentLatLng == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLatLng!,
              zoom: 13,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: _polylines,
          ),
          const GlassAppBar(),
          Positioned(
            top: 115,
            right: 16,
            child: ElevatedButton(
              onPressed: _isEndingJourney ? null : _endJourney,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _isEndingJourney
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text('End'),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        JourneyUploadScreen(username: widget.username),
                  ),
                ).then((_) => _fetchJourneyPins());
              },
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload'),
            ),
          ),
          if (_selectedTitle != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 95,
              child: JourneyDetailBottomSheet(
                title: _selectedTitle!,
                description: _selectedDescription ?? '',
                onPlayTap: () {
                  if (_selectedCoordinates != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JourneyPlayPostScreen(
                          username: _selectedSpotUsername ?? widget.username,
                          description: _selectedDescription ?? '',
                        ),
                      ),
                    );
                  }
                },
                onCloseTap: () {
                  setState(() {
                    _selectedTitle = null;
                    _selectedDescription = null;
                    _selectedCoordinates = null;
                  });
                },
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