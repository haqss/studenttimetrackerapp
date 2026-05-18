import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LecturerSessionsView extends StatefulWidget {
  final String username;
  final Function(int minutes, int sessionId) onSelectSession;

  const LecturerSessionsView({super.key, required this.username, required this.onSelectSession});

  // 🟢 FIXED: Properly overrides and links the native createState method
  @override
  State<LecturerSessionsView> createState() => _LecturerSessionsViewState();
}

class _LecturerSessionsViewState extends State<LecturerSessionsView> {
  late Future<List<Map<String, dynamic>>> _pendingSessionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPendingSessions();
  }

  // REFRESH ENGINE METHOD
  void _refreshPendingSessions() {
    setState(() {
      _pendingSessionsFuture = _loadFilteredSessions();
    });
  }

  // TWO-STEP DIRECT FILTER ENGINE
  Future<List<Map<String, dynamic>>> _loadFilteredSessions() async {
    final client = Supabase.instance.client;

    // Step 1: Pull all session IDs that THIS specific student successfully finished
    final completedResponse = await client
        .from('study_sessions')
        .select('lecturer_session_id')
        .eq('username', widget.username)
        .eq('status', 'study sesh success');

    // Extract raw integers out into a clean list of completed primary keys
    final completedIds = completedResponse
        .map((row) => row['lecturer_session_id'])
        .where((id) => id != null)
        .toList();

    // Step 2: Fetch all global lecturer sessions
    final allSessionsResponse = await client
        .from('lecturer_sessions')
        .select()
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> allSessions = List<Map<String, dynamic>>.from(allSessionsResponse);

    // Step 3: Locally filter out any session whose ID matches the completed list
    if (completedIds.isEmpty) {
      return allSessions;
    }

    return allSessions.where((session) => !completedIds.contains(session['id'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row layout header to place the text title and refresh action side-by-side
          Row(
            // 🟢 FIXED: Corrected spelling to standard MainAxisAlignment.spaceBetween
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Class Sessions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF194678)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF6495ED)),
                tooltip: 'Refresh Pending Assignments',
                onPressed: _refreshPendingSessions,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _pendingSessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return const Center(
                    child: Text(
                      'All class assignments completed! 🎉',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
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
                        trailing: Chip(
                          backgroundColor: const Color(0xFFF2F6F8),
                          label: Text(
                            '${session['allocated_minutes']} mins',
                            style: const TextStyle(color: Color(0xFF194678), fontWeight: FontWeight.bold),
                          ),
                        ),
                        onTap: () {
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