import 'package:flutter/material.dart';
import 'study_timer_view.dart';
import 'lecturer_sessions_view.dart';
import 'study_goal_view.dart';
import 'student_history_view.dart';
import 'login_page.dart';

class StudentDashboard extends StatefulWidget {
  final String username;
  const StudentDashboard({super.key, required this.username});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  int _customTimerSeconds = 1500;
  int? _selectedSessionId; // Holds the ID of the selected class session task

  @override
  Widget build(BuildContext context) {
    final List<Widget> views = [
      StudyGoalView(studentUsername: widget.username),
      StudyTimerView(
        // The combined key forces a fresh state layout when seconds OR targeted session change
        key: ValueKey('$_customTimerSeconds-$_selectedSessionId'),
        initialSeconds: _customTimerSeconds,
        studentUsername: widget.username,
        lecturerSessionId: _selectedSessionId, // Injected parameter link
      ),
      LecturerSessionsView(
        username: widget.username,
        onSelectSession: (minutes, sessionId) {
          setState(() {
            _customTimerSeconds = minutes * 60;
            _selectedSessionId = sessionId; // Stores selected task ID
            _currentIndex = 1; // Snaps student view directly onto the running clock
          });
        },
      ),
      StudentHistoryView(username: widget.username),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF194678),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: views,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF6495ED),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_calendar), label: 'Set Goal'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Study Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Class Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History Logs'),
        ],
      ),
    );
  }
}