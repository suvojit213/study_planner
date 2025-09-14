import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_planner/database/database_helper.dart';
import 'package:study_planner/models/exam.dart';
import 'package:study_planner/models/subject.dart';
import 'package:study_planner/screens/add_exam_screen.dart';

class ExamDetailsScreen extends StatefulWidget {
  final Exam exam;
  final Subject? subject;

  const ExamDetailsScreen({super.key, required this.exam, this.subject});

  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  late Exam _exam;
  late Subject? _subject;

  @override
  void initState() {
    super.initState();
    _exam = widget.exam;
    _subject = widget.subject;
  }

  Future<void> _deleteExam() async {
    await DatabaseHelper().deleteExam(_exam.id!);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_exam.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExamScreen(exam: _exam),
                ),
              );
              if (result != null && result is Exam) {
                setState(() {
                  _exam = result;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Exam'),
                  content: const Text('Are you sure you want to delete this exam?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteExam();
                        Navigator.pop(context);
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  context,
                  icon: Icons.book,
                  title: 'Subject',
                  value: _subject?.name ?? 'No Subject',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: DateFormat.yMMMd().format(_exam.date),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  icon: Icons.info_outline,
                  title: 'Status',
                  value: _exam.date.isBefore(DateTime.now()) ? 'Completed' : 'Upcoming',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String title, required String value}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }
}