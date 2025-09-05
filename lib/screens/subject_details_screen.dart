import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../services/subject_service.dart';
import 'package:intl/intl.dart';
import '../models/topic.dart';
import '../database/database_helper.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final Subject subject;

  const SubjectDetailsScreen({super.key, required this.subject});

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  final SubjectService _subjectService = SubjectService();
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<Topic>> _topicsFuture;
  late Subject _subject;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _subject = widget.subject;
    _statsFuture = _loadStats();
    _topicsFuture = _loadTopics();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final totalTime = await _subjectService.getSubjectTotalTime(_subject.id!);
    final avgDuration = await _subjectService.getAverageSessionDuration(_subject.id!);
    final sessions = await _subjectService.getStudySessionsForSubject(_subject.id!);
    return {
      'totalTime': totalTime,
      'avgDuration': avgDuration,
      'sessions': sessions,
    };
  }

  Future<List<Topic>> _loadTopics() async {
    return await dbHelper.getTopicsForSubject(_subject.id!);
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _subject.name);
    final descriptionController = TextEditingController(text: _subject.description);
    Color selectedColor = _subject.color;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 20),
                const Text('Subject Color'),
                const SizedBox(height: 10),
                ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) {
                    selectedColor = color;
                  },
                  pickerAreaHeightPercent: 0.8,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updatedSubject = _subject.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  color: selectedColor,
                );
                await _subjectService.updateSubject(updatedSubject);
                setState(() {
                  _subject = updatedSubject;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_subject.name),
        backgroundColor: _subject.color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
        ],
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
                _buildTopicsList(),
                const SizedBox(height: 24),
                _buildSessionsList(sessions),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTopicDialog,
        child: const Icon(Icons.add),
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
        _buildStatCard('Total Time', '${totalTime}m', Icons.access_time, _subject.color),
        _buildStatCard('Avg Session', '${avgDuration.toStringAsFixed(1)}m', Icons.timelapse, _subject.color),
        _buildStatCard('Daily Target', _formatDuration(_subject.dailyTarget), Icons.today, _subject.color),
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

  Widget _buildTopicsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Topic>>(
          future: _topicsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No topics for this subject yet.'),
                ),
              );
            } else {
              final topics = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Checkbox(
                        value: topic.isCompleted,
                        onChanged: (value) {
                          _toggleTopicCompletion(topic);
                        },
                      ),
                      title: Text(
                        topic.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditTopicDialog(topic);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await dbHelper.deleteTopic(topic.id!);
                              setState(() {
                                _topicsFuture = _loadTopics();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }

  void _showAddTopicDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Topic'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Topic Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newTopic = Topic(
                    subjectId: _subject.id!,
                    name: nameController.text,
                  );
                  await dbHelper.insertTopic(newTopic);
                  setState(() {
                    _topicsFuture = _loadTopics();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTopicDialog(Topic topic) {
    final nameController = TextEditingController(text: topic.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Topic'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Topic Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final updatedTopic = Topic(
                    id: topic.id,
                    subjectId: topic.subjectId,
                    name: nameController.text,
                    isCompleted: topic.isCompleted,
                  );
                  await dbHelper.updateTopic(updatedTopic);
                  setState(() {
                    _topicsFuture = _loadTopics();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _toggleTopicCompletion(Topic topic) async {
    final updatedTopic = Topic(
      id: topic.id,
      subjectId: topic.subjectId,
      name: topic.name,
      isCompleted: !topic.isCompleted,
    );
    await dbHelper.updateTopic(updatedTopic);
    setState(() {
      _topicsFuture = _loadTopics();
    });
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
                    backgroundColor: _subject.color.withOpacity(0.2),
                    child: Icon(Icons.history, color: _subject.color),
                  ),
                  title: Text(
                    '${session.durationMinutes} minutes',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(session.startTime),
                  ),
                  trailing: (session.notes?.isNotEmpty ?? false)
                      ? const Icon(Icons.note)
                      : null,
                  onTap: () {
                    _showNoteDialog(session);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  void _showNoteDialog(StudySession session) {
    final notesController = TextEditingController(text: session.notes);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Session Notes'),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(
              hintText: 'Write something about this session...',
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                final updatedSession = session.copyWith(notes: notesController.text);
                await _subjectService.updateStudySession(updatedSession);
                setState(() {
                  _statsFuture = _loadStats();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
