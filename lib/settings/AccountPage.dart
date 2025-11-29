// lib/settings/account_page.dart
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../main.dart';
import 'EditPrivateKey.dart';

class accountpage extends StatefulWidget {
  final username, email, number, public_key;

  const accountpage({
    Key? key,
    required this.username,
    required this.email,
    required this.number,
    required this.public_key,
  }) : super(key: key);

  @override
  State<accountpage> createState() =>
      _accountpageState(username, email, number, public_key);
}

class _accountpageState extends State<accountpage>
    with TickerProviderStateMixin {
  // animation controllers
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _scaleController;
  late final AnimationController _rotationController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  // secure storage
  final _storage = const FlutterSecureStorage();

  // state
  String? _privateKey;
  bool _isLoading = true;
  bool _isPrivateKeyVisible = false;

  int _selectedAvatarIndex = 0;

  // avatar options
  final List<Map<String, dynamic>> _avatarOptions = [
    {'emoji': '😊', 'color': Colors.blue},
    {'emoji': '🦁', 'color': Colors.orange},
    {'emoji': '🦊', 'color': Colors.deepOrange},
    {'emoji': '🐼', 'color': Colors.black54},
    {'emoji': '🦄', 'color': Colors.purple},
    {'emoji': '🐸', 'color': Colors.green},
    {'emoji': '🐯', 'color': Colors.amber},
    {'emoji': '🐨', 'color': Colors.grey},
    {'emoji': '🦉', 'color': Colors.brown},
    {'emoji': '🐙', 'color': Colors.pink},
    {'emoji': '🦋', 'color': Colors.indigo},
    {'emoji': '🐢', 'color': Colors.teal},
  ];

  var username, email, number, public_key;

  _accountpageState(this.username, this.email, this.number, this.public_key);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _loadPrivateKey();
    _loadSelectedAvatar();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 120), () {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    });
  }

  Future<void> _loadPrivateKey() async {
    try {
      final pri = await _storage.read(key: 'pri_key');
      if (mounted) {
        setState(() {
          _privateKey = pri;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading private key: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSelectedAvatar() async {
    try {
      final idx = await _storage.read(key: 'selected_avatar');
      if (idx != null && mounted) {
        setState(() {
          _selectedAvatarIndex = int.tryParse(idx) ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading avatar index: $e');
    }
  }

  Future<void> _saveSelectedAvatar(int index) async {
    try {
      await _storage.write(key: 'selected_avatar', value: index.toString());
      if (mounted) {
        setState(() => _selectedAvatarIndex = index);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving avatar: $e');
    }
  }

  Future<void> _deletePrivateKeyAndLogout() async {
    try {
      await _storage.delete(key: 'pri_key'); // proper delete (device-only)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Private Key Deleted'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error deleting private key: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete key')));
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
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
            child: _isLoading ? _buildLoadingState() : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Color(0xFF0A4F3C),
            Color(0xFF075E54),
            Color(0xFF128C7E),
            Color(0xFF25D366),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.black.withOpacity(0.06)),
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
              top: 90,
              left: -40,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 180,
              right: -20,
              child: Transform.rotate(
                angle: -_rotationAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.06),
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

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildCustomAppBar(),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildProfileSection(),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildInfoCard(),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
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
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showEditMenu,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _avatarOptions[_selectedAvatarIndex]['color']
                      .withOpacity(0.28),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Text(
                    _avatarOptions[_selectedAvatarIndex]['emoji'],
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: const Color(0xFF075E54),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            username.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Username', username.toString(), Icons.person),
          const SizedBox(height: 12),
          _buildInfoItem('Email', email.toString(), Icons.email),
          const SizedBox(height: 12),
          _buildInfoItem('Phone', number.toString(), Icons.phone),
          const SizedBox(height: 20),
          _buildKeySection(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeySection() {
    final isPrivateMissing = _privateKey == null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                'Encryption Keys',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildKeyItem(
            title: 'Public Key',
            value: public_key?.toString() ?? '',
            isPublic: true,
          ),
          const SizedBox(height: 12),
          _buildKeyItem(
            title: 'Private Key',
            value: _privateKey ?? 'Not found',
            isPublic: false,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyItem({
    required String title,
    required String value,
    required bool isPublic,
  }) {
    final isPrivateEmpty = !isPublic && (_privateKey == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            if (!isPublic) const SizedBox(width: 8),
            if (!isPublic)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPrivateKeyVisible = !_isPrivateKeyVisible;
                  });
                },
                child: Icon(
                  _isPrivateKeyVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white.withOpacity(0.6),
                  size: 18,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPublic || _isPrivateKeyVisible ? value : '••••••••••••••••••',
                style: TextStyle(
                  fontSize: 12,
                  color: isPrivateEmpty
                      ? Colors.red[300]
                      : Colors.white.withOpacity(0.78),
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isPrivateEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildKeyActionButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: () {
                          final text = isPublic ? value : (_privateKey ?? '');
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                            ),
                          );
                        },
                      ),
                    ),
                    if (!isPublic) const SizedBox(width: 8),
                    if (!isPublic)
                      Expanded(
                        child: _buildKeyActionButton(
                          icon: Icons.edit,
                          label: 'Edit',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    edit_private_key(pri_key: _privateKey),
                              ),
                            );
                          },
                        ),
                      ),
                    if (!isPublic) const SizedBox(width: 8),
                    if (!isPublic)
                      Expanded(
                        child: _buildKeyActionButton(
                          icon: Icons.delete,
                          label: 'Delete',
                          isDestructive: true,
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Private Key'),
                                content: const Text(
                                  "This will delete your private key. You won't be able to decrypt messages. Continue?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true)
                              await _deletePrivateKeyAndLogout();
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDestructive
                  ? Colors.red.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDestructive ? Colors.red[300] : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDestructive ? Colors.red[300] : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatarOptions.length,
              itemBuilder: (context, index) {
                final avatar = _avatarOptions[index];
                final isSelected = index == _selectedAvatarIndex;
                return GestureDetector(
                  onTap: () => _saveSelectedAvatar(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: avatar['color'].withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF075E54)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatar['emoji'],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('QR Code'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
