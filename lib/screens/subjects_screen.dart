import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/subject_service.dart';
import '../models/subject.dart';
import './subject_details_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final SubjectService _subjectService = SubjectService();
  final TextEditingController _searchController = TextEditingController();
  List<Subject> _filteredSubjects = [];

  @override
  void initState() {
    super.initState();
    _subjectService.addListener(_onSubjectsUpdate);
    _loadSubjects();
  }

  @override
  void dispose() {
    _subjectService.removeListener(_onSubjectsUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onSubjectsUpdate() {
    _filterSubjects();
  }

  Future<void> _loadSubjects() async {
    await _subjectService.loadSubjects();
    _filterSubjects();
  }

  void _filterSubjects() {
    setState(() {
      _filteredSubjects = _subjectService.searchSubjects(_searchController.text);
    });
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hoursController,
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                _showSnackBar('Please fill in all required fields', Colors.red);
                return;
              }

              final hours = int.tryParse(hoursController.text) ?? 0;
              final minutes = int.tryParse(minutesController.text) ?? 0;
              final dailyTarget = Duration(hours: hours, minutes: minutes);

              final success = await _subjectService.addSubject(
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                dailyTarget: dailyTarget.inMinutes > 0 ? dailyTarget : null,
                color: selectedColor,
              );

              if (success) {
                Navigator.pop(context);
                _showSnackBar('Subject added successfully!', Colors.green);
              } else {
                _showSnackBar('Subject with this name already exists', Colors.red);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(Subject subject) {
    final nameController = TextEditingController(text: subject.name);
    final descriptionController = TextEditingController(text: subject.description ?? '');
    final hoursController = TextEditingController(text: subject.dailyTarget?.inHours.toString() ?? '');
    final minutesController = TextEditingController(text: ((subject.dailyTarget?.inMinutes ?? 0) % 60).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hoursController,
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                _showSnackBar('Please fill in all required fields', Colors.red);
                return;
              }

              final hours = int.tryParse(hoursController.text) ?? 0;
              final minutes = int.tryParse(minutesController.text) ?? 0;
              final dailyTarget = Duration(hours: hours, minutes: minutes);

              final updatedSubject = subject.copyWith(
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                dailyTarget: dailyTarget.inMinutes > 0 ? dailyTarget : null,
              );

              final success = await _subjectService.updateSubject(updatedSubject);

              if (success) {
                Navigator.pop(context);
                _showSnackBar('Subject updated successfully!', Colors.green);
              } else {
                _showSnackBar('Failed to update subject', Colors.red);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _subjectService.deleteSubject(subject.id!);
              if (success) {
                _showSnackBar('Subject deleted successfully', Colors.green);
              } else {
                _showSnackBar('Failed to delete subject', Colors.red);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildSubjectsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            Icons.book,
            size: 28,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Text(
            'Subjects',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (value) => _subjectService.sortSubjects(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'target', child: Text('Sort by Target')),
              const PopupMenuItem(value: 'created', child: Text('Sort by Created')),
            ],
            child: Icon(
              Icons.sort,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterSubjects(),
        decoration: InputDecoration(
          hintText: 'Search subjects...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _filteredSubjects.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _filteredSubjects.length,
              itemBuilder: (context, index) {
                final subject = _filteredSubjects[index];
                return _buildSubjectCard(subject);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _subjectService.subjects.isEmpty 
                ? 'No subjects yet'
                : 'No subjects found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subjectService.subjects.isEmpty 
                ? 'Add your first subject to get started!'
                : 'Try adjusting your search',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailsScreen(subject: subject),
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: subject.color.withOpacity(0.2),
            child: Icon(
              Icons.book,
              color: subject.color,
            ),
          ),
          title: Text(
            subject.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subject.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  subject.description!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Target: ${_formatDuration(subject.dailyTarget)}',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListenableBuilder(
                listenable: _subjectService,
                builder: (context, child) {
                  final isSelected = _subjectService.selectedSubject?.id == subject.id;
                  return IconButton(
                    onPressed: () {
                      if (isSelected) {
                        _subjectService.clearSelection();
                      } else {
                        _subjectService.selectSubject(subject);
                      }
                    },
                    icon: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue[600] : Colors.grey[400],
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditSubjectDialog(subject);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(subject);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

