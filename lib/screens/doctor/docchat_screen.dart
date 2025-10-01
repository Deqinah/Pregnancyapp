import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String fullName;
  final String userId;
  final bool isDoctor;
  final String? doctorTitle;

  const ChatScreen({
    super.key,
    required this.fullName,
    required this.userId,
    this.isDoctor = false,
    this.doctorTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  late String _chatId;
  bool _welcomeMessageSent = false;

  @override
  void initState() {
    super.initState();
    _chatId = _generateChatId();
    _markMessagesAsRead();
    _checkAndSendWelcomeMessage();
  }

  Future<void> _checkAndSendWelcomeMessage() async {
    // Check if this is a doctor profile and welcome message hasn't been sent yet
    if (widget.isDoctor && !_welcomeMessageSent) {
      final chatDoc = await _firestore.collection('chats').doc(_chatId).get();
      
      // If this is a new chat (no messages exist yet)
      if (!chatDoc.exists) {
        await Future.delayed(const Duration(seconds: 1)); // Small delay for better UX
        await _sendWelcomeMessage();
      } else {
        // Check if there are any messages in the chat
        final messages = await _firestore
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .count()
            .get();
            
        if (messages.count == 0) {
          await _sendWelcomeMessage();
        }
      }
    }
  }

  Future<void> _sendWelcomeMessage() async {
    if (_welcomeMessageSent) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final title = widget.doctorTitle ?? 'Dr';
    final welcomeMessage = "Kusoo dhawaaw ${title} ${widget.fullName}, sidee ku caawin karaa?";

    try {
      await _firestore.runTransaction((transaction) async {
        final chatDoc = _firestore.collection('chats').doc(_chatId);
        final doc = await transaction.get(chatDoc);

        if (!doc.exists) {
          transaction.set(chatDoc, {
            'participants': [currentUser.uid, widget.userId],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        final messagesRef = chatDoc.collection('messages');
        transaction.set(messagesRef.doc(), {
          'text': welcomeMessage,
          'senderId': widget.userId, // Sending as the doctor
          'receiverId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'isWelcome': true, // Mark as welcome message for tracking
        });

        transaction.update(chatDoc, {
          'lastMessage': welcomeMessage,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': widget.userId,
        });
      });

      _welcomeMessageSent = true;
    } catch (e) {
      debugPrint('Error sending welcome message: $e');
      // You might want to retry after a delay
    }
  }

  String _generateChatId() {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final otherUserId = widget.userId;
    final participants = [currentUserId, otherUserId];
    participants.sort();
    return participants.join('_');
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final unreadMessages = await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in unreadMessages.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (_isSending || text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final chatDoc = _firestore.collection('chats').doc(_chatId);
        final doc = await transaction.get(chatDoc);

        if (!doc.exists) {
          transaction.set(chatDoc, {
            'participants': [currentUser.uid, widget.userId],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        final messagesRef = chatDoc.collection('messages');
        transaction.set(messagesRef.doc(), {
          'text': text,
          'senderId': currentUser.uid,
          'receiverId': widget.userId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        transaction.update(chatDoc, {
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUser.uid,
        });
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _sendMessage,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue[100],
              child: Text(
                widget.fullName.isNotEmpty 
                    ? widget.fullName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.fullName),
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

                final messages = snapshot.data?.docs ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsRead();
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _auth.currentUser?.uid;
                    final isRead = data['isRead'] ?? true;
                    final isWelcome = data['isWelcome'] ?? false;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: 
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isWelcome 
                                    ? Colors.green[100]
                                    : isMe 
                                        ? Colors.blue 
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: 
                                      isMe ? const Radius.circular(12) : Radius.zero,
                                  bottomRight: 
                                      isMe ? Radius.zero : const Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                data['text'] ?? '',
                                style: TextStyle(
                                  color: isWelcome 
                                      ? Colors.green[900]
                                      : isMe 
                                          ? Colors.white 
                                          : Colors.black,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTimestamp(data['timestamp'] as Timestamp),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  if (isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        isRead ? Icons.done_all : Icons.done,
                                        size: 14,
                                        color: isRead ? Colors.blue : Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
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

// class ChatScreen extends StatefulWidget {
//   final String fullName;
//   final String userId;

//   const ChatScreen({
//     super.key,
//     required this.fullName,
//     required this.userId,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isSending = false;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = _generateChatId();
//     _markMessagesAsRead();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final otherUserId = widget.userId;
//     final participants = [currentUserId, otherUserId];
//     participants.sort();
//     return participants.join('_');
//   }

//   Future<void> _markMessagesAsRead() async {
//     try {
//       final currentUserId = _auth.currentUser?.uid;
//       if (currentUserId == null) return;

//       final unreadMessages = await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .where('receiverId', isEqualTo: currentUserId)
//           .where('isRead', isEqualTo: true)
//           .get();

//       if (unreadMessages.docs.isNotEmpty) {
//         final batch = _firestore.batch();
//         for (final doc in unreadMessages.docs) {
//           batch.update(doc.reference, {'isRead': true});
//         }
//         await batch.commit();
//       }
//     } catch (e) {
//       debugPrint('Error marking messages as read: $e');
//     }
//   }

//   Future<void> _sendMessage() async {
//     final text = _messageController.text.trim();
//     if (_isSending || text.isEmpty) return;

//     setState(() => _isSending = true);

//     try {
//       final currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         throw Exception('User not authenticated');
//       }

//       await _firestore.runTransaction((transaction) async {
//         final chatDoc = _firestore.collection('chats').doc(_chatId);
//         final doc = await transaction.get(chatDoc);

//         if (!doc.exists) {
//           transaction.set(chatDoc, {
//             'participants': [currentUser.uid, widget.userId],
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         }

//         final messagesRef = chatDoc.collection('messages');
//         transaction.set(messagesRef.doc(), {
//           'text': text,
//           'senderId': currentUser.uid,
//           'receiverId': widget.userId,
//           'timestamp': FieldValue.serverTimestamp(),
//           'isRead': true,
//         });

//         transaction.update(chatDoc, {
//           'lastMessage': text,
//           'lastMessageTime': FieldValue.serverTimestamp(),
//           'lastMessageSender': currentUser.uid,
//         });
//       });

//       _messageController.clear();
//       _scrollToBottom();
//     } catch (e, stackTrace) {
//       debugPrint('Error sending message: $e');
//       debugPrint('Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send message: ${e.toString()}'),
//             action: SnackBarAction(
//               label: 'Retry',
//               onPressed: _sendMessage,
//             ),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isSending = false);
//       }
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
      
//       appBar: AppBar(
//   title: Row(
//     children: [
//         child: CircleAvatar(
//           radius: 25,
//           backgroundColor: Colors.blue[100],
//           child: Text(
//             widget.fullName.isNotEmpty 
//                 ? widget.fullName[0].toUpperCase()
//                 : 'U',
//             style: TextStyle(
//               color: Colors.blue[900],
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     ],
//   ),
//   actions: [
//     IconButton(
//       icon: const Icon(Icons.call),
//       onPressed: () {
//         // Add call functionality here
//       },
//     ),
//   ],
// ),
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

//                 final messages = snapshot.data?.docs ?? [];

//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   _markMessagesAsRead();
//                 });

//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     final message = messages[index];
//                     final data = message.data() as Map<String, dynamic>;
//                     final isMe = data['senderId'] == _auth.currentUser?.uid;
//                     final isRead = data['isRead'] ?? true;
                    
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       child: Align(
//                         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Column(
//                           crossAxisAlignment: 
//                               isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: isMe ? Colors.blue : Colors.grey[200],
//                                 borderRadius: BorderRadius.only(
//                                   topLeft: const Radius.circular(12),
//                                   topRight: const Radius.circular(12),
//                                   bottomLeft: 
//                                       isMe ? const Radius.circular(12) : Radius.zero,
//                                   bottomRight: 
//                                       isMe ? Radius.zero : const Radius.circular(12),
//                                 ),
//                               ),
//                               child: Text(
//                                 data['text'] ?? '',
//                                 style: TextStyle(
//                                   color: isMe ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.only(top: 4),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     _formatTimestamp(data['timestamp'] as Timestamp),
//                                     style: const TextStyle(fontSize: 10, color: Colors.grey),
//                                   ),
//                                   if (isMe)
//                                     Padding(
//                                       padding: const EdgeInsets.only(left: 4),
//                                       child: Icon(
//                                         isRead ? Icons.done_all : Icons.done,
//                                         size: 14,
//                                         color: isRead ? Colors.blue : Colors.grey,
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: _isSending
//                       ? const CircularProgressIndicator(strokeWidth: 2)
//                       : const Icon(Icons.send),
//                   onPressed: _isSending ? null : _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// otamatically sending massage when user uu soo booqdo profikayga waxaad tiraahdaa 
// kusoo dhawaawaw Dr ....... how can i help you 

// when user click doctor profile receive otamatically sending maasage
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
//   final String fullName;
//   final String userId;
//   final String? chatId;

//   const ChatScreen({
//     super.key,
//     required this.fullName,
//     required this.userId,
//     this.chatId,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isSending = false;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = widget.chatId ?? _generateChatId();
//     _markMessagesAsRead();
//     _verifyChatConnection();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final otherUserId = widget.userId;
//     final participants = [currentUserId, otherUserId];
//     participants.sort();
//     return participants.join('_');
//   }

//   Future<void> _verifyChatConnection() async {
//     try {
//       await _firestore.collection('chats').doc(_chatId).get();
//     } catch (e) {
//       debugPrint('Firestore connection error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Connection error: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _markMessagesAsRead() async {
//     try {
//       final currentUserId = _auth.currentUser?.uid;
//       if (currentUserId == null) return;

//       final unreadMessages = await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .where('receiverId', isEqualTo: currentUserId)
//           .where('isRead', isEqualTo: false)
//           .get();

//       if (unreadMessages.docs.isNotEmpty) {
//         final batch = _firestore.batch();
//         for (final doc in unreadMessages.docs) {
//           batch.update(doc.reference, {'isRead': true});
//         }
//         await batch.commit();
//       }
//     } catch (e) {
//       debugPrint('Error marking messages as read: $e');
//     }
//   }

//   Future<void> _sendMessage() async {
//     final text = _messageController.text.trim();
//     if (_isSending || text.isEmpty) return;

//     setState(() => _isSending = true);

//     try {
//       final currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         throw Exception('User not authenticated');
//       }

//       // Check Firestore permissions
//       await _firestore.runTransaction((transaction) async {
//         final chatDoc = _firestore.collection('chats').doc(_chatId);
//         final doc = await transaction.get(chatDoc);

//         if (!doc.exists) {
//           transaction.set(chatDoc, {
//             'participants': [currentUser.uid, widget.userId],
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         }

//         final messagesRef = chatDoc.collection('messages');
//         transaction.set(messagesRef.doc(), {
//           'text': text,
//           'senderId': currentUser.uid,
//           'receiverId': widget.userId,
//           'timestamp': FieldValue.serverTimestamp(),
//           'isRead': false,
//         });

//         transaction.update(chatDoc, {
//           'lastMessage': text,
//           'lastMessageTime': FieldValue.serverTimestamp(),
//           'lastMessageSender': currentUser.uid,
//         });
//       });

//       _messageController.clear();
//       _scrollToBottom();
//     } catch (e, stackTrace) {
//       debugPrint('Error sending message: $e');
//       debugPrint('Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send message: ${e.toString()}'),
//             action: SnackBarAction(
//               label: 'Retry',
//               onPressed: _sendMessage,
//             ),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isSending = false);
//       }
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.fullName),
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

//                 final messages = snapshot.data?.docs ?? [];

//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   _markMessagesAsRead();
//                 });

//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     final message = messages[index];
//                     final data = message.data() as Map<String, dynamic>;
//                     final isMe = data['senderId'] == _auth.currentUser?.uid;
                    
//                     return ListTile(
//                       title: Align(
//                         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: isMe ? Colors.blue : Colors.grey,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             data['text'] ?? '',
//                             style: TextStyle(color: isMe ? Colors.white : Colors.black),
//                           ),
//                         ),
//                       ),
//                       subtitle: Align(
//                         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Padding(
//                           padding: const EdgeInsets.only(top: 4),
//                           child: Text(
//                             _formatTimestamp(data['timestamp'] as Timestamp),
//                             style: const TextStyle(fontSize: 10),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _isSending ? null : _sendMessage,
//                 ),
//               ],
//             ),
//           ),
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

// class DocChatScreen extends StatefulWidget {
//   final String fullName;
//   final String userId;
//   final String? chatId;

//   const DocChatScreen({
//     super.key,
//     required this.fullName,
//     required this.userId,
//     this.chatId,
//   });

//   @override
//   State<DocChatScreen> createState() => _DocChatScreenState();
// }

// class _DocChatScreenState extends State<DocChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isSending = false;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = widget.chatId ?? _generateChatId();
//     _markMessagesAsRead();
//     _verifyChatConnection();
//   }

//   Future<void> _verifyChatConnection() async {
//     try {
//       // Verify we can access Firestore
//       await _firestore.collection('chats').doc(_chatId).get();
//     } catch (e) {
//       debugPrint('Firestore connection error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Connection error: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final otherUserId = widget.userId;
//     return [currentUserId, otherUserId]..sort().join('_');
//   }

//   Future<void> _markMessagesAsRead() async {
//     try {
//       final currentUserId = _auth.currentUser?.uid;
//       if (currentUserId == null) return;

//       final unreadMessages = await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .where('receiverId', isEqualTo: currentUserId)
//           .where('isRead', isEqualTo: false)
//           .get();

//       if (unreadMessages.docs.isNotEmpty) {
//         final batch = _firestore.batch();
//         for (final doc in unreadMessages.docs) {
//           batch.update(doc.reference, {'isRead': true});
//         }
//         await batch.commit();
//       }
//     } catch (e) {
//       debugPrint('Error marking messages as read: $e');
//     }
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
//     if (_isSending || text.isEmpty) return;

//     setState(() => _isSending = true);

//     try {
//       final currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         throw Exception('User not authenticated');
//       }

//       // 1. Create/update the chat document
//       await _firestore.collection('chats').doc(_chatId).set({
//         'participants': [currentUser.uid, widget.userId],
//         'lastMessage': text,
//         'lastMessageTime': FieldValue.serverTimestamp(),
//         'lastMessageSender': currentUser.uid,
//       }, SetOptions(merge: true));

//       // 2. Add the new message
//       final messageRef = await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add({
//         'text': text,
//         'senderId': currentUser.uid,
//         'receiverId': widget.userId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       });

//       debugPrint('Message sent successfully with ID: ${messageRef.id}');
      
//       _messageController.clear();
//       _scrollToBottom();
//     } catch (e, stackTrace) {
//       debugPrint('Error sending message: $e');
//       debugPrint('Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Failed to send message'),
//             action: SnackBarAction(
//               label: 'Retry',
//               onPressed: _sendMessage,
//             ),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isSending = false);
//       }
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   Widget _buildMessageBubble(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final messageText = data['text'] ?? '';
//     final isRead = data['isRead'] ?? false;
//     final timestamp = data['timestamp'] as Timestamp?;

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.75,
//         ),
//         child: Column(
//           crossAxisAlignment:
//               isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[500] : Colors.grey[200],
//                 borderRadius: BorderRadius.only(
//                   topLeft: const Radius.circular(16),
//                   topRight: const Radius.circular(16),
//                   bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
//                   bottomRight: isMe ? Radius.zero : const Radius.circular(16),
//                 ),
//               ),
//               child: Text(
//                 messageText,
//                 style: TextStyle(
//                   color: isMe ? Colors.white : Colors.black,
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (timestamp != null)
//                     Text(
//                       _formatTimestamp(timestamp),
//                       style: const TextStyle(fontSize: 10, color: Colors.grey),
//                     ),
//                   if (isMe)
//                     Padding(
//                       padding: const EdgeInsets.only(left: 4),
//                       child: Icon(
//                         isRead ? Icons.done_all : Icons.done,
//                         size: 14,
//                         color: isRead ? Colors.blue : Colors.grey,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInputField() {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               decoration: InputDecoration(
//                 hintText: 'Type a message...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(24),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//               ),
//               onSubmitted: (_) => _sendMessage(),
//             ),
//           ),
//           const SizedBox(width: 8),
//           CircleAvatar(
//             backgroundColor: Colors.blue,
//             child: IconButton(
//               icon: _isSending
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                   : const Icon(Icons.send, color: Colors.white),
//               onPressed: _isSending ? null : _sendMessage,
//             ),
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
//               backgroundColor: Colors.blue[100],
//               child: Text(
//                 widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?',
//                 style: const TextStyle(color: Colors.blue),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Text(widget.fullName),
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
//                   return Center(
//                     child: Text(
//                       'Error loading messages\n${snapshot.error}',
//                       textAlign: TextAlign.center,
//                     ),
//                   );
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final messages = snapshot.data?.docs ?? [];

//                 if (messages.isEmpty) {
//                   return const Center(
//                     child: Text('No messages yet. Start the conversation!'),
//                   );
//                 }

//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   _markMessagesAsRead();
//                   _scrollToBottom();
//                 });

//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   padding: const EdgeInsets.only(bottom: 8),
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     return _buildMessageBubble(messages[index]);
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

// class DocChatScreen extends StatefulWidget {
//   final String fullName;
//   final String userId;
//   final String? chatId;

//   const DocChatScreen({
//     super.key,
//     required this.fullName,
//     required this.userId,
//     this.chatId,
//   });

//   @override
//   State<DocChatScreen> createState() => _DocChatScreenState();
// }

// class _DocChatScreenState extends State<DocChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isSending = false;
//   late String _chatId;

//   @override
//   void initState() {
//     super.initState();
//     _chatId = widget.chatId ?? _generateChatId();
//     _markMessagesAsRead();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final otherUserId = widget.userId;
//     final participants = [currentUserId, otherUserId]..sort();
//     return participants.join('_');
//   }

//   Future<void> _markMessagesAsRead() async {
//     final currentUserId = _auth.currentUser?.uid;
//     if (currentUserId == null) return;

//     final messages = await _firestore
//         .collection('chats')
//         .doc(_chatId)
//         .collection('messages')
//         .where('receiverId', isEqualTo: currentUserId)
//         .where('isRead', isEqualTo: false)
//         .get();

//     final batch = _firestore.batch();
//     for (final doc in messages.docs) {
//       batch.update(doc.reference, {'isRead': true});
//     }
//     await batch.commit();
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
//     if (_isSending || text.isEmpty) return;

//     setState(() => _isSending = true);

//     try {
//       final currentUser = _auth.currentUser;
//       if (currentUser == null) return;

//       // Ensure chat document exists
//       await _firestore.collection('chats').doc(_chatId).set({
//         'participants': [currentUser.uid, widget.userId],
//         'lastMessage': text,
//         'lastMessageTime': FieldValue.serverTimestamp(),
//         'lastMessageSender': currentUser.uid,
//       }, SetOptions(merge: true));

//       // Add the message
//       await _firestore
//           .collection('chats')
//           .doc(_chatId)
//           .collection('messages')
//           .add({
//         'text': text,
//         'senderId': currentUser.uid,
//         'receiverId': widget.userId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       });

//       _messageController.clear();
//       _scrollToBottom();
//     } catch (e) {
//       debugPrint('Error sending message: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to send message')),
//       );
//     } finally {
//       if (mounted) setState(() => _isSending = false);
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollController.animateTo(
//         0,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     });
//   }

//   Widget _buildMessageBubble(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final messageText = data['text'] ?? '';
//     final isRead = data['isRead'] ?? false;
//     final timestamp = data['timestamp'] as Timestamp?;

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Column(
//         crossAxisAlignment:
//             isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Container(
//             constraints: BoxConstraints(
//               maxWidth: MediaQuery.of(context).size.width * 0.75,
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: isMe ? Colors.blue[500] : Colors.grey[200],
//               borderRadius: BorderRadius.only(
//                 topLeft: const Radius.circular(16),
//                 topRight: const Radius.circular(16),
//                 bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
//                 bottomRight: isMe ? Radius.zero : const Radius.circular(16),
//               ),
//             ),
//             child: Text(
//               messageText,
//               style: TextStyle(
//                 color: isMe ? Colors.white : Colors.black,
//               ),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment:
//                 isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//             children: [
//               if (timestamp != null)
//                 Text(
//                   _formatTimestamp(timestamp),
//                   style: const TextStyle(fontSize: 10, color: Colors.grey),
//                 ),
//               if (isMe)
//                 Padding(
//                   padding: const EdgeInsets.only(left: 4),
//                   child: Icon(
//                     isRead ? Icons.done_all : Icons.done,
//                     size: 14,
//                     color: isRead ? Colors.blue : Colors.grey,
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputField() {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               decoration: InputDecoration(
//                 hintText: 'Type a message...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(24),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//               ),
//               onSubmitted: (_) => _sendMessage(),
//             ),
//           ),
//           const SizedBox(width: 8),
//           CircleAvatar(
//             backgroundColor: Colors.blue,
//             child: IconButton(
//               icon: _isSending
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                   : const Icon(Icons.send, color: Colors.white),
//               onPressed: _isSending ? null : _sendMessage,
//             ),
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
//               backgroundColor: Colors.blue[100],
//               child: Text(
//                 widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?',
//                 style: const TextStyle(color: Colors.blue),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Text(widget.fullName),
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

//                 // Mark messages as read when new ones arrive
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   _markMessagesAsRead();
//                 });

//                 final messages = snapshot.data?.docs ?? [];

//                 if (messages.isEmpty) {
//                   return const Center(
//                     child: Text('Start a conversation'),
//                   );
//                 }

//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   padding: const EdgeInsets.only(bottom: 8),
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     return _buildMessageBubble(messages[index]);
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

// class DocChatScreen extends StatefulWidget {
//   final String fullName;
//   final String userId;
//   final bool isUser;

//   const DocChatScreen({
//     super.key,
//     required this.fullName,
//     required this.userId,
//     this.isUser = false,
//   });

//   @override
//   State<DocChatScreen> createState() => _DocChatScreenState();
// }

// class _DocChatScreenState extends State<DocChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isVoiceMode = true;
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
//     _markMessagesAsRead();
//   }

//   Future<void> _markMessagesAsRead() async {
//     final currentUserId = _auth.currentUser?.uid;
//     if (currentUserId == null) return;

//     final messages = await _firestore
//         .collection('chats')
//         .doc(_chatId)
//         .collection('messages')
//         .where('receiverId', isEqualTo: currentUserId)
//         .where('isRead', isEqualTo: false)
//         .get();

//     final batch = _firestore.batch();
//     for (final doc in messages.docs) {
//       batch.update(doc.reference, {'isRead': true});
//     }
//     await batch.commit();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final otherUserId = widget.userId;
//     final participants = [currentUserId, otherUserId]..sort();
//     return participants.join('_');
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

//   Future<void> _sendMessage({String? text}) async {
//     if (_isSending || (text == null || text.isEmpty)) return;

//     setState(() => _isSending = true);

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();

//       if (!doc.exists) {
//         await chatDoc.set({
//           'participants': [_auth.currentUser!.uid, widget.userId],
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }

//       await chatDoc.collection('messages').add({
//         'text': text,
//         'senderId': _auth.currentUser!.uid,
//         'receiverId': widget.userId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       });

//       _messageController.clear();
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       });
//     } catch (e) {
//       debugPrint('Error sending message: $e');
//     } finally {
//       if (mounted) setState(() => _isSending = false);
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
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: TextField(
//                   controller: _messageController,
//                   decoration: const InputDecoration(
//                     hintText: 'Type a message...',
//                     border: InputBorder.none,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _isVoiceMode
//               ? IconButton(
//                   icon: const Icon(Icons.mic, color: Colors.blue),
//                   onPressed: () {},
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
//                       : () => _sendMessage(text: _messageController.text.trim()),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final messageText = data['text'] ?? '';
//     final isRead = data['isRead'] ?? false;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment:
//             isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isUser)
//             Text(
//               widget.fullName,
//               style: const TextStyle(
//                   fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: isMe ? Colors.blue[100] : Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(messageText),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 _formatTimestamp(data['timestamp'] as Timestamp),
//                 style: const TextStyle(fontSize: 10, color: Colors.grey),
//               ),
//               if (isMe)
//                 Icon(
//                   isRead ? Icons.done_all : Icons.done,
//                   size: 14,
//                   color: isRead ? Colors.blue : Colors.grey,
//                 ),
//             ],
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
//               radius: 18,
//               child: Text(widget.fullName.isNotEmpty ? widget.fullName[0] : '?'),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.fullName),
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
                
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   _markMessagesAsRead();
//                 });

//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     return _buildMessage(snapshot.data!.docs[index]);
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

// class DocChatScreen extends StatefulWidget {
//   final String fullName;
//   final String userId;
//   final bool isUser;

//   const DocChatScreen({
//     super.key,
//     required this.fullName,
//     required this.userId,
//     this.isUser = false,
//   });

//   @override
//   State<DocChatScreen> createState() => _DocChatScreenState();
// }

// class _DocChatScreenState extends State<DocChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();

//   bool _isVoiceMode = true;
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
//     _markMessagesAsRead();
//   }

//   // Mark all unread messages as read when doctor opens the chat
//   Future<void> _markMessagesAsRead() async {
//     final currentUserId = _auth.currentUser?.uid;
//     if (currentUserId == null) return;

//     final messages = await _firestore
//         .collection('chats')
//         .doc(_chatId)
//         .collection('messages')
//         .where('receiverId', isEqualTo: currentUserId)
//         .where('isRead', isEqualTo: false)
//         .get();

//     final batch = _firestore.batch();
//     for (final doc in messages.docs) {
//       batch.update(doc.reference, {'isRead': true});
//     }
//     await batch.commit();
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     final otherUserId = widget.userId;
//     return [currentUserId, otherUserId]..sort();
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

//   Future<void> _sendMessage({String? text}) async {
//     if (_isSending || (text == null || text.isEmpty)) return;

//     setState(() => _isSending = true);

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();

//       if (!doc.exists) {
//         await chatDoc.set({
//           'participants': [_auth.currentUser!.uid, widget.userId],
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }

//       await chatDoc.collection('messages').add({
//         'text': text,
//         'senderId': _auth.currentUser!.uid,
//         'receiverId': widget.userId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false, // New messages are unread by default
//       });

//       _messageController.clear();
//       // Scroll to bottom after sending
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       });
//     } catch (e) {
//       debugPrint('Error sending message: $e');
//     } finally {
//       if (mounted) setState(() => _isSending = false);
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
//           ),
//           const SizedBox(width: 8),
//           _isVoiceMode
//               ? IconButton(
//                   icon: const Icon(Icons.mic, color: Colors.blue),
//                   onPressed: () {},
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
//                       : () => _sendMessage(text: _messageController.text.trim()),
//               ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final messageText = data['text'] ?? '';
//     final isRead = data['isRead'] ?? false;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment:
//             isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isUser)
//             Text(
//               widget.fullName,
//               style: const TextStyle(
//                   fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: isMe ? Colors.blue[100] : Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(messageText),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 _formatTimestamp(data['timestamp'] as Timestamp),
//                 style: const TextStyle(fontSize: 10, color: Colors.grey),
//               ),
//               if (isMe)
//                 Icon(
//                   isRead ? Icons.done_all : Icons.done,
//                   size: 14,
//                   color: isRead ? Colors.blue : Colors.grey,
//                 ),
//             ],
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
//               radius: 18,
//               child: Text(widget.fullName.isNotEmpty ? widget.fullName[0] : '?'),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.fullName),
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
                
//                 // Mark messages as read when they appear on screen
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   _markMessagesAsRead();
//                 });

//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   itemCount: snapshot.data?.docs.length ?? 0,
//                   itemBuilder: (context, index) {
//                     return _buildMessage(snapshot.data!.docs[index]);
//                   },
//                 );
//               }),
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

// class DocChatScreen extends StatefulWidget {
//   final String fullName;
//   final String userId;
//   final bool isUser;

//   const DocChatScreen({
//     super.key,
//     required this.fullName,
//     required this.userId,
//     this.isUser = false,
//   });

//   @override
//   State<DocChatScreen> createState() => _DocChatScreenState();
// }

// class _DocChatScreenState extends State<DocChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isVoiceMode = true;
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
//     if (widget.isUser) {
//       return '${widget.userId}_$currentUserId';
//     } else {
//       return '${currentUserId}_${widget.userId}';
//     }
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

//   Future<void> _sendMessage({String? text}) async {
//     if (_isSending || (text == null || text.isEmpty)) return;

//     setState(() => _isSending = true);

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();

//       if (!doc.exists) {
//         await chatDoc.set({
//           'participants': {
//             widget.isUser ? widget.userId : _auth.currentUser!.uid,
//             widget.isUser ? _auth.currentUser!.uid : widget.userId,
//           },
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }

//       await chatDoc.collection('messages').add({
//         'text': text,
//         'senderId': _auth.currentUser!.uid,
//         'receiverId': widget.userId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       });

//       // ✅ Mark user has messaged doctor
//       if (widget.isUser) {
//         await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
//           'hasMessaged_${widget.userId}': true,
//         }, SetOptions(merge: true));
//       }

//       _messageController.clear();
//     } catch (e) {
//       debugPrint('Error sending message: $e');
//     } finally {
//       if (mounted) setState(() => _isSending = false);
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
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _isVoiceMode
//               ? IconButton(
//                   icon: const Icon(Icons.mic, color: Colors.blue),
//                   onPressed: () {},
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
//                       : () => _sendMessage(text: _messageController.text.trim()),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final messageText = data['text'] ?? '';

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isUser)
//             Text(
//               widget.fullName,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: isMe ? Colors.blue[100] : Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(messageText),
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
//             CircleAvatar(
//               radius: 18,
//               child: Text(widget.fullName.isNotEmpty ? widget.fullName[0] : '?'),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.fullName),
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
//                     return _buildMessage(snapshot.data!.docs[index]);
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

// class DocChatScreen extends StatefulWidget {
//   final String userName;
//   final String userId;
//   final bool isUser;

//   const DocChatScreen({
//     super.key,
//     required this.userName,
//     required this.userId,
//     this.isUser = false,
//   });

//   @override
//   State<DocChatScreen> createState() => _DocChatScreenState();
// }

// class _DocChatScreenState extends State<DocChatScreen> {
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
//     _messageController.addListener(() {
//       setState(() {
//         _isVoiceMode = _messageController.text.isEmpty;
//       });
//     });
//   }

//   String _generateChatId() {
//     final currentUserId = _auth.currentUser?.uid ?? '';
//     if (widget.isUser) {
//       // User chatting with doctor: doctorId_userId
//       return '${widget.userId}_$currentUserId';
//     } else {
//       // Doctor chatting with user: doctorId_userId
//       return '${currentUserId}_${widget.userId}';
//     }
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

//   Future<void> _sendMessage({String? text}) async {
//     if (_isSending || (text == null || text.isEmpty)) return;

//     setState(() => _isSending = true);

//     try {
//       final chatDoc = _firestore.collection('chats').doc(_chatId);
//       final doc = await chatDoc.get();

//       if (!doc.exists) {
//         await chatDoc.set({
//           'participants': {
//             widget.isUser ? widget.userId : _auth.currentUser!.uid, // Doctor ID
//             widget.isUser ? _auth.currentUser!.uid : widget.userId, // User ID
//           },
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }

//       await chatDoc.collection('messages').add({
//         'text': text,
//         'senderId': _auth.currentUser!.uid,
//         'receiverId': widget.userId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       });

//       _messageController.clear();
//     } catch (e) {
//       debugPrint('Error sending message: $e');
//     } finally {
//       if (mounted) setState(() => _isSending = false);
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
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _isVoiceMode
//               ? IconButton(
//                   icon: const Icon(Icons.mic, color: Colors.blue),
//                   onPressed: () {},
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
//                       : () => _sendMessage(text: _messageController.text.trim()),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(DocumentSnapshot message) {
//     final data = message.data() as Map<String, dynamic>;
//     final isMe = data['senderId'] == _auth.currentUser?.uid;
//     final messageText = data['text'] ?? '';

//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: 4,
//         horizontal: isMe ? 16 : 8,
//       ),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           if (!isMe && !widget.isUser)
//             Text(
//               widget.userName,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: isMe ? Colors.blue[100] : Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(messageText),
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
//             CircleAvatar(
//               radius: 18,
//               child: Text(widget.userName.isNotEmpty ? widget.userName[0] : '?'),
//             ),
//             const SizedBox(width: 8),
//             Text(widget.userName),
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
//                     return _buildMessage(snapshot.data!.docs[index]);
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

// class DocChatScreen extends StatefulWidget {
//   final String userName;
//   final String userId;
//   final bool isuser;

//   const ChatScreen({
//     super.key,
//     required this.userName,
//     required this.userId,
//     this.isuser = false,
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
//     final userId = widget.isuser ? currentUserId : widget.userId;
//     final patientId = widget.isuser ? widget.userId : currentUserId;
//     return '${userId}_$patientId';
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
//         'userId': widget.isuser ? _auth.currentUser!.uid : widget.userId,
//         'userId': widget.isuser ? widget.userId : _auth.currentUser!.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': [
//           widget.isuser ? _auth.currentUser!.uid : widget.userId,
//           widget.isuser ? widget.userId : _auth.currentUser!.uid,
//         ],
//       });
//     }

//     final message = {
//       if (text != null) 'text': text,
//       if (audioUrl != null) 'audioUrl': audioUrl,
//       'senderId': _auth.currentUser?.uid,
//       'receiverId': widget.userId,
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
//               widget.userName,
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
//             Text(widget.userName),
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
