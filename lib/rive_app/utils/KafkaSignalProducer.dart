import 'dart:async';
import 'dart:convert';

class KafkaSignalProducer {
  final KafkaProducer _producer;
  final String _topic;
  
  KafkaSignalProducer(this._producer, this._topic);

  Future<void> sendSignDetection(Map<String, dynamic> signData) async {
    try {
      await _producer.produce(
        _topic,
        MessageBatch(messages: [
          Message(value: utf8.encode(jsonEncode(signData)))
        ]),
      );
    } catch (e) {
      print('Kafka producer error: $e');
    }
  }
}

class LandmarkStreamProcessor {
  final StreamController<Map<String, dynamic>> _controller = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Process incoming landmark data
  void processLandmark(List<PoseLandmark> landmarks) {
    // Extract relevant features
    final features = _extractFeatures(landmarks);
    
    // Enrich with metadata
    final enrichedData = {
      'timestamp': DateTime.now().toIso8601String(),
      'features': features,
      'handConfidence': _calculateConfidence(landmarks),
      'sessionId': _getCurrentSessionId(),
      'deviceInfo': _getDeviceInfo(),
      'processingLatency': _measureLatency(),
    };
    
    // Send to stream
    _controller.add(enrichedData);
  }
  
  Stream<Map<String, dynamic>> get landmarkStream => _controller.stream;
}