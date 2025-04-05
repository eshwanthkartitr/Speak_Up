import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_samples/rive_app/utils/hand_sign_detector.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class SignCamera extends StatefulWidget {
  final Function(String sign)? onSignDetected;
  final bool showPreview;

  const SignCamera({
    Key? key,
    this.onSignDetected,
    this.showPreview = true,
  }) : super(key: key);

  @override
  State<SignCamera> createState() => _SignCameraState();
}

class _SignCameraState extends State<SignCamera> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isDetecting = false;
  final HandSignDetector _signDetector = HandSignDetector();
  String? _lastDetectedSign;
  bool _isCameraInitialized = false;
  List<PoseLandmark>? _currentLandmarks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use front camera for sign language detection
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      await _signDetector.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startDetection();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _stopCamera() {
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _startDetection() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;

      _isDetecting = true;

      try {
        final rotation = _controller!.description.sensorOrientation;
        final inputRotation = InputImageRotation.values[rotation ~/ 90];

        final landmarks = await _signDetector.detectHand(image, inputRotation);
        
        if (landmarks.isNotEmpty) {
          if (mounted) {
            setState(() {
              _currentLandmarks = landmarks;
            });
          }
          
          final detectedSign = _signDetector.classifySign(landmarks);

          if (detectedSign != null && detectedSign != _lastDetectedSign) {
            _lastDetectedSign = detectedSign;
            widget.onSignDetected?.call(detectedSign);
          }
        } else {
          if (mounted) {
            setState(() {
              _currentLandmarks = null;
            });
          }
        }
      } catch (e) {
        print('Error processing frame: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return widget.showPreview ? _buildCameraPreview() : Container();
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    // Get the screen size
    final size = MediaQuery.of(context).size;
    
    
    // Get the camera preview size
    final previewSize = _controller!.value.previewSize!;
    final cameraAspectRatio = previewSize.height / previewSize.width;

    // Calculate the preview widget size to maintain aspect ratio
    double previewWidth = size.width;
    double previewHeight = previewWidth * cameraAspectRatio;

    // If preview height is greater than available height, scale down
    if (previewHeight > size.height) {
      previewHeight = size.height;
      previewWidth = previewHeight / cameraAspectRatio;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: previewWidth,
          height: previewHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              Transform.scale(
                scale: 1.0,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1 / cameraAspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
              
              // Overlay for better visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
              
              // Landmark visualization
              if (_currentLandmarks != null)
                CustomPaint(
                  painter: PoseLandmarkPainter(
                    landmarks: _currentLandmarks!,
                    imageSize: Size(previewWidth, previewHeight),
                    rotation: _controller!.description.sensorOrientation,
                    isSignDetected: _lastDetectedSign != null,
                  ),
                ),
              
              // Sign indicator
              if (_lastDetectedSign != null)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'Sign: $_lastDetectedSign',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PoseLandmarkPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Size imageSize;
  final int rotation;
  final bool isSignDetected;

  PoseLandmarkPainter({
    required this.landmarks,
    required this.imageSize,
    required this.rotation,
    required this.isSignDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Color pointColor = isSignDetected ? Colors.cyanAccent : Colors.greenAccent;
    final Color lineColor = isSignDetected ? Colors.cyanAccent.withOpacity(0.5) : Colors.greenAccent.withOpacity(0.5);
    final Color glowColor = isSignDetected ? Colors.cyanAccent.withOpacity(0.3) : Colors.greenAccent.withOpacity(0.3);

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill
      ..strokeWidth = 8.0;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (final landmark in landmarks) {
      PoseLandmark? currentLandmark = _getLandmark(landmarks, landmark.type);
      if (currentLandmark == null) continue;

      final point = _transformPoint(
        Offset(currentLandmark.x * size.width, currentLandmark.y * size.height),
        size,
        rotation,
      );

      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(point, 12, glowPaint);
      canvas.drawCircle(point, 6, pointPaint);

      if (landmark.type == PoseLandmarkType.rightWrist) {
        _drawConnection(canvas, linePaint, size, rotation, landmark.type, PoseLandmarkType.rightThumb);
        _drawConnection(canvas, linePaint, size, rotation, landmark.type, PoseLandmarkType.rightIndex);
        _drawConnection(canvas, linePaint, size, rotation, landmark.type, PoseLandmarkType.rightPinky);
        _drawConnection(canvas, linePaint, size, rotation, landmark.type, PoseLandmarkType.rightElbow);
      }
      if (landmark.type == PoseLandmarkType.rightElbow) {
        _drawConnection(canvas, linePaint, size, rotation, landmark.type, PoseLandmarkType.rightShoulder);
      }
      if (landmark.type == PoseLandmarkType.rightShoulder) {
        _drawConnection(canvas, linePaint, size, rotation, landmark.type, PoseLandmarkType.leftShoulder);
      }
    }
  }

  void _drawConnection(Canvas canvas, Paint paint, Size viewSize, int rotation, PoseLandmarkType type1, PoseLandmarkType type2) {
    PoseLandmark? lm1 = _getLandmark(landmarks, type1);
    PoseLandmark? lm2 = _getLandmark(landmarks, type2);

    if (lm1 != null && lm2 != null) {
      final point1 = _transformPoint(Offset(lm1.x * viewSize.width, lm1.y * viewSize.height), viewSize, rotation);
      final point2 = _transformPoint(Offset(lm2.x * viewSize.width, lm2.y * viewSize.height), viewSize, rotation);
      canvas.drawLine(point1, point2, paint);
    }
  }

  PoseLandmark? _getLandmark(List<PoseLandmark> landmarks, PoseLandmarkType type) {
    try {
      return landmarks.firstWhere((lm) => lm.type == type);
    } catch (e) {
      return null;
    }
  }

  Offset _transformPoint(Offset point, Size viewSize, int rotation) {
    double x = point.dx;
    double y = point.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(PoseLandmarkPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks || oldDelegate.isSignDetected != isSignDetected;
  }
} 