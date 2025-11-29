// lib/settings/AppearanceSettings.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:ui';
import 'dart:math' as math;

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({Key? key}) : super(key: key);

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Settings
  String _selectedTheme = 'system';
  double _fontSize = 16.0;
  String _selectedFont = 'Default';
  bool _useWallpaper = true;

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
    final theme = await _storage.read(key: 'theme');
    final fontSize = await _storage.read(key: 'font_size');
    final font = await _storage.read(key: 'font_family');
    final wallpaper = await _storage.read(key: 'use_wallpaper');

    if (mounted) {
      setState(() {
        _selectedTheme = theme ?? 'system';
        _fontSize = double.tryParse(fontSize ?? '16') ?? 16.0;
        _selectedFont = font ?? 'Default';
        _useWallpaper = wallpaper != 'false';
      });
    }
  }

  Future<void> _savePreference(String key, String value) async {
    await _storage.write(key: key, value: value);
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
          _buildAnimatedBackground(),
          _buildFloatingElements(),

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
                          title: 'THEME',
                          child: Column(
                            children: [
                              _buildThemeOption('Light', 'light'),
                              _buildThemeOption('Dark', 'dark'),
                              _buildThemeOption('System Default', 'system'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'FONT',
                          child: Column(
                            children: [
                              _buildFontSizeSlider(),
                              const SizedBox(height: 16),
                              _buildFontFamilySelector(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'CHAT WALLPAPER',
                          child: _buildWallpaperSettings(),
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
              top: 150,
              right: -50,
              child: Transform.rotate(
                angle: -_rotationAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
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
            'Appearance',
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

  Widget _buildSection({required String title, required Widget child}) {
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildThemeOption(String title, String value) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: _selectedTheme,
      activeColor: Colors.white,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => _selectedTheme = newValue);
          _savePreference('theme', newValue);
        }
      },
    );
  }

  Widget _buildFontSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Size: ${_fontSize.toInt()}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Slider(
          value: _fontSize,
          min: 12,
          max: 24,
          divisions: 12,
          activeColor: Colors.white,
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: (value) {
            setState(() => _fontSize = value);
            _savePreference('font_size', value.toString());
          },
        ),
      ],
    );
  }

  Widget _buildFontFamilySelector() {
    final fonts = ['Default', 'Roboto', 'Open Sans', 'Lato', 'Montserrat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Font Family',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: fonts.map((font) {
            final isSelected = _selectedFont == font;
            return ChoiceChip(
              label: Text(font),
              selected: isSelected,
              selectedColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF075E54) : Colors.white,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFont = font);
                  _savePreference('font_family', font);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWallpaperSettings() {
    return SwitchListTile(
      title: const Text(
        'Use Chat Wallpaper',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Show wallpaper in chat background',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      value: _useWallpaper,
      activeColor: Colors.white,
      activeTrackColor: Colors.white.withOpacity(0.5),
      onChanged: (value) {
        setState(() => _useWallpaper = value);
        _savePreference('use_wallpaper', value.toString());
      },
    );
  }
}
