import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sample_proj/components/app_bar.dart';
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/screens/upload_screen.dart';
import 'package:sample_proj/screens/user_profile_screen.dart';
import 'package:sample_proj/screens/simple_map_screen.dart';
import 'package:sample_proj/components/journeyDetailBottomSheet.dart';
import 'journey_PlayPostScreen.dart';

class JourneySavedMemoriesScreen extends StatefulWidget {
  final String username;
  final String? selectedJourneyName; // Optional: journey selected from previous screen

  const JourneySavedMemoriesScreen({
    super.key,
    required this.username,
    this.selectedJourneyName,
  });

  @override
  State<JourneySavedMemoriesScreen> createState() => _JourneyMemoriesScreenState();
}

class _JourneyMemoriesScreenState extends State<JourneySavedMemoriesScreen> {
  GoogleMapController? _mapController;
  int _selectedIndex = 3;

  LatLng? _currentLatLng;
  LatLng? _sourceLatLng;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isMapReady = false;

  BitmapDescriptor? _spotIcon;

  // Journey selection
  List<String> _journeysList = [];
  String? _selectedJourney;
  bool _isLoadingJourneys = true;

  // For Bottom Sheet
  String? _selectedTitle;
  String? _selectedDescription;
  LatLng? _selectedCoordinates;
  String? _selectedSpotUsername;

  static const String _googleMapsApiKey = '';

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _getCurrentLocation();
    _fetchJourneysList();
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
  }

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
        print("✅ Journeys List: $data");

        if (data['success'] == true) {
          List<String> journeys = List<String>.from(data['journeys'] ?? []);
          setState(() {
            _journeysList = journeys;
            _isLoadingJourneys = false;

            // If journey was passed from previous screen, use it
            if (widget.selectedJourneyName != null && journeys.contains(widget.selectedJourneyName)) {
              _selectedJourney = widget.selectedJourneyName;
              _fetchMemoryPins(_selectedJourney!);
            }
            // Otherwise auto-select first journey
            else if (journeys.isNotEmpty) {
              _selectedJourney = journeys[0];
              _fetchMemoryPins(_selectedJourney!);
            }
          });
        } else {
          print("⚠️ No journeys found: ${data['message']}");
          setState(() {
            _isLoadingJourneys = false;
          });
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
        setState(() {
          _isLoadingJourneys = false;
        });
      }
    } catch (e) {
      print("❌ Exception fetching journeys: $e");
      setState(() {
        _isLoadingJourneys = false;
      });
    }
  }

  Future<void> _fetchMemoryPins(String journeyName) async {
    final apiUrl = Uri.parse("http://10.184.180.35:4000/return-memories-pins");
    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": widget.username,
          "journeyname": journeyName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ Memory Pins Data: $data");

        List<dynamic> spotpins = data['spotpins'] ?? [];
        LatLng source = _parseLatLng(data['source']);
        print("📍 Source pin at $source");

        Set<Marker> newMarkers = {
          Marker(
            markerId: const MarkerId('source'),
            position: source,
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: "Start Point"),
          ),
        };

        List<LatLng> waypoints = [source];

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
                icon: _spotIcon ?? BitmapDescriptor.defaultMarker,
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

            waypoints.add(spotLatLng);
          } catch (e) {
            print("⚠️ Invalid spot coordinates: ${spot['latitude']}, ${spot['longitude']}");
          }
        }

        if (data['destination'] != null) {
          try {
            LatLng destLatLng = _parseLatLng(data['destination']);
            newMarkers.add(
              Marker(
                markerId: const MarkerId('destination'),
                position: destLatLng,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: "Destination"),
              ),
            );
            waypoints.add(destLatLng);
            print("📍 Destination pin at $destLatLng");
          } catch (e) {
            print("⚠️ Invalid destination coordinates: ${data['destination']}");
          }
        }

        List<LatLng> routeCoordinates = await _getRouteCoordinates(waypoints);

        setState(() {
          _sourceLatLng = source;
          _markers = newMarkers;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('journeyRoute'),
              color: Colors.pinkAccent,
              width: 5,
              points: routeCoordinates,
            ),
          };
        });

        if (_mapController != null && _isMapReady) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(source, 14),
          );
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception fetching memory pins: $e");
    }
  }

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

          for (var leg in data['routes'][0]['legs']) {
            for (var step in leg['steps']) {
              String polylinePoints = step['polyline']['points'];
              List<LatLng> stepCoordinates = _decodePolyline(polylinePoints);
              routeCoordinates.addAll(stepCoordinates);
            }
          }

          return routeCoordinates;
        }
      }

      print("⚠️ Directions API failed, using straight line");
      return waypoints;
    } catch (e) {
      print("❌ Route fetching error: $e");
      return waypoints;
    }
  }

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

    if (_sourceLatLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_sourceLatLng!, 14),
      );
    } else if (_currentLatLng != null) {
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

          if (_journeysList.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedJourney,
                    isExpanded: true,
                    hint: const Text('Select Journey'),
                    items: _journeysList.map((String journey) {
                      return DropdownMenuItem<String>(
                        value: journey,
                        child: Text(
                          journey,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedJourney = newValue;
                          _selectedTitle = null;
                        });
                        _fetchMemoryPins(newValue);
                      }
                    },
                  ),
                ),
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
                builder: (context) => SimpleMapScreen(username: widget.username),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UploadScreen(username: widget.username),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(username: widget.username),
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