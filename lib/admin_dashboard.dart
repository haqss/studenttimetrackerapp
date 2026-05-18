import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'admin_viewmodel.dart'; // Ensure this matches your ViewModel file name

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;
  late Future<List<Map<String, dynamic>>> _adminSessionsFuture;
  final AdminViewModel _monitorViewModel = AdminViewModel();

  @override
  void initState() {
    super.initState();
    _refreshSessions();
    _monitorViewModel.fetchStudentActivity(); // Pre-load student tracking data logs
  }

  void _refreshSessions() {
    setState(() {
      _adminSessionsFuture = Supabase.instance.client
          .from('lecturer_sessions')
          .select()
          .order('created_at', ascending: false);
    });
    _monitorViewModel.fetchStudentActivity(); // Sync logs when refreshing
  }

  Future<void> _deleteSession(int id) async {
    try {
      await Supabase.instance.client
          .from('lecturer_sessions')
          .delete()
          .eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session removed successfully!')),
      );
      _refreshSessions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define our two primary operational dashboard views
    final List<Widget> _tabs = [
      _buildManageSessionsTab(),
      _buildStudentMonitorTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTab == 0 ? 'Lecturer Admin Dashboard' : 'Student Verification Logs'),
        backgroundColor: const Color(0xFF194678),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSessions,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        selectedItemColor: const Color(0xFF6495ED),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Manage Sessions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Monitor Students',
          ),
        ],
      ),
      // Floating Action Button only active when on the session manager tab window view
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF6495ED),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => CreateSessionModal(onSuccess: _refreshSessions),
                );
              },
            )
          : null,
    );
  }

  // TAB 1: Core Layout Builder for managing the assignment sessions list entries
  Widget _buildManageSessionsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminSessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const Center(child: Text('No study sessions created yet. Click "+" to create one.'));
        }

        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(session['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${session['description'] ?? ''}\nDuration: ${session['allocated_minutes']} mins'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF6495ED)),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => EditSessionModal(
                            sessionData: session,
                            onSuccess: _refreshSessions,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteSession(session['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // TAB 2: List layout leveraging AnimatedBuilder to consume our isolated AdminViewModel
  Widget _buildStudentMonitorTab() {
    return AnimatedBuilder(
      animation: _monitorViewModel,
      builder: (context, child) {
        if (_monitorViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_monitorViewModel.errorMessage.isNotEmpty) {
          return Center(child: Text(_monitorViewModel.errorMessage, style: const TextStyle(color: Colors.red)));
        }

        final completed = _monitorViewModel.completedSessions;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Completion Verification',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF194678)),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Verified Successful Sessions: ${completed.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: completed.isEmpty
                    ? const Center(child: Text('No students have successfully completed a session yet.'))
                    : ListView.builder(
                        itemCount: completed.length,
                        itemBuilder: (context, index) {
                          final session = completed[index];
                          final durationMinutes = (session['duration_used'] ?? 0) ~/ 60;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE8F5E9),
                                child: Icon(Icons.done, color: Colors.green),
                              ),
                              title: Text(
                                session['username'] ?? 'Unknown Student',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Status: ${session['status']}'),
                              trailing: Chip(
                                side: BorderSide.none,
                                backgroundColor: const Color(0xFFF2F6F8),
                                label: Text(
                                  '$durationMinutes mins focused',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF194678)),
                                ),
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

// ==========================================
// MODAL COMPONENT: CREATE SESSION DIALOG
// ==========================================
class CreateSessionModal extends StatefulWidget {
  final VoidCallback onSuccess;
  const CreateSessionModal({super.key, required this.onSuccess});

  @override
  State<CreateSessionModal> createState() => _CreateSessionModalState();
}

class _CreateSessionModalState extends State<CreateSessionModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();
  bool _isSaving = false;

  Future<void> _submitSession() async {
    if (_titleController.text.trim().isEmpty || _timeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Allocation Time are required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.from('lecturer_sessions').insert({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'allocated_minutes': int.parse(_timeController.text.trim()),
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Publish New Session Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
          TextField(controller: _timeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF194678), foregroundColor: Colors.white),
              onPressed: _isSaving ? null : _submitSession,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Session'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ==========================================
// MODAL COMPONENT: EDIT SESSION DIALOG
// ==========================================
class EditSessionModal extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final VoidCallback onSuccess;
  const EditSessionModal({super.key, required this.sessionData, required this.onSuccess});

  @override
  State<EditSessionModal> createState() => _EditSessionModalState();
}

class _EditSessionModalState extends State<EditSessionModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.sessionData['title']?.toString() ?? '';
    _descController.text = widget.sessionData['description']?.toString() ?? '';
    _timeController.text = widget.sessionData['allocated_minutes']?.toString() ?? '';
  }

  Future<void> _updateSession() async {
    if (_titleController.text.trim().isEmpty || _timeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fields cannot be blank')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client
          .from('lecturer_sessions')
          .update({
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'allocated_minutes': int.parse(_timeController.text.trim()),
          })
          .eq('id', widget.sessionData['id']);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Modify Session Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
          TextField(controller: _timeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6495ED), foregroundColor: Colors.white),
              onPressed: _isSaving ? null : _updateSession,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}