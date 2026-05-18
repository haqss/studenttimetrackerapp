import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminViewModel extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _allSessions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters to expose data safely to the UI layer
  List<Map<String, dynamic>> get allSessions => _allSessions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Filtered Getter: Mapped 1:1 to your diagram parameter "study sesh success"
  List<Map<String, dynamic>> get completedSessions {
    return _allSessions.where((session) => session['status'] == 'study sesh success').toList();
  }

  // Filtered Getter: Mapped to incomplete/cheated sessions
  List<Map<String, dynamic>> get incompleteSessions {
    return _allSessions.where((session) => session['status'] != 'study sesh success').toList();
  }

  // Core Data Fetcher Engine
  Future<void> fetchStudentActivity() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners(); // Tells the UI to draw a loading spinner

    try {
      final response = await _client
          .from('study_sessions')
          .select()
          .order('created_at', ascending: false);

      _allSessions = List<Map<String, dynamic>>.from(response);
    } catch (error) {
      _errorMessage = 'Failed to fetch tracking history: $error';
    } finally {
      _isLoading = false;
      notifyListeners(); // Tells the UI to update with fresh data rows
    }
  }
}