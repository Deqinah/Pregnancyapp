import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'pchat_screen.dart';

class ChatScreen extends StatefulWidget {
  final String doctorName;
  final String doctorId;
  final bool isDoctor;

  const ChatScreen({
    super.key,
    required this.doctorName,
    required this.doctorId,
    this.isDoctor = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isVoiceMode = true;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSending = false;
  String _chatId = '';

  @override
  void initState() {
    super.initState();
    _chatId = _generateChatId();

    _messageController.addListener(() {
      setState(() {
        _isVoiceMode = _messageController.text.isEmpty;
      });
    });
  }

  String _generateChatId() {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
    final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
    return '${doctorId}_$patientId';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
    return DateFormat('MMM d, y').format(messageTime);
  }

  Future<void> _sendMessage({String? text, String? audioUrl}) async {
    if (_isSending || (text == null && audioUrl == null)) return;

    setState(() {
      _isSending = true;
    });

    try {
      final chatDoc = _firestore.collection('chats').doc(_chatId);
      final doc = await chatDoc.get();

      if (!doc.exists) {
        await chatDoc.set({
          'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
          'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'participants': [
            widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
            widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
          ],
          'lastMessage': text ?? 'Audio message',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      } else {
        await chatDoc.update({
          'lastMessage': text ?? 'Audio message',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }

      final message = {
        if (text != null) 'text': text,
        if (audioUrl != null) 'audioUrl': audioUrl,
        'senderId': _auth.currentUser?.uid,
        'receiverId': widget.doctorId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': true,
      };

      await chatDoc.collection('messages').add(message);

      if (text != null) {
        _messageController.clear();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _sendMessage(text: text.trim());
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isVoiceMode
              ? IconButton(
                  icon: const Icon(Icons.mic, color: Colors.blue),
                  onPressed: () {
                    // Add voice recording logic here
                  },
                )
              : IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.blue),
                  onPressed: _isSending
                      ? null
                      : () {
                          if (_messageController.text.trim().isNotEmpty) {
                            _sendMessage(text: _messageController.text.trim());
                          }
                        },
                ),
        ],
      ),
    );
  }

  Widget _buildMessage(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == _auth.currentUser?.uid;
    final hasText = data['text'] != null;
    final hasAudio = data['audioUrl'] != null;
    final timestamp = data['timestamp'] as Timestamp;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: isMe ? 16 : 8,
      ),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isMe) // Only show sender name for my messages
            Text(
              '', // Or you can use the user's name here
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          GestureDetector(
            onTap: hasAudio
                ? () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  }
                : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: hasAudio
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPlaying ? Icons.stop : Icons.play_arrow,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        const Text('Audio message'),
                      ],
                    )
                  : Text(hasText ? data['text'] : ''),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(timestamp),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: Row(
    children: [
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorProfileScreen(
                doctorId: widget.doctorId,
              ),
            ),
          );
        },
        child: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue[100],
          child: Text(
            widget.doctorName.isNotEmpty 
                ? widget.doctorName[0].toUpperCase()
                : 'D',
            style: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(widget.doctorName),
    ],
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.call),
      onPressed: () {
        // Add call functionality here
      },
    ),
  ],
),
 backgroundColor: Colors.white, 
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    return _buildMessage(message);
                  },
                );
              },
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}













// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'pchat_screen.dart'; // Added missing import

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isVoiceMode = true;
//   bool _isRecording = false;
//   bool _isPlaying = false;
//   bool _isSending = false;
//   String _chatId = '';

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();

//     _messageController.addListener(() {
//       setState(() {
//         _isVoiceMode = _messageController.text.isEmpty;
//       });
//     });
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     if (_isSending || (text == null && audioUrl == null)) return;

//     setState(() {
//       _isSending = true;
//     });

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();

//       if (!doc.exists) {
//         await chatDoc.set({
//           'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           'createdAt': FieldValue.serverTimestamp(),
//           'participants': [
//             widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//             widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           ],
//           'lastMessage': text ?? 'Audio message',
//           'lastMessageTime': FieldValue.serverTimestamp(),
//         });
//       } else {
//         await chatDoc.update({
//           'lastMessage': text ?? 'Audio message',
//           'lastMessageTime': FieldValue.serverTimestamp(),
//         });
//       }

//       final message = {
//         if (text != null) 'text': text,
//         if (audioUrl != null) 'audioUrl': audioUrl,
//         'senderId': _auth.currentUser?.uid,
//         'receiverId': widget.doctorId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': true,
//       };

//       await chatDoc.collection('messages').add(message);

//       if (text != null) {
//         _messageController.clear();
//       }

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (_scrollController.hasClients) {
//           _scrollController.animateTo(
//             0,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//         }
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send message: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSending = false;
//         });
//       }
//     }
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (text) {
//                   if (text.trim().isNotEmpty) {
//                     _sendMessage(text: text.trim());
//                   }
//                 },
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _isVoiceMode
//               ? IconButton(
//                   icon: const Icon(Icons.mic, color: Colors.blue),
//                   onPressed: () {
//                     // Add voice recording logic here
//                   },
//                 )
//               : IconButton(
//                   icon: _isSending
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(Icons.send, color: Colors.blue),
//                   onPressed: _isSending
//                       ? null
//                       : () {
//                           if (_messageController.text.trim().isNotEmpty) {
//                             _sendMessage(text: _messageController.text.trim());
//                           }
//                         },
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;
//     final timestamp = data['timestamp'] as Timestamp;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (isMe) // Only show sender name for my messages
//             Text(
//               '', // Or you can use the user's name here
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           GestureDetector(
//             onTap: hasAudio
//                 ? () {
//                     setState(() {
//                       _isPlaying = !_isPlaying;
//                     });
//                   }
//                 : null,
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.7,
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.only(
//                   topLeft: const Radius.circular(12),
//                   topRight: const Radius.circular(12),
//                   bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
//                   bottomRight: isMe ? Radius.zero : const Radius.circular(12),
//                 ),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ''),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const DoctorProfileScreen(
//                         doctorId: doctorDoc.id,
//                     ),
//                   ),
//                 );
//               },
//               child: const CircleAvatar(
//                 radius: 18,
//                 child: Icon(Icons.person, size: 20),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {
//               // Add call functionality here
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isVoiceMode = true;
//   bool _isRecording = false;
//   bool _isPlaying = false;
//   bool _isSending = false;
//   String _chatId = '';

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();

//     _messageController.addListener(() {
//       setState(() {
//         _isVoiceMode = _messageController.text.isEmpty;
//       });
//     });
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     if (_isSending || (text == null && audioUrl == null)) return;

//     setState(() {
//       _isSending = true;
//     });

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();

//       if (!doc.exists) {
//         await chatDoc.set({
//           'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           'createdAt': FieldValue.serverTimestamp(),
//           'participants': [
//             widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//             widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           ],
//           'lastMessage': text ?? 'Audio message',
//           'lastMessageTime': FieldValue.serverTimestamp(),
//         });
//       } else {
//         await chatDoc.update({
//           'lastMessage': text ?? 'Audio message',
//           'lastMessageTime': FieldValue.serverTimestamp(),
//         });
//       }

//       final message = {
//         if (text != null) 'text': text,
//         if (audioUrl != null) 'audioUrl': audioUrl,
//         'senderId': _auth.currentUser?.uid,
//         'receiverId': widget.doctorId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': true,
//       };

//       await chatDoc.collection('messages').add(message);

//       if (text != null) {
//         _messageController.clear();
//       }

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (_scrollController.hasClients) {
//           _scrollController.animateTo(
//             0,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//         }
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send message: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSending = false;
//         });
//       }
//     }
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (text) {
//                   if (text.trim().isNotEmpty) {
//                     _sendMessage(text: text.trim());
//                   }
//                 },
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _isVoiceMode
//               ? IconButton(
//                   icon: const Icon(Icons.mic, color: Colors.blue),
//                   onPressed: () {
//                     // Add voice recording logic here
//                   },
//                 )
//               : IconButton(
//                   icon: _isSending
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(Icons.send, color: Colors.blue),
//                   onPressed: _isSending
//                       ? null
//                       : () {
//                           if (_messageController.text.trim().isNotEmpty) {
//                             _sendMessage(text: _messageController.text.trim());
//                           }
//                         },
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;
//     final timestamp = data['timestamp'] as Timestamp;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (isMe) // Only show sender name for my messages
//             Text(
//               '', // Or you can use the user's name here
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           GestureDetector(
//             onTap: hasAudio
//                 ? () {
//                     setState(() {
//                       _isPlaying = !_isPlaying;
//                     });
//                   }
//                 : null,
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.7,
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.only(
//                   topLeft: const Radius.circular(12),
//                   topRight: const Radius.circular(12),
//                   bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
//                   bottomRight: isMe ? Radius.zero : const Radius.circular(12),
//                 ),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ''),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//              onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DoctorProfileScreen(),
//       ),
//     );
//   },
              
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {
//               // Add call functionality here
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isVoiceMode = true;
//   bool _isRecording = false;
//   bool _isPlaying = false;
//   bool _isSending = false;
//   String _chatId = '';

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();

//     _messageController.addListener(() {
//       setState(() {
//         _isVoiceMode = _messageController.text.isEmpty;
//       });
//     });
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     if (_isSending || (text == null && audioUrl == null)) return;

//     setState(() {
//       _isSending = true;
//     });

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();

//       if (!doc.exists) {
//         await chatDoc.set({
//           'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           'createdAt': FieldValue.serverTimestamp(),
//           'participants': [
//             widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//             widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           ],
//           'lastMessage': text ?? 'Audio message',
//           'lastMessageTime': FieldValue.serverTimestamp(),
//         });
//       } else {
//         await chatDoc.update({
//           'lastMessage': text ?? 'Audio message',
//           'lastMessageTime': FieldValue.serverTimestamp(),
//         });
//       }

//       final message = {
//         if (text != null) 'text': text,
//         if (audioUrl != null) 'audioUrl': audioUrl,
//         'senderId': _auth.currentUser?.uid,
//         'receiverId': widget.doctorId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       };

//       await chatDoc.collection('messages').add(message);

//       if (text != null) {
//         _messageController.clear();
//       }

//       // Scroll to bottom after sending message
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (_scrollController.hasClients) {
//           _scrollController.animateTo(
//             0,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//         }
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send message: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSending = false;
//         });
//       }
//     }
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (text) {
//                   if (text.trim().isNotEmpty) {
//                     _sendMessage(text: text.trim());
//                   }
//                 },
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _isVoiceMode
//               ? IconButton(
//                   icon: const Icon(Icons.mic, color: Colors.blue),
//                   onPressed: () {
//                     // Add voice recording logic here
//                   },
//                 )
//               : IconButton(
//                   icon: _isSending
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(Icons.send, color: Colors.blue),
//                   onPressed: _isSending
//                       ? null
//                       : () {
//                           if (_messageController.text.trim().isNotEmpty) {
//                             _sendMessage(text: _messageController.text.trim());
//                           }
//                         },
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;
//     final timestamp = data['timestamp'] as Timestamp;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           GestureDetector(
//             onTap: hasAudio
//                 ? () {
//                     setState(() {
//                       _isPlaying = !_isPlaying;
//                     });
//                   }
//                 : null,
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.7,
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.only(
//                   topLeft: const Radius.circular(12),
//                   topRight: const Radius.circular(12),
//                   bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
//                   bottomRight: isMe ? Radius.zero : const Radius.circular(12),
//                 ),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ''),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {
//               // Add call functionality here
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isVoiceMode = true;
//   bool _isRecording = false;
//   bool _isPlaying = false;
//   bool _isSending = false;
//   String _chatId = '';

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();

//     // Detect typing to switch to send icon
//     _messageController.addListener(() {
//       setState(() {
//         _isVoiceMode = _messageController.text.isEmpty;
//       });
//     });
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//  Future<void> _sendMessage({String? text, String? audioUrl}) async {
//   if (_isSending) return;

//   setState(() {
//     _isSending = true;
//   });

//   try {
//     final chatDoc = _firestore.collection('chats').doc(_chatId);
//     final doc = await chatDoc.get();

//     // Haddii chat-kii hore uusan jirin, abuuri
//     if (!doc.exists) {
//       await chatDoc.set({
//         'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//         'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         ],
//       });
//     }

//     final message = {
//       if (text != null) 'text': text,
//       if (audioUrl != null) 'audioUrl': audioUrl,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     // Dir fariinta
//     await chatDoc.collection('messages').add(message);

//     // Nadiifi input ka dib dirid
//     if (text != null) {
//       _messageController.clear();
//     }
//   } catch (e) {
//     // No Snackbar here, only console print
//     print('ERROR while sending message: $e');
//   } finally {
//     if (mounted) {
//       setState(() {
//         _isSending = false;
//       });
//     }
//   }
// }
//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _isVoiceMode
//               ? IconButton(
//                   icon: const Icon(Icons.mic, color: Colors.blue),
//                   onPressed: () {
//                     // Add voice recording logic if needed
//                   },
//                 )
//               : IconButton(
//                   icon: _isSending
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(Icons.send, color: Colors.blue),
//                   onPressed: _isSending
//                       ? null
//                       : () {
//                           if (_messageController.text.trim().isNotEmpty) {
//                             _sendMessage(text: _messageController.text.trim());
//                           }
//                         },
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//                widget.doctorName,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           GestureDetector(
//             onTap: hasAudio
//                 ? () {
//                     setState(() {
//                       _isPlaying = !_isPlaying;
//                     });
//                   }
//                 : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ''),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   bool _isRecording = false;
//   bool _isVoiceMode = false;
//   bool _isPlaying = false;
//   bool _isSending = false;
//   late String _chatId;
//   int _recordDuration = 0;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     if (_isSending) return;
    
//     setState(() {
//       _isSending = true;
//     });

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();
      
//       if (!doc.exists) {
//         await chatDoc.set({
//           'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           'createdAt': FieldValue.serverTimestamp(),
//           'participants': [
//             widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//             widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           ],
//         });
//       }

//       final message = {
//         if (text != null) 'text': text,
//         if (audioUrl != null) 'audioUrl': audioUrl,
//         'senderId': _auth.currentUser?.uid,
//         'receiverId': widget.doctorId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       };

//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) {
//         _messageController.clear();
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send message: ${e.toString()}'),
//             // backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSending = false;
//         });
//       }
//     }
//   }

//   void _toggleInputMode() {
//     setState(() {
//       _isVoiceMode = !_isVoiceMode;
//       if (!_isVoiceMode) {
//         _isRecording = false;
//         _recordDuration = 0;
//       }
//     });
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });
//   }

//   void _stopRecording() {
//     setState(() {
//       _isRecording = false;
//     });
//     // In a real app, you would upload the audio file and get the URL
//     // Then call: _sendMessage(audioUrl: audioUrl);
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: _isVoiceMode
//                 ? GestureDetector(
//                     onLongPress: _startRecording,
//                     onLongPressEnd: (_) => _stopRecording(),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       height: 48,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: Text(
//                         _isRecording ? 'Recording...' : 'Hold to record',
//                         style: TextStyle(
//                           color: _isRecording ? Colors.red : Colors.grey,
//                         ),
//                       ),
//                     ),
//                   )
//                 : Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: TextField(
//                       controller: _messageController,
//                       decoration: const InputDecoration(
//                         hintText: 'Type a message...',
//                         border: InputBorder.none,
//                       ),
//                       onSubmitted: (_) => _sendMessage(text: _messageController.text),
//                     ),
//                   ),
//           ),
//           const SizedBox(width: 8),
//           // Changed this part to show microphone when in text mode and vice versa
//           IconButton(
//             icon: Icon(
//               _isVoiceMode ? Icons.keyboard : Icons.mic,
//               color: Colors.blue,
//             ),
//             onPressed: _toggleInputMode,
//           ),
//           if (!_isVoiceMode && _messageController.text.isNotEmpty)
//             IconButton(
//               icon: _isSending 
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.send, color: Colors.blue),
//               onPressed: _isSending 
//                   ? null 
//                   : () => _sendMessage(text: _messageController.text),
//             ),
//           if (_isVoiceMode && _isRecording)
//             IconButton(
//               icon: _isSending 
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.send, color: Colors.blue),
//               onPressed: _isSending ? null : _stopRecording,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
//             onTap: hasAudio ? () {
//               setState(() {
//                 _isPlaying = !_isPlaying;
//               });
//             } : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
                  
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   bool _isRecording = false;
//   bool _isVoiceMode = false;
//   bool _isPlaying = false;
//   bool _isSending = false; // Added to track sending state
//   late String _chatId;
//   int _recordDuration = 0;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     if (_isSending) return; // Prevent multiple sends
    
//     setState(() {
//       _isSending = true;
//     });

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();
      
//       if (!doc.exists) {
//         await chatDoc.set({
//           'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           'createdAt': FieldValue.serverTimestamp(),
//           'participants': [
//             widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//             widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//           ],
//         });
//       }

//       final message = {
//         if (text != null) 'text': text,
//         if (audioUrl != null) 'audioUrl': audioUrl,
//         'senderId': _auth.currentUser?.uid,
//         'receiverId': widget.doctorId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       };

//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) {
//         _messageController.clear();
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send message: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSending = false;
//         });
//       }
//     }
//   }

//   void _toggleInputMode() {
//     setState(() {
//       _isVoiceMode = !_isVoiceMode;
//       if (!_isVoiceMode) {
//         _isRecording = false;
//         _recordDuration = 0;
//       }
//     });
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });
    
//     // Start recording implementation
//     // You would typically start a timer here to update _recordDuration
//   }

//   void _stopRecording() {
//     setState(() {
//       _isRecording = false;
//     });
//     // Stop recording and send audio
//     // In a real app, you would upload the audio file and get the URL
//     // Then call: _sendMessage(audioUrl: audioUrl);
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: _isVoiceMode
//                 ? GestureDetector(
//                     onLongPress: _startRecording,
//                     onLongPressEnd: (_) => _stopRecording(),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       height: 48,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: Text(
//                         _isRecording ? 'Recording...' : 'Hold to record',
//                         style: TextStyle(
//                           color: _isRecording ? Colors.red : Colors.grey,
//                         ),
//                       ),
//                     ),
//                   )
//                 : Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: TextField(
//                       controller: _messageController,
//                       decoration: const InputDecoration(
//                         hintText: 'Type a message...',
//                         border: InputBorder.none,
//                       ),
//                       onSubmitted: (_) => _sendMessage(text: _messageController.text),
//                     ),
//                   ),
//           ),
//           const SizedBox(width: 8),
//           IconButton(
//             icon: Icon(
//               _isVoiceMode ? Icons.message : Icons.keyboard_voice,
//               color: Colors.blue,
//             ),
//             onPressed: _toggleInputMode,
//           ),
//           if (!_isVoiceMode && _messageController.text.isNotEmpty)
//             IconButton(
//               icon: _isSending 
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.send, color: Colors.blue),
//               onPressed: _isSending 
//                   ? null 
//                   : () => _sendMessage(text: _messageController.text),
//             ),
//           if (_isVoiceMode && _isRecording)
//             IconButton(
//               icon: _isSending 
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.send, color: Colors.blue),
//               onPressed: _isSending ? null : _stopRecording,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
//             onTap: hasAudio ? () {
//               // Play audio message
//               setState(() {
//                 _isPlaying = !_isPlaying;
//               });
//             } : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {}, // Implement call functionality
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 1,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
// }






















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   bool _isRecording = false;
//   bool _isVoiceMode = false;
//   bool _isPlaying = false;
//   late String _chatId;
//   int _recordDuration = 0;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     final chatDoc = _firestore.collection('chats').doc(_chatId);
//     final doc = await chatDoc.get();
    
//     if (!doc.exists) {
//       await chatDoc.set({
//         'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//         'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         ],
//       });
//     }

//     final message = {
//       if (text != null) 'text': text,
//       if (audioUrl != null) 'audioUrl': audioUrl,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _toggleInputMode() {
//     setState(() {
//       _isVoiceMode = !_isVoiceMode;
//       if (!_isVoiceMode) {
//         _isRecording = false;
//         _recordDuration = 0;
//       }
//     });
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });
    
//     // Start recording implementation
//     // You would typically start a timer here to update _recordDuration
//   }

//   void _stopRecording() {
//     setState(() {
//       _isRecording = false;
//     });
//     // Stop recording and send audio
//     // In a real app, you would upload the audio file and get the URL
//     // Then call: _sendMessage(audioUrl: audioUrl);
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: _isVoiceMode
//                 ? GestureDetector(
//                     onLongPress: _startRecording,
//                     onLongPressEnd: (_) => _stopRecording(),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       height: 48,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: Text(
//                         _isRecording ? 'Recording...' : 'Hold to record',
//                         style: TextStyle(
//                           color: _isRecording ? Colors.red : Colors.grey,
//                         ),
//                       ),
//                     ),
//                   )
//                 : Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: TextField(
//                       controller: _messageController,
//                       decoration: const InputDecoration(
//                         hintText: 'Type a message...',
//                         border: InputBorder.none,
//                       ),
//                       onSubmitted: (_) => _sendMessage(text: _messageController.text),
//                     ),
//                   ),
//           ),
//           const SizedBox(width: 8),
//           IconButton(
//             icon: Icon(
//               _isVoiceMode ? Icons.message : Icons.keyboard_voice,
//               color: Colors.blue,
//             ),
//             onPressed: _toggleInputMode,
//           ),
//           if (!_isVoiceMode && _messageController.text.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.send, color: Colors.blue),
//               onPressed: () => _sendMessage(text: _messageController.text),
//             ),
//           if (_isVoiceMode && _isRecording)
//             IconButton(
//               icon: const Icon(Icons.send, color: Colors.blue),
//               onPressed: _stopRecording,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
//             onTap: hasAudio ? () {
//               // Play audio message
//               setState(() {
//                 _isPlaying = !_isPlaying;
//               });
//             } : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {}, // Implement call functionality
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
// }































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   bool _isRecording = false;
//   bool _isVoiceMode = false;
//   bool _isPlaying = false;
//   late String _chatId;
//   int _recordDuration = 0;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     final chatDoc = _firestore.collection('chats').doc(_chatId);
//     final doc = await chatDoc.get();
    
//     if (!doc.exists) {
//       await chatDoc.set({
//         'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//         'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         ],
//       });
//     }

//     final message = {
//       if (text != null) 'text': text,
//       if (audioUrl != null) 'audioUrl': audioUrl,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _toggleInputMode() {
//     setState(() {
//       _isVoiceMode = !_isVoiceMode;
//       if (!_isVoiceMode) {
//         _isRecording = false;
//         _recordDuration = 0;
//       }
//     });
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });
    
//     // Start recording implementation
//     // You would typically start a timer here to update _recordDuration
//   }

//   void _stopRecording() {
//     setState(() {
//       _isRecording = false;
//     });
//     // Stop recording and send audio
//     // In a real app, you would upload the audio file and get the URL
//     // Then call: _sendMessage(audioUrl: audioUrl);
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: _isVoiceMode
//                 ? GestureDetector(
//                     onLongPress: _startRecording,
//                     onLongPressEnd: (_) => _stopRecording(),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       height: 48,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(30),
//                       child: Text(
//                         _isRecording ? 'Recording...' : 'Hold to record',
//                         style: TextStyle(
//                           color: _isRecording ? Colors.red : Colors.grey,
//                         ),
//                       ),
//                     ),
//                   )
//                 : Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: TextField(
//                       controller: _messageController,
//                       decoration: const InputDecoration(
//                         hintText: 'Type a message...',
//                         border: InputBorder.none,
//                       ),
//                       onSubmitted: (_) => _sendMessage(text: _messageController.text),
//                     ),
//                   ),
//           ),
//           const SizedBox(width: 8),
//           IconButton(
//             icon: Icon(
//               _isVoiceMode ? Icons.message : Icons.keyboard_voice,
//               color: Colors.blue,
//             ),
//             onPressed: _toggleInputMode,
//           ),
//           if (!_isVoiceMode && _messageController.text.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.send, color: Colors.blue),
//               onPressed: () => _sendMessage(text: _messageController.text),
//             ),
//           if (_isVoiceMode && _isRecording)
//             IconButton(
//               icon: const Icon(Icons.send, color: Colors.blue),
//               onPressed: _stopRecording,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
//             onTap: hasAudio ? () {
//               // Play audio message
//               setState(() {
//                 _isPlaying = !_isPlaying;
//               });
//             } : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {}, // Implement call functionality
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
// }






























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   bool _isRecording = false;
//   bool _isVoiceMode = false;
//   bool _isPlaying = false;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     final chatDoc = _firestore.collection('chats').doc(_chatId);
//     final doc = await chatDoc.get();
    
//     if (!doc.exists) {
//       await chatDoc.set({
//         'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//         'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         ],
//       });
//     }

//     final message = {
//       if (text != null) 'text': text,
//       if (audioUrl != null) 'audioUrl': audioUrl,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _toggleInputMode() {
//     setState(() {
//       _isVoiceMode = !_isVoiceMode;
//       if (!_isVoiceMode) {
//         _isRecording = false;
//       }
//     });
//   }

//   void _startRecording() {
//     setState(() => _isRecording = true);
//     // Start recording implementation
//   }

//   void _stopRecording() {
//     setState(() => _isRecording = false);
//     // Stop recording and send audio
//     // _sendMessage(audioUrl: audioUrl);
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: _isVoiceMode
//                 ? Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     alignment: Alignment.center,
//                     child: Text(
//                       _isRecording ? 'Recording...' : 'Tap to record',
//                       style: TextStyle(
//                         color: _isRecording ? Colors.red : Colors.grey,
//                       ),
//                     ),
//                   )
//                 : Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: TextField(
//                       reverse:true
//                       controller: _messageController,
//                       decoration: const InputDecoration(
//                         hintText: 'Type a message...',
//                         border: InputBorder.none,
//                       ),
//                       onSubmitted: (_) => _sendMessage(text: _messageController.text),
//                     ),
//                   ),
                  
//           ),
//           const SizedBox(width: 8),
//           IconButton(
//             icon: Icon(
//               _isVoiceMode
//                   ? (_isRecording ? Icons.stop : Icons.mic)
//                   : Icons.keyboard_voice,
//               color: _isVoiceMode
//                   ? (_isRecording ? Colors.red : Colors.blue)
//                   : Colors.blue,
//             ),
//             onPressed: () {
//               if (_isVoiceMode) {
//                 _isRecording ? _stopRecording() : _startRecording();
//               } else {
//                 _toggleInputMode();
//               }
//             },
//           ),
//           if (!_isVoiceMode && _messageController.text.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.send, color: Colors.blue),
//               onPressed: () => _sendMessage(text: _messageController.text),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
//             onTap: hasAudio ? () {
//               // Play audio message
//               setState(() {
//                 _isPlaying = !_isPlaying;
//               });
//             } : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying ? Icons.stop : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {}, // Implement call functionality
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
// }






















// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// // Add these imports for audio functionality
// // import 'package:audioplayers/audioplayers.dart';
// // import 'package:record/record.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Audio related variables
//   // late final AudioPlayer _audioPlayer;
//   // late final AudioRecorder _audioRecorder;
//   bool _isRecording = false;
//   bool _isPlaying = false;
//   String? _currentPlayingUrl;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//     // _audioPlayer = AudioPlayer();
//     // _audioRecorder = AudioRecorder();
//     // _initializeAudioPlayer();
//     // _initializeRecorder();
//   }

//   // void _initializeAudioPlayer() {
//   //   _audioPlayer.onPlayerStateChanged.listen((state) {
//   //     setState(() {
//   //       _isPlaying = state == PlayerState.playing;
//   //     });
//   //   });
//   // }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? currentUserId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : currentUserId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _createChatIfNotExists() async {
//     final chatDoc = _firestore.collection('chats').doc(_chatId);
//     final doc = await chatDoc.get();
    
//     if (!doc.exists) {
//       await chatDoc.set({
//         'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//         'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         ],
//       });
//     }
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     await _createChatIfNotExists();

//     final message = {
//       if (text != null) 'text': text,
//       if (audioUrl != null) 'audioUrl': audioUrl,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   Future<void> _startRecording() async {
//     // Implement recording start
//     setState(() => _isRecording = true);
//   }

//   Future<void> _stopRecordingAndSend() async {
//     // Implement recording stop and send
//     setState(() => _isRecording = false);
//     // Get audio file and send
//     // await _sendMessage(audioUrl: audioUrl);
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (_) => _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _messageController.text.isNotEmpty
//               ? IconButton(
//                   icon: const Icon(Icons.send, color: Colors.blue),
//                   onPressed: () => _sendMessage(text: _messageController.text),
//                 )
//               : IconButton(
//                   icon: Icon(
//                     _isRecording ? Icons.stop : Icons.mic,
//                     color: _isRecording ? Colors.red : Colors.blue,
//                   ),
//                   onPressed: _isRecording ? _stopRecordingAndSend : _startRecording,
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;
//     final hasAudio = data['audioUrl'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying && _currentPlayingUrl == data['audioUrl']
//                               ? Icons.stop
//                               : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         Text('Audio message'),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecordingIndicator() {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       color: Colors.red[50],
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.mic, color: Colors.red),
//           const SizedBox(width: 8),
//           Text('Recording...'),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {}, // Implement call functionality
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording) _buildRecordingIndicator(),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     // _audioPlayer.dispose();
//     // _audioRecorder.dispose();
//     super.dispose();
//   }
// }





// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';



// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
 
  
//   late String _chatId;
//   bool _isPlaying = false;
//   String? _currentPlayingUrl;
 

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//     _initializeAudioPlayer();
//     _initializeRecorder();
//   }

//   void _initializeAudioPlayer() {
//     _audioPlayer.onPlayerStateChanged.listen((state) {
//       setState(() {
//         _isPlaying = state == PlayerState.playing;
//       });
//     });
//   }

 

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? userId : widget.doctorId;
//     final userId = widget.isDoctor ? widget.doctorId : userId;
//     return '${doctorId}_$userId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _createChatIfNotExists() async {
//     final chatDoc = _firestore.collection('chats').doc(_chatId);
//     final doc = await chatDoc.get();
    
//     if (!doc.exists) {
//       await chatDoc.set({
//         'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//         'userId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         ],
//       });
//     }
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     await _createChatIfNotExists();

//     final message = {
//       if (text != null) 'text': text,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

  

  



//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (_) => _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _messageController.text.isNotEmpty
//               ? IconButton(
//                   icon: const Icon(Icons.send, color: Colors.blue),
//                   onPressed: () => _sendMessage(text: _messageController.text),
//                 )
//               : IconButton(
//                   icon: Icon(
//                     _isRecording ? Icons.stop : Icons.mic,
//                     color: _isRecording ? Colors.red : Colors.blue,
//                   ),
//                   onPressed: _isRecording ? _stopRecordingAndSend : _startRecording,
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasText = data['text'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
          
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
                       
//                               ? Icons.stop
//                               : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
                       
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecordingIndicator() {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       color: Colors.red[50],
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.mic, color: Colors.red),
//           const SizedBox(width: 8),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {}, // Implement call functionality
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording) _buildRecordingIndicator(),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }

//   @override
  
//     _messageController.dispose();
//     super.dispose();
//   }
// }
























// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:intl/intl.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:record/record.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   final Record _audioRecorder = Record();
  
//   late String _chatId;
//   bool _isRecording = false;
//   bool _isPlaying = false;
//   String? _currentPlayingUrl;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//     _initializeAudioPlayer();
//   }

//   void _initializeAudioPlayer() {
//     _audioPlayer.onPlayerStateChanged.listen((state) {
//       setState(() {
//         _isPlaying = state == PlayerState.playing;
//       });
//     });
//   }

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? userId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : userId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _createChatIfNotExists() async {
//     final chatDoc = _firestore.collection('chats').doc(_chatId);
//     final doc = await chatDoc.get();
    
//     if (!doc.exists) {
//       await chatDoc.set({
//         'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//         'patientId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         ],
//       });
//     }
//   }

//   Future<void> _sendMessage({String? text, String? audioUrl}) async {
//     await _createChatIfNotExists();

//     final message = {
//       if (text != null) 'text': text,
//       if (audioUrl != null) 'audio': audioUrl,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   Future<void> _startRecording() async {
//     try {
//       if (await _audioRecorder.hasPermission()) {
//         await _audioRecorder.start();
//         setState(() => _isRecording = true);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Recording failed: $e')),
//       );
//     }
//   }

//   Future<void> _stopRecordingAndSend() async {
//     try {
//       final path = await _audioRecorder.stop();
//       if (path != null) {
//         final file = File(path);
//         final ref = FirebaseStorage.instance
//             .ref()
//             .child('audio_messages')
//             .child('${DateTime.now().millisecondsSinceEpoch}.m4a');
        
//         final uploadTask = ref.putFile(file);
//         final snapshot = await uploadTask.whenComplete(() {});
//         final downloadUrl = await snapshot.ref.getDownloadURL();
//         await _sendMessage(audioUrl: downloadUrl);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to save recording: $e')),
//       );
//     } finally {
//       setState(() => _isRecording = false);
//     }
//   }

//   Future<void> _playAudioMessage(String url) async {
//     if (_isPlaying && _currentPlayingUrl == url) {
//       await _audioPlayer.stop();
//       return;
//     }

//     try {
//       _currentPlayingUrl = url;
//       await _audioPlayer.play(UrlSource(url));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to play audio message')),
//       );
//     }
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (_) => _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _messageController.text.isNotEmpty
//               ? IconButton(
//                   icon: const Icon(Icons.send, color: Colors.blue),
//                   onPressed: () => _sendMessage(text: _messageController.text),
//                 )
//               : IconButton(
//                   icon: Icon(
//                     _isRecording ? Icons.stop : Icons.mic,
//                     color: _isRecording ? Colors.red : Colors.blue,
//                   ),
//                   onPressed: _isRecording ? _stopRecordingAndSend : _startRecording,
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final hasAudio = data['audio'] != null;
//     final hasText = data['text'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
//             onTap: hasAudio ? () => _playAudioMessage(data['audio']) : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: hasAudio
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying && _currentPlayingUrl == data['audio']
//                               ? Icons.stop
//                               : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text("Audio Message"),
//                       ],
//                     )
//                   : Text(hasText ? data['text'] : ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {}, // Implement call functionality
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Container(
//               padding: const EdgeInsets.all(8),
//               color: Colors.red[50],
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.mic, color: Colors.red),
//                   SizedBox(width: 8),
//                   Text("Recording..."),
//                 ],
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _audioRecorder.dispose();
//     _messageController.dispose();
//     super.dispose();
//   }
// }






















// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:intl/intl.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:record/record.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;
//   final bool isDoctor;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//     this.isDoctor = false,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   final Record _audioRecorder = Record();
  
//   late String _chatId;
//   bool _isRecording = false;
//   bool _isPlaying = false;
//   String? _currentPlayingUrl;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//     _initializeAudioPlayer();
//   }

//   void _initializeAudioPlayer() {
//     _audioPlayer.onPlayerStateChanged.listen((state) {
//       setState(() {
//         _isPlaying = state == PlayerState.playing;
//       });
//     });
//   }

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.isDoctor ? userId : widget.doctorId;
//     final patientId = widget.isDoctor ? widget.doctorId : userId;
//     return '${doctorId}_$patientId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _createChatIfNotExists() async {
//     final chatDoc = _firestore.collection('chats').doc(_chatId);
//     final doc = await chatDoc.get();
    
//     if (!doc.exists) {
//       await chatDoc.set({
//         'doctorId': widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//         'patientId': widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isDoctor ? _auth.currentUser!.uid : widget.doctorId,
//           widget.isDoctor ? widget.doctorId : _auth.currentUser!.uid,
//         ],
//       });
//     }
//   }

//   Future<void> _sendMessage({String? text, String? voicePath}) async {
//     await _createChatIfNotExists();

//     final message = {
//       if (text != null) 'text': text,
//       if (voicePath != null) 'voice': voicePath,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.isDoctor ? widget.doctorId : widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   Future<void> _startRecording() async {
//     try {
//       if (await _audioRecorder.hasPermission()) {
//         await _audioRecorder.start();
//         setState(() => _isRecording = true);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Recording failed: $e')),
//       );
//     }
//   }

//   Future<void> _stopRecording() async {
//     try {
//       final path = await _audioRecorder.stop();
//       if (path != null) {
//         final file = File(path);
//         final ref = FirebaseStorage.instance
//             .ref()
//             .child('voice_messages')
//             .child('${DateTime.now().millisecondsSinceEpoch}.m4a');
        
//         await ref.putFile(file);
//         final downloadUrl = await ref.getDownloadURL();
//         await _sendMessage(voicePath: downloadUrl);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to save recording: $e')),
//       );
//     } finally {
//       setState(() => _isRecording = false);
//     }
//   }

//   Future<void> _playVoiceMessage(String url) async {
//     if (_isPlaying && _currentPlayingUrl == url) {
//       await _audioPlayer.stop();
//       return;
//     }

//     try {
//       _currentPlayingUrl = url;
//       await _audioPlayer.play(UrlSource(url));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to play voice message')),
//       );
//     }
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (_) => _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _messageController.text.isNotEmpty
//               ? IconButton(
//                   icon: const Icon(Icons.send, color: Colors.blue),
//                   onPressed: () => _sendMessage(text: _messageController.text),
//                 )
//               : IconButton(
//                   icon: Icon(
//                     _isRecording ? Icons.stop : Icons.mic,
//                     color: _isRecording ? Colors.red : Colors.blue,
//                   ),
//                   onPressed: _isRecording ? _stopRecording : _startRecording,
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final isVoiceMessage = data['voice'] != null;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isDoctor)
//             Text(
//               widget.doctorName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           GestureDetector(
//             onTap: isVoiceMessage ? () => _playVoiceMessage(data['voice']) : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: isVoiceMessage
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isPlaying && _currentPlayingUrl == data['voice']
//                               ? Icons.stop
//                               : Icons.play_arrow,
//                           color: Colors.blue,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text("Voice Message"),
//                       ],
//                     )
//                   : Text(data['text'] ?? ""),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _formatTimestamp(data['timestamp'] as Timestamp),
//             style: const TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.doctorName),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {}, // Implement call functionality
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Container(
//               padding: const EdgeInsets.all(8),
//               color: Colors.red[50],
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.mic, color: Colors.red),
//                   SizedBox(width: 8),
//                   Text("Recording..."),
//                 ],
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _audioRecorder.dispose();
//     _messageController.dispose();
//     super.dispose();
//   }
// }



















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';
// import 'voice_call_screen.dart';
// import 'video_call_screen.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   late String _chatId;
//   bool _isRecording = false;
//   int _recordDuration = 0;
//   Timer? _recordingTimer;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     final doctorId = widget.doctorId;
//     // Sort IDs to ensure consistent chat ID regardless of who is sender/receiver
//     return userId.compareTo(doctorId) < 0 
//         ? '${userId}_$doctorId' 
//         : '${doctorId}_$userId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? voicePath}) async {
//     if ((text == null || text.isEmpty) && (voicePath == null)) return;

//     final message = {
//       if (text != null) 'text': text,
//       if (voicePath != null) 'voice': voicePath,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) {
//         _messageController.clear();
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _recordDuration++;
//       });
//     });
//   }

//   Future<void> _stopRecording() async {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     String fakeVoicePath = "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     await _sendMessage(voicePath: fakeVoicePath);
//   }

//   void _navigateToCall(String type) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
//       ),
//     );
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       color: Colors.white,
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_emotions_outlined),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'message . . .',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (value) => setState(() {}),
//                 onSubmitted: (_) => _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 4),
//           _messageController.text.isNotEmpty
//               ? GestureDetector(
//                   onTap: () => _sendMessage(text: _messageController.text),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.blue[900],
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 )
//               : GestureDetector(
//                   onLongPressStart: (_) => _startRecording(),
//                   onLongPressEnd: (_) => _stopRecording(),
//                   child: CircleAvatar(
//                     backgroundColor: _isRecording ? Colors.red : Colors.blue[900],
//                     child: Icon(
//                       _isRecording ? Icons.stop : Icons.mic_none,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!isMe)
//               Text(
//                 widget.doctorName,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             if (data['voice'] != null)
//               const Row(
//                 children: [
//                   Icon(Icons.play_arrow),
//                   SizedBox(width: 4),
//                   Text("Voice Message"),
//                 ],
//               )
//             else
//               Text(data['text'] ?? ""),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   _formatTimestamp(data['timestamp'] as Timestamp),
//                   style: const TextStyle(fontSize: 10, color: Colors.black54),
//                 ),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   Icon(
//                     data['isRead'] ? Icons.done_all : Icons.done,
//                     size: 14,
//                     color: data['isRead'] ? Colors.blue : Colors.grey,
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.doctorName,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Chip(label: Text("Today")),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'voice_call_screen.dart';
// import 'video_call_screen.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   late String _chatId;
//   bool _isRecording = false;
//   int _recordDuration = 0;
//   Timer? _recordingTimer;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     return '${widget.doctorId}_$userId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? voicePath}) async {
//     if ((text == null || text.isEmpty) && (voicePath == null)) return;

//     final message = {
//       if (text != null) 'text': text,
//       if (voicePath != null) 'voice': voicePath,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       if (text != null) {
//         _messageController.clear();
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _recordDuration++;
//       });
//     });
//   }

//   Future<void> _stopRecording() async {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     String fakeVoicePath = "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     await _sendMessage(voicePath: fakeVoicePath);
//   }

//   void _navigateToCall(String type) {
//     // You'll need to implement these screens
//      void _navigateToCall(String type) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
//       ),
//     );
//   }
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       color: Colors.white,
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_emotions_outlined),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'message . . .',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (value) => setState(() {}),
//                 onSubmitted: (_) => _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
          
      
//           const SizedBox(width: 4),
//           _messageController.text.isNotEmpty
//               ? GestureDetector(
//                   onTap: () => _sendMessage(text: _messageController.text),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.blue[900],
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 )
//               : GestureDetector(
//                   onLongPressStart: (_) => _startRecording(),
//                   onLongPressEnd: (_) => _stopRecording(),
//                   child: CircleAvatar(
//                     backgroundColor: _isRecording ? Colors.red : Colors.blue[900],
//                     child: Icon(
//                       _isRecording ? Icons.stop : Icons.mic_none,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!isMe)
//               Text(
//                 widget.doctorName,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             if (data['voice'] != null)
//               const Row(
//                 children: [
//                   Icon(Icons.play_arrow),
//                   SizedBox(width: 4),
//                   Text("Voice Message"),
//                 ],
//               )
//             else
//               Text(data['text'] ?? ""),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   _formatTimestamp(data['timestamp'] as Timestamp),
//                   style: const TextStyle(fontSize: 10, color: Colors.black54),
//                 ),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   Icon(
//                     data['isRead'] ? Icons.done_all : Icons.done,
//                     size: 14,
//                     color: data['isRead'] ? Colors.blue : Colors.grey,
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.doctorName,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ],
//               const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.doctorName,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Chip(label: Text("Today")),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }
// }

























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorId,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     return '${widget.doctorId}_$userId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   Future<void> _sendMessage() async {
//     final text = _messageController.text.trim();
//     if (text.isEmpty) return;

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add({
//             'text': text,
//             'senderId': _auth.currentUser?.uid,
//             'receiverId': widget.doctorId,
//             'timestamp': FieldValue.serverTimestamp(),
//             'isRead': false,
//           });


//            final message = {
//       'text': text,
//       'voice': voicePath,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _recordDuration++;
//       });
//     });
//   }

//   Future<void> _stopRecording() async {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     String fakeVoicePath = "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     await _sendMessage(voicePath: fakeVoicePath);
//   }

//   void _navigateToCall(String type) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       color: Colors.white,
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_emotions_outlined),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'message . . .',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (value) => setState(() {}),
//                 onSubmitted: (_) =>
//                     _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 4),
//           _messageController.text.isNotEmpty
//               ? GestureDetector(
//                   onTap: () => _sendMessage(text: _messageController.text),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.blue[900],
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 )
//               : GestureDetector(
//                   onLongPressStart: (_) => _startRecording(),
//                   onLongPressEnd: (_) => _stopRecording(),
//                   child: CircleAvatar(
//                     backgroundColor:
//                         _isRecording ? Colors.red : Colors.blue[900],
//                     child: Icon(
//                       _isRecording ? Icons.stop : Icons.mic_none,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!isMe)
//               Text(
//                 widget.doctorName,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             if (data['voice'] != null)
//               const Row(
//                 children: [
//                   Icon(Icons.play_arrow),
//                   SizedBox(width: 4),
//                   Text("Voice Message"),
//                 ],
//               )
//             else
//               Text(data['text'] ?? ""),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   _formatTimestamp(data['timestamp'] as Timestamp),
//                   style: const TextStyle(fontSize: 10, color: Colors.black54),
//                 ),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   Icon(
//                     data['isRead'] ? Icons.done_all : Icons.done,
//                     size: 14,
//                     color: data['isRead'] ? Colors.blue : Colors.grey,
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.doctorName,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Chip(label: Text("Today")),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }
// }


//       _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: ${e.toString()}')),
//       );
//     }
//   }

//   Future<void> _stopRecording() async {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     String fakeVoicePath = "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     await _sendMessage(voicePath: fakeVoicePath);
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;

//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Row(
//         mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//         children: [
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (!isMe)
//                     Text(
//                       widget.doctorName,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                     ),
//                   Text(data['text'] ?? ''),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         _formatTimestamp(data['timestamp']),
//                         style: const TextStyle(
//                           fontSize: 10, 
//                           color: Colors.black54,
//                         ),
//                       ),
//                       if (isMe) ...[
//                         const SizedBox(width: 4),
//                         Icon(
//                           data['isRead'] ? Icons.done_all : Icons.done,
//                           size: 14,
//                           color: data['isRead'] ? Colors.blue : Colors.grey,
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       color: Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               decoration: InputDecoration(
//                 hintText: 'Type a message...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16, vertical: 12),
//               ),
//               onSubmitted: (_) => _sendMessage(),
//             ),
//           ),
//           const SizedBox(width: 8),
//           IconButton(
//             icon: const Icon(Icons.send, color: Colors.blue),
//             onPressed: _sendMessage,
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             CircleAvatar(
//               child: Text(widget.doctorName.isNotEmpty 
//                   ? widget.doctorName[0].toUpperCase() 
//                   : 'D'),
//             ),
//             const SizedBox(width: 12),
//             Text(widget.doctorName),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
// }














// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'voice_call_screen.dart';
// import 'video_call_screen.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorId;

//   const ChatScreen({
//     Key? key,
//     required this.doctorName,
//     required this.doctorId,
//   }) : super(key: key);

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isRecording = false;
//   Timer? _recordingTimer;
//   int _recordDuration = 0;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     return '${widget.doctorId}_$userId';
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? voicePath}) async {
//     if ((text == null || text.trim().isEmpty) && voicePath == null) return;

//     final message = {
//       'text': text,
//       'voice': voicePath,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _recordDuration++;
//       });
//     });
//   }

//   Future<void> _stopRecording() async {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     String fakeVoicePath = "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     await _sendMessage(voicePath: fakeVoicePath);
//   }

//   void _navigateToCall(String type) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       color: Colors.white,
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_emotions_outlined),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'message . . .',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (value) => setState(() {}),
//                 onSubmitted: (_) =>
//                     _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 4),
//           _messageController.text.isNotEmpty
//               ? GestureDetector(
//                   onTap: () => _sendMessage(text: _messageController.text),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.blue[900],
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 )
//               : GestureDetector(
//                   onLongPressStart: (_) => _startRecording(),
//                   onLongPressEnd: (_) => _stopRecording(),
//                   child: CircleAvatar(
//                     backgroundColor:
//                         _isRecording ? Colors.red : Colors.blue[900],
//                     child: Icon(
//                       _isRecording ? Icons.stop : Icons.mic_none,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!isMe)
//               Text(
//                 widget.doctorName,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             if (data['voice'] != null)
//               const Row(
//                 children: [
//                   Icon(Icons.play_arrow),
//                   SizedBox(width: 4),
//                   Text("Voice Message"),
//                 ],
//               )
//             else
//               Text(data['text'] ?? ""),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   _formatTimestamp(data['timestamp'] as Timestamp),
//                   style: const TextStyle(fontSize: 10, color: Colors.black54),
//                 ),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   Icon(
//                     data['isRead'] ? Icons.done_all : Icons.done,
//                     size: 14,
//                     color: data['isRead'] ? Colors.blue : Colors.grey,
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: Row(
//           children: [
//             const CircleAvatar(
//               radius: 18,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.doctorName,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Chip(label: Text("Today")),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }
// }















// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'voice_call_screen.dart';
// import 'video_call_screen.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String avatar;
//   final String doctorId;

//   const ChatScreen({
//     Key? key,
//     required this.doctorName,
//     required this.avatar,
//     required this.doctorId,
//   }) : super(key: key);

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isRecording = false;
//   Timer? _recordingTimer;
//   int _recordDuration = 0;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     return '${widget.doctorId}_$userId'; // Or sort IDs to make consistent
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? voicePath}) async {
//     if ((text == null || text.trim().isEmpty) && voicePath == null) return;

//     final message = {
//       'text': text,
//       'voice': voicePath,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _recordDuration++;
//       });
//     });
//   }

//   Future<void> _stopRecording() async {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     // Here you would upload the actual voice file to Firebase Storage
//     // For demo, we'll just use a fake path
//     String fakeVoicePath = "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     await _sendMessage(voicePath: fakeVoicePath);
//   }

//   void _navigateToCall(String type) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       color: Colors.white,
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_emotions_outlined),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'message . . .',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (value) => setState(() {}),
//                 onSubmitted: (_) =>
//                     _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 4),
//           _messageController.text.isNotEmpty
//               ? GestureDetector(
//                   onTap: () => _sendMessage(text: _messageController.text),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.blue[900],
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 )
//               : GestureDetector(
//                   onLongPressStart: (_) => _startRecording(),
//                   onLongPressEnd: (_) => _stopRecording(),
//                   child: CircleAvatar(
//                     backgroundColor:
//                         _isRecording ? Colors.red : Colors.blue[900],
//                     child: Icon(
//                       _isRecording ? Icons.stop : Icons.mic_none,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!isMe)
//               Text(
//                 widget.doctorName,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             if (data['voice'] != null)
//               const Row(
//                 children: [
//                   Icon(Icons.play_arrow),
//                   SizedBox(width: 4),
//                   Text("Voice Message"),
//                 ],
//               )
//             else
//               Text(data['text'] ?? ""),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   _formatTimestamp(data['timestamp'] as Timestamp),
//                   style: const TextStyle(fontSize: 10, color: Colors.black54),
//                 ),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   Icon(
//                     data['isRead'] ? Icons.done_all : Icons.done,
//                     size: 14,
//                     color: data['isRead'] ? Colors.blue : Colors.grey,
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 18,
//               backgroundImage: widget.avatar.isNotEmpty
//                   ? NetworkImage(widget.avatar)
//                   : null,
//               child: widget.avatar.isEmpty
//                   ? const Icon(Icons.person, color: Colors.white)
//                   : null,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.doctorName,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Chip(label: Text("Today")),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'voice_call_screen.dart';
// import 'video_call_screen.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorData;
//   final String doctorId;

//   const ChatScreen({
//     Key? key,
//     required this.doctorData
//     required this.doctorId,
//   }) : super(key: key);

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isRecording = false;
//   Timer? _recordingTimer;
//   int _recordDuration = 0;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//   }

//   String _generateChatId() {
//     final userId = _auth.currentUser?.uid ?? '';
//     return '${widget.doctorId}_$userId'; // Or sort IDs to make consistent
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d').format(messageTime);
//   }

//   Future<void> _sendMessage({String? text, String? voicePath}) async {
//     if ((text == null || text.trim().isEmpty) && voicePath == null) return;

//     final message = {
//       'text': text,
//       'voice': voicePath,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.doctorId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'isRead': false,
//     };

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add(message);
      
//       _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _recordDuration++;
//       });
//     });
//   }

//   Future<void> _stopRecording() async {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     // Here you would upload the actual voice file to Firebase Storage
//     // For demo, we'll just use a fake path
//     String fakeVoicePath = "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     await _sendMessage(voicePath: fakeVoicePath);
//   }

//   void _navigateToCall(String type) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       color: Colors.white,
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_emotions_outlined),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'message . . .',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (value) => setState(() {}),
//                 onSubmitted: (_) =>
//                     _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 4),
//           _messageController.text.isNotEmpty
//               ? GestureDetector(
//                   onTap: () => _sendMessage(text: _messageController.text),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.blue[900],
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 )
//               : GestureDetector(
//                   onLongPressStart: (_) => _startRecording(),
//                   onLongPressEnd: (_) => _stopRecording(),
//                   child: CircleAvatar(
//                     backgroundColor:
//                         _isRecording ? Colors.red : Colors.blue[900],
//                     child: Icon(
//                       _isRecording ? Icons.stop : Icons.mic_none,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!isMe)
//               Text(
//                 widget.name,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             if (data['voice'] != null)
//               const Row(
//                 children: [
//                   Icon(Icons.play_arrow),
//                   SizedBox(width: 4),
//                   Text("Voice Message"),
//                 ],
//               )
//             else
//               Text(data['text'] ?? ""),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   _formatTimestamp(data['timestamp']),
//                   style: const TextStyle(fontSize: 10, color: Colors.black54),
//                 ),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   Icon(
//                     data['isRead'] ? Icons.done_all : Icons.done,
//                     size: 14,
//                     color: data['isRead'] ? Colors.blue : Colors.grey,
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 18,
//               backgroundImage: widget.avatar.isNotEmpty
//                   ? NetworkImage(widget.avatar)
//                   : null,
//               child: widget.avatar.isEmpty
//                   ? const Icon(Icons.person, color: Colors.white)
//                   : null,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.name,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Chip(label: Text("Today")),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(_chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final message = snapshot.data!.docs[index];
//                     return _buildMessage(message);
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }
// }























// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'voice_call_screen.dart';
// import 'video_call_screen.dart';

// class ChatScreen extends StatefulWidget {
//   final String name;
//   final String avatar;

//   const ChatScreen({
//     Key? key,
//     required this.name,
//     required this.avatar,
//   }) : super(key: key);

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final List<Map<String, dynamic>> _messages = [];
//   bool _isRecording = false;
//   Timer? _recordingTimer;
//   int _recordDuration = 0;

//   void _sendMessage({String? text, String? voicePath}) {
//     if ((text != null && text.trim().isNotEmpty) || voicePath != null) {
//       setState(() {
//         _messages.add({
//           'text': text,
//           'voice': voicePath,
//           'time': 'Now',
//           'isRead': true,
//         });
//         _messageController.clear();
//       });
//     }
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _recordDuration++;
//       });
//     });
//   }

//   void _stopRecording() {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     String fakeVoicePath =
//         "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     _sendMessage(voicePath: fakeVoicePath);
//   }

//   void _navigateToCall(String type) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       color: Colors.white,
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_emotions_outlined),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'message . . .',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (value) => setState(() {}),
//                 onSubmitted: (_) =>
//                     _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 4),
//           _messageController.text.isNotEmpty
//               ? GestureDetector(
//                   onTap: () => _sendMessage(text: _messageController.text),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.blue[900],
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 )
//               : GestureDetector(
//                   onLongPressStart: (_) => _startRecording(),
//                   onLongPressEnd: (_) => _stopRecording(),
//                   child: CircleAvatar(
//                     backgroundColor:
//                         _isRecording ? Colors.red : Colors.blue[900],
//                     child: Icon(
//                       _isRecording ? Icons.stop : Icons.mic_none,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(Map<String, dynamic> message) {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.blue[100],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (message['voice'] != null)
//               const Row(
//                 children: [
//                   Icon(Icons.play_arrow),
//                   SizedBox(width: 4),
//                   Text("Voice Message"),
//                 ],
//               )
//             else
//               Flexible(child: Text(message['text'] ?? "")),
//             const SizedBox(width: 8),
//             Text(message['time'],
//                 style: const TextStyle(fontSize: 10, color: Colors.black54)),
//             const SizedBox(width: 4),
//             Icon(message['isRead'] ? Icons.done_all : Icons.done,
//                 size: 14, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 18,
//               backgroundImage: widget.avatar.isNotEmpty
//                   ? AssetImage(widget.avatar)
//                   : null,
//               child: widget.avatar.isEmpty
//                   ? const Icon(Icons.person, color: Colors.white)
//                   : null,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.name,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Chip(label: Text("Today")),
//           Expanded(
//             child: ListView.builder(
//               reverse: true,
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final message = _messages[_messages.length - 1 - index];
//                 return _buildMessage(message);
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }
// }




























// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'voice_call_screen.dart';
// import 'video_call_screen.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final List<Map<String, dynamic>> _messages = [];
//   bool _isRecording = false;
//   Timer? _recordingTimer;
//   int _recordDuration = 0;

//   void _sendMessage({String? text, String? voicePath}) {
//     if ((text != null && text.trim().isNotEmpty) || voicePath != null) {
//       setState(() {
//         _messages.add({
//           'text': text,
//           'voice': voicePath,
//           'time': 'Now',
//           'isRead': true,
//         });
//         _messageController.clear();
//       });
//     }
//   }

//   void _startRecording() {
//     setState(() {
//       _isRecording = true;
//       _recordDuration = 0;
//     });

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _recordDuration++;
//       });
//     });
//   }

//   void _stopRecording() {
//     _recordingTimer?.cancel();
//     setState(() {
//       _isRecording = false;
//     });

//     String fakeVoicePath =
//         "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
//     _sendMessage(voicePath: fakeVoicePath);
//   }

//   void _navigateToCall(String type) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       color: Colors.white,
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_emotions_outlined),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   hintText: 'message . . .',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (value) => setState(() {}),
//                 onSubmitted: (_) =>
//                     _sendMessage(text: _messageController.text),
//               ),
//             ),
//           ),
//           const SizedBox(width: 4),
//           _messageController.text.isNotEmpty
//               ? GestureDetector(
//                   onTap: () => _sendMessage(text: _messageController.text),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.blue[900],
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 )
//               : GestureDetector(
//                   onLongPressStart: (_) => _startRecording(),
//                   onLongPressEnd: (_) => _stopRecording(),
//                   child: CircleAvatar(
//                     backgroundColor:
//                         _isRecording ? Colors.red : Colors.blue[900],
//                     child: Icon(
//                       _isRecording ? Icons.stop : Icons.mic_none,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(Map<String, dynamic> message) {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.blue[100],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (message['voice'] != null)
//               const Row(
//                 children: [
//                   Icon(Icons.play_arrow),
//                   SizedBox(width: 4),
//                   Text("Voice Message"),
//                 ],
//               )
//             else
//               Flexible(child: Text(message['text'] ?? "")),
//             const SizedBox(width: 8),
//             Text(message['time'],
//                 style: const TextStyle(fontSize: 10, color: Colors.black54)),
//             const SizedBox(width: 4),
//             Icon(message['isRead'] ? Icons.done_all : Icons.done,
//                 size: 14, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: Row(
//           children: const [
//             CircleAvatar(
//               //backgroundImage: AssetImage('assets/images/doctor_profile.jpg'),
//               radius: 18,
//             ),
//             SizedBox(width: 8),
//             Text(
//               'Doctor',
//               style: TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam, color: Colors.white),
//             onPressed: () => _navigateToCall("video"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call, color: Colors.white),
//             onPressed: () => _navigateToCall("voice"),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Chip(label: Text("Today")),
//           Expanded(
//             child: ListView.builder(
//               reverse: true,
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final message = _messages[_messages.length - 1 - index];
//                 return _buildMessage(message);
//               },
//             ),
//           ),
//           if (_isRecording)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(
//                 "Recording: $_recordDuration s",
//                 style: const TextStyle(color: Colors.green),
//               ),
//             ),
//           _buildMessageInputField(),
//         ],
//       ),
//     );
//   }
// }











































// // import 'package:flutter/material.dart';
// // import 'dart:async';
// // import 'voice_call_screen.dart';
// // import 'video_call_screen.dart';

// // class ChatScreen extends StatefulWidget {
// //   const ChatScreen({super.key});

// //   @override
// //   State<ChatScreen> createState() => _ChatScreenState();
// // }

// // class _ChatScreenState extends State<ChatScreen> {
// //   final TextEditingController _messageController = TextEditingController();
// //   final List<Map<String, dynamic>> _messages = [];
// //   bool _isRecording = false;
// //   Timer? _recordingTimer;
// //   int _recordDuration = 0;

// //   void _sendMessage({String? text, String? voicePath}) {
// //     if ((text != null && text.trim().isNotEmpty) || voicePath != null) {
// //       setState(() {
// //         _messages.add({
// //           'text': text,
// //           'voice': voicePath,
// //           'time': 'Now',
// //           'isRead': true,
// //         });
// //         _messageController.clear();
// //       });
// //     }
// //   }

// //   void _startRecording() {
// //     setState(() {
// //       _isRecording = true;
// //       _recordDuration = 0;
// //     });

// //     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       setState(() {
// //         _recordDuration++;
// //       });
// //     });
// //   }

// //   void _stopRecording() {
// //     _recordingTimer?.cancel();
// //     setState(() {
// //       _isRecording = false;
// //     });

// //     String fakeVoicePath =
// //         "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
// //     _sendMessage(voicePath: fakeVoicePath);
// //   }

// //   void _navigateToCall(String type) {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (_) =>
// //             type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _recordingTimer?.cancel();
// //     _messageController.dispose();
// //     super.dispose();
// //   }

// //   Widget _buildMessageInputField() {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// //       color: Colors.white,
// //       child: Row(
// //         children: [
// //           const Icon(Icons.emoji_emotions_outlined),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Container(
// //               decoration: BoxDecoration(
// //                 color: Colors.grey[200],
// //                 borderRadius: BorderRadius.circular(30),
// //               ),
// //               padding: const EdgeInsets.symmetric(horizontal: 16),
// //               child: TextField(
// //                 controller: _messageController,
// //                 decoration: const InputDecoration(
// //                   hintText: 'message . . .',
// //                   border: InputBorder.none,
// //                 ),
// //                 onChanged: (value) => setState(() {}),
// //                 onSubmitted: (_) =>
// //                     _sendMessage(text: _messageController.text),
// //               ),
// //             ),
// //           ),
// //           const SizedBox(width: 4),
// //           _messageController.text.isNotEmpty
// //               ? GestureDetector(
// //                   onTap: () => _sendMessage(text: _messageController.text),
// //                   child: CircleAvatar(
// //                     backgroundColor: Colors.blue[900],
// //                     child: const Icon(Icons.send, color: Colors.white),
// //                   ),
// //                 )
// //               : GestureDetector(
// //                   onLongPressStart: (_) => _startRecording(),
// //                   onLongPressEnd: (_) => _stopRecording(),
// //                   child: CircleAvatar(
// //                     backgroundColor:
// //                         _isRecording ? Colors.red : Colors.blue[900],
// //                     child: Icon(
// //                       _isRecording ? Icons.stop : Icons.mic_none,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                 ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildMessage(Map<String, dynamic> message) {
// //     return Align(
// //       alignment: Alignment.centerRight,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //         decoration: BoxDecoration(
// //           color: Colors.blue[100],
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             if (message['voice'] != null)
// //               const Row(
// //                 children: [
// //                   Icon(Icons.play_arrow),
// //                   SizedBox(width: 4),
// //                   Text("Voice Message"),
// //                 ],
// //               )
// //             else
// //               Flexible(child: Text(message['text'] ?? "")),
// //             const SizedBox(width: 8),
// //             Text(message['time'],
// //                 style: const TextStyle(fontSize: 10, color: Colors.black54)),
// //             const SizedBox(width: 4),
// //             Icon(message['isRead'] ? Icons.done_all : Icons.done,
// //                 size: 14, color: Colors.grey),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Row(
// //           children: const [
// //             CircleAvatar(child: Icon(Icons.person)),
// //             SizedBox(width: 8),
// //             Text('Doctor'),
// //           ],
// //         ),
// //         backgroundColor: Colors.blue[900],
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.videocam),
// //             onPressed: () => _navigateToCall("video"),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.call),
// //             onPressed: () => _navigateToCall("voice"),
// //           ),
// //         ],
// //       ),
// //       body: Column(
// //         children: [
// //           const SizedBox(height: 10),
// //           const Chip(label: Text("Today")),
// //           Expanded(
// //             child: ListView.builder(
// //               reverse: true,
// //               itemCount: _messages.length,
// //               itemBuilder: (context, index) {
// //                 final message = _messages[_messages.length - 1 - index];
// //                 return _buildMessage(message);
// //               },
// //             ),
// //           ),
// //           if (_isRecording)
// //             Padding(
// //               padding: const EdgeInsets.only(bottom: 8),
// //               child: Text(
// //                 "Recording: $_recordDuration s",
// //                 style: const TextStyle(color: Colors.red),
// //               ),
// //             ),
// //           _buildMessageInputField(),
// //         ],
// //       ),
// //     );
// //   }
// // }
















































// // import 'package:flutter/material.dart';
// // import 'dart:async';
// // import 'voice_call_screen.dart';
// // import 'video_call_screen.dart';

// // class ChatScreen extends StatefulWidget {
// //   const ChatScreen({super.key});

// //   @override
// //   State<ChatScreen> createState() => _ChatScreenState();
// // }

// // class _ChatScreenState extends State<ChatScreen> {
// //   final TextEditingController _messageController = TextEditingController();
// //   final List<Map<String, dynamic>> _messages = [];
// //   bool _isRecording = false;
// //   Timer? _recordingTimer;
// //   int _recordDuration = 0;

// //   void _sendMessage({String? text, String? voicePath}) {
// //     if ((text != null && text.trim().isNotEmpty) || voicePath != null) {
// //       setState(() {
// //         _messages.add({
// //           'text': text,
// //           'voice': voicePath,
// //           'time': 'Now',
// //           'isRead': true,
// //         });
// //         _messageController.clear();
// //       });
// //     }
// //   }

// //   void _startRecording() {
// //     setState(() {
// //       _isRecording = true;
// //       _recordDuration = 0;
// //     });

// //     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       setState(() {
// //         _recordDuration++;
// //       });
// //     });
// //   }

// //   void _stopRecording() {
// //     _recordingTimer?.cancel();
// //     setState(() {
// //       _isRecording = false;
// //     });

// //     String fakeVoicePath = "voice_${DateTime.now().millisecondsSinceEpoch}.mp3";
// //     _sendMessage(voicePath: fakeVoicePath);
// //   }

// //   void _navigateToCall(String type) {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (_) => type == 'voice' ? const VoiceCallScreen() : const VideoCallScreen(),
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _recordingTimer?.cancel();
// //     _messageController.dispose();
// //     super.dispose();
// //   }

// //   Widget _buildMessageInputField() {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// //       color: Colors.white,
// //       child: Row(
// //         children: [
// //           const Icon(Icons.emoji_emotions_outlined),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: TextField(
// //               controller: _messageController,
// //               decoration: const InputDecoration(
// //                 hintText: 'message . . .',
// //                 border: InputBorder.none,
          
// //               ),
// //               boderadies:RADIUS(30)
// //               onChanged: (value) => setState(() {}),
// //               onSubmitted: (_) => _sendMessage(text: _messageController.text),
// //             ),
// //           ),
// //           const SizedBox(width: 4),
// //           _messageController.text.isNotEmpty
// //               ? GestureDetector(
// //                   onTap: () => _sendMessage(text: _messageController.text),
// //                   child: const CircleAvatar(
// //                     backgroundColor: Colors.blue[900],
// //                     child: Icon(Icons.send, color: Colors.white),
// //                   ),
// //                 )
// //               : GestureDetector(
// //                   onLongPressStart: (_) => _startRecording(),
// //                   onLongPressEnd: (_) => _stopRecording(),
// //                   child: CircleAvatar(
// //                     backgroundColor: _isRecording ? Colors.red : Colors.blue[900],
// //                     child: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: Colors.white),
// //                   ),
// //                 ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildMessage(Map<String, dynamic> message) {
// //     return Align(
// //       alignment: Alignment.centerRight,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //         decoration: BoxDecoration(
// //           color: Colors.green[100],
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             if (message['voice'] != null)
// //               Row(
// //                 children: [
// //                   const Icon(Icons.play_arrow),
// //                   Text("Voice Message"),
// //                 ],
// //               )
// //             else
// //               Flexible(child: Text(message['text'] ?? "")),
// //             const SizedBox(width: 8),
// //             Text(message['time'], style: const TextStyle(fontSize: 10, color: Colors.black54)),
// //             const SizedBox(width: 4),
// //             Icon(message['isRead'] ? Icons.done_all : Icons.done, size: 14, color: Colors.grey),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Row(
// //           children: const [
// //             CircleAvatar(child: Icon(Icons.person)),
// //             SizedBox(width: 8),
// //             Text('Doctor'),
// //           ],
// //         ),
// //         backgroundColor: Colors.teal,
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.videocam),
// //             onPressed: () => _navigateToCall("video"),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.call),
// //             onPressed: () => _navigateToCall("voice"),
// //           ),
// //         ],
// //       ),
// //       body: Column(
// //         children: [
// //           const SizedBox(height: 10),
// //           const Chip(label: Text("Today")),
// //           Expanded(
// //             child: ListView.builder(
// //               reverse: true,
// //               itemCount: _messages.length,
// //               itemBuilder: (context, index) {
// //                 final message = _messages[_messages.length - 1 - index];
// //                 return _buildMessage(message);
// //               },
// //             ),
// //           ),
// //           _isRecording
// //               ? Padding(
// //                   padding: const EdgeInsets.only(bottom: 8),
// //                   child: Text("Recording: $_recordDuration s",
// //                       style: const TextStyle(color: Colors.red)),
// //                 )
// //               : const SizedBox(),
// //           _buildMessageInputField(),
// //         ],
// //       ),
// //     );
// //   }
// // }

































// // import 'package:flutter/material.dart';
// // // import 'package:cloud_firestore/cloud_firestore.dart'; // Uncomment when using Firebase

// // class ChatScreen extends StatefulWidget {
// //   const ChatScreen({super.key});

// //   @override
// //   State<ChatScreen> createState() => _ChatScreenState();
// // }

// // class _ChatScreenState extends State<ChatScreen> {
// //   final TextEditingController _messageController = TextEditingController();
// //   final List<String> _messages = [];

// //   void _sendMessage() {
// //     final text = _messageController.text.trim();
// //     if (text.isNotEmpty) {
// //       setState(() {
// //         _messages.add(text);
// //         _messageController.clear();
// //       });

// //       // TODO: Uncomment to send message to database
// //       /*
// //       FirebaseFirestore.instance.collection('chats').add({
// //         'text': text,
// //         'createdAt': Timestamp.now(),
// //         'senderId': 'userId', // Replace with actual user ID
// //       });
// //       */
// //     }
// //   }

// //   void _simulateCall(String type) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('Simulating $type call...')),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Row(
// //           children: const [
// //             CircleAvatar(
// //               // backgroundImage: AssetImage('assets/images/avatar4.jpg'),
// //               child: Icon(Icons.person),
// //             ),
// //             SizedBox(width: 8),
// //             Text('Doctor'),
// //           ],
// //         ),
// //         backgroundColor: Colors.teal,
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.videocam),
// //             onPressed: () => _simulateCall("video"),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.call),
// //             onPressed: () => _simulateCall("voice"),
// //           ),
// //           const SizedBox(width: 8),
// //         ],
// //       ),
// //       body: Column(
// //         children: [
// //           const SizedBox(height: 10),
// //           _buildDateChip("Today"),

// //           // TODO: Replace with StreamBuilder to fetch messages from database
// //           Expanded(
// //             child: ListView.builder(
// //               reverse: true,
// //               itemCount: _messages.length,
// //               itemBuilder: (context, index) {
// //                 final message = _messages[_messages.length - 1 - index];
// //                 return _buildMyMessage(message, "Now", true);
// //               },
// //             ),
// //           ),

// //           _buildMessageInputField(),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildDateChip(String date) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 8),
// //       child: Chip(label: Text(date)),
// //     );
// //   }

// //   Widget _buildMyMessage(String text, String time, bool isRead) {
// //     return Align(
// //       alignment: Alignment.centerRight,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //         decoration: BoxDecoration(
// //           color: Colors.green[100],
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Flexible(child: Text(text)),
// //             const SizedBox(width: 8),
// //             Text(time, style: const TextStyle(fontSize: 10, color: Colors.black54)),
// //             const SizedBox(width: 4),
// //             Icon(isRead ? Icons.done_all : Icons.done, size: 14, color: Colors.grey),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildMessageInputField() {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// //       color: Colors.white,
// //       child: Row(
// //         children: [
// //           const Icon(Icons.emoji_emotions_outlined),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: TextField(
// //               controller: _messageController,
// //               decoration: const InputDecoration(
// //                 hintText: 'Type a message...',
// //                 border: InputBorder.none,
// //               ),
// //               onChanged: (value) => setState(() {}),
// //               onSubmitted: (_) => _sendMessage(),
// //             ),
// //           ),
// //           const SizedBox(width: 4),
// //           _messageController.text.isNotEmpty
// //               ? GestureDetector(
// //                   onTap: _sendMessage,
// //                   child: const CircleAvatar(
// //                     backgroundColor: Colors.teal,
// //                     child: Icon(Icons.send, color: Colors.white),
// //                   ),
// //                 )
// //               : const CircleAvatar(
// //                   backgroundColor: Colors.teal,
// //                   child: Icon(Icons.mic, color: Colors.white),
// //                 ),
// //         ],
// //       ),
// //     );
// //   }
// // }


































// // import 'package:flutter/material.dart';

// // class ChatScreen extends StatelessWidget {
// //   const ChatScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Row(
// //           children: [
// //             const CircleAvatar(
// //               //backgroundImage: AssetImage('assets/images/avatar4.jpg'),
// //             ),
// //             const SizedBox(width: 8),
// //             const Text('doctor'),
// //           ],
// //         ),
// //         backgroundColor: Colors.teal,
// //         actions: const [
// //           Icon(Icons.videocam),
// //           SizedBox(width: 16),
// //           Icon(Icons.call),
// //           SizedBox(width: 16),
// //           Icon(Icons.more_vert),
// //           SizedBox(width: 8),
// //         ],
// //       ),
// //       body: Container(
// //         decoration: const BoxDecoration(
// //         //   image: DecorationImage(
// //         //     //image: AssetImage('assets/images/chat_bg.png'),
// //         //     fit: BoxFit.cover,
// //         //   ),
// //         ),
// //         child: Column(
// //           children: [
// //             const SizedBox(height: 10),
// //             _buildDateChip("26 April 2025"),
// //             _buildMissedCallTile("Missed video call", "5:25 pm"),
// //            // _buildVoiceMessageTile("assets/images/avatar4.jpg", "0:01", "5:26 pm"),
// //            // _buildVoiceMessageTile("assets/images/avatar4.jpg", "0:09", "5:26 pm"),
// //             // _buildMissedCallTile("Missed video call", "5:26 pm"),
// //             // _buildMissedCallTile("Missed video call", "5:26 pm"),
// //             _buildDateChip("Today"),
// //             _buildMyMessage("Hello", "8:30 am", true),
// //             _buildMyCallTile("Voice call", "No answer", "8:30 am"),
// //             const Spacer(),
// //             _buildMessageInputField(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildDateChip(String date) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 8),
// //       child: Chip(label: Text(date)),
// //     );
// //   }

// //   Widget _buildMissedCallTile(String title, String time) {
// //     return Row(
// //       children: [
// //         const SizedBox(width: 10),
// //         const Icon(Icons.videocam, color: Colors.red),
// //         const SizedBox(width: 10),
// //         Container(
// //           padding: const EdgeInsets.all(12),
// //           margin: const EdgeInsets.symmetric(vertical: 4),
// //           decoration: BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
// //               Text("Tap to call back", style: TextStyle(color: Colors.grey[600])),
// //               Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
// //             ],
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildVoiceMessageTile(String avatar, String duration, String time) {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.end,
// //       children: [
// //         Container(
// //           margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //           padding: const EdgeInsets.all(10),
// //           decoration: BoxDecoration(
// //             color: Colors.teal[100],
// //             borderRadius: BorderRadius.circular(20),
// //           ),
// //           child: Row(
// //             children: [
// //               const Icon(Icons.play_arrow),
// //               Container(
// //                 width: 100,
// //                 height: 20,
// //                 color: Colors.teal[300],
// //               ),
// //               const SizedBox(width: 8),
// //               Text(duration),
// //               const SizedBox(width: 8),
// //               const Icon(Icons.mic, size: 18),
// //               const SizedBox(width: 8),
// //               CircleAvatar(radius: 12, backgroundImage: AssetImage(avatar)),
// //             ],
// //           ),
// //         ),
// //         Padding(
// //           padding: const EdgeInsets.only(right: 10),
// //           child: Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildMyMessage(String text, String time, bool isRead) {
// //     return Align(
// //       alignment: Alignment.centerRight,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //         decoration: BoxDecoration(
// //           color: Colors.green[100],
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(text),
// //             const SizedBox(width: 8),
// //             Text(time, style: const TextStyle(fontSize: 10, color: Colors.black54)),
// //             const SizedBox(width: 4),
// //             Icon(isRead ? Icons.done_all : Icons.done, size: 14, color: Colors.grey),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildMyCallTile(String label, String status, String time) {
// //     return Align(
// //       alignment: Alignment.centerRight,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //         decoration: BoxDecoration(
// //           color: Colors.green[100],
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               children: [
// //                 const Icon(Icons.call, size: 16),
// //                 const SizedBox(width: 6),
// //                 Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
// //               ],
// //             ),
// //             Text(status),
// //             Text(time, style: const TextStyle(fontSize: 10, color: Colors.black54)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildMessageInputField() {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// //       color: Colors.white,
// //       child: Row(
// //         children: [
// //           const Icon(Icons.emoji_emotions_outlined),
// //           const SizedBox(width: 8),
// //           const Expanded(
// //             child: TextField(
// //               decoration: InputDecoration(
// //                 hintText: 'Message',
// //                 border: InputBorder.none,
// //               ),
// //             ),
// //           ),
    
// //           const CircleAvatar(
// //             backgroundColor: Colors.blue[900],
// //             child: Icon(Icons.massage, color: Colors.white),
// //             child: Icon(Icons.mic, color: Colors.white),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
