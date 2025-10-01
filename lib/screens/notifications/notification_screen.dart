// notification_screen.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationScreen {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_channel',
            'Appointment Notifications',
            channelDescription: 'Notifications for appointment updates',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon,
          ),
        ),
      );
    }
  }
}
























// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:intl/intl.dart';



// class NotificationScreen extends StatefulWidget {
//   @override
//   _NotificationScreenState createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   List<Map<String, dynamic>> notifications = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadNotifications();
//   }

//   Future<void> _loadNotifications() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList('pregnancy_notifications') ?? [];
    
//     setState(() {
//       notifications = saved.map((n) => jsonDecode(n) as Map<String, dynamic>).toList();
//       notifications.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('My Pregnancy Updates'),
//         backgroundColor: Colors.pink[200],
//       ),
//       body: notifications.isEmpty
//           ? Center(
//               child: Text(
//                 'No notifications yet',
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             )
//           : ListView.builder(
//               itemCount: notifications.length,
//               itemBuilder: (context, index) {
//                 final notif = notifications[index];
//                 return Card(
//                   margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.pink[100],
//                       child: Icon(Icons.pregnant_woman, color: Colors.pink),
//                     ),
//                     title: Text(
//                       notif['title'],
//                       style: TextStyle(
//                         fontWeight: notif['read'] ? FontWeight.normal : FontWeight.bold,
//                       ),
//                     ),
//                     subtitle: Text(DateFormat('MMM d, y - hh:mm a').format(DateTime.parse(notif['date']))),
//                     trailing: notif['read'] ? null : Icon(Icons.circle, color: Colors.pink, size: 12),
//                     onTap: () {
//                       _markAsRead(index);
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => NotificationDetail(notification: notif),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Future<void> _markAsRead(int index) async {
//     setState(() {
//       notifications[index]['read'] = true;
//     });
    
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList(
//       'pregnancy_notifications',
//       notifications.map((n) => jsonEncode(n)).toList(),
//     );
//   }
// }

// class NotificationDetail extends StatelessWidget {
//   final Map<String, dynamic> notification;

//   const NotificationDetail({Key? key, required this.notification}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.pink[200],
//         title: Text('Pregnancy Update'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               notification['title'],
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             Text(
//               notification['body'],
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 24),
//             Text(
//               'Date: ${DateFormat('MMMM d, y - hh:mm a').format(DateTime.parse(notification['date']))}',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }