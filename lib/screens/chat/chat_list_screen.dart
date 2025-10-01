import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';


class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _userDoctors = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser!.uid;
    _fetchUserDoctors();
  }

  Future<void> _fetchUserDoctors() async {
  try {
    final user = _auth.currentUser;
    if (user == null) return;

    final appointmentsSnapshot = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .get();

    final doctorIds = appointmentsSnapshot.docs
        .map((doc) => doc.get('doctorId') as String?)
        .where((id) => id != null)
        .toSet();

    if (doctorIds.isEmpty) {
      if (mounted) {
        setState(() {
          _userDoctors = [];
        });
      }
      return;
    }

    final doctorsSnapshot = await _firestore
        .collection('doctors')
        .where(FieldPath.documentId, whereIn: doctorIds.toList())
        .get();

    if (mounted) {
      setState(() {
        _userDoctors = doctorsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'fullName': data['fullName'] ?? 'Unknown Doctor',
            'avatar': data.containsKey('avatar') ? data['avatar'] : '',
            'specialization':
                data.containsKey('specialization') ? data['specialization'] : '',
          };
        }).toList();
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching doctors: ${e.toString()}')),
      );
    }
  }
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
        backgroundColor: Colors.blue[900],
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/home'),
         ),
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: _userDoctors.isEmpty
          ? const Center(child: Text('You have no past appointments with any doctor'))
          : ListView.builder(
              itemCount: _userDoctors.length,
              itemBuilder: (context, index) {
                final doctor = _userDoctors[index];
                final chatId = '${doctor['id']}_$_currentUserId';

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, messageSnapshot) {
                    String lastMessage = doctor['specialization'] ?? 'Start new chat';
                    String messageTime = '';
                    bool isFromMe = false;
                    bool isRead = true;

                    if (messageSnapshot.hasData &&
                        messageSnapshot.data!.docs.isNotEmpty) {
                      final message = messageSnapshot.data!.docs.first.data()
                          as Map<String, dynamic>;
                      lastMessage = message['text'] ?? lastMessage;
                      isFromMe = message['senderId'] == _currentUserId;
                      isRead = message['isRead'] ?? true;
                      if (message['timestamp'] != null) {
                        messageTime = _formatTimestamp(
                            message['timestamp'] as Timestamp);
                      }
                    }

                    Widget avatarWidget;
                    if (doctor['avatar'] != null &&
                        doctor['avatar'].toString().isNotEmpty) {
                      avatarWidget = CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(doctor['avatar']),
                      );
                    } else {
                      final initials = doctor['fullName'].isNotEmpty
                          ? doctor['fullName'][0].toUpperCase()
                          : 'D';
                      avatarWidget = CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    return ListTile(
                      leading: avatarWidget,
                      title: Text(doctor['fullName'] ?? 'Doctor'),
                      subtitle: Text(
                        isFromMe ? 'You: $lastMessage' : lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: messageTime.isNotEmpty
                          ? Text(
                              messageTime,
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              doctorName: doctor['fullName'] ?? 'Doctor',
                              doctorId: doctor['id'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

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
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//        backgroundColor: Colors.white, 
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Chat info variables
//                   int unreadCount = 0;
//                   bool hasChat = false;
                  
//                   if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
//                     final data = chatSnapshot.data!.data() as Map<String, dynamic>;
//                     unreadCount = data['unreadCount'] as int? ?? 0;
//                     hasChat = true;
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       // Message info variables
//                       String lastMessage = hasChat 
//                           ? 'No messages yet' 
//                           : doctor['specialization'] ?? 'Start new chat';
//                       String messageTime = '';
//                       bool isFromMe = false;
//                       bool isRead = true;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         isRead = message['isRead'] ?? true;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       // Avatar widget
//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[800],
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(context).scaffoldBackgroundColor,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: TextStyle(
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.black87,
//                           ),
//                         ),
//                         subtitle: Text(
//                           isFromMe ? 'You: $lastMessage' : lastMessage,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.grey[600],
//                             fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: hasChat && messageTime.isNotEmpty
//                             ? Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 crossAxisAlignment: CrossAxisAlignment.end,
//                                 children: [
//                                   Text(
//                                     messageTime,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                   const SizedBox(height: 2),
//                                   if (isFromMe)
//                                     Icon(
//                                       isRead ? Icons.check_circle : Icons.done,
//                                       size: 16,
//                                       color: isRead ? Colors.blue[800] : Colors.grey,
//                                     ),
//                                   if (!isFromMe && unreadCount > 0)
//                                     Container(
//                                       width: 12,
//                                       height: 12,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue[800],
//                                         shape: BoxShape.circle,
//                                       ),
//                                     ),
//                                 ],
//                               )
//                             : null,
//                         onTap: () {
//                           if (hasChat) {
//                             FirebaseFirestore.instance
//                                 .collection('chats')
//                                 .doc(chatId)
//                                 .update({'unreadCount': 0});
//                           }
                          
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }






















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

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
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Chat info variables
//                   int unreadCount = 0;
//                   bool hasChat = false;
                  
//                   if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
//                     final data = chatSnapshot.data!.data() as Map<String, dynamic>;
//                     unreadCount = data['unreadCount'] as int? ?? 0;
//                     hasChat = true;
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       // Message info variables
//                       String lastMessage = hasChat 
//                           ? 'No messages yet' 
//                           : doctor['specialization'] ?? 'Start new chat';
//                       String messageTime = '';
//                       bool isFromMe = false;
//                       bool isRead = false;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         isRead = message['isRead'] ?? false;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       // Avatar widget
//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[800],
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(context).scaffoldBackgroundColor,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: TextStyle(
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.black87,
//                           ),
//                         ),
//                         subtitle: Text(
//                           isFromMe ? 'You: $lastMessage' : lastMessage, // Sida tusaalaha: "You: have walaal"
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           isnot read ? Colors.blue[900] icons.circle : Icons.done,
//                           fonts color blue[900] 
//                           style: TextStyle(
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.grey[600],
//                             fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: hasChat && messageTime.isNotEmpty
//                             ? Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 crossAxisAlignment: CrossAxisAlignment.end,
//                                 children: [
//                                   Text(
//                                     messageTime,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                   if (isFromMe)
//                                     Icon(
//                                       isRead ? Icons.check_circle : Icons.done,
//                                       size: 16,
//                                       color: isRead ? Colors.blue[800] : Colors.grey,
//                                     ),
//                                   if (!isFromMe && unreadCount > 0)
//                                     Container(
//                                       margin: const EdgeInsets.only(top: 4),
//                                       width: 12,
//                                       height: 12,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue[800],
//                                         shape: BoxShape.circle,
//                                       ),
//                                     ),
//                                 ],
//                               )
//                             : null,
//                         onTap: () {
//                           if (hasChat) {
//                             FirebaseFirestore.instance
//                                 .collection('chats')
//                                 .doc(chatId)
//                                 .update({'unreadCount': 0});
//                           }
                          
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

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
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Chat info variables
//                   int unreadCount = 0;
//                   bool hasChat = false;
                  
//                   if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
//                     final data = chatSnapshot.data!.data() as Map<String, dynamic>;
//                     unreadCount = data['unreadCount'] as int? ?? 0;
//                     hasChat = true;
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       // Message info variables
//                       String lastMessage = hasChat 
//                           ? 'No messages yet' 
//                           : doctor['specialization'] ?? 'Start new chat';
//                       String messageTime = '';
//                       bool isFromMe = false;
//                       bool isRead = false;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         isRead = message['isRead'] ?? false;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       // Avatar widget
//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[800],
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(context).scaffoldBackgroundColor,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: TextStyle(
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.black87,
//                           ),
//                         ),
//                         subtitle: Text(
//                           lastMessage,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.grey[600],
//                           ),
//                         ),
//                         trailing: hasChat && messageTime.isNotEmpty
//                             ? Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     messageTime,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                   if (isFromMe)
//                                     Icon(
//                                       isRead ? Icons.check_circle : Icons.done, // ✅ Iconka cusub (dibic)
//                                       size: 16,
//                                       color: isRead ? Colors.blue[800] : Colors.grey,
//                                     ),
//                                   if (!isFromMe && unreadCount > 0)
//                                     Container(
//                                       margin: const EdgeInsets.only(top: 4),
//                                       width: 10,
//                                       height: 10,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue[900],
//                                         shape: BoxShape.circle,
//                                       ),
//                                     ),
//                                 ],
//                               )
//                             : null,
//                         onTap: () {
//                           // Reset unread count when opening chat
//                           if (hasChat) {
//                             FirebaseFirestore.instance
//                                 .collection('chats')
//                                 .doc(chatId)
//                                 .update({'unreadCount': 0});
//                           }
                          
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

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
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Chat info variables
//                   int unreadCount = 0;
//                   bool hasChat = false;
                  
//                   if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
//                     final data = chatSnapshot.data!.data() as Map<String, dynamic>;
//                     unreadCount = data['unreadCount'] as int? ?? 0;
//                     hasChat = true;
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       // Message info variables
//                       String lastMessage = hasChat 
//                           ? 'No messages yet' 
//                           : doctor['specialization'] ?? 'Start new chat';
//                       String messageTime = '';
//                       bool isFromMe = false;
//                       bool isRead = false;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         isRead = message['isRead'] ?? false;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       // Avatar widget
//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[800],
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(context).scaffoldBackgroundColor,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: TextStyle(
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.grey[600],
//                           ),
//                         ),
//                         subtitle: Text(
//                           lastMessage,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.grey[600],
//                           ),
//                         ),
//                         trailing: hasChat && messageTime.isNotEmpty
//                             ? Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     messageTime,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                   if (isFromMe)
//                                     Icon(
//                                        isRead ? Icons.done_all : Icons.done,
//                                   size: 14,
//                                   color: isRead ? Colors.blue : Colors.grey,
//                                     ),
//                                   if (!isFromMe && unreadCount > 0)
//                                     Container(
//                                       margin: const EdgeInsets.only(top: 4),
//                                       width: 10,
//                                       height: 10,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue[900],
//                                         shape: BoxShape.circle,
//                                       ),
//                                     ),
//                                 ],
//                               )
//                             : null,
//                         onTap: () {
//                           // Reset unread count when opening chat
//                           if (hasChat) {
//                             FirebaseFirestore.instance
//                                 .collection('chats')
//                                 .doc(chatId)
//                                 .update({'unreadCount': 0});
//                           }
                          
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//      if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inHours < 1) return '${difference.inMinutes}m ago';
//     if (difference.inDays < 1) return DateFormat('h:mm a').format(messageTime);
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return DateFormat('EEEE').format(messageTime);
//     return DateFormat('MMM d, y').format(messageTime);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Chat info variables
//                   int unreadCount = 0;
//                   bool hasChat = false;
                  
//                   if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
//                     final data = chatSnapshot.data!.data() as Map<String, dynamic>;
//                     unreadCount = data['unreadCount'] as int? ?? 0;
//                     hasChat = true;
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       // Message info variables
//                       String lastMessage = hasChat 
//                           ? 'No messages yet' 
//                           : doctor['specialization'] ?? 'Start new chat';
//                       String messageTime = '';
//                       bool isFromMe = false;
//                       bool isRead = false;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         isRead = message['isRead'] ?? false;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       // Avatar widget
//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[800],
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(context).scaffoldBackgroundColor,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: TextStyle(
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.black87,
//                           ),
//                         ),
//                         subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (referredBy != null)
//                           Text(
//                             'Referred by: $referredBy',
//                             style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                           ),
//                         if (chatInfo['hasChat'])
//                           Text(
//                             '${isFromMe ? 'You: ' : ''}${chatInfo['lastMessage'] ?? 'No messages'}',
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               color: chatInfo['unreadCount'] > 0 ? Colors.blue[900] : Colors.grey[600],
//                             ),
//                           ),
//                       ],
//                     ),
//                     trailing: chatInfo['hasChat'] && chatInfo['messageTime'] != null
//                         ? Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 chatInfo['messageTime']!,
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               if (isFromMe)
//                                 Icon(
//                                   isRead ? Icons.done_all : Icons.done,
//                                   size: 14,
//                                   color: isRead ? Colors.blue : Colors.grey,
//                                 ),
//                               if (!isFromMe && chatInfo['unreadCount'] > 0)
//                                 Container(
//                                   margin: const EdgeInsets.only(top: 4),
//                                   width: 10,
//                                   height: 10,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[900],
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                             ],
//                           )
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           // Reset unread count when opening chat
//                           if (hasChat) {
//                             FirebaseFirestore.instance
//                                 .collection('chats')
//                                 .doc(chatId)
//                                 .update({'unreadCount': 0});
//                           }
                          
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime); // Today: 2:30 PM
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime); // Monday, Tuesday, etc.
//     } else {
//       return DateFormat('MMM d').format(messageTime); // Jun 12
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Get unread count from chat document
//                   int unreadCount = 0;
//                   if (chatSnapshot.hasData) {
//                     final data = chatSnapshot.data!.data() as Map<String, dynamic>?;
//                     if (data != null && data.containsKey('unreadCount')) {
//                       unreadCount = data['unreadCount'] as int? ?? 0;
//                     }
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = doctor['specialization'] ?? 'No messages yet';
//                       String messageTime = '';
//                       bool isFromMe = false;
//                       bool isRead = false;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         isRead = message['isRead'] ?? false;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[800],
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(context).scaffoldBackgroundColor,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: TextStyle(
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.black87,
//                           ),
//                         ),
//                         subtitle: Row(
//                           children: [
//                             if (isFromMe)
//                              if (isFromMe)
//                                 Icon(
//                                   isRead ? Icons.done_all : Icons.done,
//                                   size: 14,
//                                   color: isRead ? Colors.blue : Colors.grey,
//                                 ),
//                               if (!isFromMe && chatInfo['unreadCount'] > 0)        if (chatInfo['hasChat'])
//                           Text(
//                             '${isFromMe ? 'You: ' : ''}${chatInfo['lastMessage'] ?? 'No messages'}',
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               color: chatInfo['unreadCount'] > 0 ? Colors.blue[900] : Colors.grey[600],
//                             ), 
//                               Icon(
//                                 isRead ? Icons.done_all : Icons.done,
//                                 size: 14,
//                                 color: isRead ? Colors.blue : Colors.grey,
//                               ),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(
//                                 '${isFromMe ? 'You: ' : ''}$lastMessage',
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                   color: unreadCount > 0 ? Colors.blue[900] : Colors.grey[600],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: unreadCount > 0 ? Colors.blue[800] : Colors.grey[600],
//                                 fontSize: 12,
//                               ),
//                             ),
//                             if (unreadCount > 0)
//                               Container(
//                                 padding: const EdgeInsets.all(6),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[800],
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Text(
//                                   unreadCount > 9 ? '9+' : unreadCount.toString(),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           // Reset unread count when opening chat
//                           FirebaseFirestore.instance
//                               .collection('chats')
//                               .doc(chatId)
//                               .update({'unreadCount': 0});
                              
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime); // Today: 2:30 PM
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime); // Monday, Tuesday, etc.
//     } else {
//       return DateFormat('MMM d').format(messageTime); // Jun 12
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Get unread count from chat document
//                   int unreadCount = 0;
//                   if (chatSnapshot.hasData) {
//                     final data = chatSnapshot.data!.data() as Map<String, dynamic>?;
//                     if (data != null && data.containsKey('unreadCount')) {
//                       unreadCount = data['unreadCount'] as int? ?? 0;
//                     }
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = doctor['specialization'] ?? 'No messages yet';
//                       String messageTime = '';
//                       bool isFromMe = false;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[800],
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(context).scaffoldBackgroundColor,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: TextStyle(
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.black87,
//                           ),
//                         ),
//                         subtitle: Text(
//                           lastMessage,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: unreadCount > 0 ? Colors.blue[800] : Colors.grey[600],
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: unreadCount > 0 ? Colors.blue[800] : Colors.grey[600],
//                                 fontSize: 12,
//                               ),
//                             ),
//                             if (unreadCount > 0)
//                               Container(
//                                 padding: const EdgeInsets.all(6),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[800],
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Text(
//                                   unreadCount > 9 ? '9+' : unreadCount.toString(),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           // Reset unread count when opening chat
//                           FirebaseFirestore.instance
//                               .collection('chats')
//                               .doc(chatId)
//                               .update({'unreadCount': 0});
                              
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }










// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime); // Today: 2:30 PM
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime); // Monday, Tuesday, etc.
//     } else {
//       return DateFormat('MMM d').format(messageTime); // Jun 12
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Get unread count from chat document
//                   int unreadCount = 0;
//                   if (chatSnapshot.hasData) {
//                     final data = chatSnapshot.data!.data() as Map<String, dynamic>?;
//                     if (data != null && data.containsKey('unreadCount')) {
//                       unreadCount = data['unreadCount'] as int? ?? 0;
//                     }
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = doctor['specialization'] ?? 'No messages yet';
//                       String messageTime = '';
//                       bool isFromMe = false;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       // Handle avatar with proper implementation
//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 12,
//                                   height: 12,
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[900],
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(context).scaffoldBackgroundColor,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: unreadCount > 0 ? Colors.black : Colors.black87,
//                           ),
//                         ),
//                         subtitle: Text(
//                           lastMessage,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.grey[600],
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 12,
//                               ),
//                             ),
//                             if (unreadCount > 0)
//                               Container(
//                                 padding: const EdgeInsets.all(5),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[900],
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Text(
//                                   unreadCount.toString(),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           // Reset unread count when opening chat
//                           FirebaseFirestore.instance
//                               .collection('chats')
//                               .doc(chatId)
//                               .update({'unreadCount': 0});
                              
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime); // Today: 2:30 PM
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime); // Monday, Tuesday, etc.
//     } else {
//       return DateFormat('MMM d').format(messageTime); // Jun 12
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
//               final chatId = '${doctorDoc.id}_$currentUserId';
              
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Get unread count from chat document
//                  final unreadCount = chatSnapshot.hasData 
//     ? (chatSnapshot.data!.data() as Map<String, dynamic>?)?['unreadCount'] ?? 0
//     : 0;

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = doctor['specialization'] ?? 'No messages yet';
//                       String messageTime = '';
//                       bool isFromMe = false;
                      
//                       if (messageSnapshot.hasData && 
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         isFromMe = message['senderId'] == currentUserId;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                         }
//                       }

//                       // Handle avatar with proper implementation
//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
                        
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundColor: Colors.blue[100],
//                           child: Text(
//                             initials,
//                             style: TextStyle(
//                               color: Colors.blue[900],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         );
//                       }

//                       return ListTile(
//                         leading: Stack(
//                           children: [
//                             avatarWidget,
//                             if (unreadCount > 0)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[900],
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           doctor['fullName'] ?? 'Doctor',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Text(
//                           lastMessage,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: unreadCount > 0 ? Colors.blue[900] : Colors.grey[600],
//                             fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 12,
//                               ),
//                             ),
//                             if (unreadCount > 0)
//                               Container(
//                                 padding: const EdgeInsets.all(6),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[900],
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Text(
//                                   unreadCount.toString(),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           // Reset unread count when opening chat
//                           FirebaseFirestore.instance
//                               .collection('chats')
//                               .doc(chatId)
//                               .update({'unreadCount': 0});
                              
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 doctorName: doctor['fullName'] ?? 'Doctor',
//                                 doctorId: doctorDoc.id,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime); // Today: 2:30 PM
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime); // Monday, Tuesday, etc.
//     } else {
//       return DateFormat('MMM d').format(messageTime); // Jun 12
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
              
//               return StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc('${doctorDoc.id}_${FirebaseAuth.instance.currentUser!.uid}')
//                     .collection('messages')
//                     .orderBy('timestamp', descending: true)
//                     .limit(1)
//                     .snapshots(),
//                 builder: (context, messageSnapshot) {
//                   String lastMessage = doctor['specialization'] ?? 'No one sending massage';
//                   String messageTime = '';
                  
//                   if (messageSnapshot.hasData && 
//                       messageSnapshot.data!.docs.isNotEmpty) {
//                     final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                     lastMessage = message['text'] ?? lastMessage;
//                     if (message['timestamp'] != null) {
//                       messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                     }
//                   }

//                   // Handle avatar with proper implementation
//                   Widget avatarWidget;
//                   if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                     avatarWidget = CircleAvatar(
//                       radius: 25,
//                       backgroundImage: NetworkImage(doctor['avatar']),
//                     );
//                   } else {
//                     final String initials = doctor['fullName']?.isNotEmpty == true 
//                         ? doctor['fullName'][0].toUpperCase()
//                         : 'D';
                    
//                     avatarWidget = CircleAvatar(
//                       radius: 25,
//                       backgroundColor: Colors.blue[100],
//                       child: Text(
//                         initials,
//                         style: TextStyle(
//                           color: Colors.blue[900],
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     );
//                   }

//                   return ListTile(
//                     leading: avatarWidget,
//                     title: Text(
//                       doctor['fullName'] ?? 'Doctor',
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       lastMessage,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: Text(
//                       messageTime,
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => ChatScreen(
//                             doctorName: doctor['fullName'] ?? 'Doctor',
//                             doctorId: doctorDoc.id,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime); // Today: 2:30 PM
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime); // Monday, Tuesday, etc.
//     } else {
//       return DateFormat('MMM d').format(messageTime); // Jun 12
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
              
//               return StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc('${doctorDoc.id}_${FirebaseAuth.instance.currentUser!.uid}')
//                     .collection('messages')
//                     .orderBy('timestamp', descending: true)
//                     .limit(1)
//                     .snapshots(),
//                 builder: (context, messageSnapshot) {
//                   String lastMessage = doctor['specialization'] ?? 'Medical Professional';
//                   String messageTime = '';
                  
//                   if (messageSnapshot.hasData && 
//                       messageSnapshot.data!.docs.isNotEmpty) {
//                     final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                     lastMessage = message['text'] ?? lastMessage;
//                     if (message['timestamp'] != null) {
//                       messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                     }
//                   }

//                   // Handle missing avatar
//                radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                   } else {
//                     avatarWidget = CircleAvatar(
//                       backgroundColor: Colors.blue[100],
//                       child: Icon(Icons.person, color: Colors.blue[900]),
//                     );
//                   }

//                   return ListTile(
//                     leading: avatarWidget,
//                     title: Text(
//                       doctor['fullname'] ?? 'Doctor',
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       lastMessage,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: Text(
//                       messageTime,
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => ChatScreen(
//                             doctorName: doctor['fullname'] ?? 'Doctor',
//                             doctorId: widget.doctorId,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime); // Today: 2:30 PM
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime); // Monday, Tuesday, etc.
//     } else {
//       return DateFormat('MMM d').format(messageTime); // Jun 12
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorDocs = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorDocs.length,
//             itemBuilder: (context, index) {
//               final doctorDoc = doctorDocs[index];
//               final doctor = doctorDoc.data() as Map<String, dynamic>;
              
//               return StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc('${doctorDoc.id}_${FirebaseAuth.instance.currentUser!.uid}') // Adjust based on your chat ID structure
//                     .collection('messages')
//                     .orderBy('timestamp', descending: true)
//                     .limit(1)
//                     .snapshots(),
//                 builder: (context, messageSnapshot) {
//                   String lastMessage = doctor['specialization'] ?? 'Medical Professional';
//                   String messageTime = '';
                  
//                   if (messageSnapshot.hasData && 
//                       messageSnapshot.data!.docs.isNotEmpty) {
//                     final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                     lastMessage = message['text'] ?? lastMessage;
//                     if (message['timestamp'] != null) {
//                       messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//                     }
//                   }

//                   // Handle missing avatar
//                   Widget avatarWidget;
//                   if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                     avatarWidget = CircleAvatar(
//                       backgroundImage: NetworkImage(doctor['avatar']),
//                     );
//                   } else {
//                     avatarWidget = CircleAvatar(
//                       backgroundColor: Colors.blue[100],
//                       child: Icon(Icons.person, color: Colors.blue[900]),
//                     );
//                   }

//                   return ListTile(
//                     leading: avatarWidget,
//                     title: Text(
//                       doctor['fullname'] ?? 'Doctor',
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       lastMessage,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: Text(
//                       messageTime,
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => ChatScreen(
//                             doctorName: doctor['fullname'] ?? 'Doctor',
//                             avatar: doctor['avatar'],
//                             doctorId: doctorDoc.id,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime); // Today: 2:30 PM
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime); // Monday, Tuesday, etc.
//     } else {
//       return DateFormat('MMM d').format(messageTime); // Jun 12
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctorData = doctorsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctorData.length,
//             itemBuilder: (context, index) {
//               final doctorData = doctorData[index];
//               final doctor = doctorData.data() as Map<String, dynamic>;
              
//               return StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc('${doctor.id}_${FirebaseAuth.instance.currentUser!.uid}') // Adjust based on your chat ID structure
//                     .collection('messages')
//                     .orderBy('timestamp', descending: true)
//                     .limit(1)
//                     .snapshots(),
//                 builder: (context, messageSnapshot) {
//                   String lastMessage = doctorData['specialization'] ?? 'Medical Professional';
//                   String messageTime = '';
                  
//                   if (messageSnapshot.hasData && 
//                       messageSnapshot.data!.docs.isNotEmpty) {
//                     final message = messageSnapshot.data!.docs.first;
//                     lastMessage = message['text'] ?? lastMessage;
//                     if (message['timestamp'] != null) {
//                       messageTime = _formatTimestamp(message['timestamp']);
//                     }
//                   }

//                   // Handle missing avatar
//                   Widget avatarWidget;
//                   if (doctorData['avatar'] != null && doctorData['avatar'].toString().isNotEmpty) {
//                     avatarWidget = CircleAvatar(
//                       backgroundImage: NetworkImage(doctorData['avatar']),
//                     );
//                   } else {
//                     avatarWidget = CircleAvatar(
//                       backgroundColor: Colors.blue[100],
//                       child: Icon(Icons.person, color: Colors.blue[900]),
//                     );
//                   }

//                   return ListTile(
//                     leading: avatarWidget,
//                     title: Text(
//                       doctorData['fullname'] ?? 'Doctor',
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       lastMessage,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: Text(
//                       messageTime,
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => ChatScreen(
//                              doctorName: doctorData['fullname'] ?? 'Doctor',
//                             avatar: widget.doctorData['image'],
//                             doctorId: doctor.id,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .where('status', isEqualTo: 'approved')
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           final doctors = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               final doctorData = doctor.data() as Map<String, dynamic>;
              
//               // Handle missing avatar
//               Widget avatarWidget;
//               if (doctorData['avatar'] != null && doctorData['avatar'].toString().isNotEmpty) {
//                 avatarWidget = CircleAvatar(
//                   backgroundImage: NetworkImage(doctorData['avatar']),
//                 );
//               } else {
//                 avatarWidget = CircleAvatar(
//                   backgroundColor: Colors.blue[100],
//                   child: Icon(Icons.person, color: Colors.blue[900]),
//                 );
//               }

//               return ListTile(
//                 leading: avatarWidget,
//                 title: Text(
//                   doctorData['fullname'] ?? 'Doctor',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(
//                   doctorData['specialization'] ?? 'Medical Professional',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 trailing: const Icon(Icons.chat),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ChatScreen(
//                         name: doctorData['fullname'] ?? 'Doctor',
//                         avatar: doctorData['avatar'],
//                         doctorId: doctor.id,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, String>> chats = [
//       {
//         'name': 'Deeqo',
//         'avatar': 'assets/images/avatar1.jpg',
//         'message': 'Hello!',
//         'date': '10:30 AM',
//       },
//       {
//         'name': 'doctor Zeynab',
//         'avatar': 'assets/images/avatar2.jpg',
//         'message': 'Sidee tahay?',
//         'date': 'Yesterday',
//       },
//       {
//         'name': 'Mss Shifa',
//         'avatar': 'assets/images/avatar3.jpg',
//         'message': 'Waan kuu soo jawaabi doonaa',
//         'date': 'Mon',
//       },
//       {
//         'name': 'doctor ikraan',
//         'avatar': 'assets/images/avatar4.jpg',
//         'message': 'Ka waran?',
//         'date': 'Sun',
//       },
//       {
//         'name': 'Doctor anas',
//         'avatar': 'assets/images/avatar5.jpg',
//         'message': 'Waqtigii ballanta?',
//         'date': 'Sat',
//       },
//       {
//         'name': 'doctor ifraax',
//         'avatar': 'assets/images/avatar6.jpg',
//         'message': 'Daawadii qaadatay?',
//         'date': 'Fri',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: ListView.builder(
//         itemCount: chats.length,
//         itemBuilder: (context, index) {
//           final chat = chats[index];
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundImage: chat['avatar']!.isNotEmpty
//                   ? AssetImage(chat['avatar']!)
//                   : null,
//               child: chat['avatar']!.isEmpty
//                   ? const Icon(Icons.person)
//                   : null,
//             ),
//             title: Text(
//               chat['name']!,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Text(
//               chat['message']!,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             trailing: Text(chat['date']!),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ChatScreen(
//                     name: chat['name']!,
//                     avatar: chat['avatar']!,
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }






















































// import 'package:flutter/material.dart';
// import 'chat_screen.dart';// import your ChatScreen

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, String>> chats = [
//       {
//     'name': 'Deeqo',
//     'avatar': 'assets/images/avatar1.jpg',
//     'message': 'Hello!',
//     'date': '10:30 AM',
//   },
//   {
//     'name': 'doctor Zeynab',
//     'avatar': 'assets/images/avatar2.jpg',
//     'message': 'Sidee tahay?',
//     'date': 'Yesterday',
//   },
//   {
//     'name': 'Mss Shifa',
//     'avatar': 'assets/images/avatar3.jpg',
//     'message': 'Waan kuu soo jawaabi doonaa',
//     'date': 'Mon',
//   },
//   {
//     'name': 'doctor ikraan',
//     'avatar': 'assets/images/avatar4.jpg',
//     'message': 'Ka waran?',
//     'date': 'Sun',
//   },
//   {
//     'name': 'Doctor anas',
//     'avatar': 'assets/images/avatar5.jpg',
//     'message': 'Waqtigii ballanta?',
//     'date': 'Sat',
//   },
//   {
//     'name': 'doctor ifraax',
//     'avatar': 'assets/images/avatar6.jpg',
//     'message': 'Daawadii qaadatay?',
//     'date': 'Fri',
//   },
//     ];

//     return Scaffold(
//        appBar: AppBar(
//     backgroundColor: Colors.blue[900],
//     title: Row(
//       children: [
//         const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           widget.name,
//           style: const TextStyle(color: Colors.white),
//         ),
//       ],
//     ),
//   ),
//       body: ListView.builder(
//         itemCount: chats.length,
//         itemBuilder: (context, index) {
//           final chat = chats[index];
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundImage: chat['avatar']!.isNotEmpty
//                   ? AssetImage(chat['avatar']!)
//                   : null,
//               child: chat['avatar']!.isEmpty
//                   ? const Icon(Icons.person)
//                   : null,
//             ),
//             title: Text(
//               chat['name']!,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Text(
//               chat['message']!,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             trailing: Text(chat['date']!),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ChatScreen(
//                     name: chats[index]['name']!,
//                     avatar: chats[index]['avatar']!
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }














































// import 'package:flutter/material.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, String>> chats = [
//       {
//         'name': 'ZHAARUU YRE',
//         'message': '3.daa Eray een hoooos kusooqoray cidiii sh...',
//         'date': '28/04/2025',
//         'avatar': 'assets/images/avatar1.jpg',
//       },
//       {
//         'name': '+252 61 5990515',
//         'message': 'reacted 🙏 to 🎙️ 0:10',
//         'date': '27/04/2025',
//         'avatar': 'assets/images/avatar2.jpg',
//       },
//       {
//         'name': '+252 61 5485960',
//         'message': 'Wardhere',
//         'date': '27/04/2025',
//         'avatar': '',
//       },
//       {
//         'name': 'Heeeeey',
//         'message': 'C6240053',
//         'date': '27/04/2025',
//         'avatar': 'assets/images/avatar3.jpg',
//       },
//       {
//         'name': 'Hooyo Mcn',
//         'message': 'Missed video call',
//         'date': '26/04/2025',
//         'avatar': 'assets/images/avatar4.jpg',
//       },
//       {
//         'name': '+252 61 8187582',
//         'message': 'Hi mcan badan',
//         'date': '23/04/2025',
//         'avatar': 'assets/images/avatar5.jpg',
//       },
//       {
//         'name': '+252 62 8100544',
//         'message': 'Maba ku aqaane wallo',
//         'date': '20/04/2025',
//         'avatar': 'assets/images/avatar6.jpg',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chats'),
//         backgroundColor: Colors.blue[900],
//         icon.search
//         label serch:Text('Search . . . . . ')
//       ),
//       body: ListView.builder(
//         itemCount: chats.length,
//         itemBuilder: (context, index) {
//           final chat = chats[index];
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundImage: chat['avatar']!.isNotEmpty
//                   ? AssetImage(chat['avatar']!)
//                   : null,
//               child: chat['avatar']!.isEmpty
//                   ? const Icon(Icons.person)
//                   : null,
//             ),
//             title: Text(
//               chat['name']!,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Text(
//               chat['message']!,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             trailing: Text(chat['date']!),
//           );
//         },
//       ),
//     );
//   }
// }
