import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../models/subject.dart';
import '../services/subject_service.dart';

class AddExamScreen extends StatefulWidget {
  final Exam? exam;

  const AddExamScreen({super.key, this.exam});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final SubjectService _subjectService = SubjectService();
  final dbHelper = DatabaseHelper();
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  late Exam _exam;
  bool get _isEditMode => widget.exam != null;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    if (_isEditMode) {
      _exam = widget.exam!;
    } else {
      _exam = Exam(subjectId: 0, name: '', date: DateTime.now());
    }
  }

  Future<void> _loadSubjects() async {
    await _subjectService.loadSubjects();
    setState(() {
      _subjects = _subjectService.subjects;
      if (_subjects.isNotEmpty) {
        if (_isEditMode) {
          _selectedSubject = _subjectService.getSubjectById(_exam.subjectId);
        } else {
          _selectedSubject = _subjects.first;
        }
      }
    });
  }

  Future<void> _saveExam() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject.')),
      );
      return;
    }

    if (_exam.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exam name.')),
      );
      return;
    }

    final examToSave = Exam(
      id: _isEditMode ? _exam.id : null,
      subjectId: _selectedSubject!.id!,
      name: _exam.name,
      date: _exam.date,
    );

    if (_isEditMode) {
      await dbHelper.updateExam(examToSave);
    } else {
      await dbHelper.insertExam(examToSave);
    }

    Navigator.of(context).pop(examToSave);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Exam' : 'Add Exam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveExam,
            tooltip: 'Save Exam',
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
            _buildExamField(),
          ],
        ),
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

  Widget _buildExamField() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: _exam.name,
              onChanged: (value) {
                _exam = _exam.copyWith(name: value);
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
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat.yMd().format(_exam.date)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _exam.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      setState(() {
        _exam = _exam.copyWith(date: pickedDate);
      });
    }
  }
}
