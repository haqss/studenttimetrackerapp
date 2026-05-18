import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyTimerView extends StatefulWidget {
  final int initialSeconds;
  final String studentUsername;
  final int? lecturerSessionId; // Relational foreign key tracker property

  const StudyTimerView({
    super.key,
    this.initialSeconds = 1500,
    required this.studentUsername,
    this.lecturerSessionId,
  });

  @override
  State<StudyTimerView> createState() => _StudyTimerViewState();
}

class _StudyTimerViewState extends State<StudyTimerView> with WidgetsBindingObserver {
  Timer? _timer;
  late int _secondsRemaining;
  bool _isTimerRunning = false;
  bool _cheated = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialSeconds;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isTimerRunning && state == AppLifecycleState.paused) {
      setState(() {
        _cheated = true;
        _isTimerRunning = false;
      });
      _timer?.cancel();
      _saveSessionToDb(success: false);
      _showCheatedDialog();
    }
  }

  void _startTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() {
      _isTimerRunning = true;
      _cheated = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _isTimerRunning = false;
          _saveSessionToDb(success: true);
        }
      });
    });
  }

  void _endSessionEarly() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
    _saveSessionToDb(success: false);
  }

  Future<void> _saveSessionToDb({required bool success}) async {
    final int secondsStudied = widget.initialSeconds - _secondsRemaining;

    try {
      await Supabase.instance.client.from('study_sessions').insert({
        'username': widget.studentUsername,
        'status': success ? 'study sesh success' : 'incomplete',
        'duration_used': secondsStudied,
        'lecturer_session_id': widget.lecturerSessionId, // Links log row back to its class task
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Session completed successfully!' : 'Session logged as incomplete.')),
      );
    } catch (e) {
      debugPrint('Error writing operational log entry metrics: $e');
    }
  }

  void _showCheatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Lockdown Broken')]),
        content: const Text('You exited the tracker system screen area. Session marked incomplete.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  String _formatTime(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_cheated ? 'SESSION FAILED' : (_isTimerRunning ? 'Focusing...' : 'Ready?'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _cheated ? Colors.red : const Color(0xFF194678))),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200, height: 200,
                  child: CircularProgressIndicator(value: _secondsRemaining / widget.initialSeconds, strokeWidth: 12, valueColor: AlwaysStoppedAnimation<Color>(_cheated ? Colors.red : const Color(0xFF6495ED))),
                ),
                Text(_formatTime(_secondsRemaining), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 40),
            !_isTimerRunning
              ? ElevatedButton.icon(onPressed: _startTimer, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6495ED), foregroundColor: Colors.white), icon: const Icon(Icons.play_arrow), label: const Text('Start Tracking'))
              : ElevatedButton.icon(onPressed: _endSessionEarly, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), icon: const Icon(Icons.stop), label: const Text('END Session')),
          ],
        ),
      ),
    );
  }
}