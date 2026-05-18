import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyGoalView extends StatefulWidget {
  final String studentUsername;
  const StudyGoalView({super.key, required this.studentUsername});

  @override
  State<StudyGoalView> createState() => _StudyGoalViewState();
}

class _StudyGoalViewState extends State<StudyGoalView> {
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Autofetch the username directly into the text field property state
    _usernameController.text = widget.studentUsername;
  }

  // 🟢 THIS IS THE METHOD THAT WAS MISSING 🟢
  Future<void> _saveGoalToDb() async {
    final username = _usernameController.text.trim();
    final timeInput = _timeController.text.trim();

    if (username.isEmpty || timeInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final int? minutes = int.tryParse(timeInput);
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of minutes')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Insert row into your self_study_goals table
      await Supabase.instance.client.from('self_study_goals').insert({
        'username': username,
        'target_minutes': minutes,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily self-study goal stored successfully!')),
      );

      _timeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save goal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Determine Your Self-Study Time',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF194678),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calculate your target daily study volume and log it to set your expectations for today\'s tracking sessions.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              readOnly: true, // Protected student identity field
              decoration: const InputDecoration(
                labelText: 'Student Name / Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Time (in minutes)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.hourglass_top_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveGoalToDb, // Now cleanly links to the method above!
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6495ED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Store Goal in Database', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}