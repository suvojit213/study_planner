import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  String? _alarmSound;

  @override
  void initState() {
    super.initState();
    _loadAlarmSound();
  }

  Future<void> _loadAlarmSound() async {
    final alarmSound = await _settingsService.getAlarmSound();
    setState(() {
      _alarmSound = alarmSound;
    });
  }

  Future<void> _pickAndSetAlarmSound() async {
    final newAlarmSound = await _settingsService.pickAlarmSound();
    if (newAlarmSound != null) {
      await _settingsService.setAlarmSound(newAlarmSound);
      _loadAlarmSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Alarm Sound'),
            subtitle: Text(_alarmSound ?? 'Default'),
            onTap: _pickAndSetAlarmSound,
          ),
        ],
      ),
    );
  }
}
