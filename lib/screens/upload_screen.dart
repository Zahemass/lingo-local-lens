import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import './user_profile_screen.dart';
import './simple_map_screen.dart';
import '../components/app_bar.dart';
import '../components/category_chips.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:sample_proj/widgets/audio_controls.dart';
import 'package:sample_proj/widgets/input_field.dart';
import 'package:sample_proj/widgets/location_selector.dart';
import 'package:sample_proj/widgets/upload_preview.dart';
import 'package:sample_proj/widgets/upload_submit.dart';
import 'package:sample_proj/widgets/thumbnail_selector.dart';
import 'journey_screen.dart';


class UploadScreen extends StatefulWidget {
  final String username;
  const UploadScreen({super.key, required this.username});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {


  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int selectedCategoryIndex = 0;
  int _selectedIndex = 1;


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

  final Map<String, String> categoryEmojis = {
    "Food": "🍔",
    "Fun": "🎢",
    "History": "🏛️",
    "Hidden spots": "🗝️",
    "Art & Culture": "🎨",
  };

  File? _thumbnail;
  File? _uploadedAudio;
  String? _recordedAudioPath;
  bool _isRecording = false;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  Timer? _recordingTimer;
  int _recordedSeconds = 0;
  LatLng? _selectedLatLng;
  bool _isGeneratingTitle = false;
  bool _isUploadingSpot = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recorder.closeRecorder();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickThumbnail(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _thumbnail = File(pickedFile.path));
    }
  }

  Future<void> _uploadAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'], // ✅ Only allow mp3
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      // ✅ Check extension again (just in case)
      if (!file.path.toLowerCase().endsWith(".mp3")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Please upload an MP3 file.")),
        );
        return;
      }

      setState(() {
        _uploadedAudio = file;
        _recordedAudioPath = null;
      });

      await _generateTitleFromAudio(file);
    }
  }


  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordedSeconds = 0;
        _recordedAudioPath = path;
        _uploadedAudio = null;
      });

      if (path != null) {
        await _generateTitleFromAudio(File(path));
      }
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/recorded_audio.aac';
      await _recorder.startRecorder(toFile: path);
      setState(() {
        _isRecording = true;
        _recordedSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (_recordedSeconds >= 45) {
          await _toggleRecording();
          return;
        }
        setState(() => _recordedSeconds++);
      });
    }
  }

  void _showAudioOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ), // 👈 THIS was missing
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text("Record Audio"),
            onTap: () {
              Navigator.pop(context);
              _toggleRecording();
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text("Upload Audio"),
            onTap: () async {
              Navigator.pop(context);
              await _uploadAudioFile();
            },
          ),
        ],
      ),
    );
  }


  Future<void> _generateTitleFromAudio(File audioFile) async {
    setState(() => _isGeneratingTitle = true);

    final uri = Uri.parse('http://10.184.180.35:4000/audiotitle');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = json.decode(resBody);
        final generatedTitle = data['title'];
        final generatedDescription = data['description'];

        if (mounted) {
          setState(() {
            _titleController.text = generatedTitle;
            _descriptionController.text = generatedDescription;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Title and description generated.")),
        );
      } else {
        throw Exception("Failed to fetch title and description");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate from audio.")),
      );
    } finally {
      setState(() => _isGeneratingTitle = false);
    }
  }


  void _showThumbnailOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Upload from Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickThumbnail(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take a Photo"),
            onTap: () {
              Navigator.pop(context);
              _pickThumbnail(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadSpot() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title")),
      );
      return;
    }

    if (_uploadedAudio == null && _recordedAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload or record an audio file")),
      );
      return;
    }

    if (_thumbnail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a thumbnail image")),
      );
      return;
    }

    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a location")),
      );
      return;
    }

    setState(() => _isUploadingSpot = true);

    try {
      final uri = Uri.parse('http://10.184.180.35:4000/spots');
      final request = http.MultipartRequest('POST', uri);

      final selectedCategory = categories[selectedCategoryIndex];

      request.fields['username'] = widget.username;
      request.fields['spotname'] = _titleController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['category'] = selectedCategory;
      request.fields['latitude'] = _selectedLatLng!.latitude.toString();
      request.fields['longitude'] = _selectedLatLng!.longitude.toString();

      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        _uploadedAudio?.path ?? _recordedAudioPath!,
      ));

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _thumbnail!.path,
      ));

      final response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Spot uploaded successfully")),
        );

        // ✅ Reset all fields
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _uploadedAudio = null;
          _recordedAudioPath = null;
          _thumbnail = null;
          _selectedLatLng = null;
          _recordedSeconds = 0;
          selectedCategoryIndex = 0; // Optional: reset to first category
        });
      } else {
        final errBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Upload failed. Please try again.")),
        );
        debugPrint("Upload failed: $errBody");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading spot: $e")),
      );
      debugPrint("Exception during upload: $e");
    } finally {
      setState(() => _isUploadingSpot = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final selectedCategory = categories[selectedCategoryIndex];
    final emoji = categoryEmojis[selectedCategory] ?? "🏷️";

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFE4EC),
      body: Stack(
        children: [
          // 🔽 Add this: Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/upl.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // adjust for strength
              child: Container(
                color: Colors.white.withOpacity(0.1), // frosted overlay
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 120, bottom: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  CategoryChips(
                    categories: categories,
                    selectedIndex: selectedCategoryIndex,
                    onSelected: (index) => setState(() => selectedCategoryIndex = index),
                  ),
                  const SizedBox(height: 15),

                  LocationSelector(
                    selectedLatLng: _selectedLatLng,
                    onPickLocation: (latLng) => setState(() => _selectedLatLng = latLng),
                  ),
                  const SizedBox(height: 24),

                  AudioControls(
                    isRecording: _isRecording,
                    recordedSeconds: _recordedSeconds,
                    onAudioOptions: _showAudioOptions,
                    onStopRecording: _toggleRecording,
                    onAddThumbnail: _showThumbnailOptions, // ✅ Pass function here
                  ),

                  const SizedBox(height: 24),


                  UploadPreview(
                    uploadedAudio: _uploadedAudio,
                    recordedAudioPath: _recordedAudioPath,
                  ),

                  if (_isGeneratingTitle) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink),
                        ),
                        SizedBox(width: 10),
                        Text("Generating title and description...", style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],

                  InputField(
                    hint: "Add Title",
                    fieldKey: "title_field",
                    controller: _titleController,
                  ),
                  const SizedBox(height: 16),

                  InputField(
                    hint: "Description",
                    fieldKey: "description_field",
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  if (_thumbnail != null)
                    ThumbnailSelector(
                      thumbnail: _thumbnail,
                      onTap: _showThumbnailOptions,
                    ),

                  const SizedBox(height: 2),
                  UploadSubmit(
                    onSubmit: _uploadSpot,
                    isUploading: _isUploadingSpot,
                  ),
                ],
              ),
            ),
          ),
          const GlassAppBar(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            // Go to map screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SimpleMapScreen(username: widget.username),
              ),
            );
          } else if (index == 2) {
            // Go to profile screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(username: widget.username),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => JourneyScreen(username: widget.username)),
            );
          }else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }
}
