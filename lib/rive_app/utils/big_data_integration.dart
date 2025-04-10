import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:mongo_dart/mongo_dart.dart';

import 'big_data_processor.dart';
import 'big_data_analytics.dart';
import 'neural_network_models.dart';
import 'knowledge_graph.dart';
import 'model_helper.dart';

/// BigDataIntegration provides a unified API for accessing all the big data components
/// used in the Tamil sign language recognition system.
class BigDataIntegration {
  // Singleton instance
  static final BigDataIntegration _instance = BigDataIntegration._internal();

  // Components
  late final BigDataAnalytics _analytics;
  late final DistributedDataPipeline _dataPipeline;
  late final KnowledgeGraph _knowledgeGraph;
  late final NeuralNetworkModel _neuralNetwork;

  // MongoDB connection
  late Db _db;
  late DbCollection _signDetectionsCollection;
  final String _connectionString = 'mongodb+srv://eshwanthkartitr:Tr310305@cluster0.2xacffx.mongodb.net/Speak_up_db';
  
  // System metrics stream
  final StreamController<Map<String, dynamic>> _metricsController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Status tracking
  bool _isInitialized = false;
  final Map<String, bool> _componentStatus = {
    'analytics': false,
    'dataPipeline': false,
    'knowledgeGraph': false,
    'neuralNetwork': false,
    'database': false
  };

  // Performance metrics
  int _framesProcessed = 0;
  int _successfulDetections = 0;
  List<double> _processingTimes = [];
  DateTime? _lastEmitTime;

  // Factory constructor
  factory BigDataIntegration() {
    return _instance;
  }

  // Private constructor
  BigDataIntegration._internal() {
    _initialize();
  }

  /// Stream of system metrics for monitoring
  Stream<Map<String, dynamic>> get systemMetrics => _metricsController.stream;

  /// Initialize all components
  Future<void> _initialize() async {
    try {
      // Initialize components
      _analytics = BigDataAnalytics();
      _componentStatus['analytics'] = true;
      _emitSystemStatus();

      _dataPipeline = DistributedDataPipeline();
      _componentStatus['dataPipeline'] = true;
      _emitSystemStatus();

      _knowledgeGraph = KnowledgeGraph();
      await _knowledgeGraph.initialize();
      _componentStatus['knowledgeGraph'] = true;
      _emitSystemStatus();

      _neuralNetwork = NeuralNetworkModel();
      await _neuralNetwork.loadModel('mobilenetv3_simple.tflite');
      _componentStatus['neuralNetwork'] = true;
      _emitSystemStatus();

      // Initialize MongoDB connection
      try {
        print('Connecting to MongoDB at cluster0.2xacffx.mongodb.net/Speak_up_db...');
        _db = await Db.create(_connectionString);
        await _db.open();
        _signDetectionsCollection = _db.collection('sign_detections');
        _componentStatus['database'] = true;
        print('Successfully connected to MongoDB sign_detections collection');
      } catch (e) {
        print('Failed to connect to MongoDB: $e');
      }

      _isInitialized = true;
      print('BigDataIntegration initialized successfully');

      // Start periodic status updates
      Timer.periodic(const Duration(seconds: 3), (timer) {
        _updateSystemMetrics();
      });
    } catch (e) {
      print('Error initializing BigDataIntegration: $e');
      _metricsController.addError(e);
    }
  }

  /// Public initialize method that waits for all components to be ready
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Wait for internal initialization to complete
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Process a frame and return results with predictions and analytics
  Future<Map<String, dynamic>> processFrame(img.Image frame) async {
    final startTime = DateTime.now();

    try {
      if (!_isInitialized) {
        return {'error': 'System not initialized'};
      }

      _framesProcessed++;

      // Pre-process frame using data pipeline
      final processedData = await _dataPipeline.processFrame(frame);

      // Extract features and metadata
      final features = processedData['features'];
      final metadata = processedData['metadata'];

      // Run inference through model helper
      final inferenceResults = await ModelHelper.runInference(frame);

      // Process analytics
      final inferenceMap = {'results': inferenceResults};
      final analyticsResults =
          await _analytics.processResults(inferenceMap, metadata);

      // Get character prediction using model helper
      final characterPrediction =
          ModelHelper.getPredictedCharacter(inferenceResults);

      // Extract character information
      String baseCharacter = characterPrediction;
      if (characterPrediction.contains('(')) {
        final parenthesisIndex = characterPrediction.indexOf('(');
        baseCharacter =
            characterPrediction.substring(0, parenthesisIndex).trim();
      }

      // Get max confidence from inference results
      double confidence = inferenceResults.isEmpty
          ? 0.5
          : inferenceResults.reduce((curr, next) => curr > next ? curr : next);

      // Build prediction object
      final prediction = {
        'character': characterPrediction,
        'baseCharacter': baseCharacter,
        'confidence': confidence,
      };

      // If we have a valid prediction, count it as successful and store in MongoDB
      if (characterPrediction != 'Background') {
        _successfulDetections++;
        
        // Push prediction to MongoDB
        if (_componentStatus['database'] == true) {
          try {
            final timestamp = DateTime.now().toIso8601String();
            final document = {
              'prediction': characterPrediction,
              'timestamp': timestamp
            };
            
            await _signDetectionsCollection.insert(document);
            print('Successfully pushed prediction "$characterPrediction" to MongoDB');
          } catch (e) {
            print('Failed to push prediction to MongoDB: $e');
          }
        }
      }

      // Generate attention maps for visualization
      final attentionMaps = _generateAttentionMaps();

      // Find related signs using knowledge graph
      final relatedSigns =
          _knowledgeGraph.findRelatedSigns(characterPrediction);

      // Record processing time
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;
      _processingTimes.add(processingTime.toDouble());
      if (_processingTimes.length > 50) {
        _processingTimes.removeAt(0);
      }

      // Calculate the average processing time
      final avgProcessingTime = _processingTimes.isNotEmpty
          ? _processingTimes.reduce((a, b) => a + b) / _processingTimes.length
          : 0;

      // Ensure metrics are updated
      _updateSystemMetrics();

      // Return comprehensive results
      return {
        'prediction': prediction,
        'inferenceResults': inferenceResults,
        'analyticsResults': analyticsResults,
        'attentionMaps': attentionMaps,
        'relatedSigns': relatedSigns,
        'processingTime': processingTime,
        'avgProcessingTime': avgProcessingTime,
        'analyticsInsights': {
          'frameComplexity': metadata['complexity'] ?? 0.5,
          'motionEstimate': metadata['motion'] ?? 1.0,
          'lightingQuality': metadata['lighting'] ?? 0.8,
        }
      };
    } catch (e) {
      print('Error processing frame: $e');
      return {'error': 'Processing error', 'details': e.toString()};
    }
  }

  /// Generate word suggestions based on the detected character
  List<String> generateWordSuggestions(String character) {
    if (character.isEmpty || character == 'Background') {
      return [];
    }

    try {
      // Use knowledge graph to get enhanced suggestions
      final enhancedSuggestions =
          _knowledgeGraph.getWordSuggestionsForSign(character);

      // If we have enhanced suggestions, use them
      if (enhancedSuggestions.isNotEmpty) {
        return enhancedSuggestions;
      }

      // Fall back to model helper if knowledge graph doesn't have suggestions
      return ModelHelper.generateWordSuggestions(character);
    } catch (e) {
      print('Error generating word suggestions: $e');
      return ModelHelper.generateWordSuggestions(character);
    }
  }

  /// Clean up resources
  void dispose() {
    _metricsController.close();
    if (_isInitialized && _componentStatus['database'] == true) {
      _db.close();
      print('Closed MongoDB connection');
    }
  }

  /// Update and emit system metrics
  void _updateSystemMetrics() {
    final now = DateTime.now();

    // Limit emission rate to avoid too many updates
    if (_lastEmitTime != null && now.difference(_lastEmitTime!).inSeconds < 2) {
      return;
    }

    _lastEmitTime = now;
    _emitSystemStatus();
  }

  /// Emit current system status
  void _emitSystemStatus() {
    if (_metricsController.isClosed) return;

    // Calculate detection rate
    final detectionRate =
        _framesProcessed > 0 ? _successfulDetections / _framesProcessed : 0.0;

    // Calculate average processing time
    final avgProcessingTime = _processingTimes.isNotEmpty
        ? _processingTimes.reduce((a, b) => a + b) / _processingTimes.length
        : 0;

    // Simulate cluster utilization
    final analyticsClusterUtilization =
        math.min(0.3 + (_framesProcessed % 10) / 30, 0.95);

    _metricsController.add({
      'timestamp': DateTime.now().toIso8601String(),
      'componentStatus': _componentStatus,
      'framesProcessed': _framesProcessed,
      'successfulDetections': _successfulDetections,
      'detectionRate': detectionRate,
      'avgProcessingTime': avgProcessingTime,
      'analyticsClusterUtilization': analyticsClusterUtilization,
      'memoryUsage': {
        'neuralNetwork': _randomPercentage(0.3, 0.6),
        'knowledgeGraph': _randomPercentage(0.2, 0.4),
        'dataPipeline': _randomPercentage(0.1, 0.3),
      }
    });
  }

  /// Generate attention maps for visualization
  List<List<double>> _generateAttentionMaps() {
    const gridSize = 6;
    final List<double> attentionMap =
        List.generate(gridSize * gridSize, (index) {
      // Create a central hotspot with surrounding gradient
      final x = index % gridSize;
      final y = index ~/ gridSize;

      // Calculate distance from center (normalized)
      final centerX = gridSize / 2;
      final centerY = gridSize / 2;
      final distFromCenter =
          math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2)) /
              (gridSize / 2);

      // Create a hotspot value that decreases with distance from center
      double value = math.max(0, 1 - distFromCenter);

      // Add some noise
      value += (math.Random().nextDouble() - 0.5) * 0.2;
      value = math.min(1, math.max(0, value));

      return value;
    });

    return [attentionMap];
  }

  /// Generate a random percentage between min and max
  double _randomPercentage(double min, double max) {
    return min + (math.Random().nextDouble() * (max - min));
  }
}