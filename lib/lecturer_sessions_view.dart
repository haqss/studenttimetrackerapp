import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LecturerSessionsView extends StatefulWidget {
  final String username;
  final Function(int minutes, int sessionId) onSelectSession;

  const LecturerSessionsView({super.key, required this.username, required this.onSelectSession});

  @override
  State<LecturerSessionsView> createState() => _LecturerSessionsViewState();
}

class _LecturerSessionsViewState extends State<LecturerSessionsView> {
  late Future<List<Map<String, dynamic>>> _pendingSessionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchPendingSessions();
  }

  void _fetchPendingSessions() {
    setState(() {
      // Pulls lecturer tasks along with matching status mappings
      _pendingSessionsFuture = Supabase.instance.client
          .from('lecturer_sessions')
          .select('''
            *,
            study_sessions(status, username)
          ''')
          .not('study_sessions.status', 'eq', 'study sesh success');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Class Sessions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF194678))),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _pendingSessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                // Filters out any task that has a successful completion log from this user
                final sessions = (snapshot.data ?? []).where((session) {
                  final histories = session['study_sessions'] as List?;
                  if (histories == null) return true;
                  return !histories.any((log) => log['username'] == widget.username && log['status'] == 'study sesh success');
                }).toList();

                if (sessions.isEmpty) {
                  return const Center(child: Text('All class assignments completed! 🎉', style: TextStyle(fontSize: 16, color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.assignment, color: Color(0xFF6495ED)),
                        title: Text(session['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(session['description'] ?? ''),
                        trailing: Chip(label: Text('${session['allocated_minutes']} mins')),
                        onTap: () {
                          // Passes parameters smoothly back to dashboard state triggers
                          widget.onSelectSession(session['allocated_minutes'], session['id']);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}