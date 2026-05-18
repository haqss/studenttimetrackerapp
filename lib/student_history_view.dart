import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentHistoryView extends StatefulWidget {
  final String username;
  const StudentHistoryView({super.key, required this.username});

  @override
  State<StudentHistoryView> createState() => _StudentHistoryViewState();
}

class _StudentHistoryViewState extends State<StudentHistoryView> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = Supabase.instance.client
        .from('study_sessions')
        .select()
        .eq('username', widget.username)
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Past Study Sessions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF194678)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return const Center(child: Text('No tracking history found yet.'));
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final bool isSuccess = log['status'] == 'study sesh success';
                    final durationMins = (log['duration_used'] ?? 0) ~/ 60;
                    final durationSecs = (log['duration_used'] ?? 0) % 60;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          child: Icon(
                            isSuccess ? Icons.check_circle : Icons.error_outline,
                            color: isSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          isSuccess ? 'Completed Focus Session' : 'Incomplete Session',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Logged: ${log['created_at'].toString().substring(0, 10)}'),
                        trailing: Text(
                          '${durationMins}m ${durationSecs}s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSuccess ? Colors.green : Colors.red
                          ),
                        ),
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