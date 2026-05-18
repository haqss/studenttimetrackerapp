import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initializing Supabase with your project keys
  await Supabase.initialize(
    url: 'https://tyqftucfwiwerzcuzbpf.supabase.co',
    anonKey: 'sb_publishable_6r9LNUSk3wrY9-6NtpQ6OQ_xyIaVgHt',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}