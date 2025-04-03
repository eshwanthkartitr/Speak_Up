import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:math' as math;

class HandSignDetector {
  final PoseDetector _poseDetector;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final HandSignDetector _instance = HandSignDetector._internal();
  factory HandSignDetector() => _instance;
  
  HandSignDetector._internal() : _poseDetector = GoogleMlKit.vision.poseDetector();

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<List<PoseLandmark>> detectHand(CameraImage image, InputImageRotation rotation) async {
    if (!_isInitialized) {
      throw Exception('HandSignDetector not initialized');
    }

    final inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    // Detect poses
    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) return [];

    // Return landmarks of the first detected pose
    return poses.first.landmarks.values.toList();
  }

  String? classifySign(List<PoseLandmark> landmarks) {
    if (!_isInitialized || landmarks.isEmpty) return null;
    return _classifyAlphabet(landmarks);
  }

  String? _classifyAlphabet(List<PoseLandmark> landmarks) {
    try {
      // Get key landmarks for the right hand
      final wrist = _getLandmark(landmarks, PoseLandmarkType.rightWrist);
      final thumb = _getLandmark(landmarks, PoseLandmarkType.rightThumb);
      final index = _getLandmark(landmarks, PoseLandmarkType.rightIndex);
      final pinky = _getLandmark(landmarks, PoseLandmarkType.rightPinky);
      
      // Calculate relative positions
      final isThumbUp = thumb.y < wrist.y;
      final isIndexUp = index.y < wrist.y;
      final isPinkyUp = pinky.y < wrist.y;
      
      // Simple classification based on finger positions
      if (isThumbUp && !isIndexUp && !isPinkyUp) {
        return "A";
      } else if (!isThumbUp && isIndexUp && !isPinkyUp) {
        return "B";
      } else if (isThumbUp && isIndexUp && !isPinkyUp) {
        return "C";
      } else if (isThumbUp && !isIndexUp && isPinkyUp) {
        return "D";
      } else if (!isThumbUp && isIndexUp && isPinkyUp) {
        return "E";
      } else if (isThumbUp && isIndexUp && isPinkyUp) {
        return "F";
      } else if (!isThumbUp && !isIndexUp && isPinkyUp) {
        return "G";
      }
      
    } catch (e) {
      print('Error in sign classification: $e');
    }
    
    return null;
  }

  PoseLandmark _getLandmark(List<PoseLandmark> landmarks, PoseLandmarkType type) {
    return landmarks.firstWhere((lm) => lm.type == type);
  }

  double _getDistance(PoseLandmark a, PoseLandmark b) {
    return math.sqrt(
      math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2) + math.pow(a.z - b.z, 2)
    );
  }

  void dispose() {
    _poseDetector.close();
  }
} 