import 'dart:async';
import 'dart:math' as math;
import 'advanced_python_integration.dart';

/// Advanced Data Governance System that manages data compliance, privacy,
/// and lineage tracking for machine learning data pipelines
class AdvancedDataGovernance {
  // Singleton pattern
  static final AdvancedDataGovernance _instance = AdvancedDataGovernance._internal();
  factory AdvancedDataGovernance() => _instance;
  
  // Access to Python backend
  final PythonBackendIntegration _pythonBackend = PythonBackendIntegration();
  
  // Data governance policies
  final Map<String, DataGovernancePolicy> _policies = {};
  
  // Data lineage tracking
  final List<DataLineageRecord> _lineageRecords = [];
  
  // Data access logs
  final List<DataAccessRecord> _accessLogs = [];
  
  // Compliance status
  Map<String, ComplianceStatus> _complianceStatus = {};
  
  // Metrics stream controller
  final StreamController<Map<String, dynamic>> _metricsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  AdvancedDataGovernance._internal() {
    _initializeDefaultPolicies();
    _startMetricsEmitter();
  }
  
  /// Stream of governance metrics
  Stream<Map<String, dynamic>> get governanceMetrics => _metricsController.stream;
  
  /// Initialize default governance policies
  void _initializeDefaultPolicies() {
    // GDPR compliance policy
    _policies['gdpr'] = DataGovernancePolicy(
      id: 'gdpr',
      name: 'GDPR Compliance',
      description: 'General Data Protection Regulation compliance policy',
      rules: [
        DataRule(
          id: 'data_retention',
          name: 'Data Retention',
          description: 'Limit data retention to necessary period',
          severity: RuleSeverity.critical
        ),
        DataRule(
          id: 'data_minimization',
          name: 'Data Minimization',
          description: 'Collect only necessary data',
          severity: RuleSeverity.high
        ),
        DataRule(
          id: 'consent_tracking',
          name: 'Consent Tracking',
          description: 'Track user consent for data usage',
          severity: RuleSeverity.critical
        ),
        DataRule(
          id: 'right_to_erasure',
          name: 'Right to Erasure',
          description: 'Support data deletion requests',
          severity: RuleSeverity.high
        )
      ]
    );
    
    // HIPAA compliance policy
    _policies['hipaa'] = DataGovernancePolicy(
      id: 'hipaa',
      name: 'HIPAA Compliance',
      description: 'Health Insurance Portability and Accountability Act compliance',
      rules: [
        DataRule(
          id: 'phi_protection',
          name: 'PHI Protection',
          description: 'Protect personally identifiable health information',
          severity: RuleSeverity.critical
        ),
        DataRule(
          id: 'access_controls',
          name: 'Access Controls',
          description: 'Implement strict access controls',
          severity: RuleSeverity.critical
        ),
        DataRule(
          id: 'audit_logging',
          name: 'Audit Logging',
          description: 'Maintain detailed access logs',
          severity: RuleSeverity.high
        )
      ]
    );
    
    // Model fairness policy
    _policies['fairness'] = DataGovernancePolicy(
      id: 'fairness',
      name: 'ML Fairness',
      description: 'Ensure ML models are fair and unbiased',
      rules: [
        DataRule(
          id: 'bias_detection',
          name: 'Bias Detection',
          description: 'Regularly test models for biases',
          severity: RuleSeverity.high
        ),
        DataRule(
          id: 'balanced_training',
          name: 'Balanced Training',
          description: 'Ensure training data is balanced',
          severity: RuleSeverity.medium
        ),
        DataRule(
          id: 'fairness_metrics',
          name: 'Fairness Metrics',
          description: 'Track metrics for model fairness',
          severity: RuleSeverity.high
        )
      ]
    );
    
    // Initialize compliance status
    for (final policy in _policies.values) {
      _complianceStatus[policy.id] = ComplianceStatus(
        policyId: policy.id,
        compliantRules: policy.rules.length ~/ 2, // Random initial compliance
        totalRules: policy.rules.length,
        lastCheck: DateTime.now().subtract(Duration(days: math.Random().nextInt(30))),
        issues: _generateRandomComplianceIssues(policy)
      );
    }
  }
  
  /// Start metrics emitter
  void _startMetricsEmitter() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      _emitGovernanceMetrics();
    });
  }
  
  /// Emit governance metrics
  void _emitGovernanceMetrics() {
    if (_metricsController.isClosed) return;
    
    final metrics = {
      'timestamp': DateTime.now().toIso8601String(),
      'complianceStatus': _complianceStatus.values.map((status) => status.toJson()).toList(),
      'dataAccessCount': _accessLogs.length,
      'dataLineageCount': _lineageRecords.length,
      'recentAccesses': _getRecentAccessLogs(5),
      'policies': _policies.length,
      'averageComplianceScore': _calculateAverageComplianceScore(),
    };
    
    _metricsController.add(metrics);
  }
  
  /// Calculate average compliance score
  double _calculateAverageComplianceScore() {
    if (_complianceStatus.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    for (final status in _complianceStatus.values) {
      totalScore += status.complianceScore;
    }
    
    return totalScore / _complianceStatus.length;
  }
  
  /// Get recent access logs
  List<Map<String, dynamic>> _getRecentAccessLogs(int count) {
    final sortedLogs = List<DataAccessRecord>.from(_accessLogs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedLogs.take(count).map((log) => log.toJson()).toList();
  }
  
  /// Generate random compliance issues
  List<ComplianceIssue> _generateRandomComplianceIssues(DataGovernancePolicy policy) {
    final issues = <ComplianceIssue>[];
    final ruleCount = policy.rules.length;
    final issueCount = math.Random().nextInt(ruleCount ~/ 2 + 1);
    
    for (int i = 0; i < issueCount; i++) {
      final rule = policy.rules[math.Random().nextInt(ruleCount)];
      
      issues.add(ComplianceIssue(
        ruleId: rule.id,
        description: 'Issue with ${rule.name}',
        severity: rule.severity,
        detectedAt: DateTime.now().subtract(Duration(days: math.Random().nextInt(14))),
        status: math.Random().nextBool() ? IssueStatus.open : IssueStatus.inProgress,
        affectedAssets: _generateRandomAssetIds(math.Random().nextInt(3) + 1)
      ));
    }
    
    return issues;
  }
  
  /// Generate random asset IDs
  List<String> _generateRandomAssetIds(int count) {
    final assetTypes = ['dataset', 'model', 'pipeline', 'report'];
    final assetIds = <String>[];
    
    for (int i = 0; i < count; i++) {
      final type = assetTypes[math.Random().nextInt(assetTypes.length)];
      final id = 100 + math.Random().nextInt(900);
      assetIds.add('$type-$id');
    }
    
    return assetIds;
  }
  
  /// Register data access
  Future<bool> registerDataAccess({
    required String datasetId,
    required String userId,
    required DataAccessType accessType,
    String? purpose,
  }) async {
    try {
      // Record access in local logs
      final accessRecord = DataAccessRecord(
        datasetId: datasetId,
        userId: userId,
        accessType: accessType,
        purpose: purpose,
        timestamp: DateTime.now()
      );
      _accessLogs.add(accessRecord);
      
      // Send to Python backend
      await _pythonBackend.processData(
        modelId: 'data-governance-system',
        data: {
          'operation': 'register_access',
          'accessRecord': accessRecord.toJson()
        },
        operation: 'process'
      );
      
      return true;
    } catch (e) {
      print('Error registering data access: $e');
      return false;
    }
  }
  
  /// Add data lineage record
  Future<bool> addLineageRecord({
    required String sourceId,
    required String targetId,
    required LineageType lineageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create lineage record
      final lineageRecord = DataLineageRecord(
        sourceId: sourceId,
        targetId: targetId,
        lineageType: lineageType,
        timestamp: DateTime.now(),
        metadata: metadata ?? {}
      );
      _lineageRecords.add(lineageRecord);
      
      // Send to Python backend
      await _pythonBackend.processData(
        modelId: 'data-governance-system',
        data: {
          'operation': 'add_lineage',
          'lineageRecord': lineageRecord.toJson()
        },
        operation: 'process'
      );
      
      return true;
    } catch (e) {
      print('Error adding lineage record: $e');
      return false;
    }
  }
  
  /// Get lineage for a specific data asset
  Future<Map<String, dynamic>> getDataLineage(String assetId) async {
    try {
      // Check local records first
      final upstreamRecords = _lineageRecords.where((r) => r.targetId == assetId).toList();
      final downstreamRecords = _lineageRecords.where((r) => r.sourceId == assetId).toList();
      
      // Request additional lineage from Python backend
      final response = await _pythonBackend.processData(
        modelId: 'data-governance-system',
        data: {
          'operation': 'get_lineage',
          'assetId': assetId
        },
        operation: 'analyze'
      );
      
      // Combine local and backend data
      return {
        'assetId': assetId,
        'upstream': upstreamRecords.map((r) => r.toJson()).toList(),
        'downstream': downstreamRecords.map((r) => r.toJson()).toList(),
        'completeLineage': response['lineageGraph'] ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting data lineage: $e');
      return {
        'error': 'Failed to retrieve lineage',
        'details': e.toString()
      };
    }
  }
  
  /// Run compliance check on a dataset
  Future<ComplianceStatus> runComplianceCheck(
      String datasetId, String policyId) async {
    try {
      // Validate policy exists
      if (!_policies.containsKey(policyId)) {
        throw Exception('Policy $policyId not found');
      }
      
      final policy = _policies[policyId]!;
      
      // Request compliance check from Python backend
      final response = await _pythonBackend.processData(
        modelId: 'data-governance-system',
        data: {
          'operation': 'compliance_check',
          'datasetId': datasetId,
          'policyId': policyId
        },
        operation: 'analyze'
      );
      
      // Parse results
      final issues = <ComplianceIssue>[];
      final compliantRules = <String>[];
      
      // Extract compliance issues from response
      if (response.containsKey('issues')) {
        for (final issue in response['issues']) {
          issues.add(ComplianceIssue(
            ruleId: issue['ruleId'],
            description: issue['description'],
            severity: _parseSeverity(issue['severity']),
            detectedAt: DateTime.now(),
            status: IssueStatus.open,
            affectedAssets: [datasetId]
          ));
        }
      }
      
      // Update compliance status
      final status = ComplianceStatus(
        policyId: policyId,
        compliantRules: policy.rules.length - issues.length,
        totalRules: policy.rules.length,
        lastCheck: DateTime.now(),
        issues: issues
      );
      
      // Update local status
      _complianceStatus[policyId] = status;
      
      return status;
    } catch (e) {
      print('Error running compliance check: $e');
      
      // Return current status
      return _complianceStatus[policyId] ?? ComplianceStatus(
        policyId: policyId,
        compliantRules: 0,
        totalRules: _policies[policyId]?.rules.length ?? 0,
        lastCheck: DateTime.now(),
        issues: []
      );
    }
  }
  
  /// Parse severity from string
  RuleSeverity _parseSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return RuleSeverity.critical;
      case 'high':
        return RuleSeverity.high;
      case 'medium':
        return RuleSeverity.medium;
      case 'low':
        return RuleSeverity.low;
      default:
        return RuleSeverity.medium;
    }
  }
  
  /// Get all policies
  List<DataGovernancePolicy> getAllPolicies() {
    return _policies.values.toList();
  }
  
  /// Get policy by ID
  DataGovernancePolicy? getPolicy(String policyId) {
    return _policies[policyId];
  }
  
  /// Get current compliance status
  Map<String, ComplianceStatus> getComplianceStatus() {
    return Map.from(_complianceStatus);
  }
  
  /// Get access logs for a dataset
  List<DataAccessRecord> getDatasetAccessLogs(String datasetId) {
    return _accessLogs.where((log) => log.datasetId == datasetId).toList();
  }
  
  /// Dispose resources
  void dispose() {
    _metricsController.close();
  }
}

/// Data governance policy
class DataGovernancePolicy {
  final String id;
  final String name;
  final String description;
  final List<DataRule> rules;
  
  DataGovernancePolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.rules,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rules': rules.map((rule) => rule.toJson()).toList(),
    };
  }
}

/// Data rule
class DataRule {
  final String id;
  final String name;
  final String description;
  final RuleSeverity severity;
  
  DataRule({
    required this.id,
    required this.name,
    required this.description,
    required this.severity,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'severity': severity.toString().split('.').last,
    };
  }
}

/// Rule severity
enum RuleSeverity {
  critical,
  high,
  medium,
  low,
}

/// Compliance status
class ComplianceStatus {
  final String policyId;
  final int compliantRules;
  final int totalRules;
  final DateTime lastCheck;
  final List<ComplianceIssue> issues;
  
  ComplianceStatus({
    required this.policyId,
    required this.compliantRules,
    required this.totalRules,
    required this.lastCheck,
    required this.issues,
  });
  
  /// Get compliance score (0.0 to 1.0)
  double get complianceScore => totalRules > 0 ? compliantRules / totalRules : 0.0;
  
  Map<String, dynamic> toJson() {
    return {
      'policyId': policyId,
      'compliantRules': compliantRules,
      'totalRules': totalRules,
      'complianceScore': complianceScore,
      'lastCheck': lastCheck.toIso8601String(),
      'issues': issues.map((issue) => issue.toJson()).toList(),
    };
  }
}

/// Compliance issue
class ComplianceIssue {
  final String ruleId;
  final String description;
  final RuleSeverity severity;
  final DateTime detectedAt;
  final IssueStatus status;
  final List<String> affectedAssets;
  
  ComplianceIssue({
    required this.ruleId,
    required this.description,
    required this.severity,
    required this.detectedAt,
    required this.status,
    required this.affectedAssets,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'description': description,
      'severity': severity.toString().split('.').last,
      'detectedAt': detectedAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'affectedAssets': affectedAssets,
    };
  }
}

/// Issue status
enum IssueStatus {
  open,
  inProgress,
  resolved,
  dismissed,
}

/// Data access record
class DataAccessRecord {
  final String datasetId;
  final String userId;
  final DataAccessType accessType;
  final String? purpose;
  final DateTime timestamp;
  
  DataAccessRecord({
    required this.datasetId,
    required this.userId,
    required this.accessType,
    this.purpose,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'datasetId': datasetId,
      'userId': userId,
      'accessType': accessType.toString().split('.').last,
      'purpose': purpose,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Data access type
enum DataAccessType {
  read,
  write,
  delete,
  modify,
  execute,
}

/// Data lineage record
class DataLineageRecord {
  final String sourceId;
  final String targetId;
  final LineageType lineageType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  DataLineageRecord({
    required this.sourceId,
    required this.targetId,
    required this.lineageType,
    required this.timestamp,
    required this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      'lineageType': lineageType.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Lineage type
enum LineageType {
  derivation,
  transformation,
  version,
  aggregation,
  copy,
  input,
  output,
} 