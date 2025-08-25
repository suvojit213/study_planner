
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:lottie/lottie.dart';

class AlarmScreen extends StatefulWidget {
  AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  @override
  void initState() {
    super.initState();
    FlutterRingtonePlayer.playAlarm(looping: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/alarm_animation.json'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FlutterRingtonePlayer.stop();
                Navigator.pop(context);
              },
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
