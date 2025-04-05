import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'dart:math' as math;

class HandSignDetector {
  final PoseDetector _poseDetector;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final HandSignDetector _instance = HandSignDetector._internal();
  factory HandSignDetector() => _instance;
  
  HandSignDetector._internal() : _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<List<PoseLandmark>> detectHand(CameraImage image, InputImageRotation rotation) async {
    if (!_isInitialized) {
      throw Exception('HandSignDetector not initialized. Call initialize() first.');
    }

    // Simplify the image processing to avoid using InputImagePlaneMetadata
    final format = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
    
    // Use the first plane's bytes directly instead of complex conversion
    final bytes = image.planes[0].bytes;
    
    final inputImageData = InputImageMetadata(
      size: ui.Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );

    try {
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) return [];
      return poses.first.landmarks.values.toList();
    } catch (e) {
      print("Error processing image in PoseDetector: $e");
      return [];
    }
  }

  String? classifySign(List<PoseLandmark> landmarks) {
    if (!_isInitialized || landmarks.isEmpty) return null;
    return _classifyWithImprovedHeuristics(landmarks);
  }

  String? _classifyWithImprovedHeuristics(List<PoseLandmark> landmarks) {
    try {
      final rightWrist = _getLandmark(landmarks, PoseLandmarkType.rightWrist);
      final rightThumb = _getLandmark(landmarks, PoseLandmarkType.rightThumb);
      final rightIndex = _getLandmark(landmarks, PoseLandmarkType.rightIndex);
      final rightPinky = _getLandmark(landmarks, PoseLandmarkType.rightPinky);
      final rightShoulder = _getLandmark(landmarks, PoseLandmarkType.rightShoulder);
      final rightElbow = _getLandmark(landmarks, PoseLandmarkType.rightElbow);

      if (rightWrist == null || rightThumb == null || rightIndex == null || rightPinky == null || rightShoulder == null || rightElbow == null) {
        return null; 
      }

      bool isThumbHigher = rightThumb.y < rightWrist.y;
      bool isIndexHigher = rightIndex.y < rightWrist.y;
      bool isPinkyHigher = rightPinky.y < rightWrist.y;
      
      bool isThumbOuter = rightThumb.x < rightWrist.x;
      bool isIndexOuter = rightIndex.x < rightWrist.x;
      bool isPinkyOuter = rightPinky.x < rightWrist.x;

      double thumbIndexDist = _getDistance(rightThumb, rightIndex);
      double indexPinkyDist = _getDistance(rightIndex, rightPinky);
      double refDist = _getDistance(rightWrist, rightElbow);
      if (refDist < 0.01) refDist = 0.1;

      double normThumbIndexDist = thumbIndexDist / refDist;
      double normIndexPinkyDist = indexPinkyDist / refDist;

      bool isHandRaised = rightWrist.y < rightShoulder.y;
      bool isHandNearHead = isHandRaised && (rightWrist.x - rightShoulder.x).abs() < _getDistance(rightShoulder, rightElbow) * 0.6;

      if (isHandRaised && isHandNearHead) {
        return "Hello";
      }

      if (isThumbHigher && !isIndexHigher && !isPinkyHigher && normIndexPinkyDist < 0.5) {
         return "A";
      }
      
      if (!isThumbHigher && isIndexHigher && isPinkyHigher && normIndexPinkyDist < 0.5) {
         return "B";
      }

      if (isIndexHigher && !isThumbHigher && !isPinkyHigher && normThumbIndexDist > 0.5 && normIndexPinkyDist > 0.5) {
         return "D";
      }
      
      if (normThumbIndexDist < 0.3 && isPinkyHigher && isIndexHigher) {
          return "F";
      }

      if (isThumbHigher && isIndexHigher && !isPinkyHigher && isThumbOuter != isIndexOuter && normThumbIndexDist > 0.6) {
          return "L";
      }

      if (isIndexHigher && isPinkyHigher && normIndexPinkyDist > 0.6) {
           return "V";
       }

    } catch (e) {
      print('Error during sign classification: $e'); 
    }
    
    return null; 
  }

  PoseLandmark? _getLandmark(List<PoseLandmark> landmarks, PoseLandmarkType type) {
    try {
      return landmarks.firstWhere((lm) => lm.type == type);
    } catch (e) {
      return null; 
    }
  }

  double _getDistance(PoseLandmark? a, PoseLandmark? b) {
    if (a == null || b == null) return double.infinity;
    return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
  }

  void dispose() {
    _poseDetector.close();
    _isInitialized = false;
  }
} 