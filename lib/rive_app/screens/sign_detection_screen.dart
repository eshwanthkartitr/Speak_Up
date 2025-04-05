import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_samples/rive_app/utils/hand_sign_detector.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';

class SignDetectionScreen extends StatefulWidget {
  const SignDetectionScreen({Key? key}) : super(key: key);

  @override
  State<SignDetectionScreen> createState() => _SignDetectionScreenState();
}

class _SignDetectionScreenState extends State<SignDetectionScreen> {
  CameraController? _controller;
  bool _isDetecting = false;
  final HandSignDetector _signDetector = HandSignDetector();
  String? _lastDetectedSign;
  bool _isCameraInitialized = false;
  List<PoseLandmark>? _currentLandmarks;
  String _predictedText = '';
  List<String> _signHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

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
            _updatePredictedText(detectedSign);
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

  void _updatePredictedText(String sign) {
    setState(() {
      _signHistory.add(sign);
      if (_signHistory.length > 5) {
        _signHistory.removeAt(0);
      }
      _predictedText = _signHistory.join(' ');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: RiveAppTheme.getBackgroundColor(isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: RiveAppTheme.getTextColor(isDarkMode),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Detection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: RiveAppTheme.getTextColor(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),

            // Camera Preview
            Expanded(
              flex: 2,
              child: _isCameraInitialized
                  ? Container(
                      margin: const EdgeInsets.all(16),
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(_controller!),
                            if (_currentLandmarks != null)
                              CustomPaint(
                                painter: PoseLandmarkPainter(
                                  landmarks: _currentLandmarks!,
                                  imageSize: Size(
                                    _controller!.value.previewSize!.height.toDouble(),
                                    _controller!.value.previewSize!.width.toDouble(),
                                  ),
                                  rotation: _controller!.description.sensorOrientation,
                                  isSignDetected: _lastDetectedSign != null,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            // Prediction Box
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RiveAppTheme.getCardColor(isDarkMode),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predicted Text:',
                    style: TextStyle(
                      color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RiveAppTheme.getInputBackgroundColor(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _predictedText.isEmpty ? 'Waiting for signs...' : _predictedText,
                      style: TextStyle(
                        color: RiveAppTheme.getTextColor(isDarkMode),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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