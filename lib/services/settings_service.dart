import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class SettingsService {
  static const String _alarmSoundKey = 'alarm_sound';
  static const MethodChannel _channel = MethodChannel('com.example.study_planner/settings');

  Future<String?> getAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_alarmSoundKey);
  }

  Future<void> setAlarmSound(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alarmSoundKey, path);
  }

  Future<String?> pickAlarmSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      return result.files.single.path;
    } else {
      // User canceled the picker
      return null;
    }
  }

  Future<String?> getDefaultAlarmSound() async {
    try {
      final String? result = await _channel.invokeMethod('getDefaultAlarmSound');
      return result;
    } on PlatformException catch (e) {
      print("Failed to get default alarm sound: '${e.message}'.");
      return null;
    }
  }
}
