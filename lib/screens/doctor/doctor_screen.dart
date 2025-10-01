import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'docchat_screen.dart';


class DoctorScreen extends StatelessWidget {
  const DoctorScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // ✅ Waa in lagu dhajiyaa DefaultTabController
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[900],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'View Schedule'),
              Tab(text: 'My appointments'),
              Tab(text : 'Send Symptoms patient'),
              Tab(text: 'My chats'),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            ViewScheduleTab(),
            MyappointmentsTab(),
            SymptomspatientTab(),
            MychatsTab(),
          ],
        ),
      ),
    );
  }
}
//////////////////////////////////////////


class ViewScheduleTab extends StatelessWidget {
  const ViewScheduleTab({super.key});

  void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red[800] : Colors.green[800],
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Center(
        child: Text('Please sign in to view schedules',
            style: TextStyle(color: Colors.white)),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final schedules = FirebaseFirestore.instance
        .collection('doctors')
        .doc(currentUser.uid)
        .collection('schedules');
      

    return StreamBuilder<QuerySnapshot>(
      stream: schedules.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
          });
          return _buildErrorWidget();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSnackBar(context, 'No upcoming schedules found', isError: false);
          });
          return _buildEmptyStateWidget();
        }

        return _buildScheduleTable(snapshot.data!.docs, context);
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Text('Error loading data', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Text('No upcoming schedules available',
          style: TextStyle(color: Colors.white)),
    );
  }

Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 50),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DataTable(
            headingRowHeight: 50,
            dataRowHeight: 48,
            horizontalMargin: 12,
            columnSpacing: 33,
            headingRowColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.blue[700]!,
            ),
            dataRowColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.white,
            ),
            columns: [
              DataColumn(
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text('Day',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                ),
              ),
              DataColumn(
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Start Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                ),
              ),
              DataColumn(
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text('End Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                ),
              ),
              DataColumn(
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text('Duration',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                ),
              ),
            ],
            rows: docs.map((document) {
              final data = document.data() as Map<String, dynamic>;
              final day = data['day'] as String; // e.g. 'Monday'
              final startTime = (data['startTime'] as Timestamp).toDate();
              final endTime = (data['endTime'] as Timestamp).toDate();
              final timeFormat = DateFormat('h:mm a');
              final duration = endTime.difference(startTime);

              return DataRow(
                cells: [
                  DataCell(
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Text(day,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          )),
                    ),
                  ),
                  DataCell(
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(timeFormat.format(startTime),
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          )),
                    ),
                  ),
                  DataCell(
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Text(timeFormat.format(endTime),
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          )),
                    ),
                  ),
                  DataCell(
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                          '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          )),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}
}

// class ViewScheduleTab extends StatelessWidget {
//   const ViewScheduleTab({super.key});

//   void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red[800] : Colors.green[800],
//         duration: Duration(seconds: isError ? 3 : 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

//     if (currentUser == null) {
//       return Center(
//         child: Text('Please sign in to view schedules',
//             style: TextStyle(color: Colors.white)),
//       );
//     }

//     final schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(currentUser.uid)
//         .collection('schedules')
//         .orderBy('date');

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
//           });
//           return _buildErrorWidget();
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingIndicator();
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         return _buildScheduleTable(snapshot.data!.docs, context);
//       },
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Text('Error loading data', style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget() {
//     return Center(
//       child: Text('No schedules available',
//           style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs, BuildContext context) {
//     return Padding(
//       // padding: const EdgeInsets.all(20.0),
//       // padding: const EdgeInsets.symmetric(horizontal: 58, vertical: 10),
//       padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 50),
      
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10,
//               spreadRadius: 3,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: DataTable(
//               headingRowHeight: 50,
//               dataRowHeight: 48,
//               horizontalMargin: 12,
//               columnSpacing: 8,
//               headingRowColor: MaterialStateProperty.resolveWith<Color>(
//                 (states) => Colors.blue[700]!,
//               ),
//               dataRowColor: MaterialStateProperty.resolveWith<Color>(
//                 (states) => Colors.white,
//               ),
//               columns: [
//                 DataColumn(
//                   label: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 5),
//                     child: Text('Date',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         )),
//                   ),
//                 ),
//                 DataColumn(
//                   label: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4),
//                     child: Text('Start Time',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         )),
//                   ),
//                 ),
//                 DataColumn(
//                   label: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 5),
//                     child: Text('End Time',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         )),
//                   ),
//                 ),
//                 DataColumn(
//                   label: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 5),
//                     child: Text('Duration',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         )),
//                   ),
//                 ),
//               ],
//               rows: docs.map((document) {
//                 final data = document.data() as Map<String, dynamic>;
//                 final date = (data['date'] as Timestamp).toDate();
//                 final startTime = (data['startTime'] as Timestamp).toDate();
//                 final endTime = (data['endTime'] as Timestamp).toDate();

//                 final dateFormat = DateFormat('MMM d, yyyy');
//                 final timeFormat = DateFormat('h:mm a');
//                 final duration = endTime.difference(startTime);

//                 return DataRow(
//                   cells: [
//                     DataCell(
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 5),
//                         child: Text(dateFormat.format(date),
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                             )),
//                       ),
//                     ),
//                     DataCell(
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 4),
//                         child: Text(timeFormat.format(startTime),
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                             )),
//                       ),
//                     ),
//                     DataCell(
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 5),
//                         child: Text(timeFormat.format(endTime),
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                             )),
//                       ),
//                     ),
//                     DataCell(
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 5),
//                         child: Text(
//                             '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                             )),
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';









// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

class MyappointmentsTab extends StatefulWidget {
  const MyappointmentsTab({Key? key}) : super(key: key);

  @override
  State<MyappointmentsTab> createState() => _MyappointmentsTabState();
}

class _MyappointmentsTabState extends State<MyappointmentsTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _doctorId;
  Future<QuerySnapshot>? _appointmentsFuture;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final Map<String, String> _fullNameCache = {};
  String? _selectedAppointmentId;

  @override
  void initState() {
    super.initState();
    _doctorId = _auth.currentUser?.uid;
    _refreshData();
  }

  Future<void> sendNotificationToUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _firestore.collection('users').doc(userId).collection('notifications').add({
          'to': fcmToken,
          'title': 'Appointment Confirmed',
          'body': 'Your appointment has been confirmed.',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  Future<void> _refreshData() async {
    if (_doctorId == null) return;

    setState(() {
      _appointmentsFuture = _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _doctorId)
          .get();
      _fullNameCache.clear();
      _selectedAppointmentId = null;
    });
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'confirmed') {
        await sendNotificationToUser(userId);
        _showSnackbar('Appointment confirmed successfully', Colors.green);
      } else if (status == 'cancelled') {
        _showSnackbar('Appointment cancelled', Colors.orange);
      }

      await _refreshData();
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
  }

  Future<String> _getfullName(String userId) async {
    if (_fullNameCache.containsKey(userId)) {
      return _fullNameCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fullName = userDoc['fullName']?.toString() ?? 'Unknown Patient';
      _fullNameCache[userId] = fullName;
      return fullName;
    } catch (e) {
      debugPrint('Error fetching patient name: $e');
      return 'Unknown Patient';
    }
  }

  Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    return FutureBuilder<String>(
      future: _getfullName(data['userId']),
      builder: (context, fullNameSnapshot) {
        final patientName = fullNameSnapshot.data ?? 'Loading...';
        final isPending = (data['status'] as String).toLowerCase() == 'pending';
        final isSelected = _selectedAppointmentId == doc.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 10,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with requested date and status chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    if (!isSelected || !isPending)
                      GestureDetector(
                        onTap: isPending
                            ? () => setState(() => _selectedAppointmentId = doc.id)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(data['status']),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusText(data['status']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),

                if (isSelected && isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _updateAppointmentStatus(doc.id, 'cancelled', data['userId']);
                            setState(() => _selectedAppointmentId = null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            _updateAppointmentStatus(doc.id, 'confirmed', data['userId']);
                            setState(() => _selectedAppointmentId = null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Confirmed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: data['doctorPhotoUrl'] != null
                          ? NetworkImage(data['doctorPhotoUrl'])
                          : null,
                      child: data['doctorPhotoUrl'] == null
                          ? Text(
                              (data['doctorName'] ?? 'D')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$patientName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (data['appointmentDate'] != null)
                            Text(
                              'Date: ${_formatTimestamp(data['appointmentDate'] as Timestamp)}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87),
                            ),
                          if (data['reason'] != null && data['reason'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Reason: ${data['reason']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_doctorId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view appointments')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        child: FutureBuilder<QuerySnapshot>(
          future: _appointmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No appointment requests found'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      onPressed: _refreshData,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildAppointmentCard(doc, data);
              },
            );
          },
        ),
      ),
    );
  }
}


// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;
//   Future<QuerySnapshot>? _appointmentsFuture;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
//   final Map<String, String> _fullNameCache = {};

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//     _refreshData();
//   }

//   Future<void> sendNotificationToUser(String userId) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fcmToken = userDoc['fcmToken'];

//       if (fcmToken != null && fcmToken.isNotEmpty) {
//         await _firestore.collection('users').doc(userId).collection('notifications').add({
//           'to': fcmToken,
//           'title': 'Appointment Confirmed',
//           'body': 'Your appointment has been confirmed.',
//           'timestamp': FieldValue.serverTimestamp(),
//           'read': false,
//         });
//       }
//     } catch (e) {
//       debugPrint('Notification error: $e');
//     }
//   }

//   Future<void> _refreshData() async {
//     if (_doctorId == null) return;

//     setState(() {
//       _appointmentsFuture = _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: _doctorId)
       
//           .get();
//       _fullNameCache.clear();
//     });
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (status == 'confirmed') {
//         await sendNotificationToUser(userId);
//         _showSnackbar('Appointment confirmed successfully', Colors.green);
//       } else if (status == 'cancelled') {
//         _showSnackbar('Appointment cancelled', Colors.orange);
//       }

//       await _refreshData();
//     } catch (e) {
//       _showSnackbar('Error: ${e.toString()}', Colors.red);
//     }
//   }

//   void _showSnackbar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       case 'pending':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _statusText(String status) {
//     return status[0].toUpperCase() + status.substring(1);
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
//   }

//   Future<String> _getfullName(String userId) async {
//     if (_fullNameCache.containsKey(userId)) {
//       return _fullNameCache[userId]!;
//     }

//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fullName = userDoc['fullName']?.toString() ?? 'Unknown Patient';
//       _fullNameCache[userId] = fullName;
//       return fullName;
//     } catch (e) {
//       debugPrint('Error fetching patient name: $e');
//       return 'Unknown Patient';
//     }
//   }

//   Future<void> _showStatusOptionsDialog(String appointmentId, String userId) async {
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Appointment Action'),
//         content: const Text('Choose an action for this appointment:'),
//         actions: [
//           TextButton(
//             child: const Text('Cancel'),
//             onPressed: () => Navigator.pop(context, 'cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//             ),
//             child: const Text('Confirm'),
//             onPressed: () => Navigator.pop(context, 'confirm'),
//           ),
//         ],
//       ),
//     );

//     if (result == 'confirm') {
//       await _updateAppointmentStatus(appointmentId, 'confirmed', userId);
//     } else if (result == 'cancel') {
//       await _updateAppointmentStatus(appointmentId, 'cancelled', userId);
//     }
//   }

//   Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
//     return FutureBuilder<String>(
//       future: _getfullName(data['userId']),
//       builder: (context, fullNameSnapshot) {
//         final patientName = fullNameSnapshot.data ?? 'Loading...';

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           elevation: 5,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header with requested date and status chip
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                       style: const TextStyle(fontSize: 13, color: Colors.grey),
//                     ),
//                     InkWell(
//                       onTap: (data['status'] as String).toLowerCase() == 'pending'
//                           ? () => _showStatusOptionsDialog(doc.id, data['userId'])
//                           : null,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: _statusColor(data['status']),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           _statusText(data['status']),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 16),

//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 32,
//                       backgroundColor: Colors.blue.shade100,
//                       backgroundImage: data['doctorPhotoUrl'] != null
//                           ? NetworkImage(data['doctorPhotoUrl'])
//                           : null,
//                       child: data['doctorPhotoUrl'] == null
//                           ? Text(
//                               (data['doctorName'] ?? 'D')[0].toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue),
//                             )
//                           : null,
//                     ),
//                     const SizedBox(width: 20),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Patient: $patientName',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600),
//                           ),
//                           const SizedBox(height: 8),
//                           if (data['appointmentDate'] != null)
//                             Text(
//                               'Date: ${_formatTimestamp(data['appointmentDate'] as Timestamp)}',
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 color: Colors.black87),
//                             ),
//                           if (data['reason'] != null && data['reason'].toString().isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 6),
//                               child: Text(
//                                 'Reason: ${data['reason']}',
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   color: Colors.black87),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Appointments'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: FutureBuilder<QuerySnapshot>(
//           future: _appointmentsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('No appointment requests found'),
//                     const SizedBox(height: 8),
//                     TextButton.icon(
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Refresh'),
//                       onPressed: _refreshData,
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final doc = snapshot.data!.docs[index];
//                 final data = doc.data() as Map<String, dynamic>;
//                 return _buildAppointmentCard(doc, data);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;
//   Future<QuerySnapshot>? _appointmentsFuture;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
//   final Map<String, String> _fullNameCache = {};

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//     _refreshData();
//   }

//   Future<void> sendNotificationToUser(String userId) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fcmToken = userDoc['fcmToken'];
//       if (fcmToken != null && fcmToken.isNotEmpty) {
//         await _firestore.collection('users').doc(userId).collection('notifications').add({
//           'to': fcmToken,
//           'title': 'Appointment Confirmed',
//           'body': 'Your appointment has been confirmed.',
//           'timestamp': FieldValue.serverTimestamp(),
//           'read': false,
//         });
//       }
//     } catch (e) {
//       debugPrint('Notification error: $e');
//     }
//   }

//   Future<void> _refreshData() async {
//     if (_doctorId == null) return;
//     setState(() {
//       _appointmentsFuture = _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: _doctorId)
//           .get();
//       _fullNameCache.clear();
//     });
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (status == 'confirmed') {
//         await sendNotificationToUser(userId);
//         _showSnackbar('Appointment confirmed successfully', Colors.green);
//       } else if (status == 'cancelled') {
//         _showSnackbar('Appointment cancelled', Colors.orange);
//       }

//       await _refreshData();
//     } catch (e) {
//       _showSnackbar('Error: ${e.toString()}', Colors.red);
//     }
//   }

//   void _showSnackbar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       case 'pending':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _statusText(String status) {
//     return status[0].toUpperCase() + status.substring(1);
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
//   }

//   Future<String> _getfullName(String userId) async {
//     if (_fullNameCache.containsKey(userId)) {
//       return _fullNameCache[userId]!;
//     }

//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fullName = userDoc['fullName']?.toString() ?? 'Unknown Patient';
//       _fullNameCache[userId] = fullName;
//       return fullName;
//     } catch (e) {
//       debugPrint('Error fetching patient name: $e');
//       return 'Unknown Patient';
//     }
//   }

//   Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
//     return FutureBuilder<String>(
//       future: _getfullName(data['userId']),
//       builder: (context, fullNameSnapshot) {
//         final patientName = fullNameSnapshot.data ?? 'Loading...';

//         final statusLower = (data['status'] as String).toLowerCase();

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           elevation: 5,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header with requested date and status chip
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                       style: const TextStyle(fontSize: 13, color: Colors.grey),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: _statusColor(data['status']),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         _statusText(data['status']),
//                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 16),

//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 32,
//                       backgroundColor: Colors.blue.shade100,
//                       backgroundImage: data['doctorPhotoUrl'] != null
//                           ? NetworkImage(data['doctorPhotoUrl'])
//                           : null,
//                       child: data['doctorPhotoUrl'] == null
//                           ? Text(
//                               (data['doctorName'] ?? 'D')[0].toUpperCase(),
//                               style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
//                             )
//                           : null,
//                     ),
//                     const SizedBox(width: 20),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Patient: $patientName',
//                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                           ),
//                           const SizedBox(height: 8),
//                           if (data['appointmentDate'] != null)
//                             Text(
//                               'Date: ${_formatTimestamp(data['appointmentDate'] as Timestamp)}',
//                               style: const TextStyle(fontSize: 15, color: Colors.black87),
//                             ),
//                           if (data['reason'] != null && data['reason'].toString().isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 6),
//                               child: Text(
//                                 'Reason: ${data['reason']}',
//                                 style: const TextStyle(fontSize: 15, color: Colors.black87),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 18),

//                 if (statusLower == 'pending')
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       ),
//                       onPressed: () => _showPendingOptionsDialog(doc.id, data['userId']!),
//                       child: const Text('Pending'),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _showPendingOptionsDialog(String appointmentId, String userId) async {
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Pending Appointment'),
//         content: const Text('Choose an action for this appointment:'),
//         actions: [
//           TextButton(
//             child: const Text('Cancel'),
//             onPressed: () => Navigator.pop(context, 'cancelled'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             child: const Text('Confirm'),
//             onPressed: () => Navigator.pop(context, 'confirmed'),
//           ),
//         ],
//       ),
//     );

//     if (result == 'confirmed' || result == 'cancelled') {
//       await _updateAppointmentStatus(appointmentId, result, userId);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Appointments'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: FutureBuilder<QuerySnapshot>(
//           future: _appointmentsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('No appointment requests found'),
//                     const SizedBox(height: 8),
//                     TextButton.icon(
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Refresh'),
//                       onPressed: _refreshData,
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final doc = snapshot.data!.docs[index];
//                 final data = doc.data() as Map<String, dynamic>;
//                 return _buildAppointmentCard(doc, data);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }


// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;
//   Future<QuerySnapshot>? _appointmentsFuture;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
//   final Map<String, String> _fullNameCache = {};

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//     _refreshData();
//   }

//   Future<void> sendNotificationToUser(String userId) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fcmToken = userDoc['fcmToken'];

//       if (fcmToken != null && fcmToken.isNotEmpty) {
//         await _firestore.collection('users').doc(userId).collection('notifications').add({
//           'to': fcmToken,
//           'title': 'Appointment Confirmed',
//           'body': 'Your appointment has been confirmed.',
//           'timestamp': FieldValue.serverTimestamp(),
//           'read': false,
//         });
//       }
//     } catch (e) {
//       debugPrint('Notification error: $e');
//     }
//   }

//   Future<void> _refreshData() async {
//     if (_doctorId == null) return;

//     setState(() {
//       _appointmentsFuture = _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: _doctorId)
//           .get();
//       _fullNameCache.clear();
//     });
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (status == 'confirmed') {
//         await sendNotificationToUser(userId);
//         _showSnackbar('Appointment confirmed successfully', Colors.green);
//       } else if (status == 'cancelled') {
//         _showSnackbar('Appointment cancelled', Colors.orange);
//       }

//       await _refreshData();
//     } catch (e) {
//       _showSnackbar('Error: ${e.toString()}', Colors.red);
//     }
//   }

//   void _showSnackbar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       case 'pending':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _statusText(String status) {
//     return status[0].toUpperCase() + status.substring(1);
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
//   }

//   Future<String> _getfullName(String userId) async {
//     if (_fullNameCache.containsKey(userId)) {
//       return _fullNameCache[userId]!;
//     }

//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fullName = userDoc['fullName']?.toString() ?? 'Unknown Patient';
//       _fullNameCache[userId] = fullName;
//       return fullName;
//     } catch (e) {
//       debugPrint('Error fetching patient name: $e');
//       return 'Unknown Patient';
//     }
//   }

  

//  Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
//   return FutureBuilder<String>(
//     future: _getfullName(data['userId']),
//     builder: (context, fullNameSnapshot) {
//       final patientName = fullNameSnapshot.data ?? 'Loading...';

//       final statusLower = (data['status'] as String).toLowerCase();

//       return Card(
//         margin: const EdgeInsets.only(bottom: 16),
//         elevation: 5,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header with requested date and status chip
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                     style: const TextStyle(fontSize: 13, color: Colors.grey),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: _statusColor(data['status']),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       _statusText(data['status']),
//                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 16),

//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 32,
//                     backgroundColor: Colors.blue.shade100,
//                     backgroundImage: data['doctorPhotoUrl'] != null
//                         ? NetworkImage(data['doctorPhotoUrl'])
//                         : null,
//                     child: data['doctorPhotoUrl'] == null
//                         ? Text(
//                             (data['doctorName'] ?? 'D')[0].toUpperCase(),
//                             style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
//                           )
//                         : null,
//                   ),
//                   const SizedBox(width: 20),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Patient: $patientName',
//                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                         ),
//                         const SizedBox(height: 8),
//                         if (data['appointmentDate'] != null)
//                           Text(
//                             'Date: ${_formatTimestamp(data['appointmentDate'] as Timestamp)}',
//                             style: const TextStyle(fontSize: 15, color: Colors.black87),
//                           ),
//                         if (data['reason'] != null && data['reason'].toString().isNotEmpty)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 6),
//                             child: Text(
//                               'Reason: ${data['reason']}',
//                               style: const TextStyle(fontSize: 15, color: Colors.black87),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 18),

//               // Show only one button for pending status
//               if (statusLower == 'pending')
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     ),
//                     onPressed: () => _showPendingOptionsDialog(doc.id, data['userId']),
//                     child: const Text('Pending'),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

// Future<void> _showPendingOptionsDialog(String appointmentId, String? userId) async {
//   final result = await showDialog<String>(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: const Text('Pending Appointment'),
//       content: const Text('Choose an action for this appointment:'),
//       actions: [
//         TextButton(
//           child: const Text('Cancel'),
//           onPressed: () => Navigator.pop(context, 'cancelled'),
//         ),
//         ElevatedButton(
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//           child: const Text('Confirm'),
//           onPressed: () => Navigator.pop(context, 'confirmed'),
//         ),
//       ],
//     ),
//   );

//   if (userId != null && (result == 'confirmed' || result == 'cancelled')) {
//     await _updateAppointmentStatus(appointmentId, result, userId);
//   }
// }


//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Appointments'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: FutureBuilder<QuerySnapshot>(
//           future: _appointmentsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('No appointment requests found'),
//                     const SizedBox(height: 8),
//                     TextButton.icon(
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Refresh'),
//                       onPressed: _refreshData,
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final doc = snapshot.data!.docs[index];
//                 final data = doc.data() as Map<String, dynamic>;
//                 return _buildAppointmentCard(doc, data);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;
//   Future<QuerySnapshot>? _appointmentsFuture;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
//   final Map<String, String> _fullNameCache = {};

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//     _refreshData();
//   }
//  Future<void> sendNotificationToUser(String userId) async {
//   try {
//     final userDoc = await _firestore.collection('users').doc(userId).get();
//     final fcmToken = userDoc['fcmToken'];

//     if (fcmToken != null && fcmToken.isNotEmpty) {
//       await _firestore.collection('users').doc(userId).collection('notifications').add({
//         'to': fcmToken,
//         'title': 'Appointment Confirmed',
//         'body': 'Your appointment has been confirmed.',
//         'timestamp': FieldValue.serverTimestamp(),
//         'read': false, // Add a read status flag
//       });
//     }
//   } catch (e) {
//     debugPrint('Notification error: $e');
//   }
// }
//   Future<void> _refreshData() async {
//     if (_doctorId == null) return;

//     setState(() {
//       _appointmentsFuture = _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: _doctorId)
//           .get();
//       _fullNameCache.clear();
//     });
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (status == 'confirmed') {
//         await sendNotificationToUser(userId);
//         _showSnackbar('Appointment confirmed successfully', Colors.green);
//       } else {
//         _showSnackbar('Appointment cancelled', Colors.orange);
//       }

//       await _refreshData();
//     } catch (e) {
//       _showSnackbar('Error: ${e.toString()}', Colors.red);
//     }
//   }

//   void _showSnackbar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       case 'pending':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _statusText(String status) {
//     return status[0].toUpperCase() + status.substring(1);
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
//   }

//   Future<String> _getfullName(String userId) async {
//     if (_fullNameCache.containsKey(userId)) {
//       return _fullNameCache[userId]!;
//     }

//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fullName = userDoc['fullName']?.toString() ?? 'Unknown Patient';
//       _fullNameCache[userId] = fullName;
//       return fullName;
//     } catch (e) {
//       debugPrint('Error fetching patient name: $e');
//       return 'Unknown Patient';
//     }
//   }

//   Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
//     return FutureBuilder<String>(
//       future: _getfullName(data['userId']),
//       builder: (context, fullNameSnapshot) {
//         final patientName = fullNameSnapshot.data ?? 'Loading...';

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header: Requested date and status
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                     Chip(
//                       label: Text(
//                         _statusText(data['status']),
//                         style: const TextStyle(color: Colors.white, fontSize: 12),
//                       ),
//                       backgroundColor: _statusColor(data['status']),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Avatar with doctor image or initials
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue.shade100,
//                   backgroundImage: data['doctorPhotoUrl'] != null
//                       ? NetworkImage(data['doctorPhotoUrl'])
//                       : null,
//                   child: data['doctorPhotoUrl'] == null
//                       ? Text(
//                           (data['doctorName'] ?? 'D')[0].toUpperCase(),
//                           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                         )
//                       : null,
//                 ),
//                 const SizedBox(height: 10),

//                 Text(
//                   'Patient: $patientName',
//                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),

//                 if (data['appointmentDate'] != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       'Date: ${_formatTimestamp(data['appointmentDate'] as Timestamp)}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 if (data['reason'] != null && data['reason'].toString().isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       'Reason: ${data['reason']}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),

//                 const SizedBox(height: 16),

//                 // Three-dot menu only for pending
//                 if ((data['status'] as String).toLowerCase() == 'pending')
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: PopupMenuButton<String>(
//                       icon: const Icon(Icons.more_vert),
//                       itemBuilder: (context) => [
//                         PopupMenuItem(
//                           value: 'confirm',
//                           child: Row(
//                             children: const [
//                               Icon(Icons.check, color: Colors.green),
//                               SizedBox(width: 8),
//                               Text('Confirm'),
//                             ],
//                           ),
//                         ),
//                         PopupMenuItem(
//                           value: 'cancel',
//                           child: Row(
//                             children: const [
//                               Icon(Icons.close, color: Colors.red),
//                               SizedBox(width: 8),
//                               Text('Cancel'),
//                             ],
//                           ),
//                         ),
//                       ],
//                       onSelected: (value) {
//                         if (value == 'confirm') {
//                           _updateAppointmentStatus(doc.id, 'confirmed', data['userId']);
//                         } else if (value == 'cancel') {
//                           _updateAppointmentStatus(doc.id, 'cancelled', data['userId']);
//                         }
//                       },
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: FutureBuilder<QuerySnapshot>(
//           future: _appointmentsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('No appointment requests found'),
//                     TextButton(
//                       onPressed: _refreshData,
//                       child: const Text('Refresh'),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final doc = snapshot.data!.docs[index];
//                 final data = doc.data() as Map<String, dynamic>;
//                 return _buildAppointmentCard(doc, data);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

///////////////////





class MychatsTab extends StatelessWidget {
  const MychatsTab({super.key});

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
    final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Patient')
            .get(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No patients available', style: TextStyle(color: Colors.grey)),
            );
          }

          final userDocs = usersSnapshot.data!.docs;

          return ListView.builder(
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final userDoc = userDocs[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;

              return FutureBuilder<Map<String, dynamic>>(
                future: _getChatInfo(userId, currentDoctorId, userData),
                builder: (context, chatInfoSnapshot) {
                  if (chatInfoSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingTile(userData);
                  }

                  final chatInfo = chatInfoSnapshot.data ?? {
                    'hasChat': false,
                    'lastMessage': null,
                    'messageTime': null,
                    'unreadCount': 0,
                    'isFromMe': false,
                    'isRead': true,
                  };

                  final isFromMe = chatInfo['isFromMe'] ?? false;
                  final isRead = chatInfo['isRead'] ?? true;
                  final referredBy = chatInfo['referredBy'];

                  // Only show if chat exists or if the doctor initiated the conversation
                  if (!chatInfo['hasChat'] && !isFromMe) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      backgroundImage: userData['avatar'] != null 
                          ? NetworkImage(userData['avatar'] as String) 
                          : null,
                      child: userData['avatar'] == null 
                          ? Text(
                              userData['fullName']?.isNotEmpty ?? false 
                                  ? userData['fullName'][0].toUpperCase() 
                                  : '?',
                              style: TextStyle(color: Colors.blue[900]),
                            )
                          : null,
                    ),
                    title: Text(
                      userData['fullName'] ?? 'Unknown Patient',
                      style: TextStyle(
                        fontWeight: chatInfo['unreadCount'] > 0 ? FontWeight.bold : FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (referredBy != null)
                          Text(
                            'Referred by: $referredBy',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        if (chatInfo['hasChat'])
                          Text(
                            '${isFromMe ? 'You: ' : ''}${chatInfo['lastMessage'] ?? 'No messages'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: chatInfo['unreadCount'] > 0 ? Colors.blue[900] : Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: chatInfo['hasChat'] && chatInfo['messageTime'] != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                chatInfo['messageTime']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (isFromMe)
                                Icon(
                                  isRead ? Icons.done_all : Icons.done,
                                  size: 14,
                                  color: isRead ? Colors.blue : Colors.grey,
                                ),
                              if (!isFromMe && chatInfo['unreadCount'] > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[900],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            fullName: userData['fullName'] ?? 'Patient',
                            userId: userId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getChatInfo(
    String userId, 
    String currentDoctorId, 
    Map<String, dynamic> userData
  ) async {
    try {
      // Get referring doctor info if available
      String? referredBy;
      if (userData['referredBy'] != null) {
        final referrerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userData['referredBy'])
            .get();
        
        if (referrerDoc.exists) {
          referredBy = (referrerDoc.data() as Map<String, dynamic>)['fullName'];
        }
      }

      // Find chat between current doctor and patient
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentDoctorId)
          .get();

      String? lastMessage;
      String? messageTime;
      bool hasChat = false;
      int unreadCount = 0;
      bool isFromMe = false;
      bool isRead = true;

      for (var chatDoc in chatQuery.docs) {
        final participants = List<String>.from(chatDoc['participants'] ?? []);
        if (participants.contains(userId)) {
          hasChat = true;
          
          // Get last message
          final messagesSnapshot = await chatDoc.reference
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();
          
          if (messagesSnapshot.docs.isNotEmpty) {
            final message = messagesSnapshot.docs.first.data();
            lastMessage = message['text']?.toString();
            messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
            isFromMe = message['senderId'] == currentDoctorId;
            isRead = message['isRead'] ?? true; // Default to true if not specified
          }

          // Get unread messages count
          final unreadMessages = await chatDoc.reference
              .collection('messages')
              .where('receiverId', isEqualTo: currentDoctorId)
              .where('isRead', isEqualTo: true)
              .get();
          
          unreadCount = unreadMessages.docs.length;
          break;
        }
      }

      return {
        if (referredBy != null) 'referredBy': referredBy,
        'hasChat': hasChat,
        'lastMessage': lastMessage,
        'messageTime': messageTime,
        'unreadCount': unreadCount,
        'isFromMe': isFromMe,
        'isRead': isRead,
      };
    } catch (e) {
      return {
        'hasChat': false,
        'lastMessage': null,
        'messageTime': null,
        'unreadCount': 0,
        'isFromMe': false,
        'isRead': true,
      };
    }
  }

  Widget _buildLoadingTile(Map<String, dynamic> userData) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(
          userData['fullName']?.isNotEmpty ?? false 
              ? userData['fullName'][0].toUpperCase() 
              : '?',
          style: TextStyle(color: Colors.blue[900]),
        ),
      ),
      title: Text(
        userData['fullName'] ?? 'Unknown Patient',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';





class SymptomspatientTab extends StatefulWidget {
  @override
  _SymptomspatientTabState createState() => _SymptomspatientTabState();
}

class _SymptomspatientTabState extends State<SymptomspatientTab> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentDoctorId;
  final Map<String, TextEditingController> _treatmentControllers = {};
  final Map<String, bool> _isUpdating = {};
  late TabController _tabController;
  final List<String> _availableTreatments = [
  'Paracetamol',
  'Ibuprofen',
  'Vitamin B6',
  'Doxylamine',
  'Lactulose',
  'Ferrous Sulfate',
  'Folic Acid',
  'Methyldopa',
  'Labetalol',
  'Insulin',
];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentDoctor();
  }

  Future<void> _getCurrentDoctor() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentDoctorId = user.uid;
      });
    }
  }

  Stream<QuerySnapshot> get _pendingCasesStream {
    if (_currentDoctorId == null) return Stream.empty();
    return _firestore.collection('symptoms')
      .where('status', isEqualTo: 'pending')
      .where('assignedDoctorId', isEqualTo: _currentDoctorId)
      .snapshots();
  }

  Stream<QuerySnapshot> get _treatedCasesStream {
    if (_currentDoctorId == null) return Stream.empty();
    return _firestore.collection('symptoms')
      .where('status', isEqualTo: 'treated')
      .where('assignedDoctorId', isEqualTo: _currentDoctorId)
      .snapshots();
  }

  Future<void> _updateSymptomStatus(String docId, String treatment, String assignedDoctorId) async {
    if (treatment.isEmpty) {
      _showSnackBar('Please enter the treatment method', isError: true);
      return;
    }

    setState(() {
      _isUpdating[docId] = true;
    });

    try {
      await _firestore.collection('symptoms').doc(docId).update({
        'status': 'treated',
        'treatment': treatment,
        'updatedAt': FieldValue.serverTimestamp(),
        'treatedBy': assignedDoctorId,
      });

      _showSnackBar('Treatment saved successfully!');
      _treatmentControllers[docId]?.clear();
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isUpdating[docId] = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _treatmentControllers.forEach((_, controller) => controller.dispose());
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              tabs: [
                Tab(text: 'Pending Cases', icon: Icon(Icons.pending_actions, color: Colors.white)),
                Tab(text: 'Treated Cases', icon: Icon(Icons.verified_user, color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCasesList(_pendingCasesStream, true),
                  _buildCasesList(_treatedCasesStream, false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasesList(Stream<QuerySnapshot> stream, bool isPending) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('An error occurred: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        final documents = snapshot.data?.docs;
        if (documents == null || documents.isEmpty) {
          return _buildEmptyStateWidget(isPending);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data[isPending ? 'createdAt' : 'updatedAt'] as Timestamp?;
              final dateTime = timestamp?.toDate();
              final assignedDoctorId = data['assignedDoctorId'];
              
              if (isPending) {
                _treatmentControllers.putIfAbsent(doc.id, () => TextEditingController());
              }

              return AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: isPending
                    ? _buildEditableCaseCard(data, dateTime, doc.id, assignedDoctorId)
                    : _buildReadOnlyCaseCard(data, dateTime),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEditableCaseCard(
    Map<String, dynamic> data, 
    DateTime? dateTime, 
    String docId,
    String assignedDoctorId,
  ) {
    final isUpdating = _isUpdating[docId] ?? false;
    final hasSelectedSymptoms = data['selectedSymptoms'] != null && 
                             (data['selectedSymptoms'] as List).isNotEmpty;
    final hasCustomSymptoms = data['customSymptoms'] != null && 
                            data['customSymptoms'].toString().isNotEmpty;

    return Card(
      key: ValueKey('pending-$docId'),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(data, dateTime, isPending: true),
            const SizedBox(height: 16),
            
            // Symptoms display
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Reported Symptoms',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (hasSelectedSymptoms) ...[
                    Text(
                      'Selected symptoms:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Column(
                      children: (data['selectedSymptoms'] as List).map((symptom) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- $symptom',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                          ),
                        )
                      ).toList(),
                    ),
                    if (hasCustomSymptoms) SizedBox(height: 8),
                  ],
                  
                  if (hasCustomSymptoms) ...[
                    Text(
                      'Additional details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      data['customSymptoms'].toString(),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    ),
                  ],
                  
                  if (!hasSelectedSymptoms && !hasCustomSymptoms) 
                    Text(
                      'No symptoms reported',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            _buildSectionHeader('Treatment Plan', icon: Icons.medical_services),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
  value: _treatmentControllers[docId]?.text.isNotEmpty == true 
         ? _treatmentControllers[docId]?.text 
         : null,
  items: _availableTreatments.map((treatment) {
    return DropdownMenuItem<String>(
      value: treatment,
      child: Text(treatment),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      _treatmentControllers[docId]?.text = value ?? '';
    });
  },
  decoration: InputDecoration(
    labelText: 'Select Treatment',
    filled: true,
    fillColor: Colors.blue.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.blue.shade200),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
),

            const SizedBox(height: 20),
            _buildActionButtons(docId, isUpdating, assignedDoctorId),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyCaseCard(Map<String, dynamic> data, DateTime? dateTime) {
    final hasSelectedSymptoms = data['selectedSymptoms'] != null && 
                             (data['selectedSymptoms'] as List).isNotEmpty;
    final hasCustomSymptoms = data['customSymptoms'] != null && 
                            data['customSymptoms'].toString().isNotEmpty;

    return Card(
      key: ValueKey('treated-${data['timestamp']}'),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(data, dateTime, isPending: false),
            const SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Reported Symptoms',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (hasSelectedSymptoms) ...[
                    Text(
                      'Selected symptoms:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Column(
                      children: (data['selectedSymptoms'] as List).map((symptom) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- $symptom',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                          ),
                        )
                      ).toList(),
                    ),
                    if (hasCustomSymptoms) SizedBox(height: 8),
                  ],
                  
                  if (hasCustomSymptoms) ...[
                    Text(
                      'Symptoms:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      data['customSymptoms'].toString(),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    ),
                  ],
                  
                  if (!hasSelectedSymptoms && !hasCustomSymptoms) 
                    Text(
                      'No symptoms reported',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            _buildSectionHeader('Provided Treatment', icon: Icons.medical_services),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Text(
                data['treatment'] ?? 'No treatment method provided',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
              ),
            ),
            if (data['updatedAt'] != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Last updated: ${_formatDate((data['updatedAt'] as Timestamp).toDate())}',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(Map<String, dynamic> data, DateTime? dateTime, {required bool isPending}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.person, color: Colors.blue),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['fullName'] ?? 'Name not provided',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  children: [
                    TextSpan(text: 'Age: ${data['age'] ?? 'N/A'}'),
                    TextSpan(text: ' • '),
                    TextSpan(text: 'Week: ${data['week'] ?? 'N/A'}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (dateTime != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
              ),
            ),
            child: Text(
              _formatDate(dateTime),
              style: TextStyle(
                color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(String docId, bool isUpdating, String assignedDoctorId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          icon: Icon(Icons.clear, size: 18),
          label: Text('CLEAR'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: isUpdating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.verified, size: 18),
          label: Text('TREAT'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isUpdating 
              ? null 
              : () => _updateSymptomStatus(
                  docId,
                  _treatmentControllers[docId]!.text.trim(),
                  assignedDoctorId,
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.blue.shade600),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
            const SizedBox(height: 20),
            Text(
              'An error occurred',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Try again'),
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading cases...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(bool isPending) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.assignment_turned_in : Icons.verified_user,
              size: 72,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 20),
            Text(
              isPending
                  ? 'No pending cases available'
                  : 'No treated cases available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isPending
                  ? 'There are currently no pending cases assigned to you.'
                  : 'You havent treated any cases yet.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }
}



// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};
//   final Map<String, bool> _isUpdating = {};
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _getCurrentDoctor();
//   }

//   Future<void> _getCurrentDoctor() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentDoctorId = user.uid;
//       });
//     }
//   }

//   Stream<QuerySnapshot> get _pendingCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'pending')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       .snapshots();
//   }

//   Stream<QuerySnapshot> get _treatedCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'treated')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       .snapshots();
//   }

//   Future<void> _updateSymptomStatus(String docId, String treatment, String assignedDoctorId) async {
//     if (treatment.isEmpty) {
//       _showSnackBar('Fadlan geli qaabka daawada', isError: true);
//       return;
//     }

//     setState(() {
//       _isUpdating[docId] = true;
//     });

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'updatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': assignedDoctorId,
//       });

//       _showSnackBar('Daawadu waa la kaydiyay!');
//       _treatmentControllers[docId]?.clear();
//     } catch (e) {
//       _showSnackBar('Khalad ayaa dhacay: ${e.toString()}', isError: true);
//     } finally {
//       setState(() {
//         _isUpdating[docId] = false;
//       });
//     }
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Container(
//             color: Colors.blue,
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.white,
//               labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//               tabs: [
//                 Tab(text: 'Kesiasha la sugayo', icon: Icon(Icons.pending_actions, color: Colors.white)),
//                 Tab(text: 'Kesiasha la daaway', icon: Icon(Icons.verified_user, color: Colors.white)),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.blue.shade50,
//                     Colors.white,
//                   ],
//                 ),
//               ),
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [
//                   _buildCasesList(_pendingCasesStream, true),
//                   _buildCasesList(_treatedCasesStream, false),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCasesList(Stream<QuerySnapshot> stream, bool isPending) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: stream,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return _buildErrorWidget('Khalad ayaa dhacay: ${snapshot.error}');
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingWidget();
//         }

//         final documents = snapshot.data?.docs;
//         if (documents == null || documents.isEmpty) {
//           return _buildEmptyStateWidget(isPending);
//         }

//         return RefreshIndicator(
//           onRefresh: () async => setState(() {}),
//           child: ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemCount: documents.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 16),
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final timestamp = data[isPending ? 'createdAt' : 'updatedAt'] as Timestamp?;
//               final dateTime = timestamp?.toDate();
//               final assignedDoctorId = data['assignedDoctorId'];
              
//               if (isPending) {
//                 _treatmentControllers.putIfAbsent(doc.id, () => TextEditingController());
//               }

//               return AnimatedSwitcher(
//                 duration: Duration(milliseconds: 300),
//                 child: isPending
//                     ? _buildEditableCaseCard(data, dateTime, doc.id, assignedDoctorId)
//                     : _buildReadOnlyCaseCard(data, dateTime),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEditableCaseCard(
//     Map<String, dynamic> data, 
//     DateTime? dateTime, 
//     String docId,
//     String assignedDoctorId,
//   ) {
//     final isUpdating = _isUpdating[docId] ?? false;
//     final hasSelectedSymptoms = data['selectedSymptoms'] != null && 
//                              (data['selectedSymptoms'] as List).isNotEmpty;
//     final hasCustomSymptoms = data['customSymptoms'] != null && 
//                             data['customSymptoms'].toString().isNotEmpty;

//     return Card(
//       key: ValueKey('pending-$docId'),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime, isPending: true),
//             const SizedBox(height: 16),
            
//             // Symptoms display
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Astaamaha la sheegay',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
                  
//                   if (hasSelectedSymptoms) ...[
//                     Text(
//                       'Astaamaha la doortay:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Column(
//                       children: (data['selectedSymptoms'] as List).map((symptom) => 
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 2),
//                           child: Text(
//                             '- $symptom',
//                             style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                           ),
//                         )
//                       ).toList(),
//                     ),
//                     if (hasCustomSymptoms) SizedBox(height: 8),
//                   ],
                  
//                   if (hasCustomSymptoms) ...[
//                     Text(
//                       'Faahfaahin dheeraad ah:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['customSymptoms'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                   ],
                  
//                   if (!hasSelectedSymptoms && !hasCustomSymptoms) 
//                     Text(
//                       'Astaamaha lama sheegin',
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 16),
//             _buildSectionHeader('Qaabka Daawada', icon: Icons.medical_services),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _treatmentControllers[docId],
//               maxLines: 4,
//               minLines: 3,
//               decoration: InputDecoration(
//                 hintText: 'Geli qaabka daawada...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide(color: Colors.blue.shade200),
//                 ),
//                 filled: true,
//                 fillColor: Colors.blue.shade50,
//                 contentPadding: const EdgeInsets.all(16),
//               ),
//             ),
//             const SizedBox(height: 20),
//             _buildActionButtons(docId, isUpdating, assignedDoctorId),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReadOnlyCaseCard(Map<String, dynamic> data, DateTime? dateTime) {
//     final hasSelectedSymptoms = data['selectedSymptoms'] != null && 
//                              (data['selectedSymptoms'] as List).isNotEmpty;
//     final hasCustomSymptoms = data['customSymptoms'] != null && 
//                             data['customSymptoms'].toString().isNotEmpty;

//     return Card(
//       key: ValueKey('treated-${data['timestamp']}'),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime, isPending: false),
//             const SizedBox(height: 16),
            
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Astaamaha la sheegay',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
                  
//                   if (hasSelectedSymptoms) ...[
//                     Text(
//                       'Astaamaha la doortay:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Column(
//                       children: (data['selectedSymptoms'] as List).map((symptom) => 
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 2),
//                           child: Text(
//                             '- $symptom',
//                             style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                           ),
//                         )
//                       ).toList(),
//                     ),
//                     if (hasCustomSymptoms) SizedBox(height: 8),
//                   ],
                  
//                   if (hasCustomSymptoms) ...[
//                     Text(
//                       'Faahfaahin dheeraad ah:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['customSymptoms'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                   ],
                  
//                   if (!hasSelectedSymptoms && !hasCustomSymptoms) 
//                     Text(
//                       'Astaamaha lama sheegin',
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 16),
//             _buildSectionHeader('Daawada la bixiyay', icon: Icons.medical_services),
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.green.shade100),
//               ),
//               child: Text(
//                 data['treatment'] ?? 'Qaabka daawada lama sheegin',
//                 style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
//               ),
//             ),
//             if (data['updatedAt'] != null) ...[
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Icon(Icons.calendar_today, size: 14, color: Colors.grey),
//                   const SizedBox(width: 6),
//                   Text(
//                     'La cusboonaysiiyay: ${_formatDate((data['updatedAt'] as Timestamp).toDate())}',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPatientHeader(Map<String, dynamic> data, DateTime? dateTime, {required bool isPending}) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue.shade100,
//           child: Icon(Icons.person, color: Colors.blue),
//         ),
//         SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 data['fullName'] ?? 'Magaca lama sheegin',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               RichText(
//                 text: TextSpan(
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                   children: [
//                     TextSpan(text: 'Da\'da: ${data['age'] ?? 'N/A'}'),
//                     TextSpan(text: ' • '),
//                     TextSpan(text: 'Toddobaadka: ${data['week'] ?? 'N/A'}'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (dateTime != null)
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
//               ),
//             ),
//             child: Text(
//               _formatDate(dateTime),
//               style: TextStyle(
//                 color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildActionButtons(String docId, bool isUpdating, String assignedDoctorId) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         OutlinedButton.icon(
//           icon: Icon(Icons.clear, size: 18),
//           label: Text('TIRTIR'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.grey.shade700,
//             side: BorderSide(color: Colors.grey.shade400),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
//         ),
//         const SizedBox(width: 12),
//         ElevatedButton.icon(
//           icon: isUpdating
//               ? SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : Icon(Icons.verified, size: 18),
//           label: Text('DAWO'),
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: Colors.green.shade600,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: isUpdating 
//               ? null 
//               : () => _updateSymptomStatus(
//                   docId,
//                   _treatmentControllers[docId]!.text.trim(),
//                   assignedDoctorId,
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionHeader(String title, {IconData? icon}) {
//     return Row(
//       children: [
//         if (icon != null) ...[
//           Icon(icon, size: 18, color: Colors.blue.shade600),
//           const SizedBox(width: 8),
//         ],
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue.shade800,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorWidget(String error) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
//             const SizedBox(height: 20),
//             Text(
//               'Khalad ayaa dhacay',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red.shade800,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               error,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               icon: Icon(Icons.refresh),
//               label: Text('Isku day mar kale'),
//               onPressed: () => setState(() {}),
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.blue.shade600,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             strokeWidth: 3,
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Kesiasha la helayo...',
//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget(bool isPending) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(30),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               isPending ? Icons.assignment_turned_in : Icons.verified_user,
//               size: 72,
//               color: Colors.blue.shade200,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               isPending
//                   ? 'Ma jiraan kesiasho la sugayo'
//                   : 'Ma jiraan kesyo la daaway',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue.shade800,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               isPending
//                   ? 'Ma jiraan kesyo kuugu habboon oo la sugayo hadda.'
//                   : 'Weli ma daawin kesyo.',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
//   }
// }



// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};
//   final Map<String, bool> _isUpdating = {};
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _getCurrentDoctor();
//   }

//   Future<void> _getCurrentDoctor() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentDoctorId = user.uid;
//       });
//     }
//   }

//   Stream<QuerySnapshot> get _pendingCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'pending')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       .snapshots();
//   }

//   Stream<QuerySnapshot> get _treatedCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'treated')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       .snapshots();
//   }

//   Future<void> _updateSymptomStatus(String docId, String treatment, String assignedDoctorId) async {
//     if (treatment.isEmpty) {
//       _showSnackBar('Please enter treatment details', isError: true);
//       return;
//     }

//     setState(() {
//       _isUpdating[docId] = true;
//     });

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'updatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': assignedDoctorId,
//       });

//       _showSnackBar('Treatment saved successfully!');
//       _treatmentControllers[docId]?.clear();
//     } catch (e) {
//       _showSnackBar('Error saving treatment: ${e.toString()}', isError: true);
//     } finally {
//       setState(() {
//         _isUpdating[docId] = false;
//       });
//     }
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//    Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Container(
//             color: Colors.blue, // You can change this color
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.white,
//               labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//               tabs: [
//                 Tab(text: 'Pending Cases', icon: Icon(Icons.pending_actions, color: Colors.white)),
//                 Tab(text: 'Treated Cases', icon: Icon(Icons.verified_user, color: Colors.white)),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.blue.shade50,
//                     Colors.white,
//                   ],
//                 ),
//               ),
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [
//                   _buildCasesList(_pendingCasesStream, true),
//                   _buildCasesList(_treatedCasesStream, false),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCasesList(Stream<QuerySnapshot> stream, bool isPending) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: stream,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return _buildErrorWidget('Error loading cases: ${snapshot.error}');
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingWidget();
//         }

//         final documents = snapshot.data?.docs;
//         if (documents == null || documents.isEmpty) {
//           return _buildEmptyStateWidget(isPending);
//         }

//         return RefreshIndicator(
//           onRefresh: () async => setState(() {}),
//           child: ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemCount: documents.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 16),
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final timestamp = data[isPending ? 'timestamp' : 'updatedAt'] as Timestamp?;
//               final dateTime = timestamp?.toDate();
//               final assignedDoctorId = data['assignedDoctorId'];
              
//               if (isPending) {
//                 _treatmentControllers.putIfAbsent(doc.id, () => TextEditingController());
//               }

//               return AnimatedSwitcher(
//                 duration: Duration(milliseconds: 300),
//                 child: isPending
//                     ? _buildEditableCaseCard(data, dateTime, doc.id, assignedDoctorId)
//                     : _buildReadOnlyCaseCard(data, dateTime),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEditableCaseCard(
//     Map<String, dynamic> data, 
//     DateTime? dateTime, 
//     String docId,
//     String assignedDoctorId,
//   ) {
//     final isUpdating = _isUpdating[docId] ?? false;
//     final hasSelectedSymptom = data['xanuun'] != null && data['xanuun'].toString().isNotEmpty;
//     final hasCustomSymptoms = data['symptoms'] != null && data['symptoms'].toString().isNotEmpty;

//     return Card(
//       key: ValueKey('pending-$docId'),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime, isPending: true),
//             const SizedBox(height: 16),
            
//             // Display symptoms section
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Reported Symptoms',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
                  
//                   // Show selected symptom if available
//                   if (hasSelectedSymptom) ...[
//                     Text(
//                       'Selected Symptom:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['xanuun'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                     if (hasCustomSymptoms) SizedBox(height: 8),
//                   ],
                  
//                   // Show custom symptoms if available
//                   if (hasCustomSymptoms) ...[
//                     if (hasSelectedSymptom) Text(
//                       'Additional Notes:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['symptoms'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                   ],
                  
//                   // Show message if no symptoms are provided
//                   if (!hasSelectedSymptom && !hasCustomSymptoms) 
//                     Text(
//                       'No symptoms reported',
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 16),
//             _buildSectionHeader('Treatment Plan', icon: Icons.medical_services),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _treatmentControllers[docId],
//               maxLines: 4,
//               minLines: 3,
//               decoration: InputDecoration(
//                 hintText: 'Enter detailed treatment plan...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide(color: Colors.blue.shade200),
//                 ),
//                 filled: true,
//                 fillColor: Colors.blue.shade50,
//                 contentPadding: const EdgeInsets.all(16),
//               ),
//             ),
//             const SizedBox(height: 20),
//             _buildActionButtons(docId, isUpdating, assignedDoctorId),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReadOnlyCaseCard(Map<String, dynamic> data, DateTime? dateTime) {
//     final hasSelectedSymptom = data['xanuun'] != null && data['xanuun'].toString().isNotEmpty;
//     final hasCustomSymptoms = data['symptoms'] != null && data['symptoms'].toString().isNotEmpty;

//     return Card(
//       key: ValueKey('treated-${data['timestamp']}'),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime, isPending: false),
//             const SizedBox(height: 16),
            
//             // Display symptoms section
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Reported Symptoms',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
                  
//                   // Show selected symptom if available
//                   if (hasSelectedSymptom) ...[
//                     Text(
//                       'Selected Symptom:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['xanuun'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                     if (hasCustomSymptoms) SizedBox(height: 8),
//                   ],
                  
//                   // Show custom symptoms if available
//                   if (hasCustomSymptoms) ...[
//                     if (hasSelectedSymptom) Text(
//                       'Additional Notes:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['symptoms'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                   ],
                  
//                   // Show message if no symptoms are provided
//                   if (!hasSelectedSymptom && !hasCustomSymptoms) 
//                     Text(
//                       'No symptoms reported',
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 16),
//             _buildSectionHeader('Treatment Provided', icon: Icons.medical_services),
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.green.shade100),
//               ),
//               child: Text(
//                 data['treatment'] ?? 'No treatment details provided',
//                 style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
//               ),
//             ),
//             if (data['updatedAt'] != null) ...[
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Icon(Icons.calendar_today, size: 14, color: Colors.grey),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Updated: ${_formatDate((data['updatedAt'] as Timestamp).toDate())}',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPatientHeader(Map<String, dynamic> data, DateTime? dateTime, {required bool isPending}) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue.shade100,
//           child: Icon(Icons.person, color: Colors.blue),
//         ),
//         SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 data['fullName'] ?? 'No name provided',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               RichText(
//                 text: TextSpan(
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                   children: [
//                     TextSpan(text: 'Age: ${data['age'] ?? 'N/A'}'),
//                     TextSpan(text: ' • '),
//                     TextSpan(text: 'Week: ${data['week'] ?? 'N/A'}'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (dateTime != null)
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
//               ),
//             ),
//             child: Text(
//               _formatDate(dateTime),
//               style: TextStyle(
//                 color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildActionButtons(String docId, bool isUpdating, String assignedDoctorId) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         OutlinedButton.icon(
//           icon: Icon(Icons.clear, size: 18),
//           label: Text('CLEAR'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.grey.shade700,
//             side: BorderSide(color: Colors.grey.shade400),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
//         ),
//         const SizedBox(width: 12),
//         ElevatedButton.icon(
//           icon: isUpdating
//               ? SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : Icon(Icons.verified, size: 18),
//           label: Text('MARK AS TREATED'),
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: Colors.green.shade600,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: isUpdating 
//               ? null 
//               : () => _updateSymptomStatus(
//                   docId,
//                   _treatmentControllers[docId]!.text.trim(),
//                   assignedDoctorId,
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionHeader(String title, {IconData? icon}) {
//     return Row(
//       children: [
//         if (icon != null) ...[
//           Icon(icon, size: 18, color: Colors.blue.shade600),
//           const SizedBox(width: 8),
//         ],
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue.shade800,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorWidget(String error) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
//             const SizedBox(height: 20),
//             Text(
//               'Something went wrong',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red.shade800,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               error,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               icon: Icon(Icons.refresh),
//               label: Text('Try Again'),
//               onPressed: () => setState(() {}),
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.blue.shade600,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             strokeWidth: 3,
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Loading patient cases...',
//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget(bool isPending) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(30),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               isPending ? Icons.assignment_turned_in : Icons.verified_user,
//               size: 72,
//               color: Colors.blue.shade200,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               isPending
//                   ? 'No pending cases assigned to you'
//                   : 'No treated cases found',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue.shade800,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               isPending
//                   ? 'All caught up! You have no pending cases at the moment.'
//                   : 'You haven\'t treated any cases yet.',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
//   }
// }

// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};
//   final Map<String, bool> _isUpdating = {};
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _getCurrentDoctor();
//   }

//   Future<void> _getCurrentDoctor() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentDoctorId = user.uid;
//       });
//     }
//   }

//   Stream<QuerySnapshot> get _pendingCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'pending')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       .snapshots();
//   }

//   Stream<QuerySnapshot> get _treatedCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'treated')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       .snapshots();
//   }

//   Future<void> _updateSymptomStatus(String docId, String treatment, String assignedDoctorId) async {
//     if (treatment.isEmpty) {
//       _showSnackBar('Please enter treatment details', isError: true);
//       return;
//     }

//     setState(() {
//       _isUpdating[docId] = true;
//     });

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'treatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': assignedDoctorId,
//       });

//       _showSnackBar('Treatment saved successfully!');
//       _treatmentControllers[docId]?.clear();
//     } catch (e) {
//       _showSnackBar('Error saving treatment: ${e.toString()}', isError: true);
//     } finally {
//       setState(() {
//         _isUpdating[docId] = false;
//       });
//     }
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Patient Symptoms'),
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           labelStyle: TextStyle(fontWeight: FontWeight.bold),
//           tabs: [
//             Tab(text: 'Pending Cases', icon: Icon(Icons.pending_actions)),
//             Tab(text: 'Treated Cases', icon: Icon(Icons.verified_user)),
//           ],
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.blue.shade50,
//               Colors.white,
//             ],
//           ),
//         ),
//         child: TabBarView(
//           controller: _tabController,
//           children: [
//             _buildCasesList(_pendingCasesStream, true),
//             _buildCasesList(_treatedCasesStream, false),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCasesList(Stream<QuerySnapshot> stream, bool isPending) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: stream,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return _buildErrorWidget('Error loading cases: ${snapshot.error}');
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingWidget();
//         }

//         final documents = snapshot.data?.docs;
//         if (documents == null || documents.isEmpty) {
//           return _buildEmptyStateWidget(isPending);
//         }

//         return RefreshIndicator(
//           onRefresh: () async => setState(() {}),
//           child: ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemCount: documents.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 16),
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final timestamp = data[isPending ? 'timestamp' : 'treatedAt'] as Timestamp?;
//               final dateTime = timestamp?.toDate();
//               final assignedDoctorId = data['assignedDoctorId'];
              
//               if (isPending) {
//                 _treatmentControllers.putIfAbsent(doc.id, () => TextEditingController());
//               }

//               return AnimatedSwitcher(
//                 duration: Duration(milliseconds: 300),
//                 child: isPending
//                     ? _buildEditableCaseCard(data, dateTime, doc.id, assignedDoctorId)
//                     : _buildReadOnlyCaseCard(data, dateTime),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEditableCaseCard(
//     Map<String, dynamic> data, 
//     DateTime? dateTime, 
//     String docId,
//     String assignedDoctorId,
//   ) {
//     final isUpdating = _isUpdating[docId] ?? false;
//     final hasSelectedSymptom = data['xanuun'] != null && data['xanuun'].toString().isNotEmpty;
//     final hasCustomSymptoms = data['symptoms'] != null && data['symptoms'].toString().isNotEmpty;

//     return Card(
//       key: ValueKey('pending-$docId'),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime, isPending: true),
//             const SizedBox(height: 16),
            
//             // Display symptoms section
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Reported Symptoms',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
                  
//                   // Show selected symptom if available
//                   if (hasSelectedSymptom) ...[
//                     Text(
//                       'Selected Symptom:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['xanuun'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                     if (hasCustomSymptoms) SizedBox(height: 8),
//                   ],
                  
//                   // Show custom symptoms if available
//                   if (hasCustomSymptoms) ...[
//                     if (hasSelectedSymptom) Text(
//                       'Additional Notes:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['symptoms'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                   ],
                  
//                   // Show message if no symptoms are provided
//                   if (!hasSelectedSymptom && !hasCustomSymptoms) 
//                     Text(
//                       'No symptoms reported',
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 16),
//             _buildSectionHeader('Treatment Plan', icon: Icons.medical_services),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _treatmentControllers[docId],
//               maxLines: 4,
//               minLines: 3,
//               decoration: InputDecoration(
//                 hintText: 'Enter detailed treatment plan...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide(color: Colors.blue.shade200),
//                 ),
//                 filled: true,
//                 fillColor: Colors.blue.shade50,
//                 contentPadding: const EdgeInsets.all(16),
//               ),
//             ),
//             const SizedBox(height: 20),
//             _buildActionButtons(docId, isUpdating, assignedDoctorId),
//           ],
//         ),
//       ),
//     );
//   }

//   // ... [rest of the code remains the same]
  
//   Widget _buildReadOnlyCaseCard(Map<String, dynamic> data, DateTime? dateTime) {
//     final hasSelectedSymptom = data['xanuun'] != null && data['xanuun'].toString().isNotEmpty;
//     final hasCustomSymptoms = data['symptoms'] != null && data['symptoms'].toString().isNotEmpty;

//     return Card(
//       key: ValueKey('treated-${data['timestamp']}'),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime, isPending: false),
//             const SizedBox(height: 16),
            
//             // Display symptoms section
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Reported Symptoms',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
                  
//                   // Show selected symptom if available
//                   if (hasSelectedSymptom) ...[
//                     Text(
//                       'Selected Symptom:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['xanuun'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                     if (hasCustomSymptoms) SizedBox(height: 8),
//                   ],
                  
//                   // Show custom symptoms if available
//                   if (hasCustomSymptoms) ...[
//                     if (hasSelectedSymptom) Text(
//                       'Additional Notes:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     Text(
//                       data['symptoms'].toString(),
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                   ],
                  
//                   // Show message if no symptoms are provided
//                   if (!hasSelectedSymptom && !hasCustomSymptoms) 
//                     Text(
//                       'No symptoms reported',
//                       style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//                     ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 16),
//             _buildSectionHeader('Treatment Provided', icon: Icons.medical_services),
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.green.shade100),
//               ),
//               child: Text(
//                 data['treatment'] ?? 'No treatment details provided',
//                 style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
//               ),
//             ),
//             if (data['treatedAt'] != null) ...[
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Icon(Icons.calendar_today, size: 14, color: Colors.grey),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Treated on: ${_formatDate((data['treatedAt'] as Timestamp).toDate())}',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//   // Add these methods inside your _SymptomspatientTabState class

// Widget _buildErrorWidget(String error) {
//   return Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(Icons.error_outline, color: Colors.red, size: 60),
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             error,
//             style: TextStyle(fontSize: 16, color: Colors.red),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildLoadingWidget() {
//   return Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         CircularProgressIndicator(),
//         SizedBox(height: 16),
//         Text('Loading cases...'),
//       ],
//     ),
//   );
// }

// Widget _buildEmptyStateWidget(bool isPending) {
//   return Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(
//           isPending ? Icons.check_circle_outline : Icons.assignment_turned_in,
//           size: 60,
//           color: Colors.grey,
//         ),
//         SizedBox(height: 16),
//         Text(
//           isPending 
//               ? 'No pending cases found'
//               : 'No treated cases yet',
//           style: TextStyle(fontSize: 18, color: Colors.grey),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildPatientHeader(Map<String, dynamic> data, DateTime? dateTime, {required bool isPending}) {
//   return Row(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       CircleAvatar(
//         backgroundColor: Colors.blue.shade100,
//         child: Icon(Icons.person, color: Colors.blue),
//       SizedBox(width: 12),
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//                 data['fullName'] ?? 'No name provided',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               RichText(
//                 text: TextSpan(
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                   children: [
//                     TextSpan(text: 'Age: ${data['age'] ?? 'N/A'}'),
//                     TextSpan(text: ' • '),
//                     TextSpan(text: 'Week: ${data['week'] ?? 'N/A'}'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (dateTime != null)
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
//               ),
//             ),
//             child: Text(
//               _formatDate(dateTime),
//               style: TextStyle(
//                 color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//       ],
//     );
//   }!= null) ...[
//               SizedBox(height: 4),
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today, size: 14, color: Colors.grey),
//                   SizedBox(width: 6),
//                   Text(
//                     isPending 
//                         ? 'Reported on: ${_formatDate(dateTime)}'
//                         : 'Treated on: ${_formatDate(dateTime)}',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     ],
//   );
// }

// Widget _buildSectionHeader(String title, {IconData? icon}) {
//   return Row(
//     children: [
//       if (icon != null) ...[
//         Icon(icon, size: 20, color: Colors.blue),
//         SizedBox(width: 8),
//       ],
//       Text(
//         title,
//         style: TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Colors.blue.shade800,
//         ),
//       ),
//     ],
//   );
// }

// Widget _buildActionButtons(String docId, bool isUpdating, String assignedDoctorId) {
//   return SizedBox
//     width: double.infinity,
//     child: ElevatedButton(
//       onPressed: isUpdating 
//           ? null 
//           : () => _updateSymptomStatus(
//                 docId, 
//                 _treatmentControllers[docId]!.text, 
//                 assignedDoctorId,
//               ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.blue.shade600,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         padding: EdgeInsets.symmetric(vertical: 14),
//       ),
//       child: isUpdating
//           ? SizedBox(
//               height: 20,
//               width: 20,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: Colors.white,
//               ),
//             )
//           Widget _buildActionButtons(String docId, bool isUpdating, String assignedDoctorId) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         OutlinedButton.icon(
//           icon: Icon(Icons.clear, size: 18),
//           label: Text('CLEAR'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.grey.shade700,
//             side: BorderSide(color: Colors.grey.shade400),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
//         ),
//         const SizedBox(width: 12),
//         ElevatedButton.icon(
//           icon: isUpdating
//               ? SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : Icon(Icons.verified, size: 18),
//           label: Text('MARK AS TREATED'),
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: Colors.green.shade600,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: isUpdating 
//               ? null 
//               : () => _updateSymptomStatus(
//                   docId,
//                   _treatmentControllers[docId]!.text.trim(),
//                   assignedDoctorId,
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionHeader(String title, {IconData? icon}) {
//     return Row(
//       children: [
//         if (icon != null) ...[
//           Icon(icon, size: 18, color: Colors.blue.shade600),
//           const SizedBox(width: 8),
//         ],
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue.shade800,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorWidget(String error) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
//             const SizedBox(height: 20),
//             Text(
//               'Something went wrong',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red.shade800,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               error,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               icon: Icon(Icons.refresh),
//               label: Text('Try Again'),
//               onPressed: () => setState(() {}),
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.blue.shade600,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             strokeWidth: 3,
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Loading patient cases...',
//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget(bool isPending) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(30),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               isPending ? Icons.assignment_turned_in : Icons.verified_user,
//               size: 72,
//               color: Colors.blue.shade200,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               isPending
//                   ? 'No pending cases assigned to you'
//                   : 'No treated cases found',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue.shade800,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               isPending
//                   ? 'All caught up! You have no pending cases at the moment.'
//                   : 'You haven\'t treated any cases yet.',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
//   }
//             ),
//     ),
//   );
  
// }

// String _formatDate(DateTime date) {
//   return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
// }

  
// }





// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};
//   final Map<String, bool> _isUpdating = {};
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _getCurrentDoctor();
//   }

//   Future<void> _getCurrentDoctor() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentDoctorId = user.uid;
//       });
//     }
//   }

//   Stream<QuerySnapshot> get _pendingCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'pending')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       // .orderBy('timestamp', descending: true)
//       .snapshots();
//   }

//   Stream<QuerySnapshot> get _treatedCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'treated')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       // .orderBy('treatedAt', descending: true)
//       .snapshots();
//   }

//  Future<void> _updateSymptomStatus(String docId, String treatment, String assignedDoctorId) async {
//   if (treatment.isEmpty) {
//     _showSnackBar('Please enter treatment details', isError: true);
//     return;
//   }

//   setState(() {
//     _isUpdating[docId] = true;
//   });

//   try {
//     // // First fetch the doctor's name from Firestore
//     // final doctorDoc = await _firestore.collection('symptoms').doc(_currentDoctorId).get();
//     //  final doctorName = doctorDoc.data()?['doctorName'] ?? 'Doctor';

//     await _firestore.collection('symptoms').doc(docId).update({
//       'status': 'treated',
//       'treatment': treatment,
//       'treatedAt': FieldValue.serverTimestamp(),
//       'treatedBy': assignedDoctorId,
     
//     });

//     _showSnackBar('Treatment saved successfully!');
//     _treatmentControllers[docId]?.clear();
//   } catch (e) {
//     _showSnackBar('Error saving treatment: ${e.toString()}', isError: true);
//   } finally {
//     setState(() {
//       _isUpdating[docId] = false;
//     });
//   }
// }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Patient Symptoms'),
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           labelStyle: TextStyle(fontWeight: FontWeight.bold),
//           tabs: [
//             Tab(text: 'Pending Cases', icon: Icon(Icons.pending_actions)),
//             Tab(text: 'Treated Cases', icon: Icon(Icons.verified_user)),
//           ],
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.blue.shade50,
//               Colors.white,
//             ],
//           ),
//         ),
//         child: TabBarView(
//           controller: _tabController,
//           children: [
//             _buildCasesList(_pendingCasesStream, true),
//             _buildCasesList(_treatedCasesStream, false),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCasesList(Stream<QuerySnapshot> stream, bool isPending) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: stream,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return _buildErrorWidget('Error loading cases: ${snapshot.error}');
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingWidget();
//         }

//         final documents = snapshot.data?.docs;
//         if (documents == null || documents.isEmpty) {
//           return _buildEmptyStateWidget(isPending);
//         }

//         return RefreshIndicator(
//           onRefresh: () async => setState(() {}),
//           child: ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemCount: documents.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 16),
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final timestamp = data[isPending ? 'timestamp' : 'treatedAt'] as Timestamp?;
//               final dateTime = timestamp?.toDate();
//               final assignedDoctorId = data['assignedDoctorId'];
              
//               if (isPending) {
//                 _treatmentControllers.putIfAbsent(doc.id, () => TextEditingController());
//               }

//               return AnimatedSwitcher(
//                 duration: Duration(milliseconds: 300),
//                 child: isPending
//                     ? _buildEditableCaseCard(data, dateTime, doc.id, assignedDoctorId)
//                     : _buildReadOnlyCaseCard(data, dateTime),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEditableCaseCard(
//     Map<String, dynamic> data, 
//     DateTime? dateTime, 
//     String docId,
//     String assignedDoctorId,
//   ) {
//     final isUpdating = _isUpdating[docId] ?? false;

//     return Card(
//       key: ValueKey('pending-$docId'),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime, isPending: true),
//             const SizedBox(height: 16),
//             _buildSymptomsSection(data),
//             const SizedBox(height: 16),
//             _buildSectionHeader('Treatment Plan', icon: Icons.medical_services),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _treatmentControllers[docId],
//               maxLines: 4,
//               minLines: 3,
//               decoration: InputDecoration(
//                 hintText: 'Enter detailed treatment plan...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide(color: Colors.blue.shade200),
//                 ),
//                 filled: true,
//                 fillColor: Colors.blue.shade50,
//                 contentPadding: const EdgeInsets.all(16),
//               ),
//             ),
//             const SizedBox(height: 20),
//             _buildActionButtons(docId, isUpdating, assignedDoctorId),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReadOnlyCaseCard(Map<String, dynamic> data, DateTime? dateTime) {
//     return Card(
//       key: ValueKey('treated-${data['timestamp']}'),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime, isPending: false),
//             const SizedBox(height: 16),
//             _buildSymptomsSection(data),
//             const SizedBox(height: 16),
//             _buildSectionHeader('Treatment Provided', icon: Icons.medical_services),
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.green.shade100),
//               ),
//               child: Text(
//                 data['treatment'] ?? 'No treatment details provided',
//                 style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
//               ),
//             ),
//             if (data['treatedAt'] != null) ...[
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Icon(Icons.calendar_today, size: 14, color: Colors.grey),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Treated on: ${_formatDate((data['treatedAt'] as Timestamp).toDate())}',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPatientHeader(Map<String, dynamic> data, DateTime? dateTime, {required bool isPending}) {
//     return Row(
//       children: [
//         CircleAvatar(
//           backgroundColor: isPending ? Colors.orange.shade100 : Colors.green.shade100,
//           child: Icon(
//             Icons.person,
//             color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 data['fullName'] ?? 'No name provided',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               RichText(
//                 text: TextSpan(
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                   children: [
//                     TextSpan(text: 'Age: ${data['age'] ?? 'N/A'}'),
//                     TextSpan(text: ' • '),
//                     TextSpan(text: 'Week: ${data['week'] ?? 'N/A'}'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (dateTime != null)
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
//               ),
//             ),
//             child: Text(
//               _formatDate(dateTime),
//               style: TextStyle(
//                 color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildSymptomsSection(Map<String, dynamic> data) {
//     return Container(
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
//               const SizedBox(width: 8),
//               Text(
//                 'Reported Symptoms',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             data['symptoms']?.toString() ?? 'No symptoms reported',
//             data['xanuun']?.toString() ?? 'No symptoms reported',
//             style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons(String docId, bool isUpdating, String assignedDoctorId) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         OutlinedButton.icon(
//           icon: Icon(Icons.clear, size: 18),
//           label: Text('CLEAR'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.grey.shade700,
//             side: BorderSide(color: Colors.grey.shade400),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
//         ),
//         const SizedBox(width: 12),
//         ElevatedButton.icon(
//           icon: isUpdating
//               ? SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : Icon(Icons.verified, size: 18),
//           label: Text('MARK AS TREATED'),
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: Colors.green.shade600,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: isUpdating 
//               ? null 
//               : () => _updateSymptomStatus(
//                   docId,
//                   _treatmentControllers[docId]!.text.trim(),
//                   assignedDoctorId,
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionHeader(String title, {IconData? icon}) {
//     return Row(
//       children: [
//         if (icon != null) ...[
//           Icon(icon, size: 18, color: Colors.blue.shade600),
//           const SizedBox(width: 8),
//         ],
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue.shade800,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorWidget(String error) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
//             const SizedBox(height: 20),
//             Text(
//               'Something went wrong',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red.shade800,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               error,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               icon: Icon(Icons.refresh),
//               label: Text('Try Again'),
//               onPressed: () => setState(() {}),
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.blue.shade600,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             strokeWidth: 3,
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Loading patient cases...',
//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget(bool isPending) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(30),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               isPending ? Icons.assignment_turned_in : Icons.verified_user,
//               size: 72,
//               color: Colors.blue.shade200,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               isPending
//                   ? 'No pending cases assigned to you'
//                   : 'No treated cases found',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue.shade800,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               isPending
//                   ? 'All caught up! You have no pending cases at the moment.'
//                   : 'You haven\'t treated any cases yet.',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
//   }
// }








// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};
//   final Map<String, bool> _isUpdating = {};
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _getCurrentDoctor();
//   }

//   Future<void> _getCurrentDoctor() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentDoctorId = user.uid;
//       });
//     }
//   }

//   Stream<QuerySnapshot> get _pendingCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'pending')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       // .orderBy('timestamp', descending: true)
//       .snapshots();
//   }

//   Stream<QuerySnapshot> get _treatedCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'treated')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       // .orderBy('treatedAt', descending: true)
//       .snapshots();
//   }

//   Future<void> _updateSymptomStatus(String docId, String treatment, String assignedDoctorId) async {
//     if (treatment.isEmpty) {
//       _showSnackBar('Please enter treatment details');
//       return;
//     }

//     setState(() {
//       _isUpdating[docId] = true;
//     });

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'treatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': assignedDoctorId,
//         'doctorName': _auth.currentUser?.displayName ?? 'Doctor',
//       });

//       _showSnackBar('Treatment saved successfully!')
//       backgroundcolor: green;
//       _treatmentControllers[docId]?.clear();
//     } catch (e) {
//       _showSnackBar('Error saving treatment: ${e.toString()}');
//     } finally {
//       setState(() {
//         _isUpdating[docId] = false;
//       });
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: [
//             Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
//             Tab(text: 'Treated', icon: Icon(Icons.verified)),
//           ],
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).primaryColor.withOpacity(0.05),
//               Colors.white,
//             ],
//           ),
//         ),
//         child: TabBarView(
//           controller: _tabController,
//           children: [
//             // Pending Cases Tab
//             _buildCasesList(_pendingCasesStream, true),
//             // Treated Cases Tab
//             _buildCasesList(_treatedCasesStream, false),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCasesList(Stream<QuerySnapshot> stream, bool isPending) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: stream,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.error_outline, size: 64, color: Colors.red),
//                 SizedBox(height: 16),
//                 Text(
//                   'Error loading cases',
//                   style: TextStyle(color: Colors.red, fontSize: 18),
//                 ),
//                 SizedBox(height: 8),
//                 ElevatedButton(
//                   onPressed: () => setState(() {}),
//                   child: Text('Retry'),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final documents = snapshot.data?.docs;
//         if (documents == null || documents.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   isPending ? Icons.assignment_turned_in : Icons.verified_user,
//                   size: 64,
//                   color: Colors.grey,
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   isPending
//                       ? 'No pending cases assigned to you'
//                       : 'No treated cases found',
//                   style: TextStyle(color: Colors.grey, fontSize: 18),
//                 ),
//               ],
//             ),
//           );
//         }

//         return RefreshIndicator(
//           onRefresh: () async => setState(() {}),
//           child: ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemCount: documents.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 16),
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final timestamp = data[isPending ? 'timestamp' : 'treatedAt'] as Timestamp?;
//               final dateTime = timestamp?.toDate();
//               final assignedDoctorId = data['assignedDoctorId'];
              
//               if (isPending) {
//                 _treatmentControllers.putIfAbsent(doc.id, () => TextEditingController());
//               }

//               return isPending
//                   ? _buildEditableCaseCard(data, dateTime, doc.id, assignedDoctorId)
//                   : _buildReadOnlyCaseCard(data, dateTime);
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEditableCaseCard(
//     Map<String, dynamic> data, 
//     DateTime? dateTime, 
//     String docId,
//     String assignedDoctorId,
//   ) {
//     final isUpdating = _isUpdating[docId] ?? false;

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime),
//             const SizedBox(height: 16),
//             _buildSymptomsSection(data),
//             const SizedBox(height: 16),
//             _buildSectionHeader('Treatment Plan'),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _treatmentControllers[docId],
//               maxLines: 3,
//               minLines: 1,
//               decoration: InputDecoration(
//                 labelText: 'Enter treatment details',
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.all(16),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildActionButtons(docId, isUpdating, assignedDoctorId),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReadOnlyCaseCard(Map<String, dynamic> data, DateTime? dateTime) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildPatientHeader(data, dateTime),
//             const SizedBox(height: 16),
//             _buildSymptomsSection(data),
//             const SizedBox(height: 16),
//             _buildSectionHeader('Treatment Provided'),
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: Text(
//                 data['treatment'] ?? 'No treatment details',
//                 style: TextStyle(fontSize: 15),
//               ),
//             ),
//             if (data['treatedAt'] != null) ...[
//               const SizedBox(height: 8),
//               Text(
//                 'Treated on: ${_formatDate((data['treatedAt'] as Timestamp).toDate())}',
//                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPatientHeader(Map<String, dynamic> data, DateTime? dateTime) {
//     return Row(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue.shade100,
//           child: Icon(Icons.person, color: Colors.blue.shade800),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 data['fullName'] ?? 'N/A',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 'Age: ${data['age'] ?? 'N/A'} • Week: ${data['week'] ?? 'N/A'}',
//                 style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//               ),
//             ],
//           ),
//         ),
//         if (dateTime != null)
//           Text(
//             _formatDate(dateTime),
//             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//           ),
//       ],
//     );
//   }

//   Widget _buildSymptomsSection(Map<String, dynamic> data) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionHeader('Symptoms:'),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             data['symptoms']?.toString() ?? 'No symptoms reported',
//             style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButtons(String docId, bool isUpdating, String assignedDoctorId) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         OutlinedButton(
//           style: OutlinedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             side: BorderSide(color: Theme.of(context).primaryColor),
//           ),
//           onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
//           child: Text(
//             'CLEAR',
//             style: TextStyle(color: Theme.of(context).primaryColor),
//           ),
//         ),
//         const SizedBox(width: 12),
//         ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           onPressed: isUpdating 
//               ? null 
//               : () => _updateSymptomStatus(
//                   docId,
//                   _treatmentControllers[docId]!.text.trim(),
//                   assignedDoctorId,
//                 ),
//           child: isUpdating
//               ? SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : Text('MARK AS TREATED'),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Theme.of(context).primaryColor,
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return DateFormat('dd/MM/yyyy HH:mm').format(date);
//   }
// }






// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};
//   final Map<String, bool> _isUpdating = {};

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentDoctor();
//   }

//   Future<void> _getCurrentDoctor() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentDoctorId = user.uid;
//       });
//     }
//   }

//   Stream<QuerySnapshot> get _assignedCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
    
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'pending')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId)
//       .snapshots();
//       hadii uuu statuska treated yahyne wxaan rabaa si table ah inaad usoo arqrisoo uunan dhaqtarka waxaba ka badali karin only read un
//   }

//   Future<void> _updateSymptomStatus(String docId, String treatment, String assignedDoctorId) async {
//     if (treatment.isEmpty) {
//       _showSnackBar('Please enter treatment details');
//       return;
//     }

//     setState(() {
//       _isUpdating[docId] = true;
//     });

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'treatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': assignedDoctorId,
//         'doctorName': _auth.currentUser?.displayName ?? 'Doctor',
//       });

//       _showSnackBar('Treatment saved successfully!');
//       _treatmentControllers[docId]?.clear();
//     } catch (e) {
//       _showSnackBar('Error saving treatment: ${e.toString()}');
//     } finally {
//       setState(() {
//         _isUpdating[docId] = false;
//       });
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).primaryColor.withOpacity(0.05),
//               Colors.white,
//             ],
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _assignedCasesStream,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.error_outline, size: 64, color: Colors.red),
//                     SizedBox(height: 16),
//                     Text(
//                       'Error loading symptoms',
//                       style: TextStyle(color: Colors.red, fontSize: 18),
//                     ),
//                     SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () => setState(() {}),
//                       child: Text('Retry'),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }

//             final documents = snapshot.data?.docs;
//             if (documents == null || documents.isEmpty) {
//               return const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No pending symptoms reports assigned to you',
//                       style: TextStyle(color: Colors.grey, fontSize: 18),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return RefreshIndicator(
//               onRefresh: () async => setState(() {}),
//               child: ListView.separated(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: documents.length,
//                 separatorBuilder: (_, __) => const SizedBox(height: 16),
//                 itemBuilder: (context, index) {
//                   final doc = documents[index];
//                   final data = doc.data() as Map<String, dynamic>;
//                   final timestamp = data['timestamp'] as Timestamp?;
//                   final dateTime = timestamp?.toDate();
//                   final assignedDoctorId = data['assignedDoctorId'];
                  
//                   _treatmentControllers.putIfAbsent(
//                     doc.id, 
//                     () => TextEditingController()
//                   );

//                   return _buildSymptomCard(data, dateTime, doc.id, assignedDoctorId);
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildSymptomCard(
//     Map<String, dynamic> data, 
//     DateTime? dateTime, 
//     String docId,
//     String assignedDoctorId,
//   ) {
//     final isUpdating = _isUpdating[docId] ?? false;

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Patient Header with assignment info
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.blue.shade100,
//                   child: Icon(Icons.person, color: Colors.blue.shade800),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         data['fullName'] ?? 'N/A',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         'Age: ${data['age'] ?? 'N/A'} • Week: ${data['week'] ?? 'N/A'}',
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (dateTime != null)
//                   Text(
//                     _formatDate(dateTime),
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 12,
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // Symptoms Section
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildSectionHeader('Symptoms:'),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     data['symptoms']?.toString() ?? 'No symptoms ',
//                     style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 16),
            
//             // Treatment Section
//             _buildSectionHeader('Treatment Plan'),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _treatmentControllers[docId],
//               maxLines: 3,
//               minLines: 1,
//               decoration: InputDecoration(
//                 labelText: 'Enter treatment details',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.all(16),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 OutlinedButton(
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     side: BorderSide(color: Theme.of(context).primaryColor),
//                   ),
//                   onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
//                   child: Text(
//                     'CLEAR',
//                     style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: isUpdating 
//                       ? null 
//                       : () => _updateSymptomStatus(
//                           docId,
//                           _treatmentControllers[docId]!.text.trim(),
//                           assignedDoctorId,
//                         ),
//                   child: isUpdating
//                       ? SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Text('MARK AS TREATED'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Theme.of(context).primaryColor,
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }






// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};
//   final Map<String, bool> _isUpdating = {};

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentDoctor();
//   }

//   Future<void> _getCurrentDoctor() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentDoctorId = user.uid;
//       });
//     }
//   }

//   Future<void> _updateSymptomStatus(String docId, String treatment) async {
//     if (treatment.isEmpty) {
//       _showSnackBar('Please enter treatment details');
//       return;
//     }

//     setState(() {
//       _isUpdating[docId] = true;
//     });

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'treatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': _currentDoctorId,
//         'doctorName': _auth.currentUser?.displayName ?? 'Doctor',
//       });

//       _showSnackBar('Treatment saved successfully!');
//       _treatmentControllers[docId]?.clear();
//     } catch (e) {
//       _showSnackBar('Error saving treatment: ${e.toString()}');
//     } finally {
//       setState(() {
//         _isUpdating[docId] = false;
//       });
//     }
//   }
// class _SymptomspatientTabState extends State<SymptomspatientTab> {
//   // ... existing code ...

//   Stream<QuerySnapshot> get _assignedCasesStream {
//     if (_currentDoctorId == null) return Stream.empty();
    
//     return _firestore.collection('symptoms')
//       .where('status', isEqualTo: 'pending')
//       .where('assignedDoctorId', isEqualTo: _currentDoctorId) // Only show cases assigned to this doctor
//       .snapshots();
//   }

//   Future<void> _updateSymptomStatus(String docId, String treatment, String assignedDoctorId) async {
//     // ... validation code ...
    
//     await _firestore.collection('symptoms').doc(docId).update({
//       'status': 'treated',
//       'treatment': treatment,
//       'treatedAt': FieldValue.serverTimestamp(),
//       'treatedBy': assignedDoctorId, // Use the originally assigned doctor
//       'doctorName': _auth.currentUser?.displayName ?? 'Doctor',
//     });

//     // ... rest of the code ...
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _assignedCasesStream, // Use the filtered stream
//           builder: (context, snapshot) {
//             // ... existing builder code ...
//             // When building cards, pass the assignedDoctorId:
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final data = doc.data() as Map<String, dynamic>;
//               return _buildSymptomCard(
//                 data,
//                 timestamp?.toDate(),
//                 doc.id,
//                 data['assignedDoctorId'], // Pass the assigned doctor ID
//               );
//             },
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildSymptomCard(
//     Map<String, dynamic> data, 
//     DateTime? dateTime, 
//     String docId,
//     String assignedDoctorId,
//   ) {
//     // ... existing card code ...
//     // Modify your update button to pass the assignedDoctorId:
//     ElevatedButton(
//       onPressed: () => _updateSymptomStatus(
//         docId,
//         _treatmentControllers[docId]!.text,
//         assignedDoctorId, // Pass the assigned doctor ID
//       ),
//       child: Text('MARK AS TREATED'),
//     ),
//     // ... rest of the card ...
//   }
// }
//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).primaryColor.withOpacity(0.05),
//               Colors.white,
//             ],
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore.collection('symptoms')
//             .where('status', isEqualTo: 'pending')
//             .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.error_outline, size: 64, color: Colors.red),
//                     SizedBox(height: 16),
//                     Text(
//                       'Error loading symptoms',
//                       style: TextStyle(color: Colors.red, fontSize: 18),
//                     ),
//                     SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () => setState(() {}),
//                       child: Text('Retry'),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }

//             final documents = snapshot.data?.docs;
//             if (documents == null || documents.isEmpty) {
//               return const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No pending symptoms reports',
//                       style: TextStyle(color: Colors.grey, fontSize: 18),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return RefreshIndicator(
//               onRefresh: () async => setState(() {}),
//               child: ListView.separated(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: documents.length,
//                 separatorBuilder: (_, __) => const SizedBox(height: 16),
//                 itemBuilder: (context, index) {
//                   final doc = documents[index];
//                   final data = doc.data() as Map<String, dynamic>;
//                   final timestamp = data['timestamp'] as Timestamp?;
//                   final dateTime = timestamp?.toDate();
                  
//                   _treatmentControllers.putIfAbsent(
//                     doc.id, 
//                     () => TextEditingController()
//                   );

//                   return _buildSymptomCard(data, dateTime, doc.id);
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildSymptomCard(Map<String, dynamic> data, DateTime? dateTime, String docId) {
//     final isUpdating = _isUpdating[docId] ?? false;

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Patient Header
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.blue.shade100,
//                   child: Icon(Icons.person, color: Colors.blue.shade800),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         data['fullName'] ?? 'N/A',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         'Age: ${data['age'] ?? 'N/A'} • Week: ${data['week'] ?? 'N/A'}',
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (dateTime != null)
//                   Text(
//                     _formatDate(dateTime),
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 12,
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildSectionHeader('Symptoms:'),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     data['symptoms']?.toString() ?? 'No symptoms reported',
//                     style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 16),
            
//             // Treatment Section
//             _buildSectionHeader('Treatment Plan'),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _treatmentControllers[docId],
//               maxLines: 3,
//               minLines: 1,
//               decoration: InputDecoration(
//                 labelText: 'Enter treatment details',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.all(16),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 OutlinedButton(
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     side: BorderSide(color: Theme.of(context).primaryColor),
//                   ),
//                   onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
//                   child: Text(
//                     'CLEAR',
//                     style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: isUpdating 
//                       ? null 
//                       : () => _updateSymptomStatus(
//                           docId,
//                           _treatmentControllers[docId]!.text.trim(),
//                         ),
//                   child: isUpdating
//                       ? SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Text('MARK AS TREATED'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Theme.of(context).primaryColor,
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};
//   final Map<String, bool> _isUpdating = {};

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentDoctor();
//   }

//   Future<void> _getCurrentDoctor() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentDoctorId = user.uid;
//       });
      
      
//     }
//   }
// uture<bool> _() async {
//   final doctor = _auth.currentdoctor;
//   if (doctor == null) return false;
  
//   final querySnapshot = await _firestore
//       .collection('trackingweeks')
//       .where('docId', isEqualTo: doc.uid)
//       .limit(1)
//       .get();
      
//   return querySnapshot.docs.isNotEmpty;
// }
  

//     setState(() {
//       _isUpdating[docId] = true;
//     });

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'treatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': _currentDoctorId,
//         'doctorName': _auth.currentUser?.displayName ?? 'Doctor',
//       });

//       _showSnackBar('Treatment saved successfully!');
//       _treatmentControllers[docId]?.clear();
//     } catch (e) {
//       _showSnackBar('Error saving treatment: ${e.toString()}');
//     } finally {
//       setState(() {
//         _isUpdating[docId] = false;
//       });
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).primaryColor.withOpacity(0.05),
//               Colors.white,
//             ],
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore.collection('symptoms')
//             .where('status', isEqualTo: 'pending')
//             // .orderBy('timestamp', descending: true)
//             .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.error_outline, size: 64, color: Colors.red),
//                     SizedBox(height: 16),
//                     Text(
//                       'Error loading symptoms',
//                       style: TextStyle(color: Colors.red, fontSize: 18),
//                     ),
//                     SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () => setState(() {}),
//                       child: Text('Retry'),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }

//             final documents = snapshot.data?.docs;
//             if (documents == null || documents.isEmpty) {
//               return const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No pending symptoms reports',
//                       style: TextStyle(color: Colors.grey, fontSize: 18),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return RefreshIndicator(
//               onRefresh: () async => setState(() {}),
//               child: ListView.separated(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: documents.length,
//                 separatorBuilder: (_, __) => const SizedBox(height: 16),
//                 itemBuilder: (context, index) {
//                   final doc = documents[index];
//                   final data = doc.data() as Map<String, dynamic>;
//                   final timestamp = data['timestamp'] as Timestamp?;
//                   final dateTime = timestamp?.toDate();
                  
//                   _treatmentControllers.putIfAbsent(
//                     doc.id, 
//                     () => TextEditingController()
//                   );

//                   return _buildSymptomCard(data, dateTime, doc.id);
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildSymptomCard(Map<String, dynamic> data, DateTime? dateTime, String docId) {
//     final isUpdating = _isUpdating[docId] ?? false;

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Patient Header
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.blue.shade100,
//                   child: Icon(Icons.person, color: Colors.blue.shade800),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         data['fullName'] ?? 'N/A',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         'Age: ${data['age'] ?? 'N/A'} • Week: ${data['week'] ?? 'N/A'}',
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (dateTime != null)
//                   Text(
//                     _formatDate(dateTime),
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 12,
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildSectionHeader('Symptoms:'),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     data['symptoms']?.toString() ?? 'No symptoms reported',
//                     style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 16),
            
//             // Treatment Section
//             _buildSectionHeader('Treatment Plan'),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _treatmentControllers[docId],
//               maxLines: 3,
//               minLines: 1,
//               decoration: InputDecoration(
//                 labelText: 'Enter treatment details',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.all(16),
//             ),
//             ),
//             const SizedBox(height: 16),
            
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 OutlinedButton(
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     side: BorderSide(color: Theme.of(context).primaryColor),
//                   ),
//                   onPressed: isUpdating ? null : () => _treatmentControllers[docId]?.clear(),
//                   child: Text(
//                     'CLEAR',
//                     style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: isUpdating 
//                       ? null 
//                       : () => _updateSymptomStatus(
//                           docId,
//                           _treatmentControllers[docId]!.text.trim(),
//                         ),
//                   child: isUpdating
//                       ? SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Text('MARK AS TREATED'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Theme.of(context).primaryColor,
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _currentDoctorId;
//   final Map<String, TextEditingController> _treatmentControllers = {};

//   @override
//   void initState() {
//     super.initState();
//     // Initialize with current doctor ID from your auth system
//     // _currentDoctorId = AuthService().currentUser?.uid;
//   }

//   Future<void> _updateSymptomStatus(String docId, String treatment) async {
//     if (treatment.isEmpty) {
//       _showSnackBar('Please enter treatment notes');
//       return;
//     }

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'treatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': _currentDoctorId ?? 'unknown',
//       });

//       _showSnackBar('Treatment saved successfully!');
//       _treatmentControllers[docId]?.clear();
//     } catch (e) {
//       _showSnackBar('Error saving treatment: ${e.toString()}');
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _treatmentControllers.forEach((_, controller) => controller.dispose());
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).primaryColor.withOpacity(0.05),
//               Colors.white,
//             ],
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore.collection('symptoms')
//             .where('status', isEqualTo: 'pending')
//             .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(
//                 child: Text('Error: ${snapshot.error}'),
//               );
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }

//             final documents = snapshot.data?.docs;
//             if (documents == null || documents.isEmpty) {
//               return const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No pending symptoms reports',
//                       style: TextStyle(color: Colors.grey, fontSize: 18),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.separated(
//               padding: const EdgeInsets.all(16),
//               itemCount: documents.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 16),
//               itemBuilder: (context, index) {
//                 final doc = documents[index];
//                 final data = doc.data() as Map<String, dynamic>;
//                 final timestamp = data['timestamp'] as Timestamp?;
//                 final dateTime = timestamp?.toDate();
                
//                 // Initialize controller for this document if not exists
//                 _treatmentControllers.putIfAbsent(
//                   doc.id, 
//                   () => TextEditingController()
//                 );

//                 return _buildSymptomCard(data, dateTime, doc.id);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildSymptomCard(Map<String, dynamic> data, DateTime? dateTime, String docId) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Patient Header
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.blue.shade100,
//                   child: Icon(Icons.person, color: Colors.blue.shade800),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         data['fullName'] ?? 'N/A',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         'Age: ${data['age'] ?? 'N/A'} • Week: ${data['week'] ?? 'N/A'}',
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (dateTime != null)
//                   Text(
//                     _formatDate(dateTime),
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 12,
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 16),

//     Row(
//   crossAxisAlignment: CrossAxisAlignment.start,
//   children: [
//     _buildSectionHeader('Symptoms:'),
//    const SizedBox(width: 10),
//     Text(
//       data['symptoms']?.toString() ?? 'No symptoms reported',
//       style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), // Made text bold
//     ),
//   ],
// ),
            
           
//             Container(
            
             
//             ),
//             const SizedBox(height: 16),
            
//             // Treatment Section
//             _buildSectionHeader('Treatment Plan'),
//             const SizedBox(height: 8),
//            TextField(
//   controller: _treatmentControllers[docId],
//   maxLines: 1,
//   minLines: 1,
//   decoration: InputDecoration(
//     labelText: 'Enter treatment details',
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(8),
//       borderSide: BorderSide(color: Colors.grey.shade300),
//     ),
//     filled: true,
//     fillColor: Colors.white,
//     contentPadding: const EdgeInsets.all(16),
//   ),
// ),
//             const SizedBox(height: 16),
            
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 OutlinedButton(
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     side: BorderSide(color: Theme.of(context).primaryColor),
//                   ),
//                   onPressed: () => _treatmentControllers[docId]?.clear(),
//                   child: Text(
//                     'CLEAR',
//                     style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: () => _updateSymptomStatus(
//                     docId,
//                     _treatmentControllers[docId]!.text.trim(),
//                   ),
//                   child: const Text('MARK AS TREATED'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Theme.of(context).primaryColor,
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _treatmentController = TextEditingController();
//   String? _currentDoctorId; // You should set this with your auth system

//   Future<void> _updateSymptomStatus(String docId, String treatment) async {
//     if (treatment.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter treatment notes')),
//       );
//       return;
//     }

//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'treatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': _currentDoctorId ?? 'unknown', // Handle null case
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Treatment saved successfully!')),
//       );
//       _treatmentController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error saving treatment: ${e.toString()}')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient Symptoms'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('symptoms')
//           .where('status', isEqualTo: 'pending')
//           // .orderBy('timestamp', descending: true) // Newest first
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error.toString()}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final documents = snapshot.data?.docs;
//           if (documents == null || documents.isEmpty) {
//             return const Center(child: Text('No pending symptoms reports'));
//           }

//           return ListView.builder(
//             itemCount: documents.length,
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final timestamp = data['timestamp'] as Timestamp?;
//               final dateTime = timestamp?.toDate();

//               return Card(
//                 margin: const EdgeInsets.all(8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Patient Information
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             data['fullName'] ?? 'N/A',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text('Age: ${data['age'] ?? 'N/A'}'),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text('Week: ${data['week'] ?? 'N/A'}'),
//                           if (dateTime != null)
//                             Text(_formatDate(dateTime)),
//                         ],
//                       ),
//                       const Divider(height: 20),
                      
//                       // Symptoms
//                       const Text(
//                         'Symptoms:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(data['symptoms']?.toString() ?? 'No symptoms reported'),
//                       const SizedBox(height: 16),
                      
//                       // Treatment Input
//                       TextField(
//                         controller: _treatmentController,
//                         decoration: const InputDecoration(
//                           labelText: 'Treatment Notes',
//                           border: OutlineInputBorder(),
//                           hintText: 'Enter treatment details...',
//                           contentPadding: EdgeInsets.all(12),
//                         ),
//                         maxLines: 3,
//                         minLines: 2,
//                       ),
//                       const SizedBox(height: 8),
                      
//                       // Save Button
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                           ),
//                           onPressed: () => _updateSymptomStatus(
//                             doc.id, 
//                             _treatmentController.text.trim(),
//                           ),
//                           child: const Text('SAVE TREATMENT'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }

//   @override
//   void dispose() {
//     _treatmentController.dispose();
//     super.dispose();
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class SymptomspatientTab extends StatefulWidget {
//   @override
//   _SymptomspatientTabState createState() => _SymptomspatientTabState();
// }

// class _SymptomspatientTabState extends State<SymptomspatientTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   TextEditingController _treatmentController = TextEditingController();

//   Future<void> _updateSymptomStatus(String docId, String treatment) async {
//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': 'treated',
//         'treatment': treatment,
//         'treatedAt': FieldValue.serverTimestamp(),
//         'treatedBy': 'currentDoctorId' // Replace with actual doctor ID
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Treatment saved successfully!')),
//       );
//       _treatmentController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error saving treatment: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Patient Symptoms'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('symptoms')
//           .where('status', isEqualTo: 'pending')
        
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No pending symptoms reports'));
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               var doc = snapshot.data!.docs[index];
//               var data = doc.data() as Map<String, dynamic>;

//               return Card(
//                 margin: EdgeInsets.all(8.0),
//                 child: Padding(
//                   padding: EdgeInsets.all(12.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Patient Information
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             '${data['fullName'] ?? 'N/A'}',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text('Age: ${data['age'] ?? 'N/A'}'),
//                         ],
//                       ),
//                       SizedBox(height: 8),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text('Week: ${data['week'] ?? 'N/A'}'),
//                           Text(
//                             '${data['timestamp'] != null ??'N/A'}',
                            
//                           ),
//                           Text(
//                             '${_formatDate(data['timestamp'].toDate()) !=null ??'N/A'}',
//                           ),
//                         ],
//                       ),
//                       Divider(height: 20),
                      
//                       // Symptoms
//                       Text(
//                         'Symptoms:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 4),
//                       Text(data['symptoms'] ?? 'No symptoms reported'),
//                       SizedBox(height: 16),
                      
//                       // Treatment Input
//                       TextField(
//                         controller: _treatmentController,
//                         decoration: InputDecoration(
//                           labelText: 'Treatment Notes',
//                           border: OutlineInputBorder(),
//                           hintText: 'Enter treatment details...',
//                         ),
//                         maxLines: 3,
//                       ),
//                       SizedBox(height: 8),
                      
//                       // Save Button
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             if (_treatmentController.text.isNotEmpty) {
//                               _updateSymptomStatus(doc.id, _treatmentController.text);
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(content: Text('Please enter treatment notes')),
//                               );
//                             }
//                           },
//                           child: Text('Save Treatment'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }

//   @override
//   void dispose() {
//     _treatmentController.dispose();
//     super.dispose();
//   }
// }










// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

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
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text('Chats', style: TextStyle(color: Colors.white)),
//         elevation: 0,
//       ),
//       body: FutureBuilder<QuerySnapshot>(
//         future: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'Patient')
//             .get(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No patients available', style: TextStyle(color: Colors.grey)),
//             );
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final userData = userDoc.data() as Map<String, dynamic>;
//               final userId = userDoc.id;

//               return FutureBuilder<Map<String, dynamic>>(
//                 future: _getChatInfo(userId, currentDoctorId, userData),
//                 builder: (context, chatInfoSnapshot) {
//                   if (chatInfoSnapshot.connectionState == ConnectionState.waiting) {
//                     return _buildLoadingTile(userData, 'Unknown');
//                   }

//                   final chatInfo = chatInfoSnapshot.data ?? {
//                     'referredBy': 'Unknown',
//                     'hasChat': false,
//                     'lastMessage': null,
//                     'messageTime': null,
//                     'unreadCount': 0,
//                     'isFromMe': false,
//                     'isRead': false,
//                   };

//                   final isFromMe = chatInfo['isFromMe'] ?? false;
//                   final isRead = chatInfo['isRead'] ?? false;

//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.blue[100],
//                       backgroundImage: userData['avatar'] != null 
//                           ? NetworkImage(userData['avatar'] as String) 
//                           : null,
//                       child: userData['avatar'] == null 
//                           ? Text(
//                               userData['fullName']?.isNotEmpty ?? false 
//                                   ? userData['fullName'][0].toUpperCase() 
//                                   : '?',
//                               style: TextStyle(color: Colors.blue[900]),
//                             )
//                           : null,
//                     ),
//                     title: Text(
//                       userData['fullName'] ?? 'Unknown Patient',
//                       style: TextStyle(
//                         fontWeight: chatInfo['unreadCount'] > 0 ? FontWeight.bold : FontWeight.w500,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Referred by: ${chatInfo['referredBy']}',
//                           style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                         ),
//                         Text(
//                           chatInfo['hasChat'] 
//                               ? '${isFromMe ? 'You: ' : ''}${chatInfo['lastMessage'] ?? 'No messages'}'
//                               : 'Start a conversation',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: chatInfo['unreadCount'] > 0 ? Colors.blue[900] : Colors.grey[600],
//                           ),
//                         ),
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
//                         : null,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => ChatScreen(
//                             fullName: userData['fullName'] ?? 'Patient',
//                             userId: userId,
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

//   Future<Map<String, dynamic>> _getChatInfo(
//     String userId, 
//     String currentDoctorId, 
//     Map<String, dynamic> userData
//   ) async {
//     try {
//       // Get referring doctor info
//       final referrerDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userData['referredBy'])
//           .get();
      
//       final referredBy = referrerDoc.exists 
//           ? (referrerDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Unknown Doctor'
//           : 'Unknown';

//       // Find chat between current doctor and patient
//       final chatQuery = await FirebaseFirestore.instance
//           .collection('chats')
//           .where('participants', arrayContains: currentDoctorId)
//           .get();

//       String? lastMessage;
//       String? messageTime;
//       bool hasChat = false;
//       int unreadCount = 0;
//       bool isFromMe = false;
//       bool isRead = false;

//       for (var chatDoc in chatQuery.docs) {
//         final participants = List<String>.from(chatDoc['participants'] ?? []);
//         if (participants.contains(userId)) {
//           hasChat = true;
          
//           // Get last message
//           final messagesSnapshot = await chatDoc.reference
//               .collection('messages')
//               .orderBy('timestamp', descending: true)
//               .limit(1)
//               .get();
          
//           if (messagesSnapshot.docs.isNotEmpty) {
//             final message = messagesSnapshot.docs.first.data();
//             lastMessage = message['text']?.toString();
//             messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//             isFromMe = message['senderId'] == currentDoctorId;
//             isRead = message['isRead'] ?? false;
//           }

//           // Get unread messages count
//           final unreadMessages = await chatDoc.reference
//               .collection('messages')
//               .where('receiverId', isEqualTo: currentDoctorId)
//               .where('isRead', isEqualTo: false)
//               .get();
          
//           unreadCount = unreadMessages.docs.length;
//           break;
//         }
//       }

//       return {
//         'referredBy': referredBy,
//         'hasChat': hasChat,
//         'lastMessage': lastMessage,
//         'messageTime': messageTime,
//         'unreadCount': unreadCount,
//         'isFromMe': isFromMe,
//         'isRead': isRead,
//       };
//     } catch (e) {
//       return {
//         'referredBy': 'Unknown',
//         'hasChat': false,
//         'lastMessage': null,
//         'messageTime': null,
//         'unreadCount': 0,
//         'isFromMe': false,
//         'isRead': false,
//       };
//     }
//   }

//   Widget _buildLoadingTile(Map<String, dynamic> userData, String referredBy) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.blue[100],
//         child: Text(
//           userData['fullName']?.isNotEmpty ?? false 
//               ? userData['fullName'][0].toUpperCase() 
//               : '?',
//           style: TextStyle(color: Colors.blue[900]),
//         ),
//       ),
//       title: Text(
//         userData['fullName'] ?? 'Unknown Patient',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           color: Colors.grey[800],
//         ),
//       ),
//       subtitle: Text(
//         'Referred by: $referredBy',
//         style: TextStyle(color: Colors.grey[600], fontSize: 12),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

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
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text('Chats', style: TextStyle(color: Colors.white)),
//         elevation: 0,
//       ),
//       body: FutureBuilder<QuerySnapshot>(
//         future: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'Patient')
//             .get(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No patients available', style: TextStyle(color: Colors.grey)),
//             );
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final userData = userDoc.data() as Map<String, dynamic>;
//               final userId = userDoc.id;

//               return FutureBuilder<Map<String, dynamic>>(
//                 future: _getChatInfo(userId, currentDoctorId, userData),
//                 builder: (context, chatInfoSnapshot) {
//                   if (chatInfoSnapshot.connectionState == ConnectionState.waiting) {
//                     return _buildLoadingTile(userData, 'Unknown');
//                   }

//                   final chatInfo = chatInfoSnapshot.data ?? {
//                     'referredBy': 'Unknown',
//                     'hasChat': false,
//                     'lastMessage': null,
//                     'messageTime': null,
//                     'unreadCount': 0,
//                   };

//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.blue[100],
//                       backgroundImage: userData['avatar'] != null 
//                           ? NetworkImage(userData['avatar'] as String) 
//                           : null,
//                       child: userData['avatar'] == null 
//                           ? Text(
//                               userData['fullName']?.isNotEmpty ?? false 
//                                   ? userData['fullName'][0].toUpperCase() 
//                                   : '?',
//                               style: TextStyle(color: Colors.blue[900]),
//                             )
//                           : null,
//                     ),
//                     title: Text(
//                       userData['fullName'] ?? 'Unknown Patient',
//                       style: TextStyle(
//                         fontWeight: chatInfo['unreadCount'] > 0 ? FontWeight.bold : FontWeight.w500,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Referred by: ${chatInfo['referredBy']}',
//                           style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                         ),
//                         Text(
//                           chatInfo['hasChat'] 
//                               ? (chatInfo['lastMessage'] ?? 'No messages')
//                               : 'Start a conversation',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: chatInfo['unreadCount'] > 0 ? Colors.blue[900] : Colors.grey[600],
//                           ),
//                         ),
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
//                               if (chatInfo['unreadCount'] > 0)
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
//                         : null,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => ChatScreen(
//                             fullName: userData['fullName'] ?? 'Patient',
//                             userId: userId,
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

//   Future<Map<String, dynamic>> _getChatInfo(
//     String userId, 
//     String currentDoctorId, 
//     Map<String, dynamic> userData
//   ) async {
//     try {
//       // Get referring doctor info
//       final referrerDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userData['referredBy'])
//           .get();
      
//       final referredBy = referrerDoc.exists 
//           ? (referrerDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Unknown Doctor'
//           : 'Unknown';

//       // Find chat between current doctor and patient
//       final chatQuery = await FirebaseFirestore.instance
//           .collection('chats')
//           .where('participants', arrayContains: currentDoctorId)
//           .get();

//       String? lastMessage;
//       String? messageTime;
//       bool hasChat = false;
//       int unreadCount = 0;

//       for (var chatDoc in chatQuery.docs) {
//         final participants = List<String>.from(chatDoc['participants'] ?? []);
//         if (participants.contains(userId)) {
//           hasChat = true;
          
//           // Get last message
//           final messagesSnapshot = await chatDoc.reference
//               .collection('messages')
//               .orderBy('timestamp', descending: true)
//               .limit(1)
//               .get();
          
//           if (messagesSnapshot.docs.isNotEmpty) {
//             final message = messagesSnapshot.docs.first.data();
//             lastMessage = message['text']?.toString();
//             messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//           }

//           // Get unread messages count
//           final unreadMessages = await chatDoc.reference
//               .collection('messages')
//               .where('receiverId', isEqualTo: currentDoctorId)
//               .where('isRead', isEqualTo: false)
//               .get();
          
//           unreadCount = unreadMessages.docs.length;
//           break;
//         }
//       }

//       return {
//         'referredBy': referredBy,
//         'hasChat': hasChat,
//         'lastMessage': lastMessage,
//         'messageTime': messageTime,
//         'unreadCount': unreadCount,
//       };
//     } catch (e) {
//       return {
//         'referredBy': 'Unknown',
//         'hasChat': false,
//         'lastMessage': null,
//         'messageTime': null,
//         'unreadCount': 0,
//       };
//     }
//   }

//   Widget _buildLoadingTile(Map<String, dynamic> userData, String referredBy) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.blue[100],
//         child: Text(
//           userData['fullName']?.isNotEmpty ?? false 
//               ? userData['fullName'][0].toUpperCase() 
//               : '?',
//           style: TextStyle(color: Colors.blue[900]),
//         ),
//       ),
//       title: Text(
//         userData['fullName'] ?? 'Unknown Patient',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           color: Colors.grey[800],
//         ),
//       ),
//       subtitle: Text(
//         'Referred by: $referredBy',
//         style: TextStyle(color: Colors.grey[600], fontSize: 12),
//       ),
//     );
//   }
// }

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text('Chats', style: TextStyle(color: Colors.white)),
//         elevation: 0,
//       ),
//       body: FutureBuilder<QuerySnapshot>(
//         future: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'Patient')
//             .get(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No patients available', style: TextStyle(color: Colors.grey)),
//             );
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final userId = userDoc.id;

//               return FutureBuilder<Map<String, dynamic>>(
//                 future: _getChatInfo(userId, currentDoctorId, user),
//                 builder: (context, chatInfoSnapshot) {
//                   if (chatInfoSnapshot.connectionState == ConnectionState.waiting) {
//                     return _buildLoadingTile(user, 'Unknown');
//                   }

//                   final chatInfo = chatInfoSnapshot.data ?? {
//                     'referredBy': 'Unknown',
//                     'hasChat': false,
//                     'lastMessage': null,
//                     'messageTime': null,
//                     'unreadCount': 0,
//                   };

//                   return _buildChatTile(context, user, chatInfo, userId);
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Future<Map<String, dynamic>> _getChatInfo(
//     String userId, 
//     String currentDoctorId, 
//     Map<String, dynamic> user
//   ) async {
//     try {
//       // Get referring doctor info
//       final referrerDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user['referredBy'])
//           .get();
      
//       final referredBy = referrerDoc.exists 
//           ? (referrerDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Unknown Doctor'
//           : 'Unknown';

//       // Find chat between current doctor and patient
//       final chatQuery = await FirebaseFirestore.instance
//           .collection('chats')
//           .where('participants', arrayContains: currentDoctorId)
//           .get();

//       String? lastMessage;
//       String? messageTime;
//       bool hasChat = false;
//       int unreadCount = 0;
//       String? chatId;

//       for (var chatDoc in chatQuery.docs) {
//         final participants = List<String>.from(chatDoc['participants'] ?? []);
//         if (participants.contains(userId)) {
//           hasChat = true;
//           chatId = chatDoc.id;
          
//           // Get last message
//           final messagesSnapshot = await chatDoc.reference
//               .collection('messages')
//               .orderBy('timestamp', descending: true)
//               .limit(1)
//               .get();
          
//           if (messagesSnapshot.docs.isNotEmpty) {
//             final message = messagesSnapshot.docs.first.data();
//             lastMessage = message['text']?.toString();
//             messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//           }

//           // Get unread messages count
//           final unreadMessages = await chatDoc.reference
//               .collection('messages')
//               .where('receiverId', isEqualTo: currentDoctorId)
//               .where('isRead', isEqualTo: false)
//               .get();
          
//           unreadCount = unreadMessages.docs.length;
//           break;
//         }
//       }

//       return {
//         'referredBy': referredBy,
//         'hasChat': hasChat,
//         'lastMessage': lastMessage,
//         'messageTime': messageTime,
//         'unreadCount': unreadCount,
//         'chatId': chatId,
//       };
//     } catch (e) {
//       return {
//         'referredBy': 'Unknown',
//         'hasChat': false,
//         'lastMessage': null,
//         'messageTime': null,
//         'unreadCount': 0,
//         'chatId': null,
//       };
//     }
//   }

//   Widget _buildLoadingTile(Map<String, dynamic> user, String referredBy) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.blue[100],
//         child: Text(
//           user['fullName']?.isNotEmpty ?? false 
//               ? user['fullName'][0].toUpperCase() 
//               : '?',
//           style: TextStyle(color: Colors.blue[900]),
//         ),
//       ),
//       title: Text(
//         user['fullName'] ?? 'Unknown Patient',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           color: Colors.grey[800],
//         ),
//       ),
//       subtitle: Text(
//         'Referred by: $referredBy',
//         style: TextStyle(color: Colors.grey[600], fontSize: 12),
//       ),
//     );
//   }

//   Widget _buildChatTile(
//     BuildContext context,
//     Map<String, dynamic> user, 
//     Map<String, dynamic> chatInfo, 
//     String userId
//   ) {
//     final hasUnreadMessages = chatInfo['unreadCount'] > 0;
    
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.blue[100],
//         backgroundImage: user['avatar'] != null 
//             ? NetworkImage(user['avatar'] as String) 
//             : null,
//         child: Stack(
//           children: [
//             if (user['avatar'] == null)
//               Text(
//                 user['fullName']?.isNotEmpty ?? false 
//                     ? user['fullName'][0].toUpperCase() 
//                     : '?',
//                 style: TextStyle(color: Colors.blue[900]),
//               ),
//             if (hasUnreadMessages)
//               Positioned(
//                 right: 0,
//                 bottom: 0,
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: Colors.red,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   constraints: const BoxConstraints(
//                     minWidth: 16,
//                     minHeight: 16,
//                   ),
//                   child: Text(
//                     chatInfo['unreadCount'].toString(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//       title: Text(
//         user['fullName'] ?? 'Unknown Patient',
//         style: TextStyle(
//           fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.w500,
//           color: hasUnreadMessages ? Colors.black : Colors.grey[800],
//         ),
//       ),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Referred by: ${chatInfo['referredBy']}',
//             style: TextStyle(color: Colors.grey[600], fontSize: 12),
//           ),
//           Text(
//             chatInfo['hasChat'] 
//                 ? (chatInfo['lastMessage'] ?? 'No messages')
//                 : 'Start a conversation',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: hasUnreadMessages ? Colors.blue[900] : Colors.grey[600],
//               fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//       trailing: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (chatInfo['messageTime'] != null)
//             Text(
//               chatInfo['messageTime']!,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: hasUnreadMessages ? Colors.blue[900] : Colors.grey,
//               ),
//             ),
//           if (hasUnreadMessages)
//             Container(
//               margin: const EdgeInsets.only(top: 4),
//               width: 10,
//               height: 10,
//               decoration: BoxDecoration(
//                 color: Colors.blue[900],
//                 shape: BoxShape.circle,
//               ),
//             ),
//         ],
//       ),
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ChatScreen(
//               userName: userData['fullName'] ?? 'Patient',
//               userId: wiget.userId,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }





// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text('Chats', style: TextStyle(color: Colors.white)),
//         elevation: 0,
//       ),
//       body: FutureBuilder<QuerySnapshot>(
//         future: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'Patient')
//             .get(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No patients available', style: TextStyle(color: Colors.grey)),
//             );
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final userId = userDoc.id;

//               return FutureBuilder<Map<String, dynamic>>(
//                 future: _getChatInfo(userId, currentDoctorId, user),
//                 builder: (context, chatInfoSnapshot) {
//                   if (chatInfoSnapshot.connectionState == ConnectionState.waiting) {
//                     return _buildLoadingTile(user, 'Unknown');
//                   }

//                   if (chatInfoSnapshot.hasError) {
//                     return _buildLoadingTile(user, 'Error loading chat');
//                   }

//                   final chatInfo = chatInfoSnapshot.data ?? {
//                     'referredBy': 'Unknown',
//                     'hasChat': false,
//                     'lastMessage': null,
//                     'messageTime': null,
//                   };

//                   return _buildChatTile(context, user, chatInfo, userId);
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Future<Map<String, dynamic>> _getChatInfo(
//     String userId, 
//     String currentDoctorId, 
//     Map<String, dynamic> user
//   ) async {
//     try {
//       // Get referring doctor info
//       final referrerDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user['referredBy'])
//           .get();
      
//       final referredBy = referrerDoc.exists 
//           ? (referrerDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Unknown Doctor'
//           : 'Unknown';

//       // Find chat between current doctor and patient
//       final chatQuery = await FirebaseFirestore.instance
//           .collection('chats')
//           .where('participants', arrayContains: currentDoctorId)
//           .get();

//       String? lastMessage;
//       String? messageTime;
//       bool hasChat = false;

//       for (var chatDoc in chatQuery.docs) {
//         final participants = List<String>.from(chatDoc['participants'] ?? []);
//         if (participants.contains(userId)) {
//           hasChat = true;
//           // Get last message
//           final messages = await chatDoc.reference
//               .collection('messages')
//               .orderBy('timestamp', descending: true)
//               .limit(1)
//               .get();
          
//           if (messages.docs.isNotEmpty) {
//             final message = messages.docs.first.data();
//             lastMessage = message['text']?.toString();
//             messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//           }
//           break;
//         }
//       }

//       return {
//         'referredBy': referredBy,
//         'hasChat': hasChat,
//         'lastMessage': lastMessage,
//         'messageTime': messageTime,
//       };
//     } catch (e) {
//       return {
//         'referredBy': 'Unknown',
//         'hasChat': false,
//         'lastMessage': null,
//         'messageTime': null,
//       };
//     }
//   }

//   Widget _buildLoadingTile(Map<String, dynamic> user, String referredBy) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.blue[100],
//         child: Text(
//           user['fullName']?.isNotEmpty ?? false 
//               ? user['fullName'][0].toUpperCase() 
//               : '?',
//           style: TextStyle(color: Colors.blue[900]),
//         ),
//       ),
//       title: Text(
//         user['fullName'] ?? 'Unknown Patient',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           color: Colors.grey[800],
//         ),
//       ),
//       subtitle: Text(
//         'Referred by: $referredBy',
//         style: TextStyle(color: Colors.grey[600], fontSize: 12),
//       ),
//     );
//   }

//   Widget _buildChatTile(
//     BuildContext context,
//     Map<String, dynamic> user, 
//     Map<String, dynamic> chatInfo, 
//     String userId
//   ) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.blue[100],
//         backgroundImage: user['avatar'] != null 
//             ? NetworkImage(user['avatar'] as String) 
//             : null,
//         child: user['avatar'] == null 
//             ? Text(
//                 user['fullName']?.isNotEmpty ?? false 
//                     ? user['fullName'][0].toUpperCase() 
//                     : '?',
//                 style: TextStyle(color: Colors.blue[900]),
//               )
//             : null,
//       ),
//       title: Text(
//         user['fullName'] ?? 'Unknown Patient',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           color: Colors.grey[800],
//         ),
//       ),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Referred by: ${chatInfo['referredBy']}',
//             style: TextStyle(color: Colors.grey[600], fontSize: 12),
//           ),
//           Text(
//             chatInfo['hasChat'] 
//                 ? (chatInfo['lastMessage'] ?? 'No messages')
//                 : 'Start a conversation',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(color: Colors.grey[600]),
//           ),
//         ],
//       ),
//       trailing: chatInfo['hasChat'] && chatInfo['messageTime'] != null
//           ? Text(
//               chatInfo['messageTime']!,
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             )
//           : null,
//       // onTap: () {
//       //   Navigator.push(
//       //     context,
//       //     MaterialPageRoute(
//       //       builder: (_) => ChatScreen(
//       //         fullName: user['fullName'] ?? 'Patient',
//       //         userId: userId,
//       //       ),
//       //     ),
//       //   );
//       // },
//     );
//   }
// }


// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   // ... (keep your existing _formatTimestamp method)

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text('Chats', style: TextStyle(color: Colors.white)),
//         elevation: 0,
//       ),
//       body: FutureBuilder<QuerySnapshot>(
//         future: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'Patient')
//             .get(),
//         builder: (context, usersSnapshot) {
//           // ... (keep your existing loading and empty state handling)

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final userId = userDoc.id;

//               return FutureBuilder(
//                 future: _getChatInfo(userId, currentDoctorId, user),
//                 builder: (context, chatInfoSnapshot) {
//                   if (chatInfoSnapshot.connectionState == ConnectionState.waiting) {
//                     return _buildLoadingTile(user, 'Unknown');
//                   }

//                   final chatInfo = chatInfoSnapshot.data as Map<String, dynamic>;
//                   return _buildChatTile(user, chatInfo, userId);
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Future<Map<String, dynamic>> _getChatInfo(String userId, String currentDoctorId, Map<String, dynamic> user) async {
//     // Get referring doctor info
//     final referrerDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user['referredBy'])
//         .get();
    
//     final referredBy = referrerDoc.exists 
//         ? (referrerDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Unknown Doctor'
//         : 'Unknown';

//     // Find chat between current doctor and patient
//     final chatQuery = await FirebaseFirestore.instance
//         .collection('chats')
//         .where('participants', arrayContains: currentDoctorId)
//         .get();

//     String? lastMessage;
//     String? messageTime;
//     bool hasChat = false;

//     for (var chatDoc in chatQuery.docs) {
//       final participants = List<String>.from(chatDoc['participants'] ?? []);
//       if (participants.contains(userId)) {
//         hasChat = true;
//         // Get last message
//         final messages = await chatDoc.reference
//             .collection('messages')
//             .orderBy('timestamp', descending: true)
//             .limit(1)
//             .get();
        
//         if (messages.docs.isNotEmpty) {
//           final message = messages.docs.first.data();
//           lastMessage = message['text']?.toString();
//           messageTime = _formatTimestamp(message['timestamp'] as Timestamp);
//         }
//         break;
//       }
//     }

//     return {
//       'referredBy': referredBy,
//       'hasChat': hasChat,
//       'lastMessage': lastMessage,
//       'messageTime': messageTime,
//     };
//   }

//   Widget _buildLoadingTile(Map<String, dynamic> user, String referredBy) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.blue[100],
//         child: Text(
//           user['fullName']?.isNotEmpty ?? false 
//               ? user['fullName'][0].toUpperCase() 
//               : '?',
//           style: TextStyle(color: Colors.blue[900]),
//         ),
//       ),
//       title: Text(
//         user['fullName'] ?? 'Unknown Patient',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           color: Colors.grey[800],
//         ),
//       ),
//       subtitle: Text(
//         'Referred by: $referredBy',
//         style: TextStyle(color: Colors.grey[600], fontSize: 12),
//       ),
//     );
//   }

//   Widget _buildChatTile(Map<String, dynamic> user, Map<String, dynamic> chatInfo, String userId) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.blue[100],
//         backgroundImage: user['avatar'] != null 
//             ? NetworkImage(user['avatar'] as String) 
//             : null,
//         child: user['avatar'] == null 
//             ? Text(
//                 user['fullName']?.isNotEmpty ?? false 
//                     ? user['fullName'][0].toUpperCase() 
//                     : '?',
//                 style: TextStyle(color: Colors.blue[900]),
//               )
//             : null,
//       ),
//       title: Text(
//         user['fullName'] ?? 'Unknown Patient',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           color: Colors.grey[800],
//         ),
//       ),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Referred by: ${chatInfo['referredBy']}',
//             style: TextStyle(color: Colors.grey[600], fontSize: 12),
//           ),
//           Text(
//             chatInfo['hasChat'] 
//                 ? (chatInfo['lastMessage'] ?? 'No messages')
//                 : 'Start a conversation',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(color: Colors.grey[600]),
//           ),
//         ],
//       ),
//       trailing: chatInfo['hasChat'] && chatInfo['messageTime'] != null
//           ? Text(
//               chatInfo['messageTime']!,
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             )
//           : null,
//       // onTap: () {
//       //   Navigator.push(
//       //     context,
//       //     MaterialPageRoute(
//       //       builder: (_) => ChatScreen(
//       //         fullName: user['fullName'] ?? 'Patient',
//       //         userId: userId,
//       //       ),
//       //     ),
//       //   );
//       // },
//     );
//   }
// }

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//         elevation: 0,
//       ),
//       body: FutureBuilder<QuerySnapshot>(
//         future: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'Patient')
//             .get(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No patients available', style: TextStyle(color: Colors.grey)),
//             );
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final userId = userDoc.id;

//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(user['referredBy'])
//                     .get(),
//                 builder: (context, referrerSnapshot) {
//                   String referredBy = 'Unknown';
//                   if (referrerSnapshot.hasData && referrerSnapshot.data!.exists) {
//                     final referrer = referrerSnapshot.data!.data() as Map<String, dynamic>;
//                     referredBy = referrer['fullName'] ?? 'Unknown Doctor';
//                   }

//                   // Check if chat exists between current doctor and this patient
//                   return FutureBuilder<QuerySnapshot>(
//                     future: FirebaseFirestore.instance
//                         .collection('messages')
//                         .where('participants', arrayContains: userId)
//                         .where('participants', arrayContains: currentDoctorId)
//                         .limit(1)
//                         .get(),
//                     builder: (context, chatSnapshot) {
//                       if (chatSnapshot.connectionState == ConnectionState.waiting) {
//                         return ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.blue[100],
//                             child: Text(
//                               user['fullName']?.isNotEmpty ?? false 
//                                   ? user['fullName'][0].toUpperCase() 
//                                   : '?',
//                               style: TextStyle(color: Colors.blue[900]),
//                             ),
//                           ),
//                           title: Text(
//                             user['fullName'] ?? 'Unknown Patient',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                           subtitle: Text(
//                             'Referred by: $referredBy',
//                             style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                           ),
//                         );
//                       }

//                       // Get the last message if chat exists
//                       return FutureBuilder<QuerySnapshot>(
//                         future: chatSnapshot.hasData && chatSnapshot.data!.docs.isNotEmpty
//                             ? FirebaseFirestore.instance
//                                 .collection('messages')
//                                 .doc(chatSnapshot.data!.docs.first.id)
//                                 .collection('messages')
//                                 .orderBy('timestamp', descending: true)
//                                 .limit(1)
//                                 .get()
//                             : null,
//                         builder: (context, messageSnapshot) {
//                           if (messageSnapshot.connectionState == ConnectionState.waiting) {
//                             return ListTile(
//                               leading: CircleAvatar(
//                                 backgroundColor: Colors.blue[100],
//                                 child: Text(
//                                   user['fullName']?.isNotEmpty ?? false 
//                                       ? user['fullName'][0].toUpperCase() 
//                                       : '?',
//                                   style: TextStyle(color: Colors.blue[900]),
//                                 ),
//                               ),
//                               title: Text(
//                                 user['fullName'] ?? 'Unknown Patient',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.grey[800],
//                                 ),
//                               ),
//                               subtitle: Text(
//                                 'Referred by: $referredBy',
//                                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                               ),
//                             );
//                           }

//                           final hasMessages = messageSnapshot.hasData && 
//                                           messageSnapshot.data!.docs.isNotEmpty;
//                           final lastMessage = hasMessages
//                               ? messageSnapshot.data!.docs.first.data() as Map<String, dynamic>
//                               : null;

//                           return ListTile(
//                             leading: CircleAvatar(
//                               backgroundColor: Colors.blue[100],
//                               backgroundImage: user['avatar'] != null 
//                                   ? NetworkImage(user['avatar'] as String) 
//                                   : null,
//                               child: user['avatar'] == null 
//                                   ? Text(
//                                       user['fullName']?.isNotEmpty ?? false 
//                                           ? user['fullName'][0].toUpperCase() 
//                                           : '?',
//                                       style: TextStyle(color: Colors.blue[900]),
//                                     )
//                                   : null,
//                             ),
//                             title: Text(
//                               user['fullName'] ?? 'Unknown Patient',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey[800],
//                               ),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Referred by: $referredBy',
//                                   style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                                 ),
//                                 if (hasMessages)
//                                   Text(
//                                     lastMessage!['senderId'] == currentDoctorId
//                                         ? 'You: ${lastMessage['text']}'
//                                         : '${user['fullName']?.split(' ')[0] ?? 'Patient'}: ${lastMessage['text']}',
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: TextStyle(
//                                       color: Colors.grey[600],
//                                     ),
//                                   )
//                                 else
//                                   const Text(
//                                     'Start a conversation',
//                                     style: TextStyle(color: Colors.grey),
//                                   ),
//                               ],
//                             ),
//                             trailing: hasMessages
//                                 ? Text(
//                                     _formatTimestamp(lastMessage!['timestamp'] as Timestamp),
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey,
//                                     ),
//                                   )
//                                 : null,
//                             // onTap: () {
//                             //   Navigator.push(
//                             //     context,
//                             //     MaterialPageRoute(
//                             //       builder: (_) => ChatScreen(
//                             //         fullName: user['fullName'] ?? 'Patient',
//                             //         userId: userId,
//                             //       ),
//                             //     ),
//                             //   );
//                             // },
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


// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//         elevation: 0,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'Patient')  // Only show patients
//             .get(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No patients available', style: TextStyle(color: Colors.grey)),
//             );
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final chatDocId = '${userDoc.id}_$currentDoctorId';

//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(user['referredBy'])  // Get the referring doctor
//                     .get(),
//                 builder: (context, referrerSnapshot) {
//                   String referredBy = 'Unknown';
//                   if (referrerSnapshot.hasData && referrerSnapshot.data!.exists) {
//                     final referrer = referrerSnapshot.data!.data() as Map<String, dynamic>;
//                     referredBy = referrer['fullName'] ?? 'Unknown Doctor';
//                   }

//                   return StreamBuilder<DocumentSnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDocId)
//                         .snapshots(),
//                     builder: (context, chatSnapshot) {
//                       // Only show if chat exists and has messages
//                       if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
//                         return const SizedBox();
//                       }

//                       return StreamBuilder<QuerySnapshot>(
//                         stream: FirebaseFirestore.instance
//                             .collection('chats')
//                             .doc(chatDocId)
//                             .collection('messages')
//                             .orderBy('timestamp', descending: true)
//                             .limit(1)
//                             .snapshots(),
//                         builder: (context, messageSnapshot) {
//                           if (messageSnapshot.connectionState == ConnectionState.waiting) {
//                             return const ListTile(
//                               title: Text('Loading...', style: TextStyle(color: Colors.grey)),
//                             );
//                           }

//                           if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
//                             return ListTile(
//                               leading: CircleAvatar(
//                                 backgroundColor: Colors.blue[100],
//                                 child: Text(
//                                   user['fullName']?.isNotEmpty ?? false 
//                                       ? user['fullName'][0].toUpperCase() 
//                                       : '?',
//                                   style: TextStyle(color: Colors.blue[900]),
//                                 ),
//                               ),
//                               title: Text(
//                                 user['fullName'] ?? 'Unknown Patient',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.grey[800],
//                                 ),
//                               ),
//                               subtitle: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Referred by: $referredBy',
//                                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                                   ),
//                                   const Text(
//                                     'Start a conversation',
//                                     style: TextStyle(color: Colors.grey),
//                                   ),
//                                 ],
//                               ),
//                               onTap: () {
//                                 // Navigate to chat screen to start new conversation
//                               },
//                             );
//                           }

//                           final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                           final lastMessage = message['text']?.toString() ?? 'No message';
//                           final messageTime = message['timestamp'] != null 
//                               ? _formatTimestamp(message['timestamp'] as Timestamp) 
//                               : '';
//                           final isOtherUserMessage = message['senderId'] != currentDoctorId;
//                           final isUnread = !(message['isRead'] ?? false) && 
//                                        message['receiverId'] == currentDoctorId;

//                           return ListTile(
//                             leading: CircleAvatar(
//                               backgroundColor: Colors.blue[100],
//                               backgroundImage: user['avatar'] != null 
//                                   ? NetworkImage(user['avatar'] as String) 
//                                   : null,
//                               child: user['avatar'] == null 
//                                   ? Text(
//                                       user['fullName']?.isNotEmpty ?? false 
//                                           ? user['fullName'][0].toUpperCase() 
//                                           : '?',
//                                       style: TextStyle(color: Colors.blue[900]),
//                                     )
//                                   : null,
//                             ),
//                             title: Text(
//                               user['fullName'] ?? 'Unknown Patient',
//                               style: TextStyle(
//                                 fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
//                                 color: isUnread ? Colors.black : Colors.grey[800],
//                               ),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Referred by: $referredBy',
//                                   style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                                 ),
//                                 Text(
//                                   isOtherUserMessage
//                                       ? '${user['fullName']?.split(' ')[0] ?? 'Patient'}: $lastMessage'
//                                       : 'You: $lastMessage',
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: TextStyle(
//                                     fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
//                                     color: isUnread ? Colors.blue[900] : Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             trailing: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   messageTime,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: isUnread ? Colors.blue[900] : Colors.grey,
//                                   ),
//                                 ),
//                                 if (isUnread)
//                                   Container(
//                                     margin: const EdgeInsets.only(top: 4),
//                                     width: 10,
//                                     height: 10,
//                                     decoration: BoxDecoration(
//                                       color: Colors.blue[900],
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                               ],
//                             ),
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => ChatScreen(
//                                     fullName: user['fullName'] ?? 'Patient',
//                                     userId: userDoc.id,
//                                     chatId: chatDocId,//remove kan
//                                   ),
//                                 ),
//                               );
//                             },
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//         elevation: 0,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('users').snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No users available', style: TextStyle(color: Colors.grey)),
//             );
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final chatDocId = '${userDoc.id}_$currentDoctorId';

//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatDocId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Only show if chat exists and has messages
//                   if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
//                     return const SizedBox();
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDocId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       if (messageSnapshot.connectionState == ConnectionState.waiting) {
//                         return const ListTile(
//                           title: Text('Loading...', style: TextStyle(color: Colors.grey)),
//                         );
//                       }

//                       if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
//                         return ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.blue[100],
//                             child: Text(
//                               user['fullName']?.isNotEmpty ?? false 
//                                   ? user['fullName'][0].toUpperCase() 
//                                   : '?',
//                               style: TextStyle(color: Colors.blue[900]),
//                             ),
//                           ),
//                           title: Text(
//                             user['fullName'] ?? 'Unknown User',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                           subtitle: const Text(
//                             'Start a conversation',
//                             style: TextStyle(color: Colors.grey)),
//                           onTap: () {
//                             // Navigate to chat screen to start new conversation
//                           },
//                         );
//                       }

//                       final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                       final lastMessage = message['text']?.toString() ?? 'No message';
//                       final messageTime = message['timestamp'] != null 
//                           ? _formatTimestamp(message['timestamp'] as Timestamp) 
//                           : '';
//                       final isOtherUserMessage = message['senderId'] != currentDoctorId;
//                       final isUnread = !(message['isRead'] ?? false) && 
//                                    message['receiverId'] == currentDoctorId;

//                       return ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: Colors.blue[100],
//                           backgroundImage: user['avatar'] != null 
//                               ? NetworkImage(user['avatar'] as String) 
//                               : null,
//                           child: user['avatar'] == null 
//                               ? Text(
//                                   user['fullName']?.isNotEmpty ?? false 
//                                       ? user['fullName'][0].toUpperCase() 
//                                       : '?',
//                                   style: TextStyle(color: Colors.blue[900]),
//                                 )
//                               : null,
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'Unknown User',
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
//                             color: isUnread ? Colors.black : Colors.grey[800],
//                           ),
//                         ),
//                         subtitle: Text(
//                           isOtherUserMessage
//                               ? '${user['fullName']?.split(' ')[0] ?? 'Patient'}: $lastMessage'
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
//                             color: isUnread ? Colors.blue[900] : Colors.grey[600],
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: isUnread ? Colors.blue[900] : Colors.grey,
//                               ),
//                             ),
//                             if (isUnread)
//                               Container(
//                                 margin: const EdgeInsets.only(top: 4),
//                                 width: 10,
//                                 height: 10,
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[900],
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         // onTap: () {
//                         //   Navigator.push(
//                         //     context,
//                         //     MaterialPageRoute(
//                         //       builder: (_) => ChatScreen(
//                         //         fullName: user['fullName'] ?? 'User',
//                         //         userId: userDoc.id,
//                         //         chatId: chatDocId,
//                         //       ),
//                         //     ),
//                         //   );
//                         // },
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

// class ChatScreen extends StatelessWidget {
//   final String fullName;
//   final String userId;
//   final String chatId;

//   const ChatScreen({
//     super.key,
//     required this.fullName,
//     required this.userId,
//     required this.chatId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(fullName),
//       ),
//       body: Center(
//         child: Text('Chat with $fullName'),
//       ),
//     );
//   }
//}



// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//         elevation: 0,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('users').snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No users available', style: TextStyle(color: Colors.grey)),
//             );
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final chatDocId = '${userDoc.id}_$currentDoctorId';

//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatDocId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Only show if chat exists and has messages
//                   if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
//                     return const SizedBox();
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDocId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       if (messageSnapshot.connectionState == ConnectionState.waiting) {
//                         return const ListTile(
//                           title: Text('Loading...', style: TextStyle(color: Colors.grey)),
//                         );
//                       }

//                       if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
//                         return ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.blue[100],
//                             child: Text(
//                               user['fullName']?.isNotEmpty ?? false 
//                                   ? user['fullName'][0].toUpperCase() 
//                                   : '?',
//                               style: TextStyle(color: Colors.blue[900]),
//                             ),
//                           ),
//                           title: Text(
//                             user['fullName'] ?? 'Unknown User',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                           subtitle: const Text(
//                             'Start a conversation',
//                             style: TextStyle(color: Colors.grey)),
//                           ),
//                           onTap: () {
//                             // Navigate to chat screen to start new conversation
//                           },
//                         );
//                       }

//                       final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                       final lastMessage = message['text']?.toString() ?? 'No message';
//                       final messageTime = message['timestamp'] != null 
//                           ? _formatTimestamp(message['timestamp']) 
//                           : '';
//                       final isOtherUserMessage = message['senderId'] != currentDoctorId;
//                       final isUnread = !(message['isRead'] ?? false) && 
//                                    message['receiverId'] == currentDoctorId;

//                       return ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: Colors.blue[100],
//                           backgroundImage: user['avatar'] != null 
//                               ? NetworkImage(user['avatar']) 
//                               : null,
//                           child: user['avatar'] == null 
//                               ? Text(
//                                   user['fullName']?.isNotEmpty ?? false 
//                                       ? user['fullName'][0].toUpperCase() 
//                                       : '?',
//                                   style: TextStyle(color: Colors.blue[900]),
//                                 )
//                               : null,
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'Unknown User',
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
//                             color: isUnread ? Colors.black : Colors.grey[800],
//                           ),
//                         ),
//                         subtitle: Text(
//                           isOtherUserMessage
//                               ? '${user['fullName']?.split(' ')[0] ?? 'Patient'}: $lastMessage'
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
//                             color: isUnread ? Colors.blue[900] : Colors.grey[600],
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: isUnread ? Colors.blue[900] : Colors.grey,
//                               ),
//                             ),
//                             if (isUnread)
//                               Container(
//                                 margin: const EdgeInsets.only(top: 4),
//                                 width: 10,
//                                 height: 10,
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[900],
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 fullName: user['fullName'] ?? 'User',
//                                 userId: userDoc.id,
//                                 chatId: chatDocId,
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
//     };
//   };
  
// };

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('users').snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No users available'));
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final chatDocId = '${userDoc.id}_$currentDoctorId';

//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatDocId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Only show if chat exists and has messages
//                   if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
//                     return const SizedBox();
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDocId)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       if (messageSnapshot.connectionState == ConnectionState.waiting) {
//                         return const ListTile(
//                           title: Text('Loading messages...'),
//                         );
//                       }

//                       if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
//                         return ListTile(
//                           leading: CircleAvatar(
//                             child: Text(user['fullName']?[0] ?? 'U'),
//                           ),
//                           title: Text(user['fullName'] ?? 'User'),
//                           subtitle: const Text('Start a new conversation'),
//                           onTap: () {
//                             // Navigate to chat screen to start new conversation
//                           },
//                         );
//                       }

//                       final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                       final lastMessage = message['text'] ?? 'No message';
//                       final messageTime = message['timestamp'] != null 
//                           ? _formatTimestamp(message['timestamp']) 
//                           : '';
//                       final isOtherUserMessage = message['senderId'] != currentDoctorId;
//                       final isUnread = !(message['isRead'] ?? false) && 
//                                    message['receiverId'] == currentDoctorId;

//                       return ListTile(
//                         leading: CircleAvatar(
//                           backgroundImage: user['avatar'] != null 
//                               ? NetworkImage(user['avatar']) 
//                               : null,
//                           child: user['avatar'] == null 
//                               ? Text(user['fullName']?[0] ?? 'U') 
//                               : null,
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'User',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: isUnread ? Colors.black : Colors.grey[700],
//                           ),
//                         ),
//                         subtitle: Text(
//                           isOtherUserMessage 
//                               ? '${user['fullName']}: $lastMessage' 
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(messageTime),
//                             if (isUnread)
//                               Container(
//                                 width: 10,
//                                 height: 10,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ChatScreen(
//                                 fullName: user['fullName'] ?? 'User',
//                                 userId: userDoc.id,
//                                 chatId: chatDocId,
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
//             .collection('chats')
//             .where(Filter.or(
//               Filter('participants', arrayContains: currentUserId),
//               Filter('participants', arrayContains: currentUserId),
//             ))
//             .snapshots(),
//         builder: (context, chatsSnapshot) {
//           if (chatsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!chatsSnapshot.hasData || chatsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No chats available'));
//           }

//           final chatDocs = chatsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: chatDocs.length,
//             itemBuilder: (context, index) {
//               final chatDoc = chatDocs[index];
//               final participants = List<String>.from(chatDoc['participants'] ?? []);
//               final otherUserId = participants.firstWhere(
//                 (id) => id != currentUserId,
//                 orElse: () => '',
//               );

//               if (otherUserId.isEmpty) {
//                 return const SizedBox();
//               }

//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
//                 builder: (context, userSnapshot) {
//                   if (!userSnapshot.hasData) {
//                     return const ListTile(title: Text('Loading...'));
//                   }

//                   final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDoc.id)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = 'No messages yet';
//                       String messageTime = '';
//                       bool isOtherUserMessage = false;
//                       bool isUnread = false;

//                       if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp']);
//                         }
//                         isOtherUserMessage = message['senderId'] != currentUserId;
//                         isUnread = !(message['isRead'] ?? false) && message['receiverId'] == currentUserId;
//                       }

//                       Widget avatarWidget;
//                       if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(userData['avatar']),
//                         );
//                       } else {
//                         final initials = userData['fullName']?.isNotEmpty == true 
//                             ? userData['fullName'][0].toUpperCase() 
//                             : 'U';
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
//                             if (isUnread)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: const BoxDecoration(
//                                     color: Colors.red,
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           userData['fullName'] ?? 'User',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: isUnread ? Colors.black : Colors.grey[700],
//                           ),
//                         ),
//                         subtitle: Text(
//                           isOtherUserMessage 
//                               ? '${userData['fullName']}: $lastMessage' 
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: isUnread ? Colors.blue[900] : Colors.grey[600],
//                                 fontSize: 12,
//                                 fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                               ),
//                             ),
//                             if (isUnread)
//                               Container(
//                                 margin: const EdgeInsets.only(top: 4),
//                                 width: 8,
//                                 height: 8,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         // onTap: () {
//                         //   Navigator.push(
//                         //     context,
//                         //     MaterialPageRoute(
//                         //       builder: (_) => ChatScreen(
//                         //         fullName: userData['fullName'] ?? 'User',
//                         //         userId: otherUserId,
//                         //         chatId: chatDoc.id,
//                         //       ),
//                         //     ),
//                         //   );
//                         // },
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('users').snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No users available'));
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           // Filter users to only those who have chats with current doctor
//           return FutureBuilder<List<DocumentSnapshot>>(
//             future: _getUsersWithChats(userDocs, currentDoctorId),
//             builder: (context, asyncSnapshot) {
//               if (asyncSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final usersWithChats = asyncSnapshot.data ?? [];

//               if (usersWithChats.isEmpty) {
//                 return const Center(child: Text('No chats available'));
//               }

//               return ListView.builder(
//                 itemCount: usersWithChats.length,
//                 itemBuilder: (context, index) {
//                   final userDoc = usersWithChats[index];
//                   final user = userDoc.data() as Map<String, dynamic>;
//                   final chatDocId = '${userDoc.id}_$currentDoctorId';

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDocId)
//                         .collection('messages')
//                         // .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = 'No messages yet';
//                       String messageTime = '';
//                       bool isOtherUserMessage = false;
//                       bool isUnread = false;

//                       if (messageSnapshot.hasData &&
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data()
//                             as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp']);
//                         }
//                         isOtherUserMessage = message['senderId'] != currentDoctorId;
//                         isUnread = !(message['isRead'] ?? false) && 
//                                   message['receiverId'] == currentDoctorId;
//                       }

//                       Widget avatarWidget;
//                       if (user['avatar'] != null &&
//                           user['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(user['avatar']),
//                         );
//                       } else {
//                         final String initials = user['fullName']?.isNotEmpty == true
//                             ? user['fullName'][0].toUpperCase()
//                             : 'U';

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
//                             if (isUnread)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: const BoxDecoration(
//                                     color: Colors.red,
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'User',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: isUnread ? Colors.black : Colors.grey[700],
//                           ),
//                         ),
//                         subtitle: Text(
//                           isOtherUserMessage 
//                               ? '${user['fullName']}: $lastMessage'
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: isUnread ? Colors.blue[900] : Colors.grey[600],
//                                 fontSize: 12,
//                                 fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                               ),
//                             ),
//                             if (isUnread)
//                               Container(
//                                 margin: const EdgeInsets.only(top: 4),
//                                 width: 8,
//                                 height: 8,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         // onTap: () {
//                         //   Navigator.push(
//                         //     context,
//                         //     MaterialPageRoute(
//                         //       builder: (_) => ChatScreen(
//                         //         fullName: user['fullName'] ?? 'User',
//                         //         userId: userDoc.id,
//                         //         chatId: chatDocId,
//                         //       ),
//                         //     ),
//                         //   );
//                         // },
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

//   Future<List<DocumentSnapshot>> _getUsersWithChats(
//       List<DocumentSnapshot> userDocs, String currentDoctorId) async {
//     final usersWithChats = <DocumentSnapshot>[];

//     for (final userDoc in userDocs) {
//       final chatDocId = '${userDoc.id}_$currentDoctorId';
//       final chatDoc = await FirebaseFirestore.instance
//           .collection('chats')
//           .doc(chatDocId)
//           .get();

//       if (chatDoc.exists) {
//         usersWithChats.add(userDoc);
//       }
//     }

//     return usersWithChats;
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     final currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('users').snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No users available'));
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//               final chatDocId = '${userDoc.id}_$currentDoctorId';

//               return StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatDocId)
//                     .snapshots(),
//                 builder: (context, chatSnapshot) {
//                   // Only show if chat exists
//                   if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
//                     return const SizedBox();
//                   }

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc('${userrDoc.id}_${FirebaseAuth.instance.currentDoctor!.uid}')
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = 'No messages yet';
//                       String messageTime = '';
//                       bool isOtherUserMessage = false;
//                       bool isUnread = false;

//                       if (messageSnapshot.hasData &&
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data()
//                             as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp']);
//                         }
//                         isOtherUserMessage = message['senderId'] != currentUser?.uid;
//                         isUnread = !(message['isRead'] ?? false) && 
//                                   message['receiverId'] == currentUser?.uid;
//                       }

//                       Widget avatarWidget;
//                       if (user['avatar'] != null &&
//                           user['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(user['avatar']),
//                         );
//                       } else {
//                         final String initials = user['fullName']?.isNotEmpty == true
//                             ? user['fullName'][0].toUpperCase()
//                             : 'U';

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
//                             if (isUnread)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: const BoxDecoration(
//                                     color: Colors.red,
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'User',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: isUnread ? Colors.black : Colors.grey[700],
//                           ),
//                         ),
//                         subtitle: Text(
//                           isOtherUserMessage 
//                               ? '${user['fullName']}: $lastMessage'
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: isUnread ? Colors.blue[900] : Colors.grey[600],
//                                 fontSize: 12,
//                                 fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                               ),
//                             ),
//                             if (isUnread)
//                               Container(
//                                 margin: const EdgeInsets.only(top: 4),
//                                 width: 8,
//                                 height: 8,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => DocChatScreen(
//                                 fullName: user['fullName'] ?? 'User',
//                                 userId: userDoc.id,
//                                 chatId: chatDocId,
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

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text(
//           'Chats',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//        return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
//       body: StreamBuilder<QuerySnapshot>(
//         return StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc('${userDoc.id}_${FirebaseAuth.instance.currentDoctor!.uid}')
//                     .collection('messages')
//                     .orderBy('timestamp', descending: true)
//                     .limit(1)
//                     .snapshots(),
//                 builder: (context, messageSnapshot) {
//                   String lastMessage = user[''] ?? 'No one sending massage';
//                   String messageTime = '';
//           }

//           if (chatsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!chatsSnapshot.hasData || chatsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No messages yet'));
//           }

//           final chatDocs = chatsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: chatDocs.length,
//             itemBuilder: (context, index) {
//               final chatDoc = chatDocs[index];
//               final chatData = chatDoc.data() as Map<String, dynamic>;
              
//               final participants = List<String>.from(chatData['participants'] ?? []);
//               final otherUserId = participants.firstWhere(
//                 (id) => id != currentUser.uid,
//                 orElse: () => '',
//               );

//               if (otherUserId.isEmpty) {
//                 return const SizedBox();
//               }

//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
//                 builder: (context, userSnapshot) {
//                   if (!userSnapshot.hasData) {
//                     return const ListTile(
//                       title: Text('Loading...'),
//                     );
//                   }

//                   final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDoc.id)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = 'No messages yet';
//                       String messageTime = '';
//                       bool isDoctorMessage = false;
//                       bool isUnread = false;

//                       if (messageSnapshot.hasData &&
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data()
//                             as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp']);
//                         }
//                         isDoctorMessage = message['senderId'] != currentUser.uid;
//                         isUnread = !(message['isRead'] ?? false) && 
//                                   message['receiverId'] == currentUser.uid;
//                       }

//                       Widget avatarWidget;
//                       if (userData['avatar'] != null &&
//                           userData['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(userData['avatar']),
//                         );
//                       } else {
//                         final String initials = userData['fullName']?.isNotEmpty == true
//                             ? userData['fullName'][0].toUpperCase()
//                             : 'U';

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
//                             if (isUnread)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: const BoxDecoration(
//                                     color: Colors.red,
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           userData['fullName'] ?? 'User',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: isUnread ? Colors.black : Colors.grey[700],
//                           ),
//                         ),
//                         subtitle: Text(
//                           isDoctorMessage 
//                               ? 'Dr. ${userData['fullName']}: $lastMessage'
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: isUnread ? Colors.blue[900] : Colors.grey[600],
//                                 fontSize: 12,
//                                 fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                               ),
//                             ),
//                             if (isUnread)
//                               Container(
//                                 margin: const EdgeInsets.only(top: 4),
//                                 width: 8,
//                                 height: 8,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => DocChatScreen(
//                                 fullName: userData['fullName'] ?? 'User',
//                                 userId: otherUserId,
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


// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

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
//             .collection('chats')
//             .where('participants', arrayContains: currentUser!.uid)
//             .snapshots(),
//         builder: (context, chatsSnapshot) {
//           if (chatsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (chatsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!chatsSnapshot.hasData || chatsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No messages yet'));
//           }

//           final chatDocs = chatsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: chatDocs.length,
//             itemBuilder: (context, index) {
//               final chatDoc = chatDocs[index];
//               final chatData = chatDoc.data() as Map<String, dynamic>;
              
//               // Get the other participant's ID
//               final participants = List<String>.from(chatData['participants'] ?? []);
//               final otherUserId = participants.firstWhere(
//                 (id) => id != currentUser.uid,
//                 orElse: () => '',
//               );

//               if (otherUserId.isEmpty) {
//                 return const SizedBox();
//               }

//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
//                 builder: (context, userSnapshot) {
//                   if (!userSnapshot.hasData) {
//                     return const ListTile(
//                       title: Text('Loading...'),
//                     );
//                   }

//                   final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDoc.id)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = 'No messages yet';
//                       String messageTime = '';
//                       bool isDoctorMessage = false;
//                       bool isUnread = false;

//                       if (messageSnapshot.hasData &&
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data()
//                             as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp']);
//                         }
//                         isDoctorMessage = message['senderId'] != currentUser.uid;
                        
//                         // Check if message is unread and sent to current user
//                         isUnread = !(message['isRead'] ?? false) && 
//                                   message['receiverId'] == currentUser.uid;
//                       }

//                       Widget avatarWidget;
//                       if (userData['avatar'] != null &&
//                           userData['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(userData['avatar']),
//                         );
//                       } else {
//                         final String initials = userData['fullName']?.isNotEmpty == true
//                             ? userData['fullName'][0].toUpperCase()
//                             : 'U';

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
//                             if (isUnread)
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: const BoxDecoration(
//                                     color: Colors.red,
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           userData['fullName'] ?? 'User',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: isUnread ? Colors.black : Colors.grey[700],
//                           ),
//                         ),
//                         subtitle: Text(
//                           isDoctorMessage 
//                               ? 'Dr. ${userData['fullName']}: $lastMessage'
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               messageTime,
//                               style: TextStyle(
//                                 color: isUnread ? Colors.blue[900] : Colors.grey[600],
//                                 fontSize: 12,
//                                 fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                               ),
//                             ),
//                             if (isUnread)
//                               Container(
//                                 margin: const EdgeInsets.only(top: 4),
//                                 width: 8,
//                                 height: 8,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => DocChatScreen(
//                                 fullName: userData['fullName'] ?? 'User',
//                                 userId: otherUserId,
//                               ),
//                             ),
//                           ).then((_) {
//                             // Refresh the chat list when returning from chat screen
//                             if (mounted) {
//                               // Force rebuild to update read status
//                               (context as Element).markNeedsBuild();
//                             }
//                           });
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'doc_chat_screen.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

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
//             .collection('chats')
//             .where('participants', arrayContains: currentUser!.uid)
//             .snapshots(),
//         builder: (context, chatsSnapshot) {
//           if (chatsSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (chatsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!chatsSnapshot.hasData || chatsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No messages yet'));
//           }

//           final chatDocs = chatsSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: chatDocs.length,
//             itemBuilder: (context, index) {
//               final chatDoc = chatDocs[index];
//               final chatData = chatDoc.data() as Map<String, dynamic>;
              
//               // Get the other participant's ID
//               final participants = List<String>.from(chatData['participants'] ?? []);
//               final otherUserId = participants.firstWhere(
//                 (id) => id != currentUser.uid,
//                 orElse: () => '',
//               );

//               if (otherUserId.isEmpty) {
//                 return const SizedBox();
//               }

//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
//                 builder: (context, userSnapshot) {
//                   if (!userSnapshot.hasData) {
//                     return const ListTile(
//                       title: Text('Loading...'),
//                     );
//                   }

//                   final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('chats')
//                         .doc(chatDoc.id)
//                         .collection('messages')
//                         .orderBy('timestamp', descending: true)
//                         .limit(1)
//                         .snapshots(),
//                     builder: (context, messageSnapshot) {
//                       String lastMessage = 'No messages yet';
//                       String messageTime = '';
//                       bool isDoctorMessage = false;

//                       if (messageSnapshot.hasData &&
//                           messageSnapshot.data!.docs.isNotEmpty) {
//                         final message = messageSnapshot.data!.docs.first.data()
//                             as Map<String, dynamic>;
//                         lastMessage = message['text'] ?? lastMessage;
//                         if (message['timestamp'] != null) {
//                           messageTime = _formatTimestamp(message['timestamp']);
//                         }
//                         isDoctorMessage = message['senderId'] != currentUser.uid;
//                       }

//                       Widget avatarWidget;
//                       if (userData['avatar'] != null &&
//                           userData['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(userData['avatar']),
//                         );
//                       } else {
//                         final String initials = userData['fullName']?.isNotEmpty == true
//                             ? userData['fullName'][0].toUpperCase()
//                             : 'U';

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
//                         leading: avatarWidget,
//                         title: Text(
//                           userData['fullName'] ?? 'User',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Text(
//                           isDoctorMessage 
//                               ? 'Dr. ${userData['fullName']}: $lastMessage'
//                               : 'You: $lastMessage',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         trailing: Text(
//                           messageTime,
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 12,
//                           ),
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => DocChatScreen(
//                                 fullName: userData['fullName'] ?? 'User',
//                                 userId: otherUserId,
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'doc_chat_screen.dart';

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

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
//             .collection('users')
//             .where('hasMessaged_${currentUser!.uid}', isEqualTo: true)
//             .snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No messages from users'));
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;

//               final chatDocId = '${currentUser.uid}_${userDoc.id}';

//               return StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatDocId)
//                     .collection('messages')
//                     .orderBy('timestamp', descending: true)
//                     .limit(1)
//                     .snapshots(),
//                 builder: (context, messageSnapshot) {
//                   String lastMessage = 'No messages yet';
//                   String messageTime = '';
//                   String senderName = '';
//                   bool isDoctor = false;

//                   if (messageSnapshot.hasData &&
//                       messageSnapshot.data!.docs.isNotEmpty) {
//                     final message = messageSnapshot.data!.docs.first.data()
//                         as Map<String, dynamic>;
//                     lastMessage = message['text'] ?? lastMessage;
//                     if (message['timestamp'] != null) {
//                       messageTime = _formatTimestamp(message['timestamp']);
//                     }
//                     isDoctor = message['isDoctor'] ?? false;
//                     senderName = isDoctor ? user['fullName'] ?? 'Doctor' : 'You';
//                   }

//                   Widget avatarWidget;
//                   if (user['avatar'] != null &&
//                       user['avatar'].toString().isNotEmpty) {
//                     avatarWidget = CircleAvatar(
//                       radius: 25,
//                       backgroundImage: NetworkImage(user['avatar']),
//                     );
//                   } else {
//                     final String initials = user['fullName']?.isNotEmpty == true
//                         ? user['fullName'][0].toUpperCase()
//                         : 'U';

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
//                       user['fullName'] ?? 'User',
//                       style: TextStyle(fontWeight: FontWeight.bold),),
//                     subtitle: Text(
//                       isDoctor 
//                           ? 'Dr. ${user['fullName']}: $lastMessage'
//                           : 'You: $lastMessage',
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
//                           builder: (_) => DocChatScreen(
//                             fullName: user['fullName'] ?? 'User',
//                             userId: userDoc.id,
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

// import 'doc_chat_screen.dart'; // Make sure you import your chat screen

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

//   String _formatTimestamp(Timestamp timestamp) {
//     final now = DateTime.now();
//     final messageTime = timestamp.toDate();
//     final difference = now.difference(messageTime);

//     if (difference.inDays == 0) {
//       return DateFormat('h:mm a').format(messageTime);
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return DateFormat('EEEE').format(messageTime);
//     } else {
//       return DateFormat('MMM d').format(messageTime);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

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
//             .collection('users')
//             .where('hasMessaged_${currentUser!.uid}', isEqualTo: true)
//             .snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No messages from users'));
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;

//               final chatDocId = '${currentUser.uid}_${userDoc.id}';

//               return StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatDocId)
//                     .collection('messages')
//                     // .orderBy('timestamp', descending: true)
//                     .limit(1)
//                     .snapshots(),
//                 builder: (context, messageSnapshot) {
//                   String lastMessage = 'No messages yet';
//                   String messageTime = '';

//                   if (messageSnapshot.hasData &&
//                       messageSnapshot.data!.docs.isNotEmpty) {
//                     final message = messageSnapshot.data!.docs.first.data()
//                         as Map<String, dynamic>;
//                     lastMessage = message['text'] ?? lastMessage;
//                     if (message['timestamp'] != null) {
//                       messageTime = _formatTimestamp(message['timestamp']);
//                     }
//                   }

//                   Widget avatarWidget;
//                   if (user['avatar'] != null &&
//                       user['avatar'].toString().isNotEmpty) {
//                     avatarWidget = CircleAvatar(
//                       radius: 25,
//                       backgroundImage: NetworkImage(user['avatar']),
//                     );
//                   } else {
//                     final String initials = user['fullName']?.isNotEmpty == true
//                         ? user['fullName'][0].toUpperCase()
//                         : 'U';

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
//                       user['fullName'] ?? 'User',
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
//                           builder: (_) => DocChatScreen(
//                             fullName: user['fullName'] ?? 'User',
//                             userId: userDoc.id,
//                             // isUser: false,
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
// import 'doc_chat_screen.dart'; // Make sure this import points to your doctor chat screen

// class MychatsTab extends StatelessWidget {
//   const MychatsTab({super.key});

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
//     final currentUser = FirebaseAuth.instance.currentUser;
    
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
//             .collection('users') // Changed from 'doctors' to 'users' since this is doctor's view
//             .snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           }

//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No users available'));
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           return ListView.builder(
//             itemCount: userDocs.length,
//             itemBuilder: (context, index) {
//               final userDoc = userDocs[index];
//               final user = userDoc.data() as Map<String, dynamic>;
              
//               // Create chat document ID with doctor ID first (current user) then user ID
//               final chatDocId = '${currentUser!.uid}_${userDoc.id}';
              
//               return StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatDocId)
//                     .collection('messages')
//                     .orderBy('timestamp', descending: true)
//                     .limit(1)
//                     .snapshots(),
//                 builder: (context, messageSnapshot) {
//                   String lastMessage = 'No messages yet';
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
//                   if (user['avatar'] != null && user['avatar'].toString().isNotEmpty) {
//                     avatarWidget = CircleAvatar(
//                       radius: 25,
//                       backgroundImage: NetworkImage(user['avatar']),
//                     );
//                   } else {
//                     final String initials = user['fullName']?.isNotEmpty == true 
//                         ? user['fullName'][0].toUpperCase()
//                         : 'U';
                    
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
//                       user['fullName'] ?? 'User',
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
//                           builder: (_) => DocChatScreen(
//                             userName: user['fullName'] ?? 'User',
//                             userId: userDoc.id,
//                             // Make sure DocChatScreen is set up to handle doctor perspective
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

// class MychatsTab extends StatelessWidget {
//   const MychatsTab ({super.key});

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
//                           builder: (_) => DocChatScreen(
//                             doctorName: doctor['fullName'] ?? 'User',
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



// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;
//   Future<QuerySnapshot>? _appointmentsFuture;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
//   final Map<String, String> _fullNameCache = {}; // Cache for patient names

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//     _refreshData();
//   }

//   Future<void> sendNotificationToUser(String userId) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fcmToken = userDoc['fcmToken'];

//       if (fcmToken != null && fcmToken.isNotEmpty) {
//         await _firestore.collection('notifications').add({
//           'to': fcmToken,
//           'title': 'Appointment Confirmed',
//           'body': 'Your appointment has been confirmed.',
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//       }
//     } catch (e) {
//       debugPrint('Notification error: $e');
//     }
//   }

//   Future<void> _refreshData() async {
//     if (_doctorId == null) return;
    
//     setState(() {
//       _appointmentsFuture = _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: _doctorId)
//           .get();
//       _fullNameCache.clear(); // Clear cache on refresh
//     });
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (status == 'confirmed') {
//         await sendNotificationToUser(userId);
//         _showSnackbar('Appointment confirmed successfully', Colors.green);
//       } else {
//         _showSnackbar('Appointment cancelled', Colors.orange);
//       }

//       await _refreshData();
//     } catch (e) {
//       _showSnackbar('Error: ${e.toString()}', Colors.red);
//     }
//   }

//   void _showSnackbar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       case 'pending':
//         return Colors.orange;
//       case 'completed':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _statusText(String status) {
//     return status[0].toUpperCase() + status.substring(1);
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
//   }

//   Future<String> _getfullName(String userId) async {
//     if (_fullNameCache.containsKey(userId)) {
//       return _fullNameCache[userId]!;
//     }

//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fullName = userDoc['fullName']?.toString() ?? 'Unknown Patient';
//       _fullNameCache[userId] = fullName; // Cache the name
//       return fullName;
//     } catch (e) {
//       debugPrint('Error fetching patient name: $e');
//       return 'Unknown Patient';
//     }
//   }

//   Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
//     return FutureBuilder<String>(
//       future: _getfullName(data['userId']),
//       builder: (context, fullNameSnapshot) {
//         final patientName = fullNameSnapshot.data ?? 'Loading...';

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Appointment request header
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     Chip(
//                       label: Text(
//                         _statusText(data['status']),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                         ),
//                       ),
//                       backgroundColor: _statusColor(data['status']),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 //photo name
//                backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.['photoUrl'] != null
//                   ? NetworkImage(widget.['photoUrl'])
//                   : null,
//               child: widget.['photoUrl'] == null
//                   ? Text(
//                       widget.['fullName']?.isNotEmpty == true

//                 // Appointment details (if available)
//                 if (data['appointmentDate'] != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       'Date: ${_formatTimestamp(data['appointmentDate'] as Timestamp)}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 if (data['reason'] != null && data['reason'].toString().isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       'Reason: ${data['reason']}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),

//                 const SizedBox(height: 16),

//                 // Action buttons for doctor
//                 if ((data['status'] as String).toLowerCase() == 'pending')
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       OutlinedButton(
//                         onPressed: () => _updateAppointmentStatus(
//                           doc.id, 'cancelled', data['userId']),
//                         style: OutlinedButton.styleFrom(
//                           side: const BorderSide(color: Colors.red),
//                         ),
//                         child: const Text(
//                           'Reject',
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton(
//                         onPressed: () => _updateAppointmentStatus(
//                           doc.id, 'confirmed', data['userId']),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                         ),
//                         child: const Text(
//                           'Confirm',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: FutureBuilder<QuerySnapshot>(
//           future: _appointmentsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('No appointment requests found'),
//                     TextButton(
//                       onPressed: _refreshData,
//                       child: const Text('Refresh'),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final doc = snapshot.data!.docs[index];
//                 final data = doc.data() as Map<String, dynamic>;
//                 return _buildAppointmentCard(doc, data);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }



// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;
//   Future<QuerySnapshot>? _appointmentsFuture;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
//   final Map<String, String> _fullNameCache = {}; // Cache for patient names

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//     _refreshData();
//   }

//   Future<void> sendNotificationToUser(String userId) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fcmToken = userDoc['fcmToken'];

//       if (fcmToken != null && fcmToken.isNotEmpty) {
//         await _firestore.collection('notifications').add({
//           'to': fcmToken,
//           'title': 'Appointment Confirmed',
//           'body': 'Your appointment has been confirmed.',
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//       }
//     } catch (e) {
//       debugPrint('Notification error: $e');
//     }
//   }

//   Future<void> _refreshData() async {
//     setState(() {
//       _appointmentsFuture = _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: _doctorId)
//           .orderBy('createdAt', descending: true)
//           .get();
//       _fullNameCache.clear(); // Clear cache on refresh
//     });
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (status == 'confirmed') {
//         await sendNotificationToUser(userId);
//         _showSnackbar('Appointment confirmed successfully', Colors.green);
//       } else {
//         _showSnackbar('Appointment cancelled', Colors.orange);
//       }

//       _refreshData();
//     } catch (e) {
//       _showSnackbar('Error: ${e.toString()}', Colors.red);
//     }
//   }

//   void _showSnackbar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       case 'pending':
//         return Colors.orange;
//       case 'completed':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _statusText(String status) {
//     return status[0].toUpperCase() + status.substring(1);
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
//   }

//   Future<String> _getfullName(String userId) async {
//     if (_fullNameCache.containsKey(userId)) {
//       return _fullNameCache[userId]!;
//     }

//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fullName = '${userDoc['fullName']}';
//       _fullNameCache[userId] = fullName; // Cache the name
//       return fullName;
//     } catch (e) {
//       debugPrint('Error fetching patient name: $e');
//       return 'Unknown Patient';
//     }
//   }

//   Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
//     return FutureBuilder<String>(
//       future: _getfullName(data['userId']),
//       builder: (context, fullNameSnapshot) {
//         final patientName = fullNameSnapshot.data ?? 'Loading...';

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Appointment request header
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     Chip(
//                       label: Text(
//                         _statusText(data['status']),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                         ),
//                       ),
//                       backgroundColor: _statusColor(data['status']),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Patient information
//                 Text(
//                   'name: $fullName',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//                 // Appointment details (if available)
//                 if (data['appointmentDate'] != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       'Date: ${_formatTimestamp(data['appointmentDate'] as Timestamp)}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 if (data['reason'] != null && data['reason'].toString().isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       'Reason: ${data['reason']}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),

//                 const SizedBox(height: 16),

//                 // Action buttons for doctor
//                 if ((data['status'] as String).toLowerCase() == 'pending')
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       OutlinedButton(
//                         onPressed: () => _updateAppointmentStatus(
//                           doc.id, 'cancelled', data['userId']),
//                         style: OutlinedButton.styleFrom(
//                           side: const BorderSide(color: Colors.red),
//                         ),
//                         child: const Text(
//                           'Reject',
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton(
//                         onPressed: () => _updateAppointmentStatus(
//                           doc.id, 'confirmed', data['userId']),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                         ),
//                         child: const Text(
//                           'Confirm',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Appointments'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _refreshData,
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: FutureBuilder<QuerySnapshot>(
//           future: _appointmentsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('No appointment requests found'),
//                     TextButton(
//                       onPressed: _refreshData,
//                       child: const Text('Refresh'),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final doc = snapshot.data!.docs[index];
//                 final data = doc.data() as Map<String, dynamic>;
//                 return _buildAppointmentCard(doc, data);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;
//   Future<QuerySnapshot>? _appointmentsFuture;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//     _refreshData();
//   }

//   Future<void> _refreshData() async {
//     setState(() {
//       _appointmentsFuture = _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: _doctorId)
//           .orderBy('createdAt', descending: true)
//           .get();
//     });
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (status == 'confirmed') {
//         await sendNotificationToUser(userId);
//         _showSnackbar('Appointment confirmed successfully', Colors.green);
//       } else {
//         _showSnackbar('Appointment cancelled', Colors.orange);
//       }

//       // Refresh data after update
//       _refreshData();
//     } catch (e) {
//       _showSnackbar('Error: ${e.toString()}', Colors.red);
//     }
//   }

//   void _showSnackbar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // ... keep all your existing helper methods (_statusColor, _statusText, etc.) ...

//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       body: RefreshIndicator(
//         key: _refreshIndicatorKey,
//         onRefresh: _refreshData,
//         child: FutureBuilder<QuerySnapshot>(
//           future: _appointmentsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('No appointment requests found'),
//                     TextButton(
//                       onPressed: _refreshData,
//                       child: const Text('Refresh'),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final doc = snapshot.data!.docs[index];
//                 final data = doc.data() as Map<String, dynamic>;

//                 return FutureBuilder<String>(
//                   future: _getPatientName(data['userId']),
//                   builder: (context, patientNameSnapshot) {
//                     final patientName = patientNameSnapshot.data ?? 'Loading...';

//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 16),
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Appointment request header
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                                 Chip(
//                                   label: Text(
//                                     _statusText(data['status']),
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                   backgroundColor: _statusColor(data['status']),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),

//                             // Patient information
//                             Text(
//                               'Patient: $patientName',
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),

//                             const SizedBox(height: 16),

//                             // Action buttons for doctor
//                             if ((data['status'] as String).toLowerCase() == 'pending')
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.end,
//                                 children: [
//                                   OutlinedButton(
//                                     onPressed: () => _updateAppointmentStatus(
//                                       doc.id, 'cancelled', data['userId']),
//                                     style: OutlinedButton.styleFrom(
//                                       side: const BorderSide(color: Colors.red),
//                                     ),
//                                     child: const Text(
//                                       'Reject',
//                                       style: TextStyle(color: Colors.red),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   ElevatedButton(
//                                     onPressed: () => _updateAppointmentStatus(
//                                       doc.id, 'confirmed', data['userId']),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.green,
//                                     ),
//                                     child: const Text(
//                                       'Confirm',
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }


// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.orange;
//     }
//   }

//   String _statusText(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return 'Confirmed';
//       case 'cancelled':
//         return 'Cancelled';
//       default:
//         return 'Pending Review';
//     }
//   }

//   // NEW: Send FCM Notification to user
//   Future<void> sendNotificationToUser(String userId) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       final fcmToken = userDoc['fcmToken'];

//       if (fcmToken != null && fcmToken.isNotEmpty) {
//         await _firestore.collection('notifications').add({
//           'to': fcmToken,
//           'title': 'Appointment Confirmed',
//           'body': 'Your appointment has been confirmed.',
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         // Optional: You can also integrate cloud function or server call here
//       }
//     } catch (e) {
//       debugPrint('Notification error: $e');
//     }
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status, String userId) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (status == 'confirmed') {
//         await sendNotificationToUser(userId);
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('dd MMMM yyyy \'at\' HH:mm').format(timestamp.toDate());
//   }

//   Future<String> _getPatientName(String userId) async {
//     try {
//       final doc = await _firestore.collection('users').doc(userId).get();
//       return doc['fullName'] ?? 'Unknown Patient';
//     } catch (e) {
//       return 'Unknown Patient';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('appointments')
//             .where('doctorId', isEqualTo: _doctorId)
//             .orderBy('createdAt', descending: true)
//             .get(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No appointment requests found'));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doc = snapshot.data!.docs[index];
//               final data = doc.data() as Map<String, dynamic>;

//               return FutureBuilder<String>(
//                 future: _getPatientName(data['userId']),
//                 builder: (context, patientNameSnapshot) {
//                   final patientName = patientNameSnapshot.data ?? 'Loading...';

//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 16),
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Appointment request header
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               Chip(
//                                 label: Text(
//                                   _statusText(data['status']),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                                 backgroundColor: _statusColor(data['status']),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),

//                           // Patient information
//                           Text(
//                             'Patient: $patientName',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),

//                           const SizedBox(height: 16),

//                           // Action buttons for doctor
//                           if (data['status'].toString().toLowerCase() == 'pending')
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 OutlinedButton(
//                                   onPressed: () => _updateAppointmentStatus(doc.id, 'cancelled', data['userId']),
//                                   style: OutlinedButton.styleFrom(
//                                     side: const BorderSide(color: Colors.red),
//                                   ),
//                                   child: const Text(
//                                     'Reject',
//                                     style: TextStyle(color: Colors.red),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 ElevatedButton(
//                                   onPressed: () => _updateAppointmentStatus(doc.id, 'confirmed', data['userId']),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                   ),
//                                   child: const Text(
//                                     'Confirm',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                         ],
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



// class MyappointmentsTab extends StatefulWidget {
//   const MyappointmentsTab({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State<MyappointmentsTab> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _doctorId;

//   @override
//   void initState() {
//     super.initState();
//     _doctorId = _auth.currentUser?.uid;
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       default: // pending
//         return Colors.orange;
//     }
//   }

//   String _statusText(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return 'Confirmed';
//       case 'cancelled':
//         return 'Cancelled';
//       default:
//         return 'Pending Review';
//     }
//   }

//   Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
//     try {
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('dd MMMM yyyy \'at\' HH:mm').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('HH:mm').format(timestamp.toDate());
//   }

//   Future<String> _getPatientName(String userId) async {
//     try {
//       final doc = await _firestore.collection('users').doc(userId).get();
//       return doc['fullName'] ?? 'Unknown Patient';
//     } catch (e) {
//       return 'Unknown Patient';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view appointments')),
//       );
//     }

//     return Scaffold(
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('appointments')
//             .where('doctorId', isEqualTo: _doctorId)
//             .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No appointment requests found'));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doc = snapshot.data!.docs[index];
//               final data = doc.data() as Map<String, dynamic>;

//               return FutureBuilder<String>(
//                 future: _getPatientName(data['userId']),
//                 builder: (context, patientNameSnapshot) {
//                   final patientName = patientNameSnapshot.data ?? 'Loading...';

//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 16),
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Appointment request header
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Requested: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               Chip(
//                                 label: Text(
//                                   _statusText(data['status']),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                                 backgroundColor: _statusColor(data['status']),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),

//                           // Patient information
//                           Text(
//                             'Patient: $patientName',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),

//                           // Appointment details
//                           Text(
//                             'Date: ${DateFormat('dd MMMM yyyy').format((data['date'] as Timestamp).toDate())}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           const SizedBox(height: 4),

//                           Text(
//                             'Time: ${_formatTime(data['startTime'] as Timestamp)} - ${_formatTime(data['endTime'] as Timestamp)}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           const SizedBox(height: 4),

//                           Text(
//                             'Specialty: ${data['specialty']}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           const SizedBox(height: 4),

//                           Text(
//                             'Fee: \$${data['fee']?.toStringAsFixed(2) ?? '0.00'}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           const SizedBox(height: 16),

//                           // Action buttons for doctor
//                           if (data['status'].toString().toLowerCase() == 'pending')
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 OutlinedButton(
//                                   onPressed: () => _updateAppointmentStatus(doc.id, 'cancelled'),
//                                   style: OutlinedButton.styleFrom(
//                                     side: const BorderSide(color: Colors.red),
//                                   ),
//                                   child: const Text(
//                                     'Reject',
//                                     style: TextStyle(color: Colors.red),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 ElevatedButton(
//                                   onPressed: () => _updateAppointmentStatus(doc.id, 'confirmed'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                   ),
//                                   child: const Text(
//                                     'Confirm',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                         ],
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



// class  MyappointmentsTab extends StatefulWidget {
//   const  MyappointmentsTab ({Key? key}) : super(key: key);

//   @override
//   State<MyappointmentsTab> createState() => _MyappointmentsTabState();
// }

// class _MyappointmentsTabState extends State< MyappointmentsTab> {
//   late Future<bool> _isDoctorFuture;
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _userId = user?.uid;
//     _isDoctorFuture = _checkIfDoctor();
//   }

//   Future<bool> _checkIfDoctor() async {
//     if (_userId == null) return false;
//     final doc = await FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(_userId)
//         .get();
//     return doc.exists;
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return Colors.green;
//       case 'Cancelled':
//         return Colors.red;
//       default: // pending
//         return Colors.orange;
//     }
//   }

//   Future<void> _updateAppointmentStatus(
//       String appointmentId, String status) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .update({'status': status});
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }

//   Stream<QuerySnapshot> _getAppointmentsStream(bool isDoctor) {
//     if (_userId == null) return const Stream.empty();
    
//     return isDoctor
//         ? FirebaseFirestore.instance
//             .collection('appointments')
//             .where('doctorId', isEqualTo: _userId)
//             .snapshots()
//         : FirebaseFirestore.instance
//             .collection('appointments')
//             .where('patientId', isEqualTo: _userId)
//             .snapshots();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Your Appointments'),
//         backgroundColor: Colors.blue, // Replace with your color
//       ),
//       body: _userId == null
//           ? const Center(child: Text('Please sign in to view appointments'))
//           : FutureBuilder<bool>(
//               future: _isDoctorFuture,
//               builder: (context, roleSnapshot) {
//                 if (roleSnapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (roleSnapshot.hasError) {
//                   return Center(child: Text('Error: ${roleSnapshot.error}'));
//                 }

//                 final isDoctor = roleSnapshot.data ?? false;

//                 return StreamBuilder<QuerySnapshot>(
//                   stream: _getAppointmentsStream(isDoctor),
//                   builder: (context, snapshot) {
//                     if (snapshot.hasError) {
//                       return Center(child: Text('Error: ${snapshot.error}'));
//                     }

//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     if (snapshot.data!.docs.isEmpty) {
//                       return const Center(child: Text('No appointments found'));
//                     }

//                     return ListView.builder(
//                       itemCount: snapshot.data!.docs.length,
//                       itemBuilder: (context, index) {
//                         final appointment = snapshot.data!.docs[index];
//                         final data = appointment.data() as Map<String, dynamic>;

//                         return Card(
//                           margin: const EdgeInsets.symmetric(
//                               horizontal: 16, vertical: 8),
//                           elevation: 4,
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12)),
//                           child: ListTile(
//                             leading: const Icon(Icons.calendar_today,
//                                 color: Colors.blue),
//                             title: Text(
//                               data['doctorName'] ?? 'No Name',
//                               style: const TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text('Date: ${data['date'] ?? 'N/A'}',
//                                     style: const TextStyle(fontSize: 14)),
//                                 Text('Time: ${data['time'] ?? 'N/A'}',
//                                     style: const TextStyle(fontSize: 14)),
//                                 if (isDoctor && data['status'] == 'Pending')
//                                   Row(
//                                     children: [
//                                       TextButton(
//                                         onPressed: () =>
//                                             _updateAppointmentStatus(
//                                                 appointment.id, 'Confirmed'),
//                                         child: const Text('Confirm',
//                                             style:
//                                                 TextStyle(color: Colors.green)),
//                                       ),
//                                       TextButton(
//                                         onPressed: () =>
//                                             _updateAppointmentStatus(
//                                                 appointment.id, 'Cancelled'),
//                                         child: const Text('Cancel',
//                                             style: TextStyle(color: Colors.red)),
//                                       ),
//                                     ],
//                                   ),
//                               ],
//                             ),
//                             trailing: Chip(
//                               label: Text(
//                                 data['status'] ?? 'Pending',
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                               backgroundColor:
//                                   _statusColor(data['status'] ?? 'Pending'),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }







// class MyappointmentsTab extends StatelessWidget {
  

//   const MyappointmentsTab ({Key? key}) : super(key: key);

//   final List<Map<String, String>> appointments = const [
// ;

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return Colors.green;
//       case 'Cancelled':
//         return Colors.red;
//       default://pending
//         return Colors.orange;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Your Appointments'),
//         backgroundColor: AppConstants.primaryColor,
//       ),
//       body: ListView.builder(
//         itemCount: appointments.length,
//         itemBuilder: (context, index) {
//           final appointment = appointments[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             elevation: 4,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             child: ListTile(
//               leading: Icon(Icons.calendar_today, color: AppConstants.primaryColor),
//               title: Text(appointment['doctorName']!, style: AppConstants.headingStyle),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Date: ${appointment['date']}', style: AppConstants.bodyTextStyle),
//                   Text('Time: ${appointment['time']}', style: AppConstants.bodyTextStyle),
//                 ],
//               ),
//               trailing: Chip(
//                 label: Text(
//                   appointment['status']!,
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 backgroundColor: _statusColor(appointment['status']!),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



// class ViewScheduleTab extends StatelessWidget {
//   const ViewScheduleTab({super.key});

//   void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red[800] : Colors.green[800],
//         duration: Duration(seconds: isError ? 3 : 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

//     if (currentUser == null) {
//       return Center(
//         child: Text('Please sign in to view schedules',
//             style: TextStyle(color: Colors.white)),
//       );
//     }

//     final schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(currentUser.uid)
//         .collection('schedules')
//         .orderBy('date');

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
//           });
//           return _buildErrorWidget();
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingIndicator();
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         return _buildScheduleTable(snapshot.data!.docs, context);
//       },
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Text('Error loading data', style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget() {
//     return Center(
//       child: Text('No schedules available',
//           style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs, BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16), // Border radius sax
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10,
//               spreadRadius: 3,
//               offset: Offset(0, 4), // Shadow muuqaal fiican
//             ),
//           ],
//         ),
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: DataTable(
//               headingRowHeight: 50,
//               dataRowHeight: 48,
//               horizontalMargin: 12, // sax horizontal alignment
//               columnSpacing: 20, // yaraynta spacing-ka
//               headingRowColor: MaterialStateProperty.resolveWith<Color>(
//                 (states) => Colors.blue[700]!,
//               ),
//               dataRowColor: MaterialStateProperty.resolveWith<Color>(
//                 (states) => Colors.white,
//               ),
//               columns: [
//                 DataColumn(
//                   label: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Text('Date',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         )),
//                   ),
//                 ),
//                 DataColumn(
//                   label: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Text('Start Time',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         )),
//                   ),
//                 ),
//                 DataColumn(
//                   label: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Text('End Time',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         )),
//                   ),
//                 ),
//                 DataColumn(
//                   label: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Text('Duration',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         )),
//                   ),
//                 ),
//               ],
//               rows: docs.map((document) {
//                 final data = document.data() as Map<String, dynamic>;
//                 final date = (data['date'] as Timestamp).toDate();
//                 final startTime = (data['startTime'] as Timestamp).toDate();
//                 final endTime = (data['endTime'] as Timestamp).toDate();

//                 final dateFormat = DateFormat('MMM d, yyyy');
//                 final timeFormat = DateFormat('h:mm a');
//                 final duration = endTime.difference(startTime);

//                 return DataRow(
//                   cells: [
//                     DataCell(
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8),
//                         child: Text(dateFormat.format(date),
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                             )),
//                       ),
//                     ),
//                     DataCell(
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8),
//                         child: Text(timeFormat.format(startTime),
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                             )),
//                       ),
//                     ),
//                     DataCell(
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8),
//                         child: Text(timeFormat.format(endTime),
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                             )),
//                       ),
//                     ),
//                     DataCell(
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8),
//                         child: Text(
//                             '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                             )),
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }




// class ViewScheduleTab extends StatelessWidget {
//   const ViewScheduleTab({super.key});

//   void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red[800] : Colors.green[800],
//         duration: Duration(seconds: isError ? 3 : 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
    
//     if (currentUser == null) {
//       return Center(
//         child: Text('Please sign in to view schedules', 
//           style: TextStyle(color: Colors.white)),
//       );
//     }

//     final schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(currentUser.uid)
//         .collection('schedules')
//         .orderBy('date');

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.snapshots(),
//       builder: (context, snapshot) {
//         // Handle errors
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
//           });
//           return _buildErrorWidget();
//         }

//         // Handle loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingIndicator();
//         }

//         // Handle empty data
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         return _buildScheduleTable(snapshot.data!.docs, context);
//       },
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Text('Error loading data', 
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget() {
//     return Center(
//       child: Text('No schedules available',
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs, BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 2,
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: DataTable(
//             headingRowHeight: 50,
//             dataRowHeight: 48,
//             horizontalMargin: 16,
//             columnSpacing: 24,
//             headingRowColor: MaterialStateProperty.resolveWith<Color>(
//               (states) => Colors.blue[700]!,
//             ),
//             dataRowColor: MaterialStateProperty.resolveWith<Color>(
//               (states) => Colors.white,
//             ),
//             columns: [
//               DataColumn(
//                 label: Text('Date', 
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('Start Time', 
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('End Time', 
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('Duration', 
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   )),
//               ),
//             ],
//             rows: docs.map((document) {
//               final data = document.data() as Map<String, dynamic>;
//               final date = (data['date'] as Timestamp).toDate();
//               final startTime = (data['startTime'] as Timestamp).toDate();
//               final endTime = (data['endTime'] as Timestamp).toDate();

//               final dateFormat = DateFormat('MMM d, yyyy');
//               final timeFormat = DateFormat('h:mm a');
//               final duration = endTime.difference(startTime);

//               return DataRow(
//                 cells: [
//                   DataCell(
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: Text(dateFormat.format(date), 
//                         style: TextStyle(
//                           color: Colors.grey[800],
//                           fontSize: 13,
//                         )),
//                     ),
//                   ),
//                   DataCell(
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: Text(timeFormat.format(startTime), 
//                         style: TextStyle(
//                           color: Colors.grey[800],
//                           fontSize: 13,
//                         )),
//                     ),
//                   ),
//                   DataCell(
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: Text(timeFormat.format(endTime), 
//                         style: TextStyle(
//                           color: Colors.grey[800],
//                           fontSize: 13,
//                         )),
//                     ),
//                   ),
//                   DataCell(
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m', 
//                         style: TextStyle(
//                           color: Colors.grey[800],
//                           fontSize: 13,
//                         )),
//                     ),
//                   ),
//                 ],
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }


// class ViewScheduleTab extends StatelessWidget {
//   const ViewScheduleTab({super.key});

//   void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red[800] : Colors.green[800],
//         duration: Duration(seconds: isError ? 3 : 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
    
//     if (currentUser == null) {
//       return Center(
//         child: Text('Please sign in to view schedules', 
//           style: TextStyle(color: Colors.white)),
//       );
//     }

//     final schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(currentUser.uid)
//         .collection('schedules')
//         .orderBy('date');

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.snapshots(),
//       builder: (context, snapshot) {
//         // Handle errors
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
//           });
//           return _buildErrorWidget();
//         }

//         // Handle loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingIndicator();
//         }

//         // Handle empty data
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         return _buildScheduleTable(snapshot.data!.docs);
//       },
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Text('Error loading data', 
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget() {
//     return Center(
//       child: Text('No schedules available',
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12), // Nice rounded corners
//         border: Border.all(
//           color: Colors.grey[300]!, // Light grey border
//           width: 1,
//         ),
//       ),
//       margin: const EdgeInsets.all(12), // Smaller margin
//       padding: const EdgeInsets.all(8), // Inner padding
//       // constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.95), // Smaller width
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           headingRowHeight: 48,
//           dataRowHeight: 42,
//           horizontalMargin: 12,
//           columnSpacing: 20,
//           headingRowColor: MaterialStateProperty.resolveWith<Color>(
//             (states) => Colors.blue[50]!, // Light blue header background
//           ),
//           dataRowColor: MaterialStateProperty.resolveWith<Color>(
//             (states) => Colors.white,
//           ),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           columns: [
//             DataColumn(
//               label: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[100], // Slightly darker blue for first column header
//                   borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
//                 ),
//                 child: Text('Date', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   )),
//               ),
//             ),
//             DataColumn(
//               label: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 child: Text('Start Time', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   )),
//               ),
//             ),
//             DataColumn(
//               label: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 child: Text('End Time', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   )),
//               ),
//             ),
//             DataColumn(
//               label: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 child: Text('Duration', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   )),
//               ),
//             ),
//           ],
//           rows: docs.map((document) {
//             final data = document.data() as Map<String, dynamic>;
//             final date = (data['date'] as Timestamp).toDate();
//             final startTime = (data['startTime'] as Timestamp).toDate();
//             final endTime = (data['endTime'] as Timestamp).toDate();

//             final dateFormat = DateFormat('MMM d, yyyy');
//             final timeFormat = DateFormat('h:mm a');
//             final duration = endTime.difference(startTime);

//             return DataRow(
//               cells: [
//                 DataCell(
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 8),
//                     child: Text(dateFormat.format(date), 
//                       style: TextStyle(
//                         color: Colors.blue[900],
//                         fontSize: 13,
//                       )),
//                   ),
//                 ),
//                 DataCell(
//                   Text(timeFormat.format(startTime), 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 13,
//                     )),
//                 ),
//                 DataCell(
//                   Text(timeFormat.format(endTime), 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 13,
//                     )),
//                 ),
//                 DataCell(
//                   Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m', 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 13,
//                     )),
//                 ),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }




// class ViewScheduleTab extends StatelessWidget {
//   const ViewScheduleTab({super.key});

//   void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red[800] : Colors.green[800],
//         duration: Duration(seconds: isError ? 3 : 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
    
//     if (currentUser == null) {
//       return Center(
//         child: Text('Please sign in to view schedules', 
//           style: TextStyle(color: Colors.white)),
//       );
//     }

//     final schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(currentUser.uid)
//         .collection('schedules')
//         .orderBy('date');

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.snapshots(),
//       builder: (context, snapshot) {
//         // Handle errors
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
//           });
//           return _buildErrorWidget();
//         }

//         // Handle loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingIndicator();
//         }

//         // Handle empty data
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         return _buildScheduleTable(snapshot.data!.docs);
//       },
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Text('Error loading data', 
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget() {
//     return Center(
//       child: Text('No schedules available',
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white, // White box color
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey[50]!, // Grey 200 shadow
//             blurRadius: 30,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       margin: const EdgeInsets.all(16),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Material(
//           elevation: 10, // Shadow for table header
//           borderRadius: BorderRadius.circular(10),
//           child: DataTable(
//             headingRowHeight: 50,
//             dataRowHeight: 50,
//             headingRowColor: MaterialStateProperty.resolveWith<Color>(
//               (Set<MaterialState> states) => Colors.white,
//             ),
//             dataRowColor: MaterialStateProperty.resolveWith<Color>(
//               (Set<MaterialState> states) => Colors.white,
//             ),
//             columns: [
//               DataColumn(
//                 label: Text('Date', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('Start Time', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('End Time', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('Duration', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('Notes', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//             ],
//             rows: docs.map((document) {
//               final data = document.data() as Map<String, dynamic>;
//               final date = (data['date'] as Timestamp).toDate();
//               final startTime = (data['startTime'] as Timestamp).toDate();
//               final endTime = (data['endTime'] as Timestamp).toDate();
//               final notes = data['notes'] as String? ?? '';

//               final dateFormat = DateFormat('MMM d, yyyy');
//               final timeFormat = DateFormat('h:mm a');
//               final duration = endTime.difference(startTime);

//               return DataRow(
//                 cells: [
//                   DataCell(Text(dateFormat.format(date), 
//                     style:  TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                   DataCell(Text(timeFormat.format(startTime), 
//                     style:  TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                   DataCell(Text(timeFormat.format(endTime), 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                   DataCell(Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m', 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                   DataCell(Text(notes, 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                 ],
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }





// class ViewScheduleTab extends StatelessWidget {
//   const ViewScheduleTab({super.key});

//   void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red[800] : Colors.green[800],
//         duration: Duration(seconds: isError ? 3 : 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
    
//     if (currentUser == null) {
//       return Center(
//         child: Text('Please sign in to view schedules', 
//           style: TextStyle(color: Colors.white)),
//       );
//     }

//     final schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(currentUser.uid)
//         .collection('schedules')
//         .orderBy('date');

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.snapshots(),
//       builder: (context, snapshot) {
//         // Handle errors
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
//           });
//           return _buildErrorWidget();
//         }

//         // Handle loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingIndicator();
//         }

//         // Handle empty data
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         return _buildScheduleTable(snapshot.data!.docs);
//       },
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Text('Error loading data', 
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget() {
//     return Center(
//       child: Text('No schedules available',
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey[300]!,
//             blurRadius: 10,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       margin: const EdgeInsets.all(16),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Material(
//           elevation: 10, // This adds shadow to the table header
//           borderRadius: BorderRadius.circular(10),
//           child: DataTable(
//             headingRowHeight: 50,
//             dataRowHeight: 50,
//             headingRowColor: MaterialStateProperty.resolveWith<Color>(
//               (Set<MaterialState> states) => Colors.white,
//             ),
//             dataRowColor: MaterialStateProperty.resolveWith<Color>(
//               (Set<MaterialState> states) => Colors.white,
//             ),
//             columns: [
//               DataColumn(
//                 label: Text('Date', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('Start Time', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('End Time', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('Duration', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//               DataColumn(
//                 label: Text('Notes', 
//                   style: TextStyle(
//                     color: Colors.blue[900], 
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   )),
//               ),
//             ],
//             rows: docs.map((document) {
//               final data = document.data() as Map<String, dynamic>;
//               final date = (data['date'] as Timestamp).toDate();
//               final startTime = (data['startTime'] as Timestamp).toDate();
//               final endTime = (data['endTime'] as Timestamp).toDate();
//               final notes = data['notes'] as String? ?? '';

//               final dateFormat = DateFormat('MMM d, yyyy');
//               final timeFormat = DateFormat('h:mm a');
//               final duration = endTime.difference(startTime);

//               return DataRow(
//                 cells: [
//                   DataCell(Text(dateFormat.format(date), 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                   DataCell(Text(timeFormat.format(startTime), 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                   DataCell(Text(timeFormat.format(endTime), 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                   DataCell(Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m', 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                   DataCell(Text(notes, 
//                     style: TextStyle(
//                       color: Colors.blue[900],
//                       fontSize: 14,
//                     ))),
//                 ],
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }



// class ViewScheduleTab extends StatelessWidget {
//   const ViewScheduleTab({super.key});

//   void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red[800] : Colors.green[800],
//         duration: Duration(seconds: isError ? 3 : 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
    
//     if (currentUser == null) {
//       return Center(
//         child: Text('Please sign in to view schedules', 
//           style: TextStyle(color: Colors.white)),
//       );
//     }

//     final schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(currentUser.uid)
//         .collection('schedules')
//         .orderBy('date');

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.snapshots(),
//       builder: (context, snapshot) {
//         // Handle errors
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
//           });
//           return _buildErrorWidget();
//         }

//         // Handle loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingIndicator();
//         }

//         // Handle empty data
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         return _buildScheduleTable(snapshot.data!.docs);
//       },
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Text('Error loading data', 
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget() {
//     return Center(
//       child: Text('No schedules available',
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.green[800],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       margin: const EdgeInsets.all(8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           headingRowColor: MaterialStateProperty.resolveWith<Color>(
//             (Set<MaterialState> states) => Colors.white!,
//           ),
//           dataRowColor: MaterialStateProperty.resolveWith<Color>(
//             (Set<MaterialState> states) => Colors.white!,
//           ),
//           columns: const [
//             DataColumn(
//               label: Text('Date', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold))),
//             DataColumn(
//               label: Text('Start Time', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold))),
//             DataColumn(
//               label: Text('End Time', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold))),
//             DataColumn(
//               label: Text('Duration', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold))),
//             DataColumn(
//               label: Text('Notes', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold))),
//           ],
//           rows: docs.map((document) {
//             final data = document.data() as Map<String, dynamic>;
//             final date = (data['date'] as Timestamp).toDate();
//             final startTime = (data['startTime'] as Timestamp).toDate();
//             final endTime = (data['endTime'] as Timestamp).toDate();
//             final notes = data['notes'] as String? ?? '';

//             final dateFormat = DateFormat('MMM d, yyyy');
//             final timeFormat = DateFormat('h:mm a');
//             final duration = endTime.difference(startTime);

//             return DataRow(
//               cells: [
//                 DataCell(Text(dateFormat.format(date), style: const TextStyle(color: Colors.blue[900]))),
//                 DataCell(Text(timeFormat.format(startTime), style: const TextStyle(color: Colors.blue[900]))),
//                 DataCell(Text(timeFormat.format(endTime), style: const TextStyle(color: Colors.blue[900]))),
//                 DataCell(Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m', 
//                   style: const TextStyle(color: Colors.blue[900]))),
//                 DataCell(Text(notes, style: const TextStyle(color: Colors.blue[900]))),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }




// class ViewScheduleTab extends StatelessWidget {
//   final String? doctorId;

//   const ViewScheduleTab({super.key, this.doctorId});

//   void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red[800] : Colors.green[800],
//         duration: Duration(seconds: isError ? 3 : 2),
//       ),
//     );
//   }
//   Future<void> _loadUserData() async {
//     final doc = _auth.currentDoc;
//     if (doc == null) return;

//     setState(() => _isLoading = true);
//     try {
//       final doc= await _firestore.collection('doctors').doc(doctor.uid).get().sub._collection('schedules').doc(schedule.uid).get();
//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           _date;
//           _startTime;
//           _endTime;
//           _notes;
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading data: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }



//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules
//           .where('uid', isNotEqualTo: '') // Filter out empty uid if needed
//           .orderBy('date')
//           .snapshots(),
//       builder: (context, snapshot) {
//         // Handle errors
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'Error: ${snapshot.error.toString()}');
//           });
//           return _buildErrorWidget();
//         }

//         // Handle loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingIndicator();
//         }

//         // Handle empty data
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         // Filter documents where uid matches doctorId (if needed)
//         final filteredDocs = snapshot.data!.docs.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           return data['uid'] == doctorId; // Only include matching uid
//         }).toList();

//         if (filteredDocs.isEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _showSnackBar(context, 'No matching schedules found', isError: false);
//           });
//           return _buildEmptyStateWidget();
//         }

//         return _buildScheduleTable(filteredDocs);
//       },
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Text('Error loading data', 
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyStateWidget() {
//     return Center(
//       child: Text('No schedules available',
//         style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildScheduleTable(List<QueryDocumentSnapshot> docs) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.green[800],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       margin: const EdgeInsets.all(8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           headingRowColor: MaterialStateProperty.resolveWith<Color>(
//             (Set<MaterialState> states) => Colors.green[900]!,
//           ),
//           dataRowColor: MaterialStateProperty.resolveWith<Color>(
//             (Set<MaterialState> states) => Colors.green[700]!,
//           ),
//           columns: const [
//             DataColumn(
//               label: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//             DataColumn(
//               label: Text('Start Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//             DataColumn(
//               label: Text('End Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//             DataColumn(
//               label: Text('Duration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//             DataColumn(
//               label: Text('Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//           ],
//           rows: docs.map((document) {
//             final data = document.data() as Map<String, dynamic>;
//             final date = (data['date'] as Timestamp).toDate();
//             final startTime = (data['startTime'] as Timestamp).toDate();
//             final endTime = (data['endTime'] as Timestamp).toDate();
//             final notes = data['notes'] as String? ?? '';

//             final dateFormat = DateFormat('MMM d, yyyy');
//             final timeFormat = DateFormat('h:mm a');
//             final duration = endTime.difference(startTime);

//             return DataRow(
//               cells: [
//                 DataCell(Text(dateFormat.format(date), style: const TextStyle(color: Colors.white))),
//                 DataCell(Text(timeFormat.format(startTime), style: const TextStyle(color: Colors.white))),
//                 DataCell(Text(timeFormat.format(endTime), style: const TextStyle(color: Colors.white))),
//                 DataCell(Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m', 
//                   style: const TextStyle(color: Colors.white))),
//                 DataCell(Text(notes, style: const TextStyle(color: Colors.white))),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }




// class ViewScheduleTab extends StatelessWidget {
//   final String? doctorId; // Filter by doctor ID

//   const ViewScheduleTab({super.key, this.doctorId});

//   @override
//   Widget build(BuildContext context) {
//     // Reference to the doctor's schedules subcollection
//     CollectionReference schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(doctorId)
//         .collection('schedules');

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.where('uid', isEqualTo: doctorId).orderBy('date').snapshots(),//isnot equal are the separated uid
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return const Center(child: Text('Error loading schedules', style: TextStyle(color: Colors.white)));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
//         }

//         if (snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text('No schedules found for this doctor', style: TextStyle(color: Colors.white)));
//         }

//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.green[800],
//             borderRadius: BorderRadius.circular(10),
//           ),
//           margin: const EdgeInsets.all(8),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               headingRowColor: MaterialStateProperty.resolveWith<Color>(
//                 (Set<MaterialState> states) => Colors.green[900]!,
//               ),
//               dataRowColor: MaterialStateProperty.resolveWith<Color>(
//                 (Set<MaterialState> states) => Colors.green[700]!,
//               ),
//               columns: const [
//                 DataColumn(
//                   label: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//                 DataColumn(
//                   label: Text('Start Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//                 DataColumn(
//                   label: Text('End Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//                 DataColumn(
//                   label: Text('Duration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//                 DataColumn(
//                   label: Text('Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//               ],
//               rows: snapshot.data!.docs.map((document) {
//                 final data = document.data() as Map<String, dynamic>;
//                 final date = (data['date'] as Timestamp).toDate();
//                 final startTime = (data['startTime'] as Timestamp).toDate();
//                 final endTime = (data['endTime'] as Timestamp).toDate();
//                 final notes = data['notes'] as String? ?? '';

//                 final dateFormat = DateFormat('MMM d, yyyy');
//                 final timeFormat = DateFormat('h:mm a');
//                 final duration = endTime.difference(startTime);

//                 return DataRow(
//                   cells: [
//                     DataCell(Text(dateFormat.format(date), style: const TextStyle(color: Colors.white))),
//                     DataCell(Text(timeFormat.format(startTime), style: const TextStyle(color: Colors.white))),
//                     DataCell(Text(timeFormat.format(endTime), style: const TextStyle(color: Colors.white))),
//                     DataCell(Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m', 
//                       style: const TextStyle(color: Colors.white))),
//                     DataCell(Text(notes, style: const TextStyle(color: Colors.white))),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }







// class ViewScheduleTab extends StatelessWidget {
//   final String? doctorId; // Filter by doctor ID

//   const ViewScheduleTab({super.key, this.doctorId});

//   @override
//   Widget build(BuildContext context) {
//     // Reference to the doctor's schedules subcollection
//     CollectionReference schedules = FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(doctorId)
//         .collection('schedules');
       

//     return StreamBuilder<QuerySnapshot>(
//       stream: schedules.where('uid', isEqualTo: doctorId).orderBy('date').snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return const Center(child: Text('Error loading schedules'));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text('No schedules found for this doctor'));
//         }

//         return SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: DataTable(
//             columns: const [
//               DataColumn(label: Text('Date')),
//               DataColumn(label: Text('Start Time')),
//               DataColumn(label: Text('End Time')),
//               DataColumn(label: Text('Duration')),
//               DataColumn(label: Text('Notes')),
//             ],
//             rows: snapshot.data!.docs.map((document) {
//               final data = document.data() as Map<String, dynamic>;
//               final date = (data['date'] as Timestamp).toDate();
//               final startTime = (data['startTime'] as Timestamp).toDate();
//               final endTime = (data['endTime'] as Timestamp).toDate();
//               final notes = data['notes'] as String? ?? '';

//               final dateFormat = DateFormat('MMM d, yyyy');
//               final timeFormat = DateFormat('h:mm a');
//               final duration = endTime.difference(startTime);

//               return DataRow(
//                 cells: [
//                   DataCell(Text(dateFormat.format(date))),
//                   DataCell(Text(timeFormat.format(startTime))),
//                   DataCell(Text(timeFormat.format(endTime))),
//                   DataCell(Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m')),
//                   DataCell(Text(notes)),
//                 ],
//               );
//             }).toList(),
//           ),
//         );
//       },
//     );
//   }
// }























// class ViewScheduleTab extends StatelessWidget {
//   final String? docId; // Optional: filter by user

//   const ViewScheduleTab ({super.key, this.docId});

//   @override
//   Widget build(BuildContext context) {
//     // Reference to the Firestore collection
//     CollectionReference schedules = FirebaseFirestore.instance.collection('schedules');
    
//     // Apply user filter if provided
//     Query query = docId != null 
//         ? schedules.where('docId', isEqualTo: docId)
//         : schedules;

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.orderBy('date').snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return const Center(child: Text('Error loading schedules'));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text('No schedules found'));
//         }

//         return SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: DataTable(
//             columns: const [
//               DataColumn(label: Text('Date')),
//               DataColumn(label: Text('Start Time')),
//               DataColumn(label: Text('End Time')),
//               DataColumn(label: Text('Duration')),
//               DataColumn(label: Text('Notes')),
//             ],
//             rows: snapshot.data!.docs.map((document) {
//               final data = document.data() as Map<String, dynamic>;
//               final date = (data['date'] as Timestamp).toDate();
//               final startTime = (data['startTime'] as Timestamp).toDate();
//               final endTime = (data['endTime'] as Timestamp).toDate();
//               final notes = data['notes'] as String? ?? '';

//               final dateFormat = DateFormat('MMM d, yyyy');
//               final timeFormat = DateFormat('h:mm a');
//               final duration = endTime.difference(startTime);

//               return DataRow(
//                 cells: [
//                   DataCell(Text(dateFormat.format(date))),
//                   DataCell(Text(timeFormat.format(startTime))),
//                   DataCell(Text(timeFormat.format(endTime))),
//                   DataCell(Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m')),
//                   DataCell(Text(notes)),
//                 ],
//               );
//             }).toList(),
//           ),
//         );
//       },
//     );
//   }
// }





// class  ViewScheduleTab extends StatelessWidget {
//   const  ViewScheduleTab ({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Schedule management will be implemented here.'),
//     );
//   }
// }




// class ViewScheduleTab extends StatefulWidget {
//   const ViewScheduleTab({super.key});

//   @override
//   State<ViewScheduleTab> createState() => _ViewScheduleTabState();
// }

// class _ViewScheduleTabState extends State<ViewScheduleTab> {
//   late DateTime _focusedDay;
//   late DateTime _selectedDay;
//   late Map<DateTime, List<Map<String, dynamic>>> _events;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _focusedDay = DateTime.now();
//     _selectedDay = DateTime.now();
//     _events = {};
//     _fetchDoctorSchedules();
//   }

//   Future<void> _fetchDoctorSchedules() async {
//     try {
//       final User? user = _auth.currentUser;
//       if (user == null) return;

//       final querySnapshot = await _firestore
//           .collection('schedules')
//           .where('doctorId', isEqualTo: user.uid)
//           .get();

//       final Map<DateTime, List<Map<String, dynamic>>> events = {};
      
//       for (var doc in querySnapshot.docs) {
//         final data = doc.data();
//         final date = (data['date'] as Timestamp).toDate();
//         final startTime = (data['startTime'] as Timestamp).toDate();
//         final endTime = (data['endTime'] as Timestamp).toDate();
        
//         final dayStart = DateTime(date.year, date.month, date.day);
        
//         if (!events.containsKey(dayStart)) {
//           events[dayStart] = [];
//         }
        
//         events[dayStart]!.add({
//           'startTime': startTime,
//           'endTime': endTime,
//           'notes': data['notes'] ?? '',
//         });
//       }

//       setState(() {
//         _events = events;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching schedules: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
//     final dayStart = DateTime(day.year, day.month, day.day);
//     return _events[dayStart] ?? [];
//   }

//   Color _getTimeSlotColor(DateTime startTime, DateTime endTime) {
//     final hour = startTime.hour;
//     final duration = endTime.difference(startTime).inHours;
    
//     // Different colors based on time of day
//     if (hour < 12) {
//       return Colors.blue.withOpacity(0.6 - (0.1 * duration)); // Morning
//     } else if (hour < 17) {
//       return Colors.green.withOpacity(0.6 - (0.1 * duration)); // Afternoon
//     } else {
//       return Colors.orange.withOpacity(0.6 - (0.1 * duration)); // Evening
//     }
//   }

//   Color _getDayColor(DateTime date) {
//     switch (date.weekday) {
//       case DateTime.saturday:
//       case DateTime.sunday:
//         return Colors.red[100]!; // Weekend color
//       default:
//         return Colors.grey[50]!; // Weekday color
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctor Schedule Calendar'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 TableCalendar(
//                   firstDay: DateTime.utc(2025, 1, 1),
//                   lastDay: DateTime.utc(2025, 12, 31),
//                   focusedDay: _focusedDay,
//                   selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                   onDaySelected: (selectedDay, focusedDay) {
//                     setState(() {
//                       _selectedDay = selectedDay;
//                       _focusedDay = focusedDay;
//                     });
//                   },
//                   eventLoader: _getEventsForDay,
//                   calendarStyle: CalendarStyle(
//                     defaultDecoration: BoxDecoration(
//                       color: _getDayColor(_focusedDay),
//                       shape: BoxShape.rectangle,
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     weekendDecoration: BoxDecoration(
//                       color: _getDayColor(_focusedDay),
//                       shape: BoxShape.rectangle,
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     markerDecoration: BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     todayDecoration: BoxDecoration(
//                       color: Colors.amber[200],
//                       shape: BoxShape.rectangle,
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     selectedDecoration: BoxDecoration(
//                       color: Colors.blue[300],
//                       shape: BoxShape.rectangle,
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     markersAlignment: Alignment.bottomRight,
//                     markersMaxCount: 3,
//                   ),
//                   headerStyle: HeaderStyle(
//                     formatButtonVisible: false,
//                     titleCentered: true,
//                   ),
//                   calendarBuilders: CalendarBuilders(
//                     defaultBuilder: (context, day, focusedDay) {
//                       return Container(
//                         margin: const EdgeInsets.all(4.0),
//                         decoration: BoxDecoration(
//                           color: _getDayColor(day),
//                           borderRadius: BorderRadius.circular(5.0),
//                         ),
//                         child: Center(
//                           child: Text(
//                             '${day.day}',
//                             style: TextStyle(
//                               color: day.weekday == DateTime.saturday || day.weekday == DateTime.sunday
//                                   ? Colors.red
//                                   : Colors.black,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 8.0),
//                 Expanded(
//                   child: ListView(
//                     children: _getEventsForDay(_selectedDay).map((event) {
//                       final start = event['startTime'] as DateTime;
//                       final end = event['endTime'] as DateTime;
//                       final timeColor = _getTimeSlotColor(start, end);
//                       final duration = end.difference(start).inHours;
                      
//                       return Card(
//                         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                         color: timeColor,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                         ),
//                         child: ListTile(
//                           title: Text(
//                             '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                           subtitle: event['notes'].isNotEmpty
//                               ? Text(
//                                   event['notes'],
//                                   style: TextStyle(color: Colors.grey[700]),
//                                 )
//                               : null,
//                           trailing: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 DateFormat('MMM d, y').format(_selectedDay),
//                                 style: TextStyle(color: Colors.grey[600]),
//                               ),
//                               Text(
//                                 '${duration}h',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.grey[700],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }

















// class ViewScheduleTab extends StatefulWidget {
//   const ViewScheduleTab ({super.key});

//   @override
//   State<ViewScheduleTab> createState() => _ViewScheduleTabState();
// }

// class _ViewScheduleTabState extends State<ViewScheduleTab> {
//   late DateTime _focusedDay;
//   late DateTime _selectedDay;
//   late Map<DateTime, List<Map<String, dynamic>>> _events;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _focusedDay = DateTime.now();
//     _selectedDay = DateTime.now();
//     _events = {};
//     _fetchDoctorSchedules();
//   }

//   Future<void> _fetchDoctorSchedules() async {
//     try {
//       final User? user = _auth.currentUser;
//       if (user == null) return;

//       final querySnapshot = await _firestore
//           .collection('schedules')
//           .where('doctorId', isEqualTo: user.uid)
//           .get();

//       final Map<DateTime, List<Map<String, dynamic>>> events = {};
      
//       for (var doc in querySnapshot.docs) {
//         final data = doc.data();
//         final date = (data['date'] as Timestamp).toDate();
//         final startTime = (data['startTime'] as Timestamp).toDate();
//         final endTime = (data['endTime'] as Timestamp).toDate();
        
//         final dayStart = DateTime(date.year, date.month, date.day);
        
//         if (!events.containsKey(dayStart)) {
//           events[dayStart] = [];
//         }
        
//         events[dayStart]!.add({
//           'startTime': startTime,
//           'endTime': endTime,
//           'notes': data['notes'] ?? '',
//         });
//       }

//       setState(() {
//         _events = events;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching schedules: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
//     final dayStart = DateTime(day.year, day.month, day.day);
//     return _events[dayStart] ?? [];
//   }

//   Color _getTimeSlotColor(TimeOfDay time) {
//     final hour = time.hour;
//     if (hour < 12) return Colors.blue[200]!; // Morning - light blue
//     if (hour < 17) return Colors.green[200]!; // Afternoon - light green
//     return Colors.orange[200]!; // Evening - light orange
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctor Schedule Calendar'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 TableCalendar(
//                   firstDay: DateTime.utc(2025, 1, 1),
//                   lastDay: DateTime.utc(2025, 12, 31),
//                   focusedDay: _focusedDay,
//                   selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                   onDaySelected: (selectedDay, focusedDay) {
//                     setState(() {
//                       _selectedDay = selectedDay;
//                       _focusedDay = focusedDay;
//                     });
//                   },
//                   eventLoader: _getEventsForDay,
//                   calendarStyle: CalendarStyle(
//                     markerDecoration: BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     todayDecoration: BoxDecoration(
//                       color: Colors.amber,
//                       shape: BoxShape.circle,
//                     ),
//                     selectedDecoration: BoxDecoration(
//                       color: Colors.blue,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   headerStyle: HeaderStyle(
//                     formatButtonVisible: false,
//                     titleCentered: true,
//                   ),
//                 ),
//                 const SizedBox(height: 8.0),
//                 Expanded(
//                   child: ListView(
//                     children: _getEventsForDay(_selectedDay).map((event) {
//                       final start = event['startTime'] as DateTime;
//                       final end = event['endTime'] as DateTime;
//                       final timeColor = _getTimeSlotColor(TimeOfDay.fromDateTime(start));
                      
//                       return Card(
//                         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                         color: timeColor.withOpacity(0.3),
//                         child: ListTile(
//                           title: Text(
//                             '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}',
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: event['notes'].isNotEmpty
//                               ? Text(event['notes'])
//                               : null,
//                           trailing: Text(
//                             DateFormat('MMM d, y').format(_selectedDay),
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }









// import 'package:flutter/material.dart';

// class DoctorScreen extends StatelessWidget {
//   const DoctorScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctor Dashboard'),
//       ),
//       body: const Center(
//         child: Text(
//           'Welcome, Doctor!',
//           style: TextStyle(fontSize: 24),
//         ),
//       ),
//     );
//   }
// }
