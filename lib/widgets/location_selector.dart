import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../../screens/LocationPickerScreen.dart';

class LocationSelector extends StatefulWidget {
  final LatLng? selectedLatLng;
  final Function(LatLng) onPickLocation;

  const LocationSelector({
    super.key,
    required this.selectedLatLng,
    required this.onPickLocation,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen()),
    );

    if (result != null && result is LatLng) {
      widget.onPickLocation(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLatLng = widget.selectedLatLng;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: const Text("📍", style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(
                  selectedLatLng != null ? Iconsax.location : Iconsax.add_circle,
                  color: selectedLatLng != null ? Colors.green : Colors.black87,
                ),
                label: Text(
                  selectedLatLng != null ? "Location Added" : "Add Location",
                  style: GoogleFonts.montserrat(color: Colors.black87),
                ),
                onPressed: _pickLocation,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        if (selectedLatLng != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: selectedLatLng,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("preview"),
                  position: selectedLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                )
              },
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: false,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) {},
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${selectedLatLng.latitude}, ${selectedLatLng.longitude}",
            style: GoogleFonts.montserrat(),
          ),
        ],
      ],
    );
  }
}
