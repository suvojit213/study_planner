import './alarm_screen.dart';
import 'package:flutter/material.dart';
import '../services/timer_service.dart';
import '../services/subject_service.dart';
import '../models/subject.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  final TimerService _timerService = TimerService();
  final SubjectService _subjectService = SubjectService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _subjectService.loadSubjects();
    _subjectService.addListener(_onSubjectUpdate);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _timerService.addListener(_onTimerUpdate);
    _timerService.isTargetCompleted.addListener(_onTargetCompleted);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timerService.removeListener(_onTimerUpdate);
    _timerService.isTargetCompleted.removeListener(_onTargetCompleted);
    _subjectService.removeListener(_onSubjectUpdate);
    super.dispose();
  }

  void _onSubjectUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTimerUpdate() {
    if (mounted) {
      setState(() {
        if (_timerService.state == TimerState.running) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      });
    }
  }

  void _onTargetCompleted() {
    if (_timerService.isTargetCompleted.value) {
      _showCompletionDialog();
    }
  }

  Future<void> _startStudy() async {
    final selectedSubject = _subjectService.selectedSubject;
    if (selectedSubject == null) {
      _showSubjectSelectionDialog();
      return;
    }

    final success = await _timerService.startStudy(selectedSubject);
    if (!success) {
      _showSnackBar('Failed to start study session', Colors.red);
    }
  }

  void _pauseStudy() {
    _timerService.pauseStudy();
  }

  void _resumeStudy() {
    _timerService.resumeStudy();
  }

  Future<void> _endStudy() async {
    final shouldEnd = await _showEndConfirmationDialog();
    if (shouldEnd) {
      await _timerService.endStudy();
      _showSnackBar('Study session ended.', Colors.blue);
    }
  }

  void _showSubjectSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final subjects = _subjectService.subjects;
        return AlertDialog(
          title: const Text('Select Subject'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  title: Text(subject.name),
                  onTap: () {
                    _subjectService.selectSubject(subject);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCompletionDialog() async {
    final subject = _subjectService.selectedSubject;
    if (subject == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmScreen(
          subject: subject,
          duration: Duration(seconds: _timerService.elapsedSeconds),
        ),
      ),
    );
  }

  Future<bool> _showEndConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Study Session'),
        content: const Text('Are you sure you want to end this study session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimerDisplay(),
                    const SizedBox(height: 40),
                    _buildSubjectInfo(),
                    const SizedBox(height: 40),
                    _buildControlButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.timer,
          size: 28,
          color: Colors.grey[700],
        ),
        const SizedBox(width: 12),
        Text(
          'Study Timer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return ListenableBuilder(
      listenable: _timerService,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _timerService.state == TimerState.running 
                  ? _pulseAnimation.value 
                  : 1.0,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _getTimerColors(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getTimerColors().first.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _timerService.formattedTime,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTimerStateText(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Color> _getTimerColors() {
    switch (_timerService.state) {
      case TimerState.running:
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
      case TimerState.paused:
        return [const Color(0xFFFF9A56), const Color(0xFFFF6B6B)];
      case TimerState.stopped:
        return [Colors.grey[400]!, Colors.grey[500]!];
    }
  }

  String _getTimerStateText() {
    switch (_timerService.state) {
      case TimerState.running:
        return 'STUDYING';
      case TimerState.paused:
        return 'PAUSED';
      case TimerState.stopped:
        return 'READY TO START';
    }
  }

  Widget _buildSubjectInfo() {
    return ListenableBuilder(
      listenable: _subjectService,
      builder: (context, child) {
        final selectedSubject = _subjectService.selectedSubject;
        
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.book,
                        color: Colors.blue[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Current Subject',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _showSubjectSelectionDialog,
                    child: Text(selectedSubject == null ? 'Select' : 'Change'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (selectedSubject != null) ...[
                Text(
                  selectedSubject.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (selectedSubject.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    selectedSubject.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${_formatDuration(selectedSubject.dailyTarget)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  'No subject selected',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select a subject to start studying',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
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

  Widget _buildControlButtons() {
    return ListenableBuilder(
      listenable: _timerService,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (_timerService.state == TimerState.stopped) ...[
              _buildControlButton(
                icon: Icons.play_arrow,
                label: 'Start',
                color: Colors.green,
                onPressed: _startStudy,
              ),
            ] else if (_timerService.state == TimerState.running) ...[
              _buildControlButton(
                icon: Icons.pause,
                label: 'Pause',
                color: Colors.orange,
                onPressed: _pauseStudy,
              ),
              _buildControlButton(
                icon: Icons.stop,
                label: 'End',
                color: Colors.red,
                onPressed: _endStudy,
              ),
            ] else if (_timerService.state == TimerState.paused) ...[
              _buildControlButton(
                icon: Icons.play_arrow,
                label: 'Resume',
                color: Colors.green,
                onPressed: _resumeStudy,
              ),
              _buildControlButton(
                icon: Icons.stop,
                label: 'End',
                color: Colors.red,
                onPressed: _endStudy,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

