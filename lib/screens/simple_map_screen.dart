import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:sample_proj/components/app_bar.dart';
import 'package:sample_proj/components/category_chips.dart';
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/components/GlassDetailBottomSheet.dart';
import 'package:sample_proj/screens/user_profile_screen.dart';
import './upload_screen.dart';
import './PlayPostScreen.dart'; // Adjust path as needed
import 'dart:ui' as ui; // Required for instantiateImageCodec
import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sample_proj/screens/journey_screen.dart';
import 'package:audioplayers/audioplayers.dart';






class SimpleMapScreen extends StatefulWidget {
  final String username;

  const SimpleMapScreen({super.key, required this.username});

  @override
  State<SimpleMapScreen> createState() => _SimpleMapScreenState();
}

class _SimpleMapScreenState extends State<SimpleMapScreen> {

  Set<Marker> _dynamicMarkers = {};
  String? _selectedSpotUsername;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';

  String aiReply = '';
  String suggestedCategory = '';

  bool awaitingSpotConfirmation = false;
  String? lastSuggestedCategory;

  final FlutterTts _flutterTts = FlutterTts();

  final player = AudioPlayer();

  Future<void> playKiraVoice(String text) async {
    final apiKey = "";
    final voiceId = "EXAVITQu4vr4xnSDxMaL"; // Default ElevenLabs voice

    final url = Uri.parse(
        "https://api.elevenlabs.io/v1/text-to-speech/$voiceId/stream");

    final headers = {
      "xi-api-key": apiKey,
      "Content-Type": "application/json",
    };

    final body = jsonEncode({
      "text": text,
      "model_id": "eleven_multilingual_v2",
      "voice_settings": {
        "stability": 0.4,
        "similarity_boost": 0.7
      }
    });

    final request = http.Request("POST", url)
      ..headers.addAll(headers)
      ..body = body;

    final response = await request.send();

    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      await player.play(BytesSource(bytes));   // 👈 Plays audio directly!!
    } else {
      print("❌ ElevenLabs TTS Error: ${response.statusCode}");
    }
  }



  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll('&', 'and').trim();
  }


  @override
  void initState() {
    super.initState();
    _initLocation();
    _speech = stt.SpeechToText();

  }

  void _openGlassDetailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassDetailBottomSheet(
        title: _selectedTitle!,
        description: _selectedDescription!,
        views: _selectedViews!,
        onDirectionTap: () {
          if (_liveLocation != null && _selectedCoordinates != null) {
            _drawStraightLine(_liveLocation!, _selectedCoordinates!);
          }
        },
        onPlayTap: () {
          if (_selectedCoordinates != null &&
              _selectedDescription != null &&
              _selectedViews != null &&
              _selectedTitle != null) {
            print("▶ Spot Username: $_selectedSpotUsername");

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayPostScreen(
                  username: _selectedSpotUsername ?? widget.username,
                  description: _selectedDescription!,
                  views: _selectedViews!,
                  latitude: _selectedCoordinates!.latitude,
                  longitude: _selectedCoordinates!.longitude,
                ),
              ),
            );
          }
        },
        onCloseTap: () {
          setState(() {
            _selectedTitle = null;
            _selectedDescription = null;
            _selectedViews = null;
            _selectedCoordinates = null;
            _polylines.clear();
          });
        },
      ),
    );
  }

  String? _selectedCategory;


  Future<void> _requestMicPermission() async {
    var micStatus = await Permission.microphone.status;
    var speechStatus = await Permission.speech.status;

    if (micStatus.isGranted && speechStatus.isGranted) {
      print('✅ Permissions already granted');
      _startListening();
    } else {
      final micResult = await Permission.microphone.request();
      final speechResult = await Permission.speech.request();

      if (micResult.isGranted && speechResult.isGranted) {
        print('✅ Permissions granted after request');
        _startListening();
      } else {
        print('🚫 Permissions denied');
        openAppSettings();
      }
    }
  }



  // 🔹 Shared function for both tap & voice
  void _triggerNearbySpots() async {
    if (_liveLocation != null) {
      await _fetchNearbySpots(
        _liveLocation!.latitude,
        _liveLocation!.longitude,
      );

      Future.delayed(const Duration(milliseconds: 400), () async {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.speak("Here are the nearby spots.");
      });
    } else {
      await _flutterTts.speak("I couldn't find your location.");
    }
  }



  void _startListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        print("🎙 Speech status: $status");
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print("❌ Speech error: $error");
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _voiceInput = '';
      });

      print("🎤 Listening...");

      _speech.listen(
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 10),
        onResult: (result) async {
          if (!result.finalResult) return;

          final spokenRaw = result.recognizedWords.trim();
          final spokenLower = spokenRaw.toLowerCase();
          print("🎤 Final user input: $spokenRaw");

          // 🔹 Voice: "show me the nearby spot" / "show me any one nearby spot" / "find nearby spot"
          if (spokenLower.contains("show me the nearby spot") ||
              spokenLower.contains("show me any one nearby spot") ||
              spokenLower.contains("find nearby spot") ||
              spokenLower.contains("nearby spot")) {
            _triggerNearbySpots();
            return;
          }

          // 🔹 Voice: "show me the direction"
          if (spokenLower.contains("show me the direction") ||
              spokenLower.contains("get me the direction") ||
              spokenLower.contains("navigate to")) {
            if (_liveLocation != null && _selectedCoordinates != null) {
              _drawStraightLine(_liveLocation!, _selectedCoordinates!);
              await _flutterTts.speak(
                  "Showing you the directions to ${_selectedTitle ?? 'the spot'}.");
            } else {
              await _flutterTts.speak("Please select a spot first.");
            }
            return;
          }

          // 🔹 Voice: "play the spot"
          if (spokenLower.contains("play the spot") ||
              spokenLower.contains("play this spot") ||
              spokenLower.contains("start playing")) {
            if (_selectedCoordinates != null &&
                _selectedDescription != null &&
                _selectedViews != null &&
                _selectedTitle != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayPostScreen(
                    username: _selectedSpotUsername ?? widget.username,
                    description: _selectedDescription!,
                    views: _selectedViews!,
                    latitude: _selectedCoordinates!.latitude,
                    longitude: _selectedCoordinates!.longitude,
                  ),
                ),
              );
              await _flutterTts.speak("Playing ${_selectedTitle ?? 'the spot'}.");
            } else {
              await _flutterTts.speak("Please select a spot first.");
            }
            return;
          }

          // 🔹 Handle "/spot-intro"
          if (spokenLower.contains("/spot-intro")) {
            if (_selectedTitle != null &&
                _selectedDescription != null &&
                _selectedViews != null &&
                _selectedCoordinates != null) {
              _openGlassDetailSheet();
            } else {
              print("⚠ Cannot open GlassDetailBottomSheet: Missing spot data");
            }
            return;
          }

          // 🔹 Match exact spot name (works like tap selection)
          final matchingSpots = _backendNearbySpots
              .cast<Map<String, dynamic>>()
              .where((spot) =>
          spot['spotname']?.toString().toLowerCase() == spokenLower)
              .toList();

          if (matchingSpots.isNotEmpty) {
            final matchedSpot = matchingSpots.first;
            print("📍 Voice matched spot: ${matchedSpot['spotname']}");

            setState(() {
              _selectedTitle = matchedSpot['spotname'];
              _selectedDescription = matchedSpot['description'];
              _selectedViews = matchedSpot['viewcount'];
              _selectedCoordinates = LatLng(
                matchedSpot['lat'],
                matchedSpot['lng'],
              );
              _selectedSpotUsername = matchedSpot['username'];
            });

            _openGlassDetailSheet(); // same as tap
            await _flutterTts.speak("Here is ${matchedSpot['spotname']}");
            await _flutterTts.awaitSpeakCompletion(true);
            return;
          }

          // 🔹 Yes/Sure confirmation after category suggestion
          if (awaitingSpotConfirmation) {
            final normalized = _normalize(spokenRaw);
            if (normalized.contains("yes") ||
                normalized.contains("yeah") ||
                normalized.contains("sure")) {
              awaitingSpotConfirmation = false;

              if (_selectedCategory != null) {
                final filteredSpots = _backendNearbySpots
                    .where((spot) =>
                spot['category']?.toString().toLowerCase() ==
                    _selectedCategory!.toLowerCase())
                    .toList();

                if (filteredSpots.isNotEmpty) {
                  final randomSpot = (filteredSpots..shuffle()).first;
                  final spotName = randomSpot['spotname'];

                  print("🎯 Auto-selected spot in category: $spotName");

                  setState(() {
                    _selectedTitle = spotName;
                    _selectedDescription =
                        randomSpot['description'] ?? "The spot which gives you nice vibe 😉.";
                    _selectedViews = randomSpot['viewcount'] ?? 0;
                    _selectedCoordinates = LatLng(
                      randomSpot['lat'],
                      randomSpot['lng'],
                    );
                    _selectedSpotUsername = randomSpot['username'] ?? "";
                    _selectedCategory = randomSpot['category'] ?? "Unknown";
                  });

                  _openGlassDetailSheet();
                  await Future.delayed(const Duration(milliseconds: 300));
                  await _flutterTts
                      .speak("Here is a spot you might like: $spotName");
                  await _flutterTts.awaitSpeakCompletion(true);
                } else {
                  await _flutterTts
                      .speak("Sorry, no spots found in that category nearby.");
                }
              } else {
                await _flutterTts.speak("I don't know which category to use.");
              }
              return;
            } else {
              await _flutterTts
                  .speak("Okay, let me know if you need help later.");
              awaitingSpotConfirmation = false;
              return;
            }
          }

          // 🔹 Send general input to Kira
          try {
            final kiraResponse = await http.post(
              Uri.parse("http://10.184.180.35:5005/kira"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"prompt": spokenRaw}),
            );

            if (kiraResponse.statusCode == 200) {
              final data = jsonDecode(kiraResponse.body);
              final reply = data['reply'];
              final category = data['category'] ?? "";

              await playKiraVoice(reply);


              if (category.isNotEmpty) {
                _selectedCategory = category;

                final matchedIndex = categories.indexWhere(
                        (c) => c.toLowerCase() == category.toLowerCase());

                if (matchedIndex != -1) {
                  setState(() {
                    selectedCategoryIndex = matchedIndex;
                  });

                  if (_liveLocation != null) {
                    await _fetchNearbySpots(
                      _liveLocation!.latitude,
                      _liveLocation!.longitude,
                    );

                    // 👇 After fetching, auto-open the first spot
                    if (_backendNearbySpots.isNotEmpty) {
                      final firstSpot = _backendNearbySpots.first;
                      final username = firstSpot['username'];
                      final lat = firstSpot['latitude'];
                      final lng = firstSpot['longitude'];

                      try {
                        final introUrl = Uri.parse(
                            "http://10.184.180.35:4000/spotintro?username=$username&lat=$lat&lon=$lng"
                        );
                        final introResponse = await http.get(introUrl);

                        if (introResponse.statusCode == 200) {
                          final introData = jsonDecode(introResponse.body);

                          setState(() {
                            _selectedTitle = introData['category'];
                            _selectedDescription = introData['description'];
                            _selectedViews = introData['viewcount'];
                            _selectedCoordinates = LatLng(lat, lng);
                            _selectedSpotUsername = username;
                          });

                          // 👈 open with correct description
                        } else {
                          print("❌ Failed to fetch spot intro: ${introResponse.statusCode}");
                        }
                      } catch (e) {
                        print("⚠ Error fetching spot intro (auto-open): $e");
                      }
                    }


                  }
                }

              }
            }
          } catch (e) {
            print("⚠ Exception during Kira call: $e");
          }
        },
      );
    } else {
      print("❌ Speech recognition not available");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }


  Future<void> getRoutePolyline(LatLng origin, LatLng destination) async {
    const apiKey = ''; // 🔁 Replace this
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        final decodedPoints = _decodePolyline(points);

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: decodedPoints,
            ),
          };
        });
      } else {
        print("No routes found");
      }
    } else {
      print("Directions API failed: ${response.statusCode}");
    }
  }

//api
  Future<void> _initLocation() async {
    final LatLng defaultLocation = const LatLng(13.0740, 80.2616); // Egmore

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
// 👇 Use default location (Egmore)
      setState(() => _liveLocation = defaultLocation);
      _fetchNearbySpots(defaultLocation.latitude, defaultLocation.longitude);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final currentLoc = LatLng(position.latitude, position.longitude);
      setState(() => _liveLocation = currentLoc);
      await _loadProfileMarkerIcon();
      _fetchNearbySpots(currentLoc.latitude, currentLoc.longitude);
    } catch (e) {
// 👇 Fallback in case of any error while getting location
      setState(() => _liveLocation = defaultLocation);
      _fetchNearbySpots(defaultLocation.latitude, defaultLocation.longitude);
      print("⚠ Location fetch failed, fallback to Egmore: $e");
    }


  }

  Future<void> _loadProfileMarkerIcon() async {
    final url = Uri.parse("http://10.184.180.35:4000/profilepicreturn"); // Update if needed

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": widget.username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profilePicUrl = data['profile_image'];

        if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
          final imageResponse = await http.get(Uri.parse(profilePicUrl));
          if (imageResponse.statusCode == 200) {
            final Uint8List imageBytes = imageResponse.bodyBytes;

// Decode image and resize
            final ui.Codec codec = await ui.instantiateImageCodec(
              imageBytes,
              targetWidth: 100,
              targetHeight: 100,
            );
            final ui.FrameInfo frame = await codec.getNextFrame();
            final ui.Image originalImage = frame.image;

// Create circular image
            final ui.PictureRecorder recorder = ui.PictureRecorder();
            final Canvas canvas = Canvas(recorder);
            final Paint paint = Paint()..isAntiAlias = true;

            final double radius = 50;
            final Rect rect = Rect.fromLTWH(0, 0, 100, 100);
            final RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

            canvas.clipRRect(rRect);
            canvas.drawImage(originalImage, Offset.zero, paint);

            final ui.Image circularImage = await recorder.endRecording().toImage(100, 100);
            final ByteData? byteData = await circularImage.toByteData(format: ui.ImageByteFormat.png);

            if (byteData != null) {
              final Uint8List markerIconBytes = byteData.buffer.asUint8List();

              setState(() {
                _profileMarkerIcon = BitmapDescriptor.fromBytes(markerIconBytes);
              });
            }
          }
        }
      } else {
        print("❌ API error: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠ Exception in loading marker icon: $e");
    }
  }




  Future<void> _fetchSearchedSpots(String searchQuery) async {
    final url = Uri.parse("http://10.184.180.35:4000/search-spots");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"SearchQuery": searchQuery}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List spots = data['spots'];

        final String imagePath = categoryToPinImage[categories[selectedCategoryIndex]] ?? 'assets/images/pin_1.png';

        final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(60, 60)),
          imagePath,
        );

        final markers = spots.map<Marker>((spot) {
          final lat = spot['latitude'] as double;
          final lng = spot['longitude'] as double;

          return Marker(
            markerId: MarkerId(spot['spotname']),
            position: LatLng(lat, lng),
            icon: customIcon,
            onTap: () {
              setState(() {
                _selectedTitle = spot['spotname'];
                _selectedDescription = spot['description'] ?? '';
                _selectedViews = spot['viewcount'] ?? 0;
                _selectedCoordinates = LatLng(lat, lng);
                _selectedSpotUsername = spot['username'];
              });

            },
          );
        }).toSet();

        setState(() {
          _dynamicMarkers = markers;
          _backendNearbySpots = List<Map<String, dynamic>>.from(spots);
        });
      } else {
        print("❌ Failed to fetch searched spots: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠ Error fetching searched spots: $e");
    }
  }

  Future<void> _fetchNearbySpots(double lat, double lon) async {
    final String selectedCategory = categories[selectedCategoryIndex];
    final String categoryQuery = Uri.encodeComponent(selectedCategory);

    final url = Uri.parse("http://10.184.180.35:4000/nearby?lat=$lat&lng=$lon&SearchQuery=$categoryQuery");


    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<Map<String, dynamic>> filteredSpots = List<Map<String, dynamic>>.from(data);

        final String imagePath = categoryToPinImage[selectedCategory] ?? 'assets/images/pin_1.png';

        final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(30, 30)),
          imagePath,
        );

        final markers = filteredSpots.map((spot) {
          final lat = spot['latitude'] as double;
          final lng = spot['longitude'] as double;

          return Marker(
            markerId: MarkerId(spot['spotname']),
            position: LatLng(lat, lng),
            icon: customIcon,
            onTap: () async {
              try {
                final username = spot['username'];
                final latStr = lat.toString();
                final lonStr = lng.toString();

                final introUrl = Uri.parse(
                    "http://10.184.180.35:4000/spotintro?username=$username&lat=$latStr&lon=$lonStr"
                );

                final introResponse = await http.get(introUrl);
                if (introResponse.statusCode == 200) {
                  final introData = jsonDecode(introResponse.body);

                  setState(() {
                    _selectedTitle = introData['category'];
                    _selectedDescription = introData['description'];
                    _selectedViews = introData['viewcount'];
                    _selectedCoordinates = LatLng(lat, lng);
                    _selectedSpotUsername = username;
                  });
                } else {
                  print("❌ Failed to fetch spot intro: ${introResponse.statusCode}");
                }
              } catch (e) {
                print("⚠ Error fetching spot intro: $e");
              }
            },
          );
        }).toSet();

        setState(() {
          _backendNearbySpots = filteredSpots;
          _dynamicMarkers = markers;
        });

        print("✅ Spots for category '$selectedCategory': $_backendNearbySpots");
      } else {
        print("❌ Failed to fetch spots: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠ Error fetching spots: $e");
    }
  }



  GoogleMapController? _googleMapController;
  LatLng? _liveLocation;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  BitmapDescriptor? _profileMarkerIcon; // 👈 Add this
  String? _selectedTitle;
  String? _selectedDescription;
  int? _selectedViews;
  LatLng? _selectedCoordinates;

  Set<Polyline> _polylines = {}; // 🔹 For straight line drawing

  int selectedCategoryIndex = 0;
  int _selectedIndex = 0;

  final List<String> categories = [
    "Foodie Finds",
    "Funny Tail",
    "History Whishpers",
    "Hidden spots",
    "Art & Culture",
    "Legends & Myths",
    "Shopping Gems",
    "Festive Movements"
  ];

  final Map<String, String> categoryToPinImage = {
    "Foodie Finds": "assets/images/pin_1.png",
    "Funny Tail": "assets/images/funnytales.png",
    "History Whishpers": "assets/images/historywhishpers.png",
    "Hidden spots": "assets/images/hiddenspots.png",
    "Art & Culture": "assets/images/art&culture.png",
    "Legends & Myths": "assets/images/legends&myths.png",
    "Shopping Gems": "assets/images/shoppinggems.png",
    "Festive Movements": "assets/images/festivemovements.png",
  };

  List<Map<String, dynamic>> _backendNearbySpots = [];


  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) return;
    final url =
        "https://nominatim.openstreetmap.org/search?q=$input&format=json&limit=5&addressdetails=1";
    final response = await http.get(Uri.parse(url), headers: {
      "User-Agent": "FlutterMapApp"
    });
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() => _suggestions = List<Map<String, dynamic>>.from(data));
    }
  }

  Future<void> _onSuggestionTap(Map<String, dynamic> suggestion) async {
    final lat = double.parse(suggestion['lat']);
    final lon = double.parse(suggestion['lon']);
    final selected = LatLng(lat, lon);
    final query = suggestion['display_name'];

    setState(() {
      _searchController.text = query;
      _suggestions = [];
    });

    _googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(selected, 15),
    );

    await _fetchSearchedSpots(query); // 👈 fetch backend data for searched location
  }


  void _drawStraightLine(LatLng start, LatLng end) {
    getRoutePolyline(start, end);
  }


  Future<Set<Marker>> _buildMarkers() async {
    final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/images/pin_1.png',
    );

    final backendMarkers = _backendNearbySpots.map((spot) {
      final lat = spot['latitude'] as double;
      final lng = spot['longitude'] as double;

      return Marker(
        markerId: MarkerId(spot['spotname']),
        position: LatLng(lat, lng),
        icon: customIcon,
        onTap: () {
          setState(() {
            _selectedTitle = spot['spotname'];
            _selectedDescription = "Lat: $lat\nLng: $lng";
            _selectedViews = (spot['distance'] as num).round(); // using distance as "views"
            _selectedCoordinates = LatLng(lat, lng);
          });
        },
      );
    }).toSet();

    return backendMarkers;
  }
  String _selectedBudget = "₹200 - ₹500";
  final List<String> _budgetOptions = [
    "₹200 - ₹500",
    "₹500 - ₹1000",
    "₹1000 - ₹2000",
    "₹2000 above"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_selectedTitle != null) {
            setState(() {
              _selectedTitle = null;
              _polylines = {}; // clear route when closing detail
            });
          }
        },
        child: Stack(

          children: [


            if (_liveLocation == null)
              const Center(child: CircularProgressIndicator())
            else
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _liveLocation!,
                  zoom: 14,
                ),
                onMapCreated: (controller) => _googleMapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: {
                  if (_liveLocation != null)
                    Marker(
                      markerId: const MarkerId("live"),
                      position: _liveLocation!,
                      icon: _profileMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(title: "You"),
                    ),
                  ..._dynamicMarkers, // 👈 We'll define this below
                },
                polylines: _polylines,
              ),

            Positioned(
              bottom: 160,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.black87,
                onPressed: _startListening,
                child: Icon(
                  _isListening ? Icons.mic_none : Icons.mic,
                  color: Colors.white,
                ),

              ),
            ),
            const GlassAppBar(),

            // 🔹 Search + Budget Row
            Positioned(
              top: 110,
              left: 15,
              right: 15,
              child: Row(
                children: [
                  // Search Bar (reduced width)
                  Expanded(
                    flex: 1,
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: 55,
                      borderRadius: 12,
                      blur: 15,
                      alignment: Alignment.center,
                      border: 1,
                      linearGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white38.withOpacity(0.2)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white24.withOpacity(0.2),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(Icons.search, color: Colors.black87),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _fetchSuggestions,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: "Search places...",
                                hintStyle: TextStyle(color: Colors.black54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Budget Dropdown
                  Expanded(
                    flex: 1,
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: 55,
                      borderRadius: 12,
                      blur: 15,
                      alignment: Alignment.center,
                      border: 1,
                      linearGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white38.withOpacity(0.2)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white24.withOpacity(0.2),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBudget,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.black87),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedBudget = newValue!;
                              // 🔹 keep logic untouched, only UI now
                            });
                          },
                          items: _budgetOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 175,
              left: 16,
              right: 0,
              child: CategoryChips(
                categories: categories,
                selectedIndex: selectedCategoryIndex,
                onSelected: (index) {
                  setState(() {
                    selectedCategoryIndex = index;
                    final selectedCategory = categories[index];
                    if (_liveLocation != null) {
                      _fetchNearbySpots(_liveLocation!.latitude, _liveLocation!.longitude);
                    }

                  });
                },
              ),
            ),

            if (_suggestions.isNotEmpty)
              Positioned(
                top: 230,
                left: 15,
                right: 15,
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: _suggestions.length * 55.0,
                  borderRadius: 12,
                  blur: 20,
                  alignment: Alignment.topCenter,
                  border: 1,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white38.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white24.withOpacity(0.2),
                    ],
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, color: Colors.black),
                        title: Text(
                          suggestion['display_name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black),
                        ),
                        onTap: () => _onSuggestionTap(suggestion),
                      );
                    },
                  ),
                ),
              ),

            if (_selectedTitle != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 95,
                child: GestureDetector(
                  onTap: () {}, // prevent tap propagation
                  child: GlassDetailBottomSheet(
                    title: _selectedTitle!,
                    description: _selectedDescription ?? '',
                    views: _selectedViews ?? 0,
                    onDirectionTap: () {
                      if (_liveLocation != null && _selectedCoordinates != null) {
                        _drawStraightLine(_liveLocation!, _selectedCoordinates!);
                      }
                    },
                    onPlayTap: () {
                      if (_selectedCoordinates != null &&
                          _selectedDescription != null &&
                          _selectedViews != null &&
                          _selectedTitle != null)

                        print("▶ Spot Username: $_selectedSpotUsername");

                      {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayPostScreen(
                              username: _selectedSpotUsername ?? widget.username,
                              description: _selectedDescription!,
                              views: _selectedViews!,
                              latitude: _selectedCoordinates!.latitude,
                              longitude: _selectedCoordinates!.longitude,
                            ),
                          ),
                        );
                      }
                    },
                    onCloseTap: () {
                      setState(() {
                        _selectedTitle = null;
                        _selectedDescription = null;
                        _selectedViews = null;
                        _selectedCoordinates = null;
                        _polylines.clear(); // optional: clear route
                      });
                    },

                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UploadScreen(username: widget.username)),
            );
          }else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen(username: widget.username)),
            );
          }else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => JourneyScreen(username: widget.username)),
            );
          }else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),

    );
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}