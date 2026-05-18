import 'package:flutter/material.dart';
import 'admin_viewmodel.dart';

class AdminStudentMonitorView extends StatefulWidget {
  const AdminStudentMonitorView({super.key});

  @override
  State<AdminStudentMonitorView> createState() => _AdminStudentMonitorViewState();
}

class _AdminStudentMonitorViewState extends State<AdminStudentMonitorView> {
  final AdminViewModel _viewModel = AdminViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.fetchStudentActivity(); // Initial load trigger
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_viewModel.errorMessage.isNotEmpty) {
          return Center(child: Text(_viewModel.errorMessage, style: const TextStyle(color: Colors.red)));
        }

        final completed = _viewModel.completedSessions;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Completion Verification',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF194678)),
              ),
              const SizedBox(height: 8),
              Text('Total Verified Successful Sessions: ${completed.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 16),
              Expanded(
                child: completed.isEmpty
                    ? const Center(child: Text('No students have successfully completed a session yet today.'))
                    : ListView.builder(
                        itemCount: completed.length,
                        itemBuilder: (context, index) {
                          final session = completed[index];
                          // Convert raw duration metrics cleanly
                          final durationMinutes = (session['duration_used'] ?? 0) ~/ 60;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.greenAccent,
                                child: Icon(Icons.check, color: Colors.darkGreen),
                              ),
                              title: Text(
                                session['username'] ?? 'Unknown Student',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Status: ${session['status']}'),
                              trailing: Text(
                                '$durationMinutes mins tracked',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF194678)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}