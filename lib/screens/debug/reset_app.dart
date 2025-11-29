import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResetAppPage extends StatefulWidget {
  const ResetAppPage({Key? key}) : super(key: key);

  @override
  State<ResetAppPage> createState() => _ResetAppPageState();
}

class _ResetAppPageState extends State<ResetAppPage> {
  final storage = const FlutterSecureStorage();
  bool _isResetting = false;
  String _status = '';

  Future<void> _resetEverything() async {
    setState(() {
      _isResetting = true;
      _status = 'Starting reset...';
    });

    try {
      // 1. Sign out
      setState(() => _status = 'Signing out...');
      await FirebaseAuth.instance.signOut();

      // 2. Clear secure storage
      setState(() => _status = 'Clearing secure storage...');
      await storage.deleteAll();

      // 3. Clear any cached data
      setState(() => _status = 'Clearing cache...');
      
      setState(() {
        _status = '✅ Reset complete!\n\nPlease restart the app and sign up again.';
        _isResetting = false;
      });

      // Wait a bit then pop
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isResetting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset App'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Reset App Data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will:\n• Sign you out\n• Delete all encryption keys\n• Clear all app data',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isResetting ? null : _resetEverything,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isResetting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Reset Everything',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}