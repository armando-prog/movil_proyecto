import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database_service.dart';
import 'data/models.dart';
import 'ui/auth_page.dart';
import 'ui/garden_shell.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BroteApp());
}

class BroteApp extends StatelessWidget {
  const BroteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brote — bitácora verde',
      debugShowCheckedModeBanner: false,
      theme: buildBroteTheme(),
      home: const AppGate(),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  final _database = DatabaseService.instance;
  BroteUser? _user;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      await _database.open();
      final preferences = await SharedPreferences.getInstance();
      final userId = preferences.getInt('session_user_id');
      if (userId != null) {
        _user = await _database.getUser(userId);
        if (_user == null) await preferences.remove('session_user_id');
      }
    } catch (error) {
      _error = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signedIn(BroteUser user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('session_user_id', user.id!);
    if (mounted) setState(() => _user = user);
  }

  Future<void> _signedOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('session_user_id');
    if (mounted) setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_outlined, size: 44),
                const SizedBox(height: 16),
                const Text('No pudimos abrir tu jardín.'),
                const SizedBox(height: 8),
                Text(
                  'Detalle: $_error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() {
                    _loading = true;
                    _error = null;
                    _restoreSession();
                  }),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_user == null) {
      return AuthPage(database: _database, onSignedIn: _signedIn);
    }
    return GardenShell(
      key: ValueKey(_user!.id),
      user: _user!,
      database: _database,
      onSignedOut: _signedOut,
      onUserChanged: (user) => setState(() => _user = user),
    );
  }
}
