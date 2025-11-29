import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'add_friend.dart';
import 'models/group_collection.dart';

class ChatScreen extends StatefulWidget {
  final String groupName;
  final String groupId;
  final String userId;

  const ChatScreen({
    Key? key,
    required this.groupName,
    required this.groupId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // State variables
  String? _currentUserId;
  String? _privateKey;
  String? _userName;
  int _messageLimit = 40;
  final int _limitIncrement = 20;
  bool _isSending = false;
  bool _isLoadingMore = false;
  Map<String, Color> _userColors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      _currentUserId = await _storage.read(key: "number");
      _privateKey = await _storage.read(key: "pri_key");
      _userName = await _storage.read(key: "userName") ?? "User";
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error initializing chat: $e");
    }
  }

  void _scrollListener() {
    if (!_scrollController.hasClients || _isLoadingMore) return;

    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        _isLoadingMore = true;
        _messageLimit += _limitIncrement;
      });

      // Reset loading state after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp-like background
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_isLoadingMore) _buildLoadingIndicator(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Text(
              widget.groupName.isNotEmpty
                  ? widget.groupName[0].toUpperCase()
                  : 'G',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // You can add "typing..." or "online" status here
                // Text(
                //   "tap for more info",
                //   style: TextStyle(fontSize: 12, color: Colors.white70),
                // ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 1,
      actions: [
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: const [
                  Icon(Icons.people_alt, color: Colors.black54),
                  SizedBox(width: 10),
                  Text("Add Friend"),
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.black54),
                  SizedBox(width: 10),
                  Text("Group Info"),
                ],
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: Row(
                children: const [
                  Icon(Icons.exit_to_app, color: Colors.black54),
                  SizedBox(width: 10),
                  Text("Exit Group"),
                ],
              ),
            ),
          ],
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: _handleMenuSelection,
        ),
      ],
    );
  }

  void _handleMenuSelection(int value) {
    switch (value) {
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => add_friend(group_name: widget.groupName),
            fullscreenDialog: true,
          ),
        );
        break;
      case 2:
        _showGroupInfo();
        break;
      case 3:
        _showExitConfirmation();
        break;
    }
  }

  Widget _buildMessageList() {
    if (widget.groupId.isEmpty || _currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.groupId)
          .collection(widget.userId)
          .orderBy("sentAt", descending: true)
          .limit(_messageLimit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No messages yet",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start a conversation!",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _decryptMessages(messages),
          builder: (context, decryptedSnapshot) {
            if (!decryptedSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final decryptedMessages = decryptedSnapshot.data!;

            return ListView.builder(
              reverse: true,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              itemCount: decryptedMessages.length,
              itemBuilder: (context, index) {
                final message = decryptedMessages[index];
                final previousMessage = index < decryptedMessages.length - 1
                    ? decryptedMessages[index + 1]
                    : null;

                // Check if we need to show date separator
                bool showDateSeparator = _shouldShowDateSeparator(
                  message['sentAt'],
                  previousMessage?['sentAt'],
                );

                return Column(
                  children: [
                    if (showDateSeparator)
                      _buildDateSeparator(message['sentAt']),
                    _buildMessage(message),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final bool isMyMessage = message['sentBy'] == _currentUserId;
    final String senderName = message['sentByUserName'] ?? 'Unknown';
    final String messageText = message['msgText'] ?? '';
    final dynamic timestamp = message['sentAt'];

    if (isMyMessage) {
      return _buildMyMessage(messageText, timestamp);
    } else {
      return _buildOtherMessage(
        messageText,
        timestamp,
        senderName,
        message['sentBy'],
      );
    }
  }

  Widget _buildMyMessage(String text, dynamic timestamp) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 80, right: 8, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFDCF8C6), // WhatsApp green
          borderRadius: BorderRadius.circular(
            12,
          ).copyWith(bottomRight: const Radius.circular(2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(width: 4),
                Icon(Icons.done_all, size: 14, color: Colors.blue[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherMessage(
    String text,
    dynamic timestamp,
    String senderName,
    String senderId,
  ) {
    final Color userColor = _getUserColor(senderId);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 80, top: 2, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: userColor,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    12,
                  ).copyWith(topLeft: const Radius.circular(2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: userColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(dynamic timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(timestamp),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey[600]),
            onPressed: _handleAttachment,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {}); // To update send button
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: _showEmojiPicker,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            radius: 24,
            child: IconButton(
              icon: Icon(
                _messageController.text.isEmpty ? Icons.mic : Icons.send,
                color: Colors.white,
              ),
              onPressed: _messageController.text.isEmpty
                  ? _handleVoiceMessage
                  : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      HapticFeedback.lightImpact();

      final groupData = await FirebaseFirestore.instance
          .collection("group")
          .doc(widget.groupId)
          .get();

      if (!groupData.exists) {
        throw Exception("Group not found");
      }

      final groupCollection = GroupCollection(
        groupData["createdAt"],
        groupData["createdBy"],
        groupData["id"],
        groupData["members"],
        groupData["modifiedAt"],
        groupData["name"],
        groupData["recentMessages"],
        groupData["type"],
      );

      await groupCollection.sendMessage(
        _currentUserId!,
        widget.groupId,
        messageText,
      );

      _messageController.clear();

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _decryptMessages(
    List<QueryDocumentSnapshot<Object?>> messages,
  ) async {
    if (_privateKey == null || _currentUserId == null) {
      await _initializeChat();
    }

    final List<Map<String, dynamic>> decryptedMessages = [];

    for (final message in messages) {
      try {
        String messageText = message.get("msgText") ?? "";

        // Attempt decryption if the message is for current user
        if (message.get("sentTo") == _currentUserId && _privateKey != null) {
          try {
            messageText = await RSA.decryptPKCS1v15(messageText, _privateKey!);
          } catch (e) {
            // If decryption fails, keep original or show error
            debugPrint("Decryption failed: $e");
            messageText = "[Unable to decrypt message]";
          }
        }

        decryptedMessages.add({
          "msgText": messageText,
          "sentAt": message.get("sentAt"),
          "sentBy": message.get("sentBy"),
          "sentTo": message.get("sentTo"),
          "sentByUserName": message.get("sentByUserName") ?? "Unknown",
        });
      } catch (e) {
        debugPrint("Error processing message: $e");
      }
    }

    return decryptedMessages;
  }

  Color _getUserColor(String userId) {
    if (!_userColors.containsKey(userId)) {
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.pink,
        Colors.indigo,
        Colors.red,
        Colors.amber,
        Colors.cyan,
      ];
      _userColors[userId] = colors[userId.hashCode.abs() % colors.length];
    }
    return _userColors[userId]!;
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  bool _shouldShowDateSeparator(dynamic current, dynamic previous) {
    if (previous == null) return true;

    DateTime currentDate;
    DateTime previousDate;

    if (current is Timestamp) {
      currentDate = current.toDate();
    } else if (current is DateTime) {
      currentDate = current;
    } else {
      return false;
    }

    if (previous is Timestamp) {
      previousDate = previous.toDate();
    } else if (previous is DateTime) {
      previousDate = previous;
    } else {
      return false;
    }

    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }

  void _handleAttachment() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.image, color: Colors.white),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery picker
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.pink,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                // Implement camera
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.insert_drive_file, color: Colors.white),
              ),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                // Implement document picker
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleVoiceMessage() {
    // Implement voice message recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice message feature coming soon')),
    );
  }

  void _showEmojiPicker() {
    // Implement emoji picker
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Emoji picker coming soon')));
  }

  void _showGroupInfo() {
    // Navigate to group info page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Group info page')));
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Group'),
        content: Text('Are you sure you want to exit "${widget.groupName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement exit group logic
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}