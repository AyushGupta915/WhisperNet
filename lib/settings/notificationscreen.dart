// lib/settings/NotificationsSettings.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:ui';
import 'dart:math' as math;

class NotificationsSettings extends StatefulWidget {
  const NotificationsSettings({Key? key}) : super(key: key);

  @override
  State<NotificationsSettings> createState() => _NotificationsSettingsState();
}

class _NotificationsSettingsState extends State<NotificationsSettings>
    with TickerProviderStateMixin {
  // Animation controller
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Notification preferences
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _callNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _previewMessage = true;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPreferences();
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
  }

  Future<void> _loadPreferences() async {
    // Load saved preferences
    final messageNotif = await _storage.read(key: 'message_notifications');
    final groupNotif = await _storage.read(key: 'group_notifications');
    final sound = await _storage.read(key: 'sound_enabled');
    final vibration = await _storage.read(key: 'vibration_enabled');
    final preview = await _storage.read(key: 'preview_message');

    if (mounted) {
      setState(() {
        _messageNotifications = messageNotif != 'false';
        _groupNotifications = groupNotif != 'false';
        _soundEnabled = sound != 'false';
        _vibrationEnabled = vibration != 'false';
        _previewMessage = preview != 'false';
      });
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          _buildAnimatedBackground(),
          _buildFloatingElements(),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSection(
                          title: 'MESSAGE NOTIFICATIONS',
                          items: [
                            _buildSwitchTile(
                              icon: Icons.message,
                              title: 'Message Notifications',
                              subtitle:
                                  'Receive notifications for new messages',
                              value: _messageNotifications,
                              onChanged: (value) {
                                setState(() => _messageNotifications = value);
                                _savePreference('message_notifications', value);
                              },
                            ),
                            _buildSwitchTile(
                              icon: Icons.group,
                              title: 'Group Notifications',
                              subtitle: 'Receive notifications from groups',
                              value: _groupNotifications,
                              onChanged: (value) {
                                setState(() => _groupNotifications = value);
                                _savePreference('group_notifications', value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'NOTIFICATION PREFERENCES',
                          items: [
                            _buildSwitchTile(
                              icon: Icons.volume_up,
                              title: 'Sound',
                              subtitle: 'Play sound for notifications',
                              value: _soundEnabled,
                              onChanged: (value) {
                                setState(() => _soundEnabled = value);
                                _savePreference('sound_enabled', value);
                              },
                            ),
                            _buildSwitchTile(
                              icon: Icons.vibration,
                              title: 'Vibration',
                              subtitle: 'Vibrate for notifications',
                              value: _vibrationEnabled,
                              onChanged: (value) {
                                setState(() => _vibrationEnabled = value);
                                _savePreference('vibration_enabled', value);
                              },
                            ),
                            _buildSwitchTile(
                              icon: Icons.preview,
                              title: 'Message Preview',
                              subtitle: 'Show message content in notification',
                              value: _previewMessage,
                              onChanged: (value) {
                                setState(() => _previewMessage = value);
                                _savePreference('preview_message', value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A4F3C),
            const Color(0xFF075E54),
            const Color(0xFF128C7E),
            const Color(0xFF25D366),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: 100,
              left: -50,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
