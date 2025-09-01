import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';

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

  void _showColorPicker(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: themeService.appColor,
              onColorChanged: (color) {
                themeService.setAppColor(color);
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
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
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Alarm Sound'),
                subtitle: Text(_alarmSound ?? 'Default'),
                onTap: _pickAndSetAlarmSound,
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeService.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeService.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              ListTile(
                title: const Text('App Color'),
                trailing: CircleAvatar(
                  backgroundColor: themeService.appColor,
                  radius: 15,
                ),
                onTap: () {
                  _showColorPicker(context, themeService);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
larmSound);
      _loadAlarmSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Alarm Sound'),
                subtitle: Text(_alarmSound ?? 'Default'),
                onTap: _pickAndSetAlarmSound,
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeService.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeService.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
