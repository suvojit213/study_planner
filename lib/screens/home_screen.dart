import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../services/timer_service.dart';
import '../services/subject_service.dart';
import '../models/subject.dart';
import './schedule_screen.dart'; // Import the new screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TimerService _timerService = TimerService();
  final SubjectService _subjectService = SubjectService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, int> _todayProgress = {};
  Map<String, int> _monthlyProgress = {};
  int _todayTotal = 0;
  List<Exam> _upcomingExams = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _timerService.addListener(_onTimerUpdate);
    _timerService.isTargetCompleted.addListener(_onTargetCompleted);
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimerUpdate);
    _timerService.isTargetCompleted.removeListener(_onTargetCompleted);
    super.dispose();
  }

  void _onTargetCompleted() {
    if (_timerService.isTargetCompleted.value) {
      _loadData();
    }
  }

  void _onTimerUpdate() {
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await _timerService.getTodayProgress();
    final total = await _timerService.getTodayTotalMinutes();
    final exams = await _dbHelper.getAllExams();
    exams.sort((a, b) => a.date.compareTo(b.date));
    final monthlyProgress = await _dbHelper.getMonthlyStudyTime();

    if (mounted) {
      setState(() {
        _todayProgress = progress;
        _todayTotal = total;
        _upcomingExams = exams;
        _monthlyProgress = monthlyProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Planner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'Track your learning journey',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        toolbarHeight: 70,
        actions: [
          IconButton(
            icon: Icon(Icons.schedule, color: Colors.grey[700], size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScheduleScreen()),
              );
            },
            tooltip: 'Weekly Schedule',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentSession(),
                const SizedBox(height: 24),
                _buildUpcomingExams(),
                const SizedBox(height: 24),
                _buildTodayOverview(),
                const SizedBox(height: 24),
                _buildMonthlyProgress(),
                const SizedBox(height: 24),
                _buildSubjectProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSession() {
    return ListenableBuilder(
      listenable: _timerService,
      builder: (context, child) {
        final isActive = _timerService.state != TimerState.stopped;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive 
                  ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                  : [Colors.grey[300]!, Colors.grey[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                children: [
                  Icon(
                    isActive ? Icons.timer : Icons.timer_off,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isActive ? 'Current Session' : 'No Active Session',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isActive) ...[
                const SizedBox(height: 16),
                Text(
                  _timerService.formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                if (_timerService.currentSubject != null)
                  Text(
                    _timerService.currentSubject!.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingExams() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_note,
                color: Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Upcoming Exams',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingExams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No upcoming exams',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._upcomingExams.map((exam) {
              final daysUntil = exam.date.difference(DateTime.now()).inDays;
              final subject = _subjectService.getSubjectById(exam.subjectId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: subject?.color ?? Colors.blue[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.name,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (subject != null)
                            Text(
                              subject.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '$daysUntil days',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTodayOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today,
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Today\'s Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Time',
                  '${_todayTotal}m',
                  Icons.access_time,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Subjects',
                  '${_todayProgress.length}',
                  Icons.book,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: Colors.deepPurple[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_monthlyProgress.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No study sessions this month',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._monthlyProgress.entries.map((entry) {
              final subject = _subjectService.subjects.firstWhere((s) => s.name == entry.key);
              final monthlyTarget = subject.monthlyTarget?.inMinutes ?? 0;
              final progress = monthlyTarget > 0 ? (entry.value / monthlyTarget).clamp(0, 1) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${entry.value} / ${monthlyTarget}m',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.purple[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Today\'s Subject Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayProgress.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No study sessions today',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start studying to see your progress!',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._todayProgress.entries.map((entry) => 
              _buildSubjectProgressItem(entry.key, entry.value)
            ).toList(),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressItem(String subjectName, int minutes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subjectName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            '${minutes}m',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }
}

