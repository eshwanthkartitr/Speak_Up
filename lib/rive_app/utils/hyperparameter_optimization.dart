import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';

/// HyperparameterOptimization implements Bayesian optimization techniques
/// to automatically find optimal neural network configurations for
/// Tamil sign language recognition models.
class HyperparameterOptimization {
  // Singleton pattern
  static final HyperparameterOptimization _instance = HyperparameterOptimization._internal();
  factory HyperparameterOptimization() => _instance;
  
  // Hyperparameter search space
  final Map<String, Map<String, dynamic>> _searchSpace = {
    'learningRate': {
      'type': 'continuous',
      'lower': 0.0001,
      'upper': 0.1,
      'log': true,
    },
    'batchSize': {
      'type': 'discrete',
      'values': [8, 16, 32, 64, 128],
    },
    'numLayers': {
      'type': 'integer',
      'lower': 2,
      'upper': 6,
    },
    'hiddenUnits': {
      'type': 'integer',
      'lower': 32,
      'upper': 512,
      'log': true,
    },
    'dropoutRate': {
      'type': 'continuous',
      'lower': 0.0,
      'upper': 0.5,
    },
    'l2Regularization': {
      'type': 'continuous',
      'lower': 0.00001,
      'upper': 0.01,
      'log': true,
    },
    'optimizerType': {
      'type': 'categorical',
      'values': ['adam', 'sgd', 'rmsprop', 'adagrad'],
    },
    'activationFunction': {
      'type': 'categorical',
      'values': ['relu', 'leaky_relu', 'swish', 'mish'],
    },
  };
  
  // Optimization history
  final List<Map<String, dynamic>> _optimizationHistory = [];
  
  // Current best configuration
  Map<String, dynamic>? _bestConfiguration;
  double _bestScore = -double.infinity;
  
  // Gaussian Process model parameters (for Bayesian optimization)
  final Map<String, dynamic> _gpModel = {
    'lengthScales': <String, double>{},
    'signalVariance': 1.0,
    'noiseVariance': 0.1,
    'trainingInputs': <List<double>>[],
    'trainingOutputs': <double>[],
  };
  
  // Optimization settings
  final Map<String, dynamic> _optimizationSettings = {
    'maxTrials': 50,
    'numInitialPoints': 10,
    'explorationFactor': 0.1,
    'maxParallelTrials': 3,
    'acquisitionFunction': 'ei', // Expected Improvement
    'randomSeed': 42,
  };
  
  // Search progress
  int _completedTrials = 0;
  bool _isOptimizing = false;
  
  // Event stream
  final StreamController<Map<String, dynamic>> _optimizationProgressController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Constructor
  HyperparameterOptimization._internal() {
    _initializeGPModel();
  }
  
  /// Initialize Gaussian Process model parameters
  void _initializeGPModel() {
    // Initialize length scales for each hyperparameter
    _searchSpace.forEach((hyperparam, config) {
      if (config['type'] == 'categorical') {
        _gpModel['lengthScales'][hyperparam] = 1.0;
      } else if (config['log'] == true) {
        _gpModel['lengthScales'][hyperparam] = 0.5;
      } else {
        _gpModel['lengthScales'][hyperparam] = 0.2;
      }
    });
  }
  
  /// Start hyperparameter optimization
  Future<Map<String, dynamic>> optimizeHyperparameters({
    required Future<double> Function(Map<String, dynamic>) evaluationFunction,
    int? maxTrials,
    int? maxParallelTrials,
    String? acquisitionFunction,
    double? explorationFactor,
  }) async {
    if (_isOptimizing) {
      return {'error': 'Optimization already in progress'};
    }
    
    try {
      _isOptimizing = true;
      _completedTrials = 0;
      
      // Update settings if provided
      if (maxTrials != null) _optimizationSettings['maxTrials'] = maxTrials;
      if (maxParallelTrials != null) _optimizationSettings['maxParallelTrials'] = maxParallelTrials;
      if (acquisitionFunction != null) _optimizationSettings['acquisitionFunction'] = acquisitionFunction;
      if (explorationFactor != null) _optimizationSettings['explorationFactor'] = explorationFactor;
      
      print('Starting hyperparameter optimization with ${_optimizationSettings['maxTrials']} trials');
      print('Using ${_optimizationSettings['acquisitionFunction']} acquisition function');
      
      // Initial random points
      final numInitialPoints = _optimizationSettings['numInitialPoints'];
      print('Generating $numInitialPoints initial random points');
      
      // Generate initial random configurations
      for (int i = 0; i < numInitialPoints; i++) {
        final configuration = _sampleRandomConfiguration();
        
        // Evaluate configuration
        final score = await evaluationFunction(configuration);
        
        // Store result
        _recordResult(configuration, score);
        
        // Update progress
        _completedTrials++;
        _optimizationProgressController.add({
          'trial': _completedTrials,
          'maxTrials': _optimizationSettings['maxTrials'],
          'configuration': configuration,
          'score': score,
          'bestScore': _bestScore,
          'bestConfiguration': _bestConfiguration,
          'phase': 'initialization',
        });
      }
      
      // Bayesian optimization phase
      print('Starting Bayesian optimization phase');
      
      while (_completedTrials < _optimizationSettings['maxTrials']) {
        // Determine how many configurations to run in parallel
        final remainingTrials = _optimizationSettings['maxTrials'] - _completedTrials;
        final numParallel = math.min<int>(
            remainingTrials, 
            _optimizationSettings['maxParallelTrials']
        );
        
        // Generate batch of configurations using Bayesian optimization
        final configurations = <Map<String, dynamic>>[];
        for (int i = 0; i < numParallel; i++) {
          final config = _sampleNextConfigurationBO();
          configurations.add(config);
        }
        
        // Evaluate configurations in parallel
        final futures = configurations.map((config) async {
          final score = await evaluationFunction(config);
          return {'configuration': config, 'score': score};
        }).toList();
        
        final results = await Future.wait(futures);
        
        // Process results
        for (final result in results) {
          final configuration = result['configuration'] as Map<String, dynamic>;
          final score = result['score'] as double;
          
          // Store result
          _recordResult(configuration, score);
          
          // Update progress
          _completedTrials++;
          _optimizationProgressController.add({
            'trial': _completedTrials,
            'maxTrials': _optimizationSettings['maxTrials'],
            'configuration': configuration,
            'score': score,
            'bestScore': _bestScore,
            'bestConfiguration': _bestConfiguration,
            'phase': 'bayesian_optimization',
          });
        }
      }
      
      // Optimization complete
      print('Hyperparameter optimization complete');
      print('Best configuration: $_bestConfiguration');
      print('Best score: $_bestScore');
      
      _isOptimizing = false;
      
      return {
        'status': 'completed',
        'bestConfiguration': Map.from(_bestConfiguration!),
        'bestScore': _bestScore,
        'numTrials': _completedTrials,
        'history': List.from(_optimizationHistory),
      };
      
    } catch (e) {
      print('Error during hyperparameter optimization: $e');
      _isOptimizing = false;
      
      return {
        'status': 'failed',
        'error': e.toString(),
        'bestConfiguration': _bestConfiguration != null ? Map.from(_bestConfiguration!) : null,
        'bestScore': _bestScore != double.negativeInfinity ? _bestScore : null,
        'completedTrials': _completedTrials,
      };
    }
  }
  
  /// Sample a random configuration from the search space
  Map<String, dynamic> _sampleRandomConfiguration() {
    final random = math.Random(_optimizationSettings['randomSeed'] + _completedTrials);
    final configuration = <String, dynamic>{};
    
    _searchSpace.forEach((param, config) {
      switch (config['type']) {
        case 'continuous':
          double value;
          if (config['log'] == true) {
            // Sample on log scale
            final logLower = math.log(config['lower']);
            final logUpper = math.log(config['upper']);
            final logValue = logLower + random.nextDouble() * (logUpper - logLower);
            value = math.exp(logValue);
          } else {
            // Linear scale
            value = config['lower'] + random.nextDouble() * (config['upper'] - config['lower']);
          }
          configuration[param] = value;
          break;
          
        case 'integer':
          int value;
          if (config['log'] == true) {
            // Sample on log scale
            final logLower = math.log(config['lower'].toDouble());
            final logUpper = math.log(config['upper'].toDouble());
            final logValue = logLower + random.nextDouble() * (logUpper - logLower);
            value = math.exp(logValue).round();
            // Ensure value is in range
            value = math.max(config['lower'], math.min(config['upper'], value));
          } else {
            // Linear scale
            value = config['lower'] + random.nextInt(config['upper'] - config['lower'] + 1);
          }
          configuration[param] = value;
          break;
          
        case 'discrete':
          final values = config['values'] as List;
          final index = random.nextInt(values.length);
          configuration[param] = values[index];
          break;
          
        case 'categorical':
          final values = config['values'] as List;
          final index = random.nextInt(values.length);
          configuration[param] = values[index];
          break;
      }
    });
    
    return configuration;
  }
  
  /// Sample next configuration using Bayesian Optimization
  Map<String, dynamic> _sampleNextConfigurationBO() {
    // If we don't have enough data points for GP, use random sampling
    if (_gpModel['trainingInputs'].length < 2) {
      return _sampleRandomConfiguration();
    }
    
    // Generate candidate configurations
    final int numCandidates = 1000;
    final candidates = List<Map<String, dynamic>>.generate(
        numCandidates, (_) => _sampleRandomConfiguration());
    
    // Convert configurations to numerical feature vectors
    final candidateFeatures = candidates.map((c) => _configToFeatures(c)).toList();
    
    // Calculate acquisition function value for each candidate
    final acquisitionValues = <double>[];
    for (final features in candidateFeatures) {
      final acqValue = _calculateAcquisitionValue(features);
      acquisitionValues.add(acqValue);
    }
    
    // Find candidate with highest acquisition value
    int bestIndex = 0;
    double bestAcqValue = acquisitionValues[0];
    
    for (int i = 1; i < acquisitionValues.length; i++) {
      if (acquisitionValues[i] > bestAcqValue) {
        bestAcqValue = acquisitionValues[i];
        bestIndex = i;
      }
    }
    
    return candidates[bestIndex];
  }
  
  /// Calculate acquisition function value
  double _calculateAcquisitionValue(List<double> features) {
    final gpPrediction = _predictGP(features);
    final mean = gpPrediction['mean'] ?? 0.0;
    final stdDev = math.sqrt(gpPrediction['variance'] ?? 0.0);
    
    // Different acquisition functions
    switch (_optimizationSettings['acquisitionFunction']) {
      case 'ucb': // Upper Confidence Bound
        final kappa = _optimizationSettings['explorationFactor'];
        return mean + kappa * stdDev;
        
      case 'pi': // Probability of Improvement
        if (stdDev < 1e-6) return mean > _bestScore ? 1.0 : 0.0;
        final z = (mean - _bestScore) / stdDev;
        return _normalCDF(z);
        
      case 'ei': // Expected Improvement
      default:
        if (stdDev < 1e-6) return mean > _bestScore ? (mean - _bestScore) : 0.0;
        final z = (mean - _bestScore) / stdDev;
        final cdf = _normalCDF(z);
        final pdf = _normalPDF(z);
        return stdDev * (z * cdf + pdf);
    }
  }
  
  /// Predict mean and variance using Gaussian Process
  Map<String, double> _predictGP(List<double> features) {
    if (_gpModel['trainingInputs'].isEmpty) {
      return {'mean': 0.0, 'variance': 1.0};
    }
    
    // Calculate kernel matrix K
    final n = _gpModel['trainingInputs'].length;
    final List<List<double>> K = List.generate(
        n, (_) => List<double>.filled(n, 0.0));
    
    for (int i = 0; i < n; i++) {
      for (int j = i; j < n; j++) {
        final kValue = _rbfKernel(_gpModel['trainingInputs'][i], _gpModel['trainingInputs'][j]);
        K[i][j] = kValue;
        K[j][i] = kValue; // Symmetric
      }
      // Add noise to diagonal
      K[i][i] += _gpModel['noiseVariance'];
    }
    
    // Calculate k* (kernel values between test point and training points)
    final List<double> kStar = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      kStar[i] = _rbfKernel(features, _gpModel['trainingInputs'][i]);
    }
    
    // Calculate k** (kernel value of test point with itself)
    final kStarStar = _rbfKernel(features, features) + _gpModel['noiseVariance'];
    
    // Solve K⁻¹ * y using Cholesky decomposition (simulated)
    // In a real implementation, we would use proper linear algebra libraries
    final List<double> alpha = _solveLinearSystem(K, _gpModel['trainingOutputs']);
    
    // Calculate mean: k*ᵀ * K⁻¹ * y = k*ᵀ * alpha
    double mean = 0.0;
    for (int i = 0; i < n; i++) {
      mean += kStar[i] * alpha[i];
    }
    
    // Simplified variance calculation (full version would compute k*ᵀ * K⁻¹ * k*)
    // Here we approximate as k** - weighted sum of k*
    double varianceReduction = 0.0;
    for (int i = 0; i < n; i++) {
      varianceReduction += kStar[i] * kStar[i] / K[i][i];
    }
    
    final variance = math.max(0.0, kStarStar - varianceReduction);
    
    return {'mean': mean, 'variance': variance};
  }
  
  /// RBF kernel function for Gaussian Process
  double _rbfKernel(List<double> x1, List<double> x2) {
    if (x1.length != x2.length) {
      throw Exception('Vectors must have same dimension in kernel calculation');
    }
    
    double sum = 0.0;
    
    // Calculate weighted squared distance
    for (int i = 0; i < x1.length; i++) {
      final diff = x1[i] - x2[i];
      final lengthScale = _gpModel['lengthScales'][_featureIndexToParam(i)] ?? 1.0;
      sum += (diff * diff) / (lengthScale * lengthScale);
    }
    
    // RBF kernel: k(x,y) = σ² * exp(-1/2 * (x-y)ᵀL⁻²(x-y))
    return _gpModel['signalVariance'] * math.exp(-0.5 * sum);
  }
  
  /// Map feature index back to parameter name
  String _featureIndexToParam(int index) {
    final params = _searchSpace.keys.toList();
    return params[index % params.length];
  }
  
  /// Solve linear system K*alpha = y (simplified implementation)
  List<double> _solveLinearSystem(List<List<double>> K, List<double> y) {
    // This is a very simplified solver - in production code use a proper linear algebra library
    final n = y.length;
    final List<double> alpha = List<double>.filled(n, 0.0);
    
    // Simple approximation: diagonal dominance assumption
    for (int i = 0; i < n; i++) {
      alpha[i] = y[i] / K[i][i];
    }
    
    // Refine with a few Jacobi iterations
    for (int iter = 0; iter < 5; iter++) {
      final List<double> newAlpha = List<double>.filled(n, 0.0);
      
      for (int i = 0; i < n; i++) {
        double sum = y[i];
        for (int j = 0; j < n; j++) {
          if (i != j) {
            sum -= K[i][j] * alpha[j];
          }
        }
        newAlpha[i] = sum / K[i][i];
      }
      
      alpha.setAll(0, newAlpha);
    }
    
    return alpha;
  }
  
  /// Standard normal CDF approximation
  double _normalCDF(double x) {
    // Approximation of the standard normal CDF
    const double a1 = 0.254829592;
    const double a2 = -0.284496736;
    const double a3 = 1.421413741;
    const double a4 = -1.453152027;
    const double a5 = 1.061405429;
    const double p = 0.3275911;
    
    // Save the sign
    final sign = x < 0 ? -1 : 1;
    final absX = x.abs();
    
    // A&S formula 7.1.26
    final t = 1.0 / (1.0 + p * absX);
    final y = 1.0 - ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * math.exp(-absX * absX);
    
    return 0.5 * (1.0 + sign * y);
  }
  
  /// Standard normal PDF
  double _normalPDF(double x) {
    return math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi);
  }
  
  /// Convert configuration to feature vector
  List<double> _configToFeatures(Map<String, dynamic> config) {
    final features = <double>[];
    
    _searchSpace.forEach((param, paramConfig) {
      if (!config.containsKey(param)) return;
      
      final value = config[param];
      
      switch (paramConfig['type']) {
        case 'continuous':
          double normalizedValue;
          if (paramConfig['log'] == true) {
            // Normalize on log scale
            final logLower = math.log(paramConfig['lower']);
            final logUpper = math.log(paramConfig['upper']);
            final logValue = math.log(value);
            normalizedValue = (logValue - logLower) / (logUpper - logLower);
          } else {
            // Linear normalization
            normalizedValue = (value - paramConfig['lower']) / 
                (paramConfig['upper'] - paramConfig['lower']);
          }
          features.add(normalizedValue);
          break;
          
        case 'integer':
          double normalizedValue;
          if (paramConfig['log'] == true) {
            // Normalize on log scale
            final logLower = math.log(paramConfig['lower'].toDouble());
            final logUpper = math.log(paramConfig['upper'].toDouble());
            final logValue = math.log(value.toDouble());
            normalizedValue = (logValue - logLower) / (logUpper - logLower);
          } else {
            // Linear normalization
            normalizedValue = (value - paramConfig['lower']) / 
                (paramConfig['upper'] - paramConfig['lower']);
          }
          features.add(normalizedValue);
          break;
          
        case 'discrete':
          final index = (paramConfig['values'] as List).indexOf(value);
          features.add(index / (paramConfig['values'] as List).length);
          break;
          
        case 'categorical':
          // One-hot encoding
          final List<String> categories = (paramConfig['values'] as List).cast<String>();
          for (int i = 0; i < categories.length; i++) {
            features.add(categories[i] == value ? 1.0 : 0.0);
          }
          break;
      }
    });
    
    return features;
  }
  
  /// Record result and update best configuration
  void _recordResult(Map<String, dynamic> configuration, double score) {
    // Normalize numerical values for storage in GP model
    final features = _configToFeatures(configuration);
    
    // Update GP model
    _gpModel['trainingInputs'].add(features);
    _gpModel['trainingOutputs'].add(score);
    
    // Update optimization history
    _optimizationHistory.add({
      'configuration': Map.from(configuration),
      'score': score,
      'trial': _completedTrials + 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Update best configuration
    if (score > _bestScore) {
      _bestScore = score;
      _bestConfiguration = Map.from(configuration);
    }
  }
  
  /// Get optimization progress stream
  Stream<Map<String, dynamic>> get optimizationProgress => _optimizationProgressController.stream;
  
  /// Get current best configuration
  Map<String, dynamic>? getBestConfiguration() {
    return _bestConfiguration != null ? Map.from(_bestConfiguration!) : null;
  }
  
  /// Get optimization history
  List<Map<String, dynamic>> getHistory() {
    return List.from(_optimizationHistory);
  }
  
  /// Check if optimization is currently running
  bool get isOptimizing => _isOptimizing;
  
  /// Get search space definition
  Map<String, Map<String, dynamic>> getSearchSpace() {
    return Map.from(_searchSpace);
  }
  
  /// Dispose resources
  void dispose() {
    _optimizationProgressController.close();
  }
} 