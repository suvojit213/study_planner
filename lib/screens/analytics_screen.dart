import 'package:flutter/material.dart';
import '../database/database_helper.dart';
// import 'package:cristalyse/cristalyse.dart'; // Assuming this is the import path

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Data for charts
  List<Map<String, dynamic>> _dailyStudyData = [];
  List<Map<String, dynamic>> _weeklyStudyData = [];
  List<Map<String, dynamic>> _monthlyStudyData = [];
  List<Map<String, dynamic>> _subjectStudyData = [];
  List<int> _sessionDurations = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final now = DateTime.now();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

      _dailyStudyData = await _dbHelper.getDailyStudyTime(oneMonthAgo, now);
      _weeklyStudyData = await _dbHelper.getWeeklyStudyTime(oneYearAgo, now);
      _monthlyStudyData = await _dbHelper.getMonthlyStudyTime(oneYearAgo, now);
      _subjectStudyData = await _dbHelper.getSubjectStudyTime();
      _sessionDurations = await _dbHelper.getAllStudySessionDurations();
    } catch (e) {
      _errorMessage = 'Failed to load analytics data: $e';
      debugPrint(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Study Time (Last Month)',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      // Placeholder for Cristalyse Bar Chart
                      Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(child: Text('Daily Bar Chart Here')),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Subject-wise Study Time',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      // Placeholder for Cristalyse Pie Chart
                      Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(child: Text('Subject Pie Chart Here')),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Weekly Study Time (Last Year)',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      // Placeholder for Cristalyse Line Chart
                      Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(child: Text('Weekly Line Chart Here')),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Session Duration Distribution',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      // Placeholder for Cristalyse Histogram
                      Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(child: Text('Session Duration Histogram Here')),
                      ),
                    ],
                  ),
                ),
    );
  }
}