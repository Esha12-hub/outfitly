import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'package:untitled2/user_dashboard.dart';

class VirtualTryOnScreen extends StatefulWidget {
  const VirtualTryOnScreen({super.key});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  CameraController? _controller;
  XFile? _dressFile;
  Uint8List? _dressPreview;
  Uint8List? _capturedImage;
  List<CameraDescription>? _cameras;
  String _status = "Initializing camera...";

  double _dressScale = 1.0;
  double _dressX = 0.0;
  double _dressY = 0.0;
  double _dressRotation = 0.0;

  double _previousScale = 1.0;
  Offset _previousOffset = Offset.zero;
  double _previousRotation = 0.0;

  int _countdown = 0;
  final GlobalKey _previewContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    requestPermissionsAndInit();
  }

  Future<void> requestPermissionsAndInit() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _status = "Camera permission denied!");
      return;
    }
    await initCamera();
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      setState(() => _status = "No camera found on device.");
      return;
    }
    _controller = CameraController(
      _cameras!.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      ),
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    setState(() => _status = "Camera ready — pick a dress!");
  }

  Future<void> pickDress() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _dressFile = file;
        _dressPreview = bytes;
        _status = "Dress selected — overlay active!";
      });
    }
  }

  Future<void> captureWithOverlay({int delaySeconds = 10}) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _status = "Capturing in $delaySeconds seconds...";
      _countdown = delaySeconds;
    });

    for (int i = delaySeconds; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _countdown = i - 1);
    }

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final boundary =
      _previewContainerKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      setState(() {
        _capturedImage = pngBytes;
        _status = "Image captured with dress overlay!";
        _countdown = 0;
      });
    } catch (e) {
      setState(() => _status = "Capture failed: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonFontSize = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WardrobeHomeScreen()),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.02),
            child: Image.asset(
              'assets/images/white_back_btn.png',
              width: screenWidth * 0.06,
              height: screenWidth * 0.06,
            ),
          ),
        ),
        title: Text(
          "Virtual Try-On",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // Live camera preview + dress overlay
          Expanded(
            child: RepaintBoundary(
              key: _previewContainerKey,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_controller != null && _controller!.value.isInitialized)
                    CameraPreview(_controller!),
                  if (_dressPreview != null)
                    GestureDetector(
                      onScaleStart: (details) {
                        _previousScale = _dressScale;
                        _previousRotation = _dressRotation;
                        _previousOffset = Offset(_dressX, _dressY);
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          // Smooth scale
                          _dressScale = _previousScale * details.scale.clamp(0.2, 5.0);

                          // Smooth rotation
                          _dressRotation = _previousRotation + details.rotation;

                          // Smooth movement using translation delta
                          final delta = details.focalPointDelta;
                          _dressX += delta.dx;
                          _dressY += delta.dy;
                        });
                      },
                      child: Transform.translate(
                        offset: Offset(_dressX, _dressY),
                        child: Transform.rotate(
                          angle: _dressRotation,
                          child: Transform.scale(
                            scale: _dressScale,
                            child: Image.memory(
                              _dressPreview!,
                              height: screenHeight * 0.5,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),


                  // Countdown display
                  if (_countdown > 0)
                    Positioned(
                      top: screenHeight * 0.07,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_countdown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Controls section
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: screenWidth * 0.04,
                  runSpacing: screenWidth * 0.03,
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickDress,
                      icon: Icon(Icons.shopping_bag, color: Colors.white, size: screenWidth * 0.05),
                      label: Text(
                        "Pick Dress",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: buttonFontSize,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenWidth * 0.03,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => captureWithOverlay(delaySeconds: 10),
                      icon: Icon(Icons.camera_alt, color: Colors.white, size: screenWidth * 0.05),
                      label: Text(
                        "Capture (10s)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: buttonFontSize,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenWidth * 0.03,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.035,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                if (_capturedImage != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              title: const Text("Captured Image"),
                            ),
                            body: Center(
                              child: InteractiveViewer(
                                panEnabled: true,
                                scaleEnabled: true,
                                child: Image.memory(
                                  _capturedImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: screenHeight * 0.015),
                      height: screenHeight * 0.25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Image.memory(
                        _capturedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
