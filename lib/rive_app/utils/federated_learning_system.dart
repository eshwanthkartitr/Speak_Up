import 'dart:math' as math;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// FederatedLearningSystem implements decentralized machine learning algorithms
/// that allow on-device model training without sharing raw user data.
/// This is ideal for privacy-preserving training of sign language models.
class FederatedLearningSystem {
  // Singleton pattern
  static final FederatedLearningSystem _instance = FederatedLearningSystem._internal();
  factory FederatedLearningSystem() => _instance;
  
  // Simulated federated nodes (clients)
  final List<FederatedClient> _federatedClients = [];
  
  // Global model parameters (weights and biases)
  final Map<String, List<List<double>>> _globalModelParameters = {};
  
  // Current training round
  int _currentRound = 0;
  
  // Aggregation algorithm (default: FedAvg)
  String _aggregationAlgorithm = 'FedAvg';
  
  // Security parameters
  final Map<String, dynamic> _securityParams = {
    'differentialPrivacyEnabled': true,
    'noiseScale': 0.05,
    'clipNorm': 5.0,
    'secureAggregationEnabled': true,
    'encryptionKeySize': 2048,
  };
  
  // System metrics
  final Map<String, dynamic> _systemMetrics = {
    'participatingClients': 0,
    'totalRounds': 0,
    'globalLoss': double.infinity,
    'globalAccuracy': 0.0,
    'communicationCost': 0.0,
    'lastUpdateTimestamp': 0,
    'averageClientComputeTimeMs': 0.0,
    'totalParameterSize': 0,
  };
  
  // Event streams
  final StreamController<Map<String, dynamic>> _trainingProgressController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Private constructor
  FederatedLearningSystem._internal() {
    _initializeSystem();
  }
  
  /// Initialize the federated learning system
  void _initializeSystem() {
    // Initialize global model parameters for a simplified Tamil sign recognition model
    _globalModelParameters['conv1'] = _generateRandomMatrix(32, 12); // Conv layer 1
    _globalModelParameters['conv2'] = _generateRandomMatrix(64, 32); // Conv layer 2
    _globalModelParameters['dense1'] = _generateRandomMatrix(128, 64); // Dense layer 1
    _globalModelParameters['output'] = _generateRandomMatrix(306, 128); // Output layer (Tamil signs)
    
    // Create simulated federated clients
    _createFederatedClients(20); // 20 simulated devices
    
    // Calculate total parameter size
    int totalParams = 0;
    _globalModelParameters.forEach((key, matrix) {
      totalParams += matrix.length * (matrix[0].length);
    });
    
    _systemMetrics['totalParameterSize'] = totalParams;
    
    print('Federated Learning System initialized with ${_federatedClients.length} clients');
    print('Global model has $totalParams parameters');
  }
  
  /// Generate a random matrix for model parameters
  List<List<double>> _generateRandomMatrix(int rows, int cols) {
    final matrix = List.generate(
      rows,
      (_) => List.generate(
        cols,
        (_) => (math.Random().nextDouble() * 2 - 1) * 0.1 // Initialize with small random values
      )
    );
    
    return matrix;
  }
  
  /// Create simulated federated clients
  void _createFederatedClients(int numClients) {
    for (int i = 0; i < numClients; i++) {
      final client = FederatedClient(
        clientId: 'client_$i',
        dataSize: 100 + math.Random().nextInt(400), // Random data size between 100-500
        computePower: 0.5 + math.Random().nextDouble() * 0.5, // Random compute power 0.5-1.0
        connectionQuality: 0.6 + math.Random().nextDouble() * 0.4, // Random connection quality 0.6-1.0
        isOnline: math.Random().nextDouble() > 0.2, // 80% chance to be online
      );
      
      _federatedClients.add(client);
    }
  }
  
  /// Start federated training process
  Future<Map<String, dynamic>> startFederatedTraining({
    int numRounds = 10,
    int minClientsPerRound = 5,
    String aggregationAlgorithm = 'FedAvg',
    Map<String, dynamic>? securityParams,
  }) async {
    try {
      // Update configuration
      _aggregationAlgorithm = aggregationAlgorithm;
      if (securityParams != null) {
        _securityParams.addAll(securityParams);
      }
      
      // Reset training metrics
      _currentRound = 0;
      _systemMetrics['globalLoss'] = double.infinity;
      _systemMetrics['globalAccuracy'] = 0.0;
      _systemMetrics['communicationCost'] = 0.0;
      _systemMetrics['totalRounds'] = numRounds;
      
      print('Starting federated training with $aggregationAlgorithm aggregation');
      print('Training will run for $numRounds rounds with minimum $minClientsPerRound clients per round');
      
      final startTime = DateTime.now();
      
      // Run training rounds
      for (int round = 0; round < numRounds; round++) {
        _currentRound = round + 1;
        
        // Select clients for this round based on availability and strategy
        final selectedClients = _selectClientsForRound(minClientsPerRound);
        
        if (selectedClients.isEmpty) {
          print('Warning: No clients available for round $_currentRound');
          continue;
        }
        
        _systemMetrics['participatingClients'] = selectedClients.length;
        
        // Distribute global model to selected clients
        await _distributeGlobalModel(selectedClients);
        
        // Clients perform local training (in parallel)
        final localUpdateResults = await _performDistributedLocalTraining(selectedClients);
        
        // Apply differential privacy if enabled
        if (_securityParams['differentialPrivacyEnabled']) {
          _applyDifferentialPrivacy(localUpdateResults);
        }
        
        // Aggregate model updates
        final aggregationResult = _aggregateModelUpdates(
            localUpdateResults, selectedClients);
        
        // Update global model
        _updateGlobalModel(aggregationResult['aggregatedUpdates']);
        
        // Update system metrics
        _systemMetrics['globalLoss'] = aggregationResult['globalLoss'];
        _systemMetrics['globalAccuracy'] = aggregationResult['globalAccuracy'];
        _systemMetrics['communicationCost'] += aggregationResult['roundCommunicationCost'];
        _systemMetrics['lastUpdateTimestamp'] = DateTime.now().millisecondsSinceEpoch;
        
        // Calculate average client compute time
        final totalComputeTime = localUpdateResults.fold<double>(
            0, (sum, result) => sum + (result['computeTimeMs'] as double));
        _systemMetrics['averageClientComputeTimeMs'] = 
            totalComputeTime / localUpdateResults.length;
        
        // Emit progress event
        _trainingProgressController.add({
          'round': _currentRound,
          'totalRounds': numRounds,
          'globalLoss': _systemMetrics['globalLoss'],
          'globalAccuracy': _systemMetrics['globalAccuracy'],
          'participatingClients': selectedClients.length,
          'timeElapsedMs': DateTime.now().difference(startTime).inMilliseconds,
        });
        
        // Simulate delay between rounds
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      // Training completed
      final trainingTime = DateTime.now().difference(startTime).inMilliseconds;
      final results = {
        'status': 'completed',
        'totalRounds': numRounds,
        'finalLoss': _systemMetrics['globalLoss'],
        'finalAccuracy': _systemMetrics['globalAccuracy'],
        'trainingTimeMs': trainingTime,
        'communicationCost': _systemMetrics['communicationCost'],
        'algorithm': _aggregationAlgorithm,
        'averageClientsPerRound': _systemMetrics['participatingClients'],
      };
      
      print('Federated training completed in ${trainingTime}ms');
      print('Final model accuracy: ${_systemMetrics['globalAccuracy']}');
      
      return results;
    } catch (e) {
      print('Error in federated training: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
        'completedRounds': _currentRound,
      };
    }
  }
  
  /// Select clients for the current training round
  List<FederatedClient> _selectClientsForRound(int minClients) {
    // Filter clients that are online
    final availableClients = _federatedClients
        .where((client) => client.isOnline)
        .toList();
    
    if (availableClients.length <= minClients) {
      return availableClients;
    }
    
    // Different client selection strategies
    switch (_aggregationAlgorithm) {
      case 'FedProx':
      case 'SCAFFOLD':
        // Prioritize clients with better connection quality for these algorithms
        availableClients.sort((a, b) => 
            b.connectionQuality.compareTo(a.connectionQuality));
        return availableClients.take(minClients).toList();
        
      case 'FedAvg':
      default:
        // Random selection for FedAvg
        availableClients.shuffle();
        return availableClients.take(minClients).toList();
    }
  }
  
  /// Distribute global model to selected clients
  Future<void> _distributeGlobalModel(List<FederatedClient> clients) async {
    // In a real system, this would send model weights to actual devices
    // Here we just update our simulated clients
    
    for (final client in clients) {
      // Copy global model parameters to client
      client.receiveGlobalModel(Map.from(_globalModelParameters));
      
      // Simulate network delay based on connection quality
      final delay = (100 * (1.0 / client.connectionQuality)).round();
      await Future.delayed(Duration(milliseconds: delay));
    }
  }
  
  /// Perform distributed local training on all selected clients
  Future<List<Map<String, dynamic>>> _performDistributedLocalTraining(
      List<FederatedClient> clients) async {
    // Use compute isolates to simulate parallel training on multiple devices
    final futures = clients.map((client) {
      return compute(_simulateLocalTraining, {
        'clientId': client.clientId,
        'dataSize': client.dataSize,
        'computePower': client.computePower,
        'localEpochs': 5,
        'batchSize': 16,
        'learningRate': 0.01,
      });
    }).toList();
    
    // Wait for all clients to complete local training
    return await Future.wait(futures);
  }
  
  /// Apply differential privacy to model updates
  void _applyDifferentialPrivacy(List<Map<String, dynamic>> clientUpdates) {
    final noiseScale = _securityParams['noiseScale'];
    final clipNorm = _securityParams['clipNorm'];
    
    for (final update in clientUpdates) {
      final modelDelta = update['modelDelta'] as Map<String, List<List<double>>>;
      
      // Apply gradient clipping (bound sensitivity)
      _clipGradients(modelDelta, clipNorm);
      
      // Add calibrated Gaussian noise
      _addGaussianNoise(modelDelta, noiseScale);
    }
  }
  
  /// Clip gradients to bound sensitivity
  void _clipGradients(Map<String, List<List<double>>> modelDelta, double clipNorm) {
    // Calculate the Frobenius norm of the gradient
    double squaredSum = 0.0;
    
    modelDelta.forEach((layerName, matrix) {
      for (final row in matrix) {
        for (final value in row) {
          squaredSum += value * value;
        }
      }
    });
    
    final gradientNorm = math.sqrt(squaredSum);
    
    // Apply clipping if norm exceeds threshold
    if (gradientNorm > clipNorm) {
      final scalingFactor = clipNorm / gradientNorm;
      
      modelDelta.forEach((layerName, matrix) {
        for (int i = 0; i < matrix.length; i++) {
          for (int j = 0; j < matrix[i].length; j++) {
            matrix[i][j] *= scalingFactor;
          }
        }
      });
    }
  }
  
  /// Add calibrated Gaussian noise for differential privacy
  void _addGaussianNoise(Map<String, List<List<double>>> modelDelta, double noiseScale) {
    final random = math.Random();
    
    // Box-Muller transform to generate Gaussian noise
    double generateGaussian() {
      final u1 = 1.0 - random.nextDouble(); // Uniform(0,1)
      final u2 = 1.0 - random.nextDouble();
      final radius = math.sqrt(-2.0 * math.log(u1));
      final theta = 2.0 * math.pi * u2;
      return radius * math.cos(theta);
    }
    
    modelDelta.forEach((layerName, matrix) {
      for (int i = 0; i < matrix.length; i++) {
        for (int j = 0; j < matrix[i].length; j++) {
          // Add calibrated noise
          matrix[i][j] += generateGaussian() * noiseScale;
        }
      }
    });
  }
  
  /// Aggregate model updates from clients
  Map<String, dynamic> _aggregateModelUpdates(
      List<Map<String, dynamic>> clientUpdates,
      List<FederatedClient> clients) {
    
    // Different aggregation algorithms
    Map<String, List<List<double>>> aggregatedUpdates;
    
    switch (_aggregationAlgorithm) {
      case 'FedProx':
        // FedProx: Adds proximal term to client objective
        aggregatedUpdates = _fedProxAggregation(clientUpdates, clients);
        break;
        
      case 'SCAFFOLD':
        // SCAFFOLD: Uses control variates to correct drift
        aggregatedUpdates = _scaffoldAggregation(clientUpdates, clients);
        break;
        
      case 'FedAvg':
      default:
        // Federated Averaging (McMahan et al.)
        aggregatedUpdates = _fedAvgAggregation(clientUpdates, clients);
    }
    
    // Calculate global metrics based on aggregated updates
    final globalLoss = _calculateGlobalLoss(aggregatedUpdates);
    final globalAccuracy = _calculateGlobalAccuracy(aggregatedUpdates);
    
    // Calculate communication cost (proportional to model size and clients)
    final roundCommunicationCost = _systemMetrics['totalParameterSize'] * 
        clientUpdates.length * 4.0 / (1024 * 1024); // in MB
    
    return {
      'aggregatedUpdates': aggregatedUpdates,
      'globalLoss': globalLoss,
      'globalAccuracy': globalAccuracy,
      'roundCommunicationCost': roundCommunicationCost,
    };
  }
  
  /// Federated Averaging aggregation (FedAvg)
  Map<String, List<List<double>>> _fedAvgAggregation(
      List<Map<String, dynamic>> clientUpdates,
      List<FederatedClient> clients) {
    
    // Calculate total data size for weighted averaging
    final totalDataSize = clients.fold<int>(
        0, (sum, client) => sum + client.dataSize);
    
    // Initialize aggregated updates with zeros
    final aggregatedUpdates = <String, List<List<double>>>{};
    
    // Initialize with zeros using first client's update structure
    final firstUpdate = clientUpdates.first['modelDelta'] as Map<String, List<List<double>>>;
    firstUpdate.forEach((layerName, matrix) {
      aggregatedUpdates[layerName] = List.generate(
        matrix.length,
        (i) => List.filled(matrix[i].length, 0.0)
      );
    });
    
    // Perform weighted averaging
    for (int c = 0; c < clientUpdates.length; c++) {
      final update = clientUpdates[c]['modelDelta'] as Map<String, List<List<double>>>;
      final client = clients[c];
      final weight = client.dataSize / totalDataSize;
      
      update.forEach((layerName, matrix) {
        for (int i = 0; i < matrix.length; i++) {
          for (int j = 0; j < matrix[i].length; j++) {
            aggregatedUpdates[layerName]![i][j] += matrix[i][j] * weight;
          }
        }
      });
    }
    
    return aggregatedUpdates;
  }
  
  /// FedProx aggregation with proximal term
  Map<String, List<List<double>>> _fedProxAggregation(
      List<Map<String, dynamic>> clientUpdates,
      List<FederatedClient> clients) {
    
    // FedProx is similar to FedAvg but with a proximal term to limit client drift
    // Here we simulate this by reducing the effective learning rate for stragglers
    
    // Calculate total data size for weighted averaging
    final totalDataSize = clients.fold<int>(
        0, (sum, client) => sum + client.dataSize);
    
    // Initialize aggregated updates with zeros
    final aggregatedUpdates = <String, List<List<double>>>{};
    
    // Initialize with zeros using first client's update structure
    final firstUpdate = clientUpdates.first['modelDelta'] as Map<String, List<List<double>>>;
    firstUpdate.forEach((layerName, matrix) {
      aggregatedUpdates[layerName] = List.generate(
        matrix.length,
        (i) => List.filled(matrix[i].length, 0.0)
      );
    });
    
    // Proximal term constant (μ in FedProx paper)
    const double proximityConstant = 0.01;
    
    // Perform weighted averaging with proximal term
    for (int c = 0; c < clientUpdates.length; c++) {
      final update = clientUpdates[c]['modelDelta'] as Map<String, List<List<double>>>;
      final client = clients[c];
      final weight = client.dataSize / totalDataSize;
      
      // Calculate proxy for heterogeneity (lower compute power = more heterogeneous)
      final heterogeneityFactor = 1.0 - client.computePower;
      
      update.forEach((layerName, matrix) {
        for (int i = 0; i < matrix.length; i++) {
          for (int j = 0; j < matrix[i].length; j++) {
            // Apply proximal term effect (smaller updates for stragglers)
            final proximalFactor = 1.0 / (1.0 + proximityConstant * heterogeneityFactor);
            aggregatedUpdates[layerName]![i][j] += matrix[i][j] * weight * proximalFactor;
          }
        }
      });
    }
    
    return aggregatedUpdates;
  }
  
  /// SCAFFOLD aggregation with control variates
  Map<String, List<List<double>>> _scaffoldAggregation(
      List<Map<String, dynamic>> clientUpdates,
      List<FederatedClient> clients) {
    
    // SCAFFOLD uses control variates to correct for client drift
    // Here we simulate this effect without implementing the full algorithm
    
    // Start with standard FedAvg
    final aggregatedUpdates = _fedAvgAggregation(clientUpdates, clients);
    
    // Simulate control variate correction for server drift
    // In a real implementation, each client would maintain its own control variate
    
    // Drift correction factor (typically decreases over rounds)
    final driftCorrection = math.max(0.1, 1.0 - (_currentRound / 20.0));
    
    // Apply correction
    aggregatedUpdates.forEach((layerName, matrix) {
      for (int i = 0; i < matrix.length; i++) {
        for (int j = 0; j < matrix[i].length; j++) {
          // Scale update to correct for drift
          matrix[i][j] *= driftCorrection;
        }
      }
    });
    
    return aggregatedUpdates;
  }
  
  /// Update global model with aggregated updates
  void _updateGlobalModel(Map<String, List<List<double>>> aggregatedUpdates) {
    // Update each layer of the global model
    aggregatedUpdates.forEach((layerName, updateMatrix) {
      final globalMatrix = _globalModelParameters[layerName]!;
      
      for (int i = 0; i < globalMatrix.length; i++) {
        for (int j = 0; j < globalMatrix[i].length; j++) {
          // Apply the update to the global model
          globalMatrix[i][j] += updateMatrix[i][j];
        }
      }
    });
  }
  
  /// Calculate global loss based on aggregated updates
  double _calculateGlobalLoss(Map<String, List<List<double>>> aggregatedUpdates) {
    // In a real system, this would evaluate the model on a validation dataset
    // Here we simulate decreasing loss over training rounds
    
    // Start high and decrease with some random fluctuations
    final baseLoss = 2.0 * math.exp(-0.2 * _currentRound);
    final randomFactor = 1.0 + ((math.Random().nextDouble() - 0.5) * 0.2);
    
    return baseLoss * randomFactor;
  }
  
  /// Calculate global accuracy based on aggregated updates
  double _calculateGlobalAccuracy(Map<String, List<List<double>>> aggregatedUpdates) {
    // In a real system, this would evaluate the model on a validation dataset
    // Here we simulate increasing accuracy with diminishing returns
    
    // Start low and increase with diminishing returns
    final baseAccuracy = 0.5 * (1.0 - math.exp(-0.3 * _currentRound));
    final randomFactor = 1.0 + ((math.Random().nextDouble() - 0.5) * 0.05);
    
    // Cap at 95% to simulate real-world limitations
    return math.min(0.95, (0.4 + baseAccuracy) * randomFactor);
  }
  
  /// Get current training progress as a stream
  Stream<Map<String, dynamic>> get trainingProgress => _trainingProgressController.stream;
  
  /// Get the current state of the global model
  Map<String, List<List<double>>> getGlobalModel() {
    // Deep copy to avoid external modification
    final modelCopy = <String, List<List<double>>>{};
    
    _globalModelParameters.forEach((key, matrix) {
      modelCopy[key] = List.generate(
        matrix.length,
        (i) => List.from(matrix[i])
      );
    });
    
    return modelCopy;
  }
  
  /// Get system metrics
  Map<String, dynamic> getSystemMetrics() {
    return Map.from(_systemMetrics);
  }
  
  /// Get active clients
  List<Map<String, dynamic>> getActiveClients() {
    return _federatedClients
      .where((client) => client.isOnline)
      .map((client) => client.toJson())
      .toList();
  }
  
  /// Dispose resources
  void dispose() {
    _trainingProgressController.close();
  }
  
  /// Static method to simulate local training (to be run in isolate)
  static Map<String, dynamic> _simulateLocalTraining(Map<String, dynamic> params) {
    final String clientId = params['clientId'];
    final int dataSize = params['dataSize'];
    final double computePower = params['computePower'];
    final int localEpochs = params['localEpochs'];
    final int batchSize = params['batchSize'];
    final double learningRate = params['learningRate'];
    
    // Simulate training time based on data size and compute power
    final baseTimeMs = (dataSize * localEpochs ~/ batchSize) * (1.0 / computePower);
    
    // Add random variation
    final actualTimeMs = baseTimeMs * (0.9 + math.Random().nextDouble() * 0.2);
    
    // Simulate model update (deltas)
    final modelDelta = <String, List<List<double>>>{
      'conv1': _simulateLayerUpdate(32, 12),
      'conv2': _simulateLayerUpdate(64, 32),
      'dense1': _simulateLayerUpdate(128, 64),
      'output': _simulateLayerUpdate(306, 128),
    };
    
    // Simulate local metrics
    final localLoss = 0.5 + math.Random().nextDouble() * 0.5;
    final localAccuracy = 0.6 + math.Random().nextDouble() * 0.3;
    
    return {
      'clientId': clientId,
      'modelDelta': modelDelta,
      'localLoss': localLoss,
      'localAccuracy': localAccuracy,
      'samplesProcessed': dataSize,
      'computeTimeMs': actualTimeMs,
      'localEpochs': localEpochs,
    };
  }
  
  /// Static helper to simulate layer update
  static List<List<double>> _simulateLayerUpdate(int rows, int cols) {
    return List.generate(
      rows,
      (_) => List.generate(
        cols,
        (_) => (math.Random().nextDouble() * 2 - 1) * 0.01
      )
    );
  }
}

/// FederatedClient represents a device participating in federated learning
class FederatedClient {
  final String clientId;
  final int dataSize;
  final double computePower;
  final double connectionQuality;
  bool isOnline;
  
  // Local model parameters
  Map<String, List<List<double>>>? _localModelParameters;
  
  // Client metrics
  final Map<String, dynamic> _metrics = {
    'trainingRoundsParticipated': 0,
    'totalComputeTimeMs': 0.0,
    'lastUpdateTimestamp': 0,
    'lastLocalLoss': double.infinity,
    'lastLocalAccuracy': 0.0,
    'batteryLevel': 0.0,
  };
  
  FederatedClient({
    required this.clientId,
    required this.dataSize,
    required this.computePower,
    required this.connectionQuality,
    this.isOnline = true,
  }) {
    // Initialize client metrics
    _metrics['batteryLevel'] = 0.7 + math.Random().nextDouble() * 0.3;
  }
  
  /// Receive global model for local training
  void receiveGlobalModel(Map<String, List<List<double>>> globalModel) {
    // Deep copy the global model for local update
    _localModelParameters = <String, List<List<double>>>{};
    
    globalModel.forEach((key, matrix) {
      _localModelParameters![key] = List.generate(
        matrix.length,
        (i) => List.from(matrix[i])
      );
    });
    
    // Update metrics
    _metrics['lastUpdateTimestamp'] = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Convert client to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'dataSize': dataSize,
      'computePower': computePower,
      'connectionQuality': connectionQuality,
      'isOnline': isOnline,
      'metrics': Map.from(_metrics),
    };
  }
} 