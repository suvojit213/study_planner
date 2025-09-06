import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/subject.dart';
import '../models/scheduled_session.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() {
    setState(() {
      _schedulesFuture = dbHelper.getScheduledSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _schedulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No recurring schedules yet.\nTap the + button to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final schedules = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              final session = ScheduledSession.fromMap(schedule);
              final subjectColor = Color(schedule['subjectColor'] as int);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: subjectColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    schedule['subjectName'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '${session.startTime.format(context)} for ${session.durationMinutes} mins',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      _buildDayChips(session.repeatDays, subjectColor),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      await dbHelper.deleteScheduledSession(session.id!);
                      _loadSchedules();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayChips(List<int> days, Color color) {
    const dayMap = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Wrap(
      spacing: 4.0,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isSelected = days.contains(dayIndex);
        return CircleAvatar(
          radius: 12,
          backgroundColor: isSelected ? color : Colors.grey[300],
          child: Text(
            dayMap[index],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }),
    );
  }

  void _showAddScheduleDialog(BuildContext context) async {
    final subjects = await dbHelper.getAllSubjects();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AddScheduleDialog(subjects: subjects, dbHelper: dbHelper, onSave: _loadSchedules);
      },
    );
  }
}

class AddScheduleDialog extends StatefulWidget {
  final List<Subject> subjects;
  final DatabaseHelper dbHelper;
  final VoidCallback onSave;

  const AddScheduleDialog({super.key, required this.subjects, required this.dbHelper, required this.onSave});

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  Subject? _selectedSubject;
  TimeOfDay? _selectedTime;
  final _durationController = TextEditingController();
  final List<int> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Recurring Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Subject>(
              value: _selectedSubject,
              items: widget.subjects.map((subject) {
                return DropdownMenuItem<Subject>(
                  value: subject,
                  child: Text(subject.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(_selectedTime?.format(context) ?? 'Not set'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
            ),
            const SizedBox(height: 24),
            const Text('Repeat on:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDaySelector(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saveSchedule,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    const dayMap = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isSelected = _selectedDays.contains(dayIndex);
        return FilterChip(
          label: Text(dayMap[index]),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(dayIndex);
              } else {
                _selectedDays.remove(dayIndex);
              }
            });
          },
        );
      }),
    );
  }

  void _saveSchedule() async {
    if (_selectedSubject == null ||
        _selectedTime == null ||
        _durationController.text.isEmpty ||
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select at least one day.')),
      );
      return;
    }

    final newSession = ScheduledSession(
      subjectId: _selectedSubject!.id!,
      startTime: _selectedTime!,
      durationMinutes: int.parse(_durationController.text),
      repeatDays: _selectedDays,
    );

    await widget.dbHelper.insertScheduledSession(newSession);
    widget.onSave();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
