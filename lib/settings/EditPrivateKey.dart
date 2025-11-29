// lib/settings/EditPrivateKey.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whispernet/main.dart';

class edit_private_key extends StatefulWidget {
  final String? pri_key;

  const edit_private_key({Key? key, required this.pri_key}) : super(key: key);

  @override
  State<edit_private_key> createState() => _edit_private_keyState();
}

class _edit_private_keyState extends State<edit_private_key>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pri_key = TextEditingController();
  final _storage = const FlutterSecureStorage();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pri_key.text = widget.pri_key ?? '';
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _pri_key.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _updatePrivateKey() async {
    final text = _pri_key.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Field cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _storage.write(key: 'pri_key', value: text); // await the write
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Private key updated'),
          backgroundColor: Colors.green,
        ),
      );

      // navigate to HomePage clearing stack (same as your original)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error saving private key: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update key')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          // animated gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF0A4F3C),
                  Color(0xFF075E54),
                  Color(0xFF128C7E),
                  Color(0xFF25D366),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.black.withOpacity(0.05)),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: Column(
                  children: [
                    // App bar row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Update Private Key',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // center card
                    Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 720),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter your private key below.\n(Stored only on this device)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // large editable text field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 120,
                                ),
                                child: TextField(
                                  controller: _pri_key,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '-----BEGIN PRIVATE KEY-----',
                                    hintStyle: TextStyle(color: Colors.white38),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSaving
                                        ? null
                                        : () async {
                                            HapticFeedback.lightImpact();
                                            await _updatePrivateKey();
                                          },
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: Text(
                                      _isSaving ? 'Saving...' : 'Update',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      textStyle: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          _pri_key.text = widget.pri_key ?? '';
                                        },
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  label: const Text('Reset'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 16,
                                    ),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: widget.pri_key ?? '',
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Original key copied to clipboard',
                                              ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.white70,
                                  ),
                                  label: const Text(
                                    'Copy original',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Cancel changes?',
                                              ),
                                              content: const Text(
                                                'Discard un-saved changes and go back?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(false),
                                                  child: const Text('No'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(true),
                                                  child: const Text('Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true)
                                            Navigator.pop(context);
                                        },
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
