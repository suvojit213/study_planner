import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../services/subject_service.dart';

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
    _loadData();
  }

  void _loadData() {
    _statsFuture = _loadStats();
    _topicsFuture = _loadTopics();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final totalTime = await _subjectService.getSubjectTotalTime(_subject.id!);
    final avgDuration =
        await _subjectService.getAverageSessionDuration(_subject.id!);
    final sessions =
        await _subjectService.getStudySessionsForSubject(_subject.id!);
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
    final descriptionController =
        TextEditingController(text: _subject.description);
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
                BlockPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) {
                    selectedColor = color;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsCard(totalTime, avgDuration),
                    const SizedBox(height: 16),
                    if (_subject.description?.isNotEmpty ?? false) ...[
                      _buildDescriptionCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildTopicsCard(),
                    const SizedBox(height: 16),
                    _buildSessionsCard(sessions),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTopicDialog,
        backgroundColor: _subject.color,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: _subject.color,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _showEditDialog,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _subject.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          color: _subject.color,
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(left: 0, bottom: 16.0),
      ),
    );
  }

  Widget _buildStatsCard(int totalTime, double avgDuration) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.access_time, 'Total Time', '${totalTime}m'),
            _buildStatItem(
                Icons.timelapse, 'Avg Session', '${avgDuration.toStringAsFixed(1)}m'),
            _buildStatItem(
                Icons.flag, 'Target', _formatDuration(_subject.dailyTarget)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _subject.color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _subject.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Topics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
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
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text('No topics yet. Add one!'),
                    ),
                  );
                }

                final topics = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return ListTile(
                      leading: Checkbox(
                        value: topic.isCompleted,
                        onChanged: (value) => _toggleTopicCompletion(topic),
                        activeColor: _subject.color,
                      ),
                      title: Text(
                        topic.name,
                        style: TextStyle(
                          decoration: topic.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditTopicDialog(topic),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () async {
                              await dbHelper.deleteTopic(topic.id!);
                              setState(() {
                                _topicsFuture = _loadTopics();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsCard(List<StudySession> sessions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (sessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('No completed sessions yet.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return ListTile(
                    leading: Icon(Icons.history, color: _subject.color),
                    title: Text('${session.durationMinutes} minutes'),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(session.startTime),
                    ),
                    trailing: (session.notes?.isNotEmpty ?? false)
                        ? const Icon(Icons.note_alt)
                        : null,
                    onTap: () => _showNoteDialog(session),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.inMinutes == 0) return '-';
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
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final updatedTopic = topic.copyWith(name: nameController.text);
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
    final updatedTopic = topic.copyWith(isCompleted: !topic.isCompleted);
    await dbHelper.updateTopic(updatedTopic);
    setState(() {
      _topicsFuture = _loadTopics();
    });
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
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                final updatedSession =
                    session.copyWith(notes: notesController.text);
                await _subjectService.updateStudySession(updatedSession);
                // No need to call setState, as the session list is rebuilt on statsFuture reload
                // which we are not doing here to keep it simple. The note icon will update on next screen load.
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
