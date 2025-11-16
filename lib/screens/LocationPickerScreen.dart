import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _googleMapController;

  LatLng? _pickedLocation;
  LatLng _defaultLocation = const LatLng(13.0827, 80.2707); // Chennai
  List<dynamic> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _defaultLocation = currentLatLng;
        _pickedLocation = currentLatLng;
      });
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 16),
      );
    }
  }

  Future<void> _searchPlace(String query) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5");
    final response = await http.get(url, headers: {
      "User-Agent": "FlutterApp (your@email.com)"
    });

    if (response.statusCode == 200) {
      setState(() {
        _suggestions = json.decode(response.body);
      });
    }
  }

  Future<void> _searchWithButton() async {
    if (_searchController.text.isEmpty) return;

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${_searchController.text}&format=json&limit=1");
    final response = await http.get(url, headers: {
      "User-Agent": "FlutterApp (contact@email.com)"
    });

    final data = json.decode(response.body);
    if (data.isNotEmpty) {
      final place = data.first;
      _selectPlace(place);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Place not found.")),
      );
    }
  }

  void _selectPlace(dynamic place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final latLng = LatLng(lat, lon);

    _googleMapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    setState(() {
      _pickedLocation = latLng;
      _searchController.text = place['display_name'];
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 80,
          borderRadius: 0,
          blur: 15,
          alignment: Alignment.center,
          linearGradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: 0,
          borderGradient: LinearGradient(colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ]),
          child: SafeArea(
            child: Center(
              child: Text(
                "Pick a Location",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultLocation,
              zoom: 13,
            ),
            onMapCreated: (controller) => _googleMapController = controller,
            onTap: (latLng) {
              setState(() => _pickedLocation = latLng);
            },
            markers: _pickedLocation != null
                ? {
              Marker(
                markerId: const MarkerId("picked"),
                position: _pickedLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ),
            }
                : {},
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 🔍 Search field and button with glass effect
          Positioned(
            top: 90,
            left: 20,
            right: 20,
            child: Column(
              children: [
                GlassmorphicContainer(
                  width: double.infinity,
                  height: 55,
                  borderRadius: 12,
                  blur: 15,
                  alignment: Alignment.center,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: 1,
                  borderGradient: LinearGradient(colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ]),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              if (val.length > 2) _searchPlace(val);
                            },
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search a place",
                              hintStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.grey.shade700,
                              ),
                              border: InputBorder.none,
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _suggestions = []);
                                },
                              )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _searchWithButton,
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5)
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(
                            suggestion['display_name'],
                            style: const TextStyle(fontFamily: 'Montserrat'),
                          ),
                          onTap: () => _selectPlace(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ✅ Green Glass Confirm Button
          if (_pickedLocation != null)
            Positioned(
              bottom: 30,
              left: 50,
              right: 50,
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 55,
                borderRadius: 20,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withOpacity(0.2),
                    Colors.lightGreenAccent.withOpacity(0.2),
                  ],
                  stops: const [0.1, 1],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.greenAccent.withOpacity(0.3),
                    Colors.green.withOpacity(0.3),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon:
                  const Icon(Icons.pin_drop_sharp, color: Colors.black),
                  label: const Text(
                    "Confirm Location",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, _pickedLocation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
