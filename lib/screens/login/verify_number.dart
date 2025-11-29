import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../../main.dart';

enum Status { Waiting, Error, Generating }

class VerifyNumber extends StatefulWidget {
  const VerifyNumber({
    Key? key,
    this.number,
    this.username,
    this.email,
    this.page_name,
  }) : super(key: key);

  final String? number;
  final String? username;
  final String? email;
  final String? page_name;

  @override
  State<VerifyNumber> createState() => _VerifyNumberState();
}

class _VerifyNumberState extends State<VerifyNumber>
    with TickerProviderStateMixin {
  // State variables
  Status _status = Status.Waiting;
  String? _verificationId;
  final _otpController = TextEditingController();

  // RSA variables
  var key, pub_key, pri_key;

  // Storage
  final storage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  // OTP boxes focus nodes
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _verifyPhoneNumber();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future _verifyPhoneNumber() async {
    if (widget.number == null) return;

    _auth.verifyPhoneNumber(
      phoneNumber: widget.number!,
      verificationCompleted: (phonesAuthCredentials) async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Auto-verification completed"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      verificationFailed: (verificationFailed) async {
        if (mounted) {
          setState(() => _status = Status.Error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Verification Failed"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      codeSent: (verificationId, resendingToken) async {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("OTP Sent Successfully"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) async {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
          });
        }
      },
    );
  }

  Future _sendCodeToFirebase({String? code}) async {
    if (_verificationId == null || code == null) return;

    setState(() => _status = Status.Generating);

    // Show an early snackbar depending on flow
    final isSignUp = widget.page_name == "signup";
    if (isSignUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Generating encryption keys..."),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Signing you in..."),
          duration: Duration(seconds: 2),
        ),
      );
    }

    var credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    );

    try {
      final userCredential = await _auth.signInWithCredential(credential);

      // If signup flow, generate keys and create user documents
      if (isSignUp) {
        // Generate RSA keys
        key = await RSA.generate(2048);
        setState(() {
          pub_key = key.publicKey;
          pri_key = key.privateKey;
        });

        // Store keys locally
        await storage.write(key: "pri_key", value: pri_key);
        await storage.write(key: "number", value: widget.number);

        // Create user document
        var obj1 = FirebaseFirestore.instance
            .collection('user')
            .doc(widget.number);
        var userData = {
          "displayName": widget.username,
          "email": widget.email ?? "",
          "groups": [widget.number],
          "photoURL": "",
          "uid": widget.number,
          "public_key": pub_key,
          "status": "Online",
        };
        await obj1.set(userData);

        // Create group
        var obj2 = FirebaseFirestore.instance
            .collection('group')
            .doc(widget.number);
        var groupData = {
          "createdAt": DateTime.now(),
          "createdBy": widget.number,
          "members": [
            {"user_id": widget.number, "public_key": pub_key},
          ],
          "id": widget.number,
          "modifiedAt": "",
          "name": "Me",
          "recentMessages": {
            "message_text": "",
            "readBy": "",
            "sentAt": "",
            "sentBy": "",
          },
          "type": "1",
        };
        await obj2.set(groupData);

        // Create group metadata
        var obj3 = FirebaseFirestore.instance
            .collection('group_metadata')
            .doc(widget.number)
            .collection("group_name")
            .doc(widget.number);

        var groupMetaData = {
          "group_name": "Me",
          "group_id": widget.number,
          "last_msg_time": DateTime.now(),
          "msg": "Say Hi",
          "type": "1",
        };
        await obj3.set(groupMetaData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Setup Complete!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Non-signup flows (sign-in / edit number): just store number and show appropriate message
        await storage.write(key: "number", value: widget.number);
        if (mounted) {
          final msg = widget.page_name == "edit_number"
              ? "Number updated!"
              : "Welcome back!";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
          );
        }
      }

      // Navigate to Home
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    } catch (error) {
      // On error, reset inputs and status
      setState(() {
        _otpController.clear();
        for (var controller in _controllers) {
          controller.clear();
        }
        _status = Status.Error;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

Future<void> generateCleanKeys() async {
  final keyPair = await RSA.generate(2048);

  String cleanPublicKey = keyPair.publicKey
      .replaceAll("-----BEGIN RSA PUBLIC KEY-----", "")
      .replaceAll("-----END RSA PUBLIC KEY-----", "")
      .replaceAll("\n", "")
      .trim();

  String cleanPrivateKey = keyPair.privateKey
      .replaceAll("-----BEGIN RSA PRIVATE KEY-----", "")
      .replaceAll("-----END RSA PRIVATE KEY-----", "")
      .replaceAll("\n", "")
      .trim();

  print("Public Key (clean): $cleanPublicKey");
  print("Private Key (clean): $cleanPrivateKey");
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),

          // Floating decorative elements
          _buildFloatingElements(),

          // Main content
          SafeArea(
            child: _status == Status.Generating
                ? _buildGeneratingView()
                : _status != Status.Error
                ? _buildOTPView()
                : _buildErrorView(),
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(color: Colors.black.withOpacity(0.1)),
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
            Positioned(
              top: 300,
              right: -30,
              child: Transform.rotate(
                angle: -_rotationAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
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
              bottom: 200,
              left: 20,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.5,
                child: Container(
                  width: 80,
                  height: 80,
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

  Widget _buildOTPView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildHeader(),
            ),
          ),
          const SizedBox(height: 50),
          FadeTransition(opacity: _fadeAnimation, child: _buildOTPBoxes()),
          const SizedBox(height: 40),
          FadeTransition(opacity: _fadeAnimation, child: _buildResendButton()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'OTP Verification',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the code sent to',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
        ),
        const SizedBox(height: 4),
        Text(
          widget.number ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOTPBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _controllers[index].text.isNotEmpty
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }

              // Check if all boxes are filled
              String otp = _controllers.map((c) => c.text).join();
              if (otp.length == 6) {
                _sendCodeToFirebase(code: otp);
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildResendButton() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the OTP?",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _status = Status.Waiting;
                  for (var controller in _controllers) {
                    controller.clear();
                  }
                });
                _verifyPhoneNumber();
              },
              child: const Text(
                'RESEND OTP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer, color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 6),
              Text(
                'Code expires in 60 seconds',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.white.withOpacity(0.9),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Verification Failed',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The code entered is invalid',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF075E54),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Edit Number',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _status = Status.Waiting;
                for (var controller in _controllers) {
                  controller.clear();
                }
              });
              _verifyPhoneNumber();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Resend OTP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingView() {
    final isSignUp = widget.page_name == "signup";
    final title = isSignUp ? 'Setting up your account' : 'Completing sign in';
    final subtitle = isSignUp
        ? 'Generating encryption keys...'
        : 'Verifying and signing you in...';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}