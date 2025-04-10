import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'advanced_python_integration.dart';

/// Advanced Model Visualizer that displays interactive visualizations of
/// ML models, leveraging the Python backend integration for data
class AdvancedModelVisualizer {
  // Singleton pattern
  static final AdvancedModelVisualizer _instance = AdvancedModelVisualizer._internal();
  factory AdvancedModelVisualizer() => _instance;
  
  // Access to Python backend
  final PythonBackendIntegration _pythonBackend = PythonBackendIntegration();
  
  // Visualization data cache
  final Map<String, Map<String, dynamic>> _visualizationCache = {};
  
  // Currently active model ID
  String? _activeModelId;
  
  // Available visualization types
  final List<String> _availableVisualizations = [
    'attention_maps',
    'gradient_flow',
    'feature_importance',
    'activation_patterns',
    'layer_outputs',
    'decision_boundaries',
    'embedding_space',
    'confusion_matrix',
    'training_progress',
    'error_analysis'
  ];
  
  AdvancedModelVisualizer._internal();
  
  /// Get all available visualization types
  List<String> get availableVisualizations => List.from(_availableVisualizations);
  
  /// Set the active model for visualization
  Future<bool> setActiveModel(String modelId) async {
    try {
      final models = await _pythonBackend.getAvailableModels();
      final modelExists = models.any((model) => model['id'] == modelId);
      
      if (modelExists) {
        _activeModelId = modelId;
        return true;
      } else {
        print('Model $modelId not found in available models');
        return false;
      }
    } catch (e) {
      print('Error setting active model: $e');
      return false;
    }
  }
  
  /// Get attention map visualization data for the current model
  Future<Map<String, dynamic>> getAttentionMapVisualization() async {
    if (_activeModelId == null) {
      return {'error': 'No active model set'};
    }
    
    // Check cache first
    final cacheKey = 'attention_${_activeModelId}';
    if (_visualizationCache.containsKey(cacheKey)) {
      return _visualizationCache[cacheKey]!;
    }
    
    // Simulate requesting data from Python backend
    try {
      final response = await _pythonBackend.processData(
        modelId: _activeModelId!,
        data: {'visualizationType': 'attention_maps'},
        operation: 'analyze'
      );
      
      // Generate attention visualization (simulated)
      final attentionData = _generateAttentionMaps(8, 8);
      
      // Add to cache
      _visualizationCache[cacheKey] = attentionData;
      
      return attentionData;
    } catch (e) {
      print('Error getting attention maps: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Generate synthetic attention map data for visualization
  Map<String, dynamic> _generateAttentionMaps(int gridWidth, int gridHeight) {
    // Create multiple attention heads for a transformer model
    final int numHeads = 8;
    final List<Map<String, dynamic>> attentionHeads = [];
    
    for (int h = 0; h < numHeads; h++) {
      // Generate grid of attention weights
      final List<List<double>> attentionGrid = List.generate(
        gridHeight, 
        (y) => List.generate(
          gridWidth, 
          (x) {
            // Generate different patterns for different heads
            double value;
            
            switch (h % 4) {
              case 0: // Center focus pattern
                final centerX = gridWidth / 2;
                final centerY = gridHeight / 2;
                final distance = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));
                final maxDistance = math.sqrt(math.pow(gridWidth / 2, 2) + math.pow(gridHeight / 2, 2));
                value = 1.0 - (distance / maxDistance);
                break;
                
              case 1: // Horizontal pattern
                value = math.sin(x * math.pi / gridWidth) * 0.5 + 0.5;
                break;
                
              case 2: // Vertical pattern
                value = math.cos(y * math.pi / gridHeight) * 0.5 + 0.5;
                break;
                
              case 3: // Diagonal pattern
                value = math.sin((x + y) * math.pi / (gridWidth + gridHeight)) * 0.5 + 0.5;
                break;
                
              default:
                value = math.Random().nextDouble();
            }
            
            // Add some noise
            value = math.max(0.0, math.min(1.0, value + (math.Random().nextDouble() - 0.5) * 0.2));
            return value;
          }
        )
      );
      
      attentionHeads.add({
        'headIndex': h,
        'headName': 'Attention Head ${h+1}',
        'gridData': attentionGrid,
        'maxValue': 1.0,
      });
    }
    
    return {
      'modelId': _activeModelId,
      'visualizationType': 'attention_maps',
      'attentionHeads': attentionHeads,
      'gridDimensions': {'width': gridWidth, 'height': gridHeight},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get neuron activation visualization for a specific layer
  Future<Map<String, dynamic>> getNeuronActivations(String layerName) async {
    if (_activeModelId == null) {
      return {'error': 'No active model set'};
    }
    
    // Check cache first
    final cacheKey = 'activations_${_activeModelId}_$layerName';
    if (_visualizationCache.containsKey(cacheKey)) {
      return _visualizationCache[cacheKey]!;
    }
    
    // Simulate delay for Python backend processing
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate neuron activation data (simulated)
    final activationData = _generateNeuronActivations(layerName);
    
    // Add to cache
    _visualizationCache[cacheKey] = activationData;
    
    return activationData;
  }
  
  /// Generate synthetic neuron activation data
  Map<String, dynamic> _generateNeuronActivations(String layerName) {
    // Determine layer type and dimensions based on name
    String layerType;
    int numNeurons;
    int? width, height, channels;
    
    if (layerName.contains('conv')) {
      layerType = 'convolution';
      // Size decreases, channels increase as we go deeper
      final layerIndex = int.tryParse(layerName.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      width = 32 ~/ math.pow(2, math.min(layerIndex, 4)).toInt();
      height = width;
      channels = 16 * math.pow(2, layerIndex).toInt();
      numNeurons = width * height * channels;
    } else if (layerName.contains('dense') || layerName.contains('fc')) {
      layerType = 'fully_connected';
      final layerIndex = int.tryParse(layerName.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      numNeurons = 1024 ~/ math.pow(2, layerIndex).toInt();
      width = null;
      height = null;
      channels = null;
    } else {
      layerType = 'other';
      numNeurons = 128;
      width = null;
      height = null;
      channels = null;
    }
    
    // Generate activation values
    final List<double> activations = List.generate(numNeurons, (i) {
      // Generate activation pattern based on neuron index
      if (layerType == 'convolution') {
        // More sparse activations in convolutional layers
        return math.Random().nextDouble() > 0.7 ? 
            math.Random().nextDouble() : 
            math.Random().nextDouble() * 0.2;
      } else {
        // More bell-curve like distribution in fully connected layers
        return 0.5 + (math.Random().nextDouble() - 0.5) * 0.8;
      }
    });
    
    // Create feature maps for convolutional layers
    final List<Map<String, dynamic>>? featureMaps = layerType == 'convolution' ? 
        _generateFeatureMaps(width!, height!, channels!) : null;
    
    return {
      'modelId': _activeModelId,
      'layerName': layerName,
      'layerType': layerType,
      'numNeurons': numNeurons,
      'dimensions': {
        'width': width,
        'height': height,
        'channels': channels,
      },
      'activations': activations,
      'featureMaps': featureMaps,
      'statistics': {
        'mean': activations.reduce((a, b) => a + b) / activations.length,
        'max': activations.reduce(math.max),
        'min': activations.reduce(math.min),
        'sparsity': activations.where((a) => a < 0.1).length / activations.length,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Generate feature maps for convolutional layers
  List<Map<String, dynamic>> _generateFeatureMaps(int width, int height, int channels) {
    final featureMaps = <Map<String, dynamic>>[];
    
    // Only generate a subset of feature maps for visualization
    final numMapsToGenerate = math.min(9, channels);
    
    for (int c = 0; c < numMapsToGenerate; c++) {
      final List<List<double>> mapData = List.generate(
        height, 
        (y) => List.generate(
          width, 
          (x) {
            // Generate different patterns for different channels
            double value;
            
            switch (c % 5) {
              case 0: // Edge detection like pattern
                value = ((x + y) % 2 == 0) ? 0.8 : 0.2;
                break;
                
              case 1: // Gradient pattern
                value = x / width;
                break;
                
              case 2: // Center blob pattern
                final centerX = width / 2;
                final centerY = height / 2;
                final distance = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));
                final maxDistance = math.sqrt(math.pow(width / 2, 2) + math.pow(height / 2, 2));
                value = 1.0 - (distance / maxDistance);
                break;
                
              case 3: // Checkerboard pattern
                value = ((x ~/ 2 + y ~/ 2) % 2 == 0) ? 0.8 : 0.2;
                break;
                
              default: // Random noise pattern
                value = math.Random().nextDouble();
            }
            
            // Add some noise
            value = math.max(0.0, math.min(1.0, value + (math.Random().nextDouble() - 0.5) * 0.2));
            return value;
          }
        )
      );
      
      featureMaps.add({
        'channelIndex': c,
        'mapData': mapData,
        'maxValue': 1.0,
      });
    }
    
    return featureMaps;
  }
  
  /// Get model training progress visualization
  Future<Map<String, dynamic>> getTrainingProgressVisualization() async {
    if (_activeModelId == null) {
      return {'error': 'No active model set'};
    }
    
    // Check cache first
    final cacheKey = 'training_${_activeModelId}';
    if (_visualizationCache.containsKey(cacheKey)) {
      return _visualizationCache[cacheKey]!;
    }
    
    // Simulate requesting training data from Python backend
    try {
      final response = await _pythonBackend.processData(
        modelId: _activeModelId!,
        data: {'epochs': 20, 'batchSize': 32},
        operation: 'train'
      );
      
      // Generate training progress visualization (simulated)
      final trainingData = _generateTrainingProgress(20);
      
      // Add to cache
      _visualizationCache[cacheKey] = trainingData;
      
      return trainingData;
    } catch (e) {
      print('Error getting training progress: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Generate synthetic training progress data
  Map<String, dynamic> _generateTrainingProgress(int epochs) {
    final List<Map<String, dynamic>> epochData = [];
    
    double trainLoss = 0.8;
    double trainAcc = 0.7;
    double valLoss = 0.9;
    double valAcc = 0.65;
    double learningRate = 0.001;
    
    for (int i = 0; i < epochs; i++) {
      // Simulate improvements over epochs
      trainLoss *= 0.9;
      trainAcc += (1.0 - trainAcc) * 0.15;
      valLoss *= 0.92;
      valAcc += (1.0 - valAcc) * 0.1;
      
      // Add some randomness
      trainLoss += (math.Random().nextDouble() - 0.5) * 0.02;
      trainAcc += (math.Random().nextDouble() - 0.5) * 0.02;
      valLoss += (math.Random().nextDouble() - 0.5) * 0.03;
      valAcc += (math.Random().nextDouble() - 0.5) * 0.02;
      
      // Ensure values stay in reasonable range
      trainLoss = math.max(0.01, trainLoss);
      trainAcc = math.min(0.99, math.max(0.5, trainAcc));
      valLoss = math.max(0.02, valLoss);
      valAcc = math.min(0.98, math.max(0.45, valAcc));
      
      // Learning rate decay
      if (i > 0 && i % 5 == 0) {
        learningRate *= 0.5;
      }
      
      epochData.add({
        'epoch': i + 1,
        'trainLoss': trainLoss,
        'trainAccuracy': trainAcc,
        'valLoss': valLoss,
        'valAccuracy': valAcc,
        'learningRate': learningRate,
      });
    }
    
    return {
      'modelId': _activeModelId,
      'visualizationType': 'training_progress',
      'epochs': epochs,
      'epochData': epochData,
      'finalMetrics': {
        'trainLoss': trainLoss,
        'trainAccuracy': trainAcc,
        'valLoss': valLoss,
        'valAccuracy': valAcc,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get confusion matrix visualization
  Future<Map<String, dynamic>> getConfusionMatrixVisualization(int numClasses) async {
    if (_activeModelId == null) {
      return {'error': 'No active model set'};
    }
    
    // Check cache first
    final cacheKey = 'confusion_${_activeModelId}_$numClasses';
    if (_visualizationCache.containsKey(cacheKey)) {
      return _visualizationCache[cacheKey]!;
    }
    
    // Simulate requesting confusion matrix from Python backend
    try {
      final response = await _pythonBackend.processData(
        modelId: _activeModelId!,
        data: {'numClasses': numClasses},
        operation: 'analyze'
      );
      
      // Generate confusion matrix visualization (simulated)
      final confusionData = _generateConfusionMatrix(numClasses);
      
      // Add to cache
      _visualizationCache[cacheKey] = confusionData;
      
      return confusionData;
    } catch (e) {
      print('Error getting confusion matrix: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Generate synthetic confusion matrix data
  Map<String, dynamic> _generateConfusionMatrix(int numClasses) {
    final List<List<int>> matrix = List.generate(
      numClasses, 
      (i) => List.generate(numClasses, (j) {
        if (i == j) {
          // Diagonal elements (true positives)
          return 70 + math.Random().nextInt(30);
        } else if ((i - j).abs() == 1) {
          // Near-diagonal elements (common confusions)
          return 5 + math.Random().nextInt(15);
        } else {
          // Far-from-diagonal elements (rare confusions)
          return math.Random().nextInt(5);
        }
      })
    );
    
    // Calculate metrics
    int totalSamples = 0;
    int correctPredictions = 0;
    
    for (int i = 0; i < numClasses; i++) {
      for (int j = 0; j < numClasses; j++) {
        totalSamples += matrix[i][j];
        if (i == j) {
          correctPredictions += matrix[i][j];
        }
      }
    }
    
    // Calculate per-class metrics
    final List<Map<String, dynamic>> classMetrics = [];
    
    for (int i = 0; i < numClasses; i++) {
      int truePositives = matrix[i][i];
      int falseNegatives = 0;
      int falsePositives = 0;
      
      for (int j = 0; j < numClasses; j++) {
        if (j != i) {
          falseNegatives += matrix[i][j]; // Actually class i, predicted as j
          falsePositives += matrix[j][i]; // Actually class j, predicted as i
        }
      }
      
      int totalPredicted = truePositives + falsePositives;
      int totalActual = truePositives + falseNegatives;
      
      double precision = totalPredicted > 0 ? truePositives / totalPredicted : 0;
      double recall = totalActual > 0 ? truePositives / totalActual : 0;
      double f1Score = precision + recall > 0 ? 
          2 * precision * recall / (precision + recall) : 0;
      
      classMetrics.add({
        'class': i,
        'precision': precision,
        'recall': recall,
        'f1Score': f1Score,
        'support': totalActual,
      });
    }
    
    return {
      'modelId': _activeModelId,
      'visualizationType': 'confusion_matrix',
      'numClasses': numClasses,
      'matrix': matrix,
      'classLabels': List.generate(numClasses, (i) => 'Class $i'),
      'totalSamples': totalSamples,
      'accuracy': totalSamples > 0 ? correctPredictions / totalSamples : 0,
      'classMetrics': classMetrics,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Clear visualization cache
  void clearCache() {
    _visualizationCache.clear();
  }
  
  /// Render a heatmap visualization to a widget
  Widget renderHeatmap(List<List<double>> data, {
    Color startColor = const Color(0xFFFFFFFF),
    Color endColor = const Color(0xFF0000FF),
    double cellSize = 20.0,
    bool showValues = false,
  }) {
    if (data.isEmpty) return Container();
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: data.map((row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((value) {
              // Calculate color based on value (0.0 to 1.0)
              final color = Color.lerp(startColor, endColor, value)!;
              
              return Container(
                width: cellSize,
                height: cellSize,
                color: color,
                alignment: Alignment.center,
                child: showValues 
                    ? Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          color: value > 0.5 ? Colors.white : Colors.black,
                          fontSize: cellSize * 0.5,
                        ),
                      )
                    : null,
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

/// Visualization configuration for the advanced model visualizer
class VisualizationConfig {
  final String visualizationType;
  final Map<String, dynamic> parameters;
  
  const VisualizationConfig({
    required this.visualizationType,
    this.parameters = const {},
  });
  
  // Factory constructors for common visualizations
  factory VisualizationConfig.attentionMaps() => const VisualizationConfig(
    visualizationType: 'attention_maps',
  );
  
  factory VisualizationConfig.neuronActivations({required String layerName}) => 
    VisualizationConfig(
      visualizationType: 'neuron_activations',
      parameters: {'layerName': layerName},
    );
  
  factory VisualizationConfig.trainingProgress() => const VisualizationConfig(
    visualizationType: 'training_progress',
  );
  
  factory VisualizationConfig.confusionMatrix({int numClasses = 10}) => 
    VisualizationConfig(
      visualizationType: 'confusion_matrix',
      parameters: {'numClasses': numClasses},
    );
} 