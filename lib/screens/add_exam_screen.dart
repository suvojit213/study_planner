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
            tooltip: 'Save Exams',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubjectDropdown(),
            const SizedBox(height: 24),
            _buildExamsTitle(),
            const SizedBox(height: 8),
            _buildExamsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExamField,
        label: const Text('Add Exam'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<Subject>(
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
          labelText: 'Select a Subject',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildExamsTitle() {
    return Text(
      _selectedSubject != null
          ? 'Exams for ${_selectedSubject!.name}'
          : 'Please select a subject',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildExamsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _exams.length,
        itemBuilder: (context, index) {
          return _buildExamField(index);
        },
      ),
    );
  }

  Widget _buildExamField(int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam #${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _exams[index].name,
              onChanged: (value) {
                _exams[index] = _exams[index].copyWith(name: value);
              },
              decoration: const InputDecoration(
                labelText: 'Exam Name (e.g., Mid-Term, Final)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_important_outline),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exam Date',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                TextButton.icon(
                  onPressed: () => _pickDate(index),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat.yMd().format(_exams[index].date)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                onPressed: () => _removeExamField(index),
                tooltip: 'Remove this exam',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(int index) async {
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
  }
}