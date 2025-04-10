import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_samples/rive_app/utils/advanced_model_orchestrator.dart';
import 'package:flutter_samples/rive_app/utils/big_data_analytics.dart';

// Simple custom chart widget that doesn't rely on external packages
class CustomChartWidget extends StatelessWidget {
  final List<double> data;
  final Color color;
  final Color fillColor;
  final double maxValue;
  final bool showLabels;

  const CustomChartWidget({
    Key? key,
    required this.data,
    required this.color,
    required this.fillColor,
    required this.maxValue,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChartPainter(
        data: data,
        color: color,
        fillColor: fillColor,
        maxValue: maxValue,
        showLabels: showLabels,
      ),
      child: Container(),
    );
  }
}

// Custom painter for drawing line charts
class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color fillColor;
  final double maxValue;
  final bool showLabels;

  ChartPainter({
    required this.data,
    required this.color,
    required this.fillColor,
    required this.maxValue,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Calculate point positions
    final double xStep = size.width / (data.length - 1);
    final double yScale = size.height / maxValue;

    // Start paths at the first point
    final startX = 0.0;
    final startY = size.height - (data.first * yScale);
    path.moveTo(startX, startY);
    fillPath.moveTo(startX, startY);

    // Add points to the paths
    for (int i = 1; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - (data[i] * yScale);
      
      // For a curved line, use quadraticBezierTo
      if (i < data.length - 1) {
        final nextX = (i + 1) * xStep;
        final nextY = size.height - (data[i + 1] * yScale);
        
        final controlX = x + (nextX - x) / 2;
        path.quadraticBezierTo(x, y, controlX, (y + nextY) / 2);
        fillPath.quadraticBezierTo(x, y, controlX, (y + nextY) / 2);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete the fill path by connecting to bottom corners
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Draw the fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw labels if needed
    if (showLabels) {
      final textStyle = TextStyle(
        color: color,
        fontSize: 10,
      );
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      // Draw min and max values
      final maxText = maxValue.toStringAsFixed(1);
      textPainter.text = TextSpan(text: maxText, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, 4));

      final minText = '0.0';
      textPainter.text = TextSpan(text: minText, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, size.height - textPainter.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.maxValue != maxValue;
  }
}

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> with SingleTickerProviderStateMixin {
  final AdvancedModelOrchestrator _orchestrator = AdvancedModelOrchestrator();
  final BigDataAnalytics _analytics = BigDataAnalytics();
  
  late TabController _tabController;
  StreamSubscription? _metricsSubscription;
  
  Map<String, dynamic> _metrics = {};
  Map<String, List<double>> _timeSeriesData = {
    'accuracy': <double>[],
    'confidence': <double>[],
    'processingTime': <double>[],
    'knowledgeGraphQueries': <double>[],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _orchestrator.initialize().then((_) {
      _setupMetricsListener();
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _metricsSubscription?.cancel();
    super.dispose();
  }

  void _setupMetricsListener() {
    _metricsSubscription = _orchestrator.systemMetrics.listen((metrics) {
      setState(() {
        _metrics = metrics;
        
        // Update time series data - make sure we handle nulls and convert ints to doubles
        _timeSeriesData['accuracy']!.add(
            (metrics['performance']?['recognitionRate'] ?? 0.0).toDouble());
        _timeSeriesData['confidence']!.add(
            (metrics['metrics']?['averageConfidence'] ?? 0.0).toDouble());
        _timeSeriesData['processingTime']!.add(
            (metrics['metrics']?['averageProcessingTimeMs'] ?? 0.0).toDouble());
        _timeSeriesData['knowledgeGraphQueries']!.add(
            (metrics['metrics']?['knowledgeGraphQueriesCount'] ?? 0).toDouble());
        
        // Keep only the most recent 20 points
        if (_timeSeriesData['accuracy']!.length > 20) {
          for (var key in _timeSeriesData.keys) {
            _timeSeriesData[key]!.removeAt(0);
          }
        }
      });
    });
  }
  
  Future<void> _loadInitialData() async {
    final simulatedData = await _analytics.generateDashboardMetrics();
    setState(() {
      // Initialize with some data if metrics are empty
      if (_metrics.isEmpty) {
        _metrics = {
          'metrics': simulatedData['metrics'],
          'performance': simulatedData['performance'],
          'componentStatus': simulatedData['componentStatus'],
        };
      }
      
      // Add some initial data points for charts
      for (int i = 0; i < 10; i++) {
        _timeSeriesData['accuracy']!.add(0.7 + (i * 0.02));
        _timeSeriesData['confidence']!.add(0.6 + (i * 0.03));
        _timeSeriesData['processingTime']!.add(30.0 - (i * 0.5));
        _timeSeriesData['knowledgeGraphQueries']!.add(100.0 + (i * 20));
      }
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
            _buildHeader(isDarkMode),
            _buildTabBar(isDarkMode),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(isDarkMode),
                  _buildPerformanceTab(isDarkMode),
                  _buildComponentsTab(isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
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
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RiveAppTheme.getTextColor(isDarkMode),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.blue : Colors.deepPurple,
            ),
            onPressed: _loadInitialData,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: RiveAppTheme.getCardColor(isDarkMode),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDarkMode ? Colors.blue : Colors.deepPurple,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: RiveAppTheme.getTextSecondaryColor(isDarkMode),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Performance'),
          Tab(text: 'Components'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDarkMode) {
    final metrics = _metrics['metrics'] ?? {};
    final performance = _metrics['performance'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('System Overview', isDarkMode),
          const SizedBox(height: 16),
          
          // Stats cards row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Frames',
                  '${metrics['totalFramesProcessed'] ?? 0}',
                  Icons.video_library,
                  Colors.blue,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Recognition Rate',
                  '${((performance['recognitionRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                  Icons.check_circle_outline,
                  Colors.green,
                  isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Avg. Confidence',
                  '${((metrics['averageConfidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                  Icons.thumb_up_outlined,
                  Colors.orange,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Processing Time',
                  '${(metrics['averageProcessingTimeMs'] ?? 0.0).toStringAsFixed(1)} ms',
                  Icons.timer_outlined,
                  Colors.purple,
                  isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Confidence trend chart
          _buildSectionHeader('Recognition Confidence Trend', isDarkMode),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RiveAppTheme.getCardColor(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _timeSeriesData['confidence']!.isEmpty
                ? Center(
                    child: Text(
                      'Collecting data...',
                      style: TextStyle(
                        color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                      ),
                    ),
                  )
                : CustomChartWidget(
                    data: _timeSeriesData['confidence']!,
                    color: Colors.orange,
                    fillColor: Colors.orange.withOpacity(0.2),
                    maxValue: 1.0,
                    showLabels: false,
                  ),
          ),
          const SizedBox(height: 24),
          
          // Knowledge graph section
          _buildSectionHeader('Knowledge Graph Activity', isDarkMode),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RiveAppTheme.getCardColor(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildKnowledgeMetric(
                      'Total Queries',
                      '${metrics['knowledgeGraphQueriesCount'] ?? 0}',
                      isDarkMode,
                    ),
                    _buildKnowledgeMetric(
                      'Node Count',
                      '${(_metrics['componentStatus']?['knowledgeGraph']?['nodeCount']) ?? 247}',
                      isDarkMode,
                    ),
                    _buildKnowledgeMetric(
                      'Edge Count',
                      '${(_metrics['componentStatus']?['knowledgeGraph']?['edgeCount']) ?? 1240}',
                      isDarkMode,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Processing Performance', isDarkMode),
          const SizedBox(height: 16),
          
          // Processing time chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RiveAppTheme.getCardColor(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _timeSeriesData['processingTime']!.isEmpty
                ? Center(
                    child: Text(
                      'Collecting data...',
                      style: TextStyle(
                        color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                      ),
                    ),
                  )
                : CustomChartWidget(
                    data: _timeSeriesData['processingTime']!,
                    color: Colors.purple,
                    fillColor: Colors.purple.withOpacity(0.2),
                    maxValue: 50.0,
                    showLabels: false,
                  ),
          ),
          const SizedBox(height: 24),
          
          // Quantum processing visualization
          _buildSectionHeader('Quantum-Inspired Processing', isDarkMode),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RiveAppTheme.getCardColor(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuantumMetric(
                      'Circuit Executions',
                      '${_metrics['metrics']?['quantumCircuitExecutions'] ?? 0}',
                      isDarkMode,
                    ),
                    _buildQuantumMetric(
                      'QFT Operations',
                      '${(_metrics['componentStatus']?['quantumProcessor']?['qftOperations']) ?? 314}',
                      isDarkMode,
                    ),
                    _buildQuantumMetric(
                      'Entanglement Score',
                      '${(_metrics['componentStatus']?['quantumProcessor']?['entanglementScore'] ?? 0.76).toStringAsFixed(2)}',
                      isDarkMode,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quantum circuit visualization (simplified representation)
                SizedBox(
                  height: 100,
                  child: Row(
                    children: List.generate(
                      8, // 8 qubits visualization
                      (index) => Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 10, 
                              color: Colors.blue.withOpacity(0.6),
                            ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: RiveAppTheme.getTextColor(isDarkMode).withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Q$index',
                              style: TextStyle(
                                fontSize: 12,
                                color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Federated learning section
          _buildSectionHeader('Federated Learning', isDarkMode),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RiveAppTheme.getCardColor(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RiveAppTheme.getTextColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (_metrics['metrics']?['federatedRoundsCompleted'] ?? 0) / 10,
                  backgroundColor: RiveAppTheme.getInputBackgroundColor(isDarkMode),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rounds Completed: ${_metrics['metrics']?['federatedRoundsCompleted'] ?? 0}/10',
                  style: TextStyle(
                    fontSize: 14,
                    color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFederatedMetric(
                      'Active Clients',
                      '${(_metrics['componentStatus']?['federatedLearning']?['activeClients']) ?? 8}',
                      isDarkMode,
                    ),
                    _buildFederatedMetric(
                      'Aggregation Method',
                      '${(_metrics['componentStatus']?['federatedLearning']?['aggregationMethod']) ?? "FedAvg"}',
                      isDarkMode,
                    ),
                    _buildFederatedMetric(
                      'Privacy Level',
                      '${(_metrics['componentStatus']?['federatedLearning']?['privacyLevel']) ?? "High"}',
                      isDarkMode,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Neural Network Model', isDarkMode),
          const SizedBox(height: 16),
          _buildComponentCard(
            isDarkMode,
            title: 'Model Architecture',
            icon: Icons.memory,
            iconColor: Colors.blue,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModelDetail('Type', '${(_metrics['componentStatus']?['neuralNetwork']?['modelType']) ?? "MobileNetV3"}', isDarkMode),
                _buildModelDetail('Parameters', '${(_metrics['componentStatus']?['neuralNetwork']?['parameters']) ?? "2.7M"}', isDarkMode),
                _buildModelDetail('Input Shape', '${(_metrics['componentStatus']?['neuralNetwork']?['inputShape']) ?? "[1, 3, 224, 224]"}', isDarkMode),
                _buildModelDetail('Quantized', '${(_metrics['componentStatus']?['neuralNetwork']?['isQuantized']) ?? "Yes"}', isDarkMode),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Hyperparameter Optimization', isDarkMode),
          const SizedBox(height: 16),
          _buildComponentCard(
            isDarkMode,
            title: 'Optimization Status',
            icon: Icons.tune,
            iconColor: Colors.orange,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Best Configuration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: RiveAppTheme.getTextColor(isDarkMode),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildHyperparamDetail('Learning Rate', '0.0032', isDarkMode),
                          _buildHyperparamDetail('Batch Size', '64', isDarkMode),
                          _buildHyperparamDetail('Layers', '4', isDarkMode),
                        ],
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: RiveAppTheme.getInputBackgroundColor(isDarkMode),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CustomPaint(
                        painter: BayesianOptimizationPainter(
                          isDarkMode: isDarkMode,
                        ),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Last Optimization Score: ${(_metrics['metrics']?['lastOptimizationScore'] ?? 0.0).toStringAsFixed(3)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.blue : Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Big Data Processing', isDarkMode),
          const SizedBox(height: 16),
          _buildComponentCard(
            isDarkMode,
            title: 'Distributed Pipeline',
            icon: Icons.grid_view,
            iconColor: Colors.green,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataFlowDiagram(isDarkMode),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDataMetric('Nodes', '8', isDarkMode),
                    _buildDataMetric('Throughput', '142 fps', isDarkMode),
                    _buildDataMetric('Cache Hit', '87%', isDarkMode),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: RiveAppTheme.getTextColor(isDarkMode),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RiveAppTheme.getCardColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_upward,
                color: Colors.green,
                size: 16,
              ),
              Text(
                '${(2 + (value.hashCode % 8)).toString()}%',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RiveAppTheme.getTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeMetric(String label, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: RiveAppTheme.getTextColor(isDarkMode),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantumMetric(String label, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildFederatedMetric(String label, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RiveAppTheme.getTextColor(isDarkMode),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
          ),
        ),
      ],
    );
  }
  
  Widget _buildModelDetail(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: RiveAppTheme.getTextColor(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHyperparamDetail(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: RiveAppTheme.getTextColor(isDarkMode),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataMetric(String label, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
          ),
        ),
      ],
    );
  }
  
  Widget _buildComponentCard(
    bool isDarkMode, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RiveAppTheme.getCardColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RiveAppTheme.getTextColor(isDarkMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
  
  Widget _buildDataFlowDiagram(bool isDarkMode) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RiveAppTheme.getInputBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDataNode('Input', isDarkMode),
          _buildDataFlow(isDarkMode),
          _buildDataNode('Process', isDarkMode),
          _buildDataFlow(isDarkMode),
          _buildDataNode('Transform', isDarkMode),
          _buildDataFlow(isDarkMode),
          _buildDataNode('Output', isDarkMode),
        ],
      ),
    );
  }
  
  Widget _buildDataNode(String label, bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.layers,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDataFlow(bool isDarkMode) {
    return SizedBox(
      width: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_forward,
            color: Colors.green.withOpacity(0.7),
            size: 16,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for Bayesian optimization visualization
class BayesianOptimizationPainter extends CustomPainter {
  final bool isDarkMode;
  
  BayesianOptimizationPainter({required this.isDarkMode});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    final fillPaint = Paint()
      ..color = Colors.orange.withOpacity(0.1)
      ..style = PaintingStyle.fill;
      
    final dotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
      
    final bestDotPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    
    // Draw coordinate system
    final axisPaint = Paint()
      ..color = RiveAppTheme.getTextSecondaryColor(isDarkMode).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    // X-axis
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      axisPaint,
    );
    
    // Y-axis
    canvas.drawLine(
      Offset(size.width * 0.1, 0),
      Offset(size.width * 0.1, size.height),
      axisPaint,
    );
    
    // Draw acquisition function curve
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.7);
    
    for (double x = 0; x <= 1.0; x += 0.01) {
      // Simulate Bayesian optimization curve
      final y = 0.5 + 0.3 * math.sin(x * 5.0) * math.exp(-2.0 * (x - 0.6) * (x - 0.6));
      path.lineTo(
        size.width * (0.1 + x * 0.9),
        size.height * (0.8 - y * 0.7),
      );
    }
    
    canvas.drawPath(path, paint);
    
    // Fill below the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height * 0.8);
    fillPath.lineTo(size.width * 0.1, size.height * 0.8);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw evaluation points
    for (int i = 0; i < 8; i++) {
      final x = 0.1 + (i / 8.0) * 0.85;
      final y = 0.5 + 0.2 * math.sin(x * 12.0) * math.exp(-2.0 * (x - 0.6) * (x - 0.6));
      
      canvas.drawCircle(
        Offset(size.width * x, size.height * (0.8 - y * 0.7)),
        3.0,
        dotPaint,
      );
    }
    
    // Draw best point
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.35),
      5.0,
      bestDotPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Math helper
class Math {
  static double sin(double x) => math.sin(x);
  static double exp(double x) => math.exp(x);
} 