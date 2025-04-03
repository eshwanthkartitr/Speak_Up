import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class SignDetector {
  final PoseDetector _poseDetector;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final SignDetector _instance = SignDetector._internal();
  factory SignDetector() => _instance;
  
  SignDetector._internal() : _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<List<PoseLandmark>> detectPose(CameraImage image, InputImageRotation rotation) async {
    if (!_isInitialized) {
      throw Exception('SignDetector not initialized');
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
    final List<Pose> poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) return [];

    // Return landmarks of the first detected pose
    return poses.first.landmarks.values.toList();
  }

  String? classifySign(List<PoseLandmark> landmarks) {
    if (!_isInitialized || landmarks.isEmpty) return null;
    return _classifyWithHeuristics(landmarks);
  }

  String? _classifyWithHeuristics(List<PoseLandmark> landmarks) {
    // Simple heuristic-based classification
    try {
      final rightWrist = landmarks.firstWhere(
        (lm) => lm.type == PoseLandmarkType.rightWrist,
        orElse: () => landmarks.first,
      );
      
      final rightShoulder = landmarks.firstWhere(
        (lm) => lm.type == PoseLandmarkType.rightShoulder,
        orElse: () => landmarks.first,
      );
      
      // If right hand is raised near head height
      if (rightWrist.y < rightShoulder.y && 
          (rightWrist.x - rightShoulder.x).abs() < 0.3) {
        return "Hello";
      }
      
      // Add more sign detection logic here
      
    } catch (e) {
      print('Error in sign classification: $e');
    }
    
    return null;
  }

  void dispose() {
    _poseDetector.close();
  }
} 