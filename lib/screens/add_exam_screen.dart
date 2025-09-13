
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../models/subject.dart';
import '../services/subject_service.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final SubjectService _subjectService = SubjectService();
  final dbHelper = DatabaseHelper();
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  final List<Exam> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _addExamField();
  }

  Future<void> _loadSubjects() async {
    await _subjectService.loadSubjects();
    setState(() {
      _subjects = _subjectService.subjects;
      if (_subjects.isNotEmpty) {
        _selectedSubject = _subjects.first;
      }
    });
  }

  void _addExamField() {
    setState(() {
      _exams.add(Exam(subjectId: 0, name: '', date: DateTime.now()));
    });
  }

  void _removeExamField(int index) {
    setState(() {
      _exams.removeAt(index);
    });
  }

  Future<void> _saveExams() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject.')),
      );
      return;
    }

    for (final exam in _exams) {
      if (exam.name.isNotEmpty) {
        final newExam = Exam(
          subjectId: _selectedSubject!.id!,
          name: exam.name,
          date: exam.date,
        );
        await dbHelper.insertExam(newExam);
      }
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveExams,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<Subject>(
              value: _selectedSubject,
              items: _subjects.map((subject) {
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
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _exams.length,
                itemBuilder: (context, index) {
                  return _buildExamField(index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExamField,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExamField(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _exams[index].name,
                onChanged: (value) {
                  _exams[index] = _exams[index].copyWith(name: value);
                },
                decoration: const InputDecoration(
                  labelText: 'Exam Name',
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _exams[index].date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _exams[index] = _exams[index].copyWith(date: pickedDate);
                  });
                }
              },
              child: Text(DateFormat.yMd().format(_exams[index].date)),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removeExamField(index),
            ),
          ],
        ),
      ),
    );
  }
}
