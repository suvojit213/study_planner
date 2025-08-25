import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../services/subject_service.dart';
import 'package:intl/intl.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final Subject subject;

  const SubjectDetailsScreen({super.key, required this.subject});

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  final SubjectService _subjectService = SubjectService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final totalTime = await _subjectService.getSubjectTotalTime(widget.subject.id!);
    final avgDuration = await _subjectService.getAverageSessionDuration(widget.subject.id!);
    final sessions = await _subjectService.getStudySessionsForSubject(widget.subject.id!);
    return {
      'totalTime': totalTime,
      'avgDuration': avgDuration,
      'sessions': sessions,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available.'));
          }

          final stats = snapshot.data!;
          final totalTime = stats['totalTime'] as int;
          final avgDuration = stats['avgDuration'] as double;
          final sessions = stats['sessions'] as List<StudySession>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsOverview(totalTime, avgDuration),
                const SizedBox(height: 24),
                _buildSessionsList(sessions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(int totalTime, double avgDuration) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard('Total Time', '${totalTime}m', Icons.access_time, Colors.green),
        _buildStatCard('Avg Session', '${avgDuration.toStringAsFixed(1)}m', Icons.timelapse, Colors.orange),
        _buildStatCard('Daily Target', _formatDuration(widget.subject.dailyTarget), Icons.today, Colors.blue),
      ],
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.inMinutes == 0) {
      return '-';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsList(List<StudySession> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Sessions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        if (sessions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No completed study sessions for this subject yet.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.history, color: Colors.blue[600]),
                  ),
                  title: Text(
                    '${session.durationMinutes} minutes',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(session.startTime),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
