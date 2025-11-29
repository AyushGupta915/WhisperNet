// lib/screens/add_friend.dart
import 'dart:ui';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:whispernet/screens/models/group_collection.dart';

import 'models/user.dart';

class add_friend extends StatefulWidget {
  final String group_name;

  const add_friend({Key? key, required String this.group_name})
      : super(key: key);

  @override
  State<add_friend> createState() => _add_friendState(group_name);
}

class _add_friendState extends State<add_friend> with TickerProviderStateMixin {
  final TextEditingController _friendId = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final String group_name;

  bool _isProcessing = false;
  String? _errorText;

  // animation controllers for background decoration
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  _add_friendState(String this.group_name);

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _rotationAnimation =
        Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotationController);
  }

  @override
  void dispose() {
    _friendId.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _addFriend() async {
    final trimmed = _friendId.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorText = 'Field cannot be empty');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Field cannot be empty"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please wait — adding user..."),
        duration: Duration(seconds: 2),
      ));

      // getting the number of current user
      var number = await _storage.read(key: "number");
      if (number == null) {
        throw Exception('Your number not found in secure storage');
      }

      final groupId = number + "+" + group_name;

      final groupSnapshot = await FirebaseFirestore.instance
          .collection("group")
          .doc(groupId)
          .get();

      if (!groupSnapshot.exists) {
        throw Exception('Group not found');
      }

      final group_collection_obj = GroupCollection(
        groupSnapshot["createdAt"],
        groupSnapshot["createdBy"],
        groupSnapshot["id"],
        groupSnapshot["members"],
        groupSnapshot["modifiedAt"],
        groupSnapshot["name"],
        groupSnapshot["recentMessages"],
        groupSnapshot["type"],
      );

      // normalize friend id (you used +91)
      final friend_id = "+91" + trimmed;

      final friend_exist = await FirebaseFirestore.instance
          .collection("user")
          .doc(friend_id)
          .get();

      if (!friend_exist.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("The user doesn't exist"),
          backgroundColor: Colors.red,
        ));
        setState(() => _isProcessing = false);
        return;
      }

      if (group_collection_obj.does_friendId_exist(friend_id)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("The user is already in the group"),
          backgroundColor: Colors.red,
        ));
        setState(() => _isProcessing = false);
        return;
      }

      // add user to group object using their public key
      group_collection_obj.add_user(friend_id, friend_exist["public_key"]);

      await FirebaseFirestore.instance
          .collection("group")
          .doc(groupId)
          .update(group_collection_obj.toJson());

      // update group metadata for current user
      var obj1 = FirebaseFirestore.instance
          .collection('group_metadata')
          .doc(number)
          .collection("group_name")
          .doc(groupId);

      var GroupMetaData = {
        "group_name": group_name,
        "group_id": groupId,
        "last_msg_time": DateTime.now(),
        "msg": "New User added",
        "type": "2",
      };
      await obj1.set(GroupMetaData);

      // update group metadata for friend
      var obj2 = FirebaseFirestore.instance
          .collection('group_metadata')
          .doc(friend_id)
          .collection("group_name")
          .doc(groupId);

      var GroupMetaData2 = {
        "group_name": group_name,
        "group_id": groupId,
        "last_msg_time": DateTime.now(),
        "msg": "New User added",
        "type": "2",
      };
      await obj2.set(GroupMetaData2);

      // update friend's user doc to include this group if not present
      final data = await FirebaseFirestore.instance
          .collection("user")
          .doc(friend_id)
          .get();

      final obj = user(
        data['displayName'],
        data['email'],
        data['groups'],
        data['photoURL'],
        data['public_key'],
        data['uid'],
      );

      if (!obj.does_group_exist(groupId.trim())) {
        obj.add_groupid(groupId.trim());
        await FirebaseFirestore.instance
            .collection("user")
            .doc(friend_id)
            .update(obj.toJson());
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("User Added"),
        backgroundColor: Colors.green,
      ));

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error adding friend: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A4F3C),
                  Color(0xFF075E54),
                  Color(0xFF128C7E),
                  Color(0xFF25D366),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.black.withOpacity(0.05)),
            ),
          ),

          // floating elements
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: 80,
                    left: -50,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.08), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 160,
                    right: -30,
                    child: Transform.rotate(
                      angle: -_rotationAnimation.value,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.06), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    // custom app bar row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Add Friend',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // center card
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 720),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 14)],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Friend Number',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          // phone input
                          IntlPhoneField(
                            controller: _friendId,
                            keyboardType: TextInputType.number,
                            initialCountryCode: 'IN',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.02),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              hintText: 'Enter number (without +91)',
                              hintStyle: TextStyle(color: Colors.white38),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onChanged: (val) {
                              if (_errorText != null) setState(() => _errorText = null);
                            },
                          ),

                          if (_errorText != null) ...[
                            const SizedBox(height: 10),
                            Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
                          ],

                          const SizedBox(height: 20),

                          // buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _addFriend,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Add', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () {
                                        _friendId.clear();
                                        setState(() => _errorText = null);
                                      },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Clear', style: TextStyle(color: Colors.white70)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
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
