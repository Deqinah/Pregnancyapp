import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Booking_screen.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class DoctorlistScreen extends StatefulWidget {
  const DoctorlistScreen({super.key});

  @override
  State<DoctorlistScreen> createState() => _DoctorlistScreenState();
}

class _DoctorlistScreenState extends State<DoctorlistScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late DateTime today;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
  }

  Future<Map<String, Set<String>>> _getBusySchedules() async {
    final appointments = await _firestore.collection('appointments')
        .where('status', isEqualTo: 'pending')
        .get();
    
    final busySchedules = <String, Set<String>>{};
    
    for (final doc in appointments.docs) {
      final doctorId = doc['doctorId'] as String?;
      final scheduleId = doc['scheduleId'] as String?;
      
      if (doctorId != null && scheduleId != null) {
        if (!busySchedules.containsKey(doctorId)) {
          busySchedules[doctorId] = <String>{};
        }
        busySchedules[doctorId]!.add(scheduleId);
      }
    }
    
    return busySchedules;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, Set<String>>>(
        future: _getBusySchedules(),
        builder: (context, busySchedulesSnapshot) {
          if (busySchedulesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (busySchedulesSnapshot.hasError) {
            return Center(child: Text('Error loading schedules: ${busySchedulesSnapshot.error}'));
          }
          
          final busySchedules = busySchedulesSnapshot.data ?? {};
          
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
            builder: (context, doctorsSnapshot) {
              if (doctorsSnapshot.hasError) {
                return Center(child: Text('Error loading doctors: ${doctorsSnapshot.error}'));
              }

              if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No approved doctors available'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: doctorsSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doctor = doctorsSnapshot.data!.docs[index];
                  return DoctorCard(
                    doctorId: doctor.id,
                    doctorData: doctor.data() as Map<String, dynamic>,
                    today: today,
                    busyScheduleIds: busySchedules[doctor.id] ?? {},
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

class DoctorCard extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;
  final DateTime today;
  final Set<String> busyScheduleIds;

  const DoctorCard({
    super.key,
    required this.doctorId,
    required this.doctorData,
    required this.today,
    required this.busyScheduleIds,
  });

  double _calculateFee() {
    final experience = doctorData['experience'] ?? 0;
    return 0.01;
  }

  int _calculateStars() {
    final points = doctorData['ratingPoints'] ?? 0;
    if (points <= 3) return 1;
    if (points <= 7) return 2;
    if (points <= 10) return 3;
    if (points <= 14) return 4;
    return 5;
  }

  Widget _buildRatingStars() {
    final stars = _calculateStars();
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  String _formatScheduleTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Time not specified';
    try {
      final time = timestamp.toDate();
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return 'Invalid time';
    }
  }

  Future<void> _showScheduleDialog(BuildContext context) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('schedules')
          .get();

      if (querySnapshot.docs.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(doctorData['fullName'] ?? 'Doctor'),
            content: const Text('This doctor has no available schedules.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
        return;
      }

      // Group available schedules by day name
      final availableSchedules = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        if (!busyScheduleIds.contains(doc.id)) {
          availableSchedules.add({
            ...doc.data(),
            'id': doc.id,
          });
        }
      }

      if (availableSchedules.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(doctorData['fullName'] ?? 'Doctor'),
            content: const Text('All schedules for this doctor are currently booked.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
        return;
      }

      // Group by day
      final scheduleGroups = <String, List<Map<String, dynamic>>>{};
      
      for (final schedule in availableSchedules) {
        final dayName = schedule['day'] as String? ?? 'Unknown Day';
        final startTime = schedule['startTime'] as Timestamp?;
        final endTime = schedule['endTime'] as Timestamp?;
        final address = schedule['address'] as String?;
        final scheduleId = schedule['id'] as String;

        if (startTime != null && endTime != null) {
          final scheduleEntry = {
            'startTime': startTime,
            'endTime': endTime,
            'address': address,
            'id': scheduleId,
          };

          if (scheduleGroups.containsKey(dayName)) {
            scheduleGroups[dayName]!.add(scheduleEntry);
          } else {
            scheduleGroups[dayName] = [scheduleEntry];
          }
        }
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('${doctorData['fullName']}\'s Available Schedules'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: scheduleGroups.entries.map((entry) {
                  final dayName = entry.key;
                  final schedules = entry.value;
return Card(
  margin: const EdgeInsets.symmetric(vertical: 8),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
         // kala fogeyn u dhaxaysa dayName iyo schedules
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: schedules.map((schedule) {
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      '${_formatScheduleTime(schedule['startTime'])} - ${_formatScheduleTime(schedule['endTime'])}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    subtitle: schedule['address'] != null
                        ? Text(schedule['address'] as String)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _handleBookNow(context);
                    },
                  ),
                  if (schedules.last != schedule)
                    const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ),
  ),
);

                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error showing schedule dialog: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load schedules: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  void _handleBookNow(BuildContext context) {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          doctorId: doctorId,
          doctorData: doctorData,
          scheduleId: busyScheduleIds.isNotEmpty ? busyScheduleIds.first : '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    doctorData['fullName']?.isNotEmpty == true 
                        ? (doctorData['fullName'] as String)[0] 
                        : 'D',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorData['fullName'] ?? 'Doctor Name',
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Specialty: ${doctorData['specialties'] ?? 'General'}',
                        style: TextStyle(
                          fontSize: 14, 
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doctorData['experience'] ?? 0} years experience',
                        style: TextStyle(
                          fontSize: 14, 
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRatingStars(),
                          const SizedBox(width: 4),
                          Text(
                            '${_calculateStars()}.0',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            'Fee: \$${_calculateFee()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _showScheduleDialog(context),
                  child: const Text(
                    'View Schedule',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handleBookNow(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'Booking_screen.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class DoctorlistScreen extends StatefulWidget {
//   const DoctorlistScreen({super.key});

//   @override
//   State<DoctorlistScreen> createState() => _DoctorlistScreenState();
// }

// class _DoctorlistScreenState extends State<DoctorlistScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late DateTime today;

//   @override
//   void initState() {
//     super.initState();
//     tz.initializeTimeZones();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//   }

//   Future<Map<String, Set<String>>> _getBusySchedules() async {
//     final appointments = await _firestore.collection('appointments')
//         .where('status', isEqualTo: 'pending')
//         .get();
    
//     final busySchedules = <String, Set<String>>{};
    
//     for (final doc in appointments.docs) {
//       final doctorId = doc['doctorId'] as String?;
//       final scheduleId = doc['scheduleId'] as String?;
      
//       if (doctorId != null && scheduleId != null) {
//         if (!busySchedules.containsKey(doctorId)) {
//           busySchedules[doctorId] = <String>{};
//         }
//         busySchedules[doctorId]!.add(scheduleId);
//       }
//     }
    
//     return busySchedules;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: FutureBuilder<Map<String, Set<String>>>(
//         future: _getBusySchedules(),
//         builder: (context, busySchedulesSnapshot) {
//           if (busySchedulesSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (busySchedulesSnapshot.hasError) {
//             return Center(child: Text('Error loading schedules: ${busySchedulesSnapshot.error}'));
//           }
          
//           final busySchedules = busySchedulesSnapshot.data ?? {};
          
//           return StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//             builder: (context, doctorsSnapshot) {
//               if (doctorsSnapshot.hasError) {
//                 return Center(child: Text('Error loading doctors: ${doctorsSnapshot.error}'));
//               }

//               if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//                 return const Center(child: Text('No approved doctors available'));
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: doctorsSnapshot.data!.docs.length,
//                 itemBuilder: (context, index) {
//                   final doctor = doctorsSnapshot.data!.docs[index];
//                   return DoctorCard(
//                     doctorId: doctor.id,
//                     doctorData: doctor.data() as Map<String, dynamic>,
//                     today: today,
//                     busyScheduleIds: busySchedules[doctor.id] ?? {},
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

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   final DateTime today;
//   final Set<String> busyScheduleIds;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//     required this.today,
//     required this.busyScheduleIds,
//   });

//   double _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     return 0.01;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       final time = timestamp.toDate();
//       return DateFormat('h:mm a').format(time);
//     } catch (e) {
//       debugPrint('Error formatting time: $e');
//       return 'Invalid time';
//     }
//   }

//   Future<void> _showScheduleDialog(BuildContext context) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctorId)
//           .collection('schedules')
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no available schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       // Group available schedules by day name
//       final availableSchedules = <Map<String, dynamic>>[];
      
//       for (final doc in querySnapshot.docs) {
//         if (!busyScheduleIds.contains(doc.id)) {
//           availableSchedules.add({
//             ...doc.data(),
//             'id': doc.id,
//           });
//         }
//       }

//       if (availableSchedules.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('All schedules for this doctor are currently booked.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       // Group by day
//       final scheduleGroups = <String, List<Map<String, dynamic>>>{};
      
//       for (final schedule in availableSchedules) {
//         final dayName = schedule['day'] as String? ?? 'Unknown Day';
//         final startTime = schedule['startTime'] as Timestamp?;
//         final endTime = schedule['endTime'] as Timestamp?;
//         final address = schedule['address'] as String?;
//         final scheduleId = schedule['id'] as String;

//         if (startTime != null && endTime != null) {
//           final scheduleEntry = {
//             'startTime': startTime,
//             'endTime': endTime,
//             'address': address,
//             'id': scheduleId,
//           };

//           if (scheduleGroups.containsKey(dayName)) {
//             scheduleGroups[dayName]!.add(scheduleEntry);
//           } else {
//             scheduleGroups[dayName] = [scheduleEntry];
//           }
//         }
//       }

//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text('${doctorData['fullName']}\'s Available Schedules'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: scheduleGroups.entries.map((entry) {
//                   final dayName = entry.key;
//                   final schedules = entry.value;

//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             dayName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           ...schedules.map((schedule) {
//                             return Column(
//                               children: [
//                                 ListTile(
//                                   title: Text(
//                                     '${_formatScheduleTime(schedule['startTime'])} - ${_formatScheduleTime(schedule['endTime'])}',
//                                     style: const TextStyle(fontSize: 15),
//                                   ),
//                                   subtitle: schedule['address'] != null 
//                                       ? Text(schedule['address'] as String)
//                                       : null,
//                                   onTap: () {
//                                     Navigator.pop(context);
//                                     _handleBookNow(context, schedule['id']);
//                                   },
//                                 ),
//                                 if (schedules.last != schedule)
//                                   const Divider(height: 1),
//                               ],
//                             );
//                           }).toList(),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             )
//           ],
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error showing schedule dialog: $e');
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to load schedules: ${e.toString()}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//     }
//   }

//   void _handleBookNow(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BookingScreen(
//           doctorId: doctorId,
//           doctorData: doctorData,
//           scheduleId: scheduleId,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? (doctorData['fullName'] as String)[0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }












// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'Booking_screen.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class DoctorlistScreen extends StatefulWidget {
//   const DoctorlistScreen({super.key});

//   @override
//   State<DoctorlistScreen> createState() => _DoctorlistScreenState();
// }

// class _DoctorlistScreenState extends State<DoctorlistScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late DateTime today;

//   @override
//   void initState() {
//     super.initState();
//     tz.initializeTimeZones();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${doctorsSnapshot.error}'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           return StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection('appointments')
//                 .where('status', isEqualTo: 'pending')
//                 .snapshots(),
//             builder: (context, appointmentsSnapshot) {
//               if (appointmentsSnapshot.hasError) {
//                 return Center(child: Text('Error loading appointments: ${appointmentsSnapshot.error}'));
//               }

//               final busyDoctorIds = appointmentsSnapshot.hasData
//                   ? appointmentsSnapshot.data!.docs
//                       .map((doc) => doc['doctorId'] as String?)
//                       .where((id) => id != null)
//                       .toSet()
//                   : <String>{};

//               final availableDoctors = doctorsSnapshot.data!.docs
//                   .where((doctor) => !busyDoctorIds.contains(doctor.id))
//                   .toList();

//               if (availableDoctors.isEmpty) {
//                 return const Center(
//                   child: Text('All doctors are currently busy with pending appointments'),
//                 );
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: availableDoctors.length,
//                 itemBuilder: (context, index) {
//                   final doctor = availableDoctors[index];
//                   return DoctorCard(
//                     doctorId: doctor.id,
//                     doctorData: doctor.data() as Map<String, dynamic>,
//                     today: today,
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

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   final DateTime today;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//     required this.today,
//   });

//   double _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     return 0.01;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       final time = timestamp.toDate();
//       return DateFormat('h:mm a').format(time);
//     } catch (e) {
//       debugPrint('Error formatting time: $e');
//       return 'Invalid time';
//     }
//   }

//   Future<void> _showScheduleDialog(BuildContext context) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctorId)
//           .collection('schedules')
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no available schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       // Group schedules by day name
//       final scheduleGroups = <String, List<Map<String, dynamic>>>{};
      
//       for (final doc in querySnapshot.docs) {
//         final schedule = doc.data();
//         final dayName = schedule['day'] as String? ?? 'Unknown Day';
//         final startTime = schedule['startTime'] as Timestamp?;
//         final endTime = schedule['endTime'] as Timestamp?;
//         final address = schedule['address'] as String?;

//         if (startTime != null && endTime != null) {
//           final scheduleEntry = {
//             'startTime': startTime,
//             'endTime': endTime,
//             'address': address,
//           };

//           if (scheduleGroups.containsKey(dayName)) {
//             scheduleGroups[dayName]!.add(scheduleEntry);
//           } else {
//             scheduleGroups[dayName] = [scheduleEntry];
//           }
//         }
//       }

//       if (scheduleGroups.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no valid schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text('${doctorData['fullName']}\'s Available Schedules'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: scheduleGroups.entries.map((entry) {
//                   final dayName = entry.key;
//                   final schedules = entry.value;

//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             dayName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           ...schedules.map((schedule) {
//                             return Column(
//                               children: [
//                                 Text(
//                                   '${_formatScheduleTime(schedule['startTime'])} - ${_formatScheduleTime(schedule['endTime'])}',
//                                   style: const TextStyle(fontSize: 15),
//                                 ),
//                                 if (schedule['address'] != null && (schedule['address'] as String).isNotEmpty)
//                                   Padding(
//                                     padding: const EdgeInsets.only(top: 4),
//                                     child: Row(
//                                       children: [
//                                         const Icon(Icons.location_on, size: 16),
//                                         const SizedBox(width: 4),
//                                         Flexible(child: Text(schedule['address'] as String)),
//                                       ],
//                                     ),
//                                   ),
//                                 if (schedules.last != schedule)
//                                   const Divider(height: 16),
//                               ],
//                             );
//                           }).toList(),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             )
//           ],
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error showing schedule dialog: $e');
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to load schedules: ${e.toString()}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//     }
//   }

//   void _handleBookNow(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BookingScreen(
//           doctorId: doctorId,
//           doctorData: doctorData,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? (doctorData['fullName'] as String)[0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }












// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'Booking_screen.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class DoctorlistScreen extends StatefulWidget {
//   const DoctorlistScreen({super.key});

//   @override
//   State<DoctorlistScreen> createState() => _DoctorlistScreenState();
// }

// class _DoctorlistScreenState extends State<DoctorlistScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late DateTime today;

//   @override
//   void initState() {
//     super.initState();
//     tz.initializeTimeZones();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${doctorsSnapshot.error}'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           return StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection('appointments')
//                 .where('status', isEqualTo: 'pending')
//                 .snapshots(),
//             builder: (context, appointmentsSnapshot) {
//               if (appointmentsSnapshot.hasError) {
//                 return Center(child: Text('Error loading appointments: ${appointmentsSnapshot.error}'));
//               }

//               final busyDoctorIds = appointmentsSnapshot.hasData
//                   ? appointmentsSnapshot.data!.docs
//                       .map((doc) => doc['doctorId'] as String?)
//                       .where((id) => id != null)
//                       .toSet()
//                   : <String>{};

//               final availableDoctors = doctorsSnapshot.data!.docs
//                   .where((doctor) => !busyDoctorIds.contains(doctor.id))
//                   .toList();

//               if (availableDoctors.isEmpty) {
//                 return const Center(
//                   child: Text('All doctors are currently busy with pending appointments'),
//                 );
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: availableDoctors.length,
//                 itemBuilder: (context, index) {
//                   final doctor = availableDoctors[index];
//                   return DoctorCard(
//                     doctorId: doctor.id,
//                     doctorData: doctor.data() as Map<String, dynamic>,
//                     today: today,
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

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   final DateTime today;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//     required this.today,
//   });

//   double _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     return 0.01;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleDay(DateTime day) {
//     return DateFormat('EEEE').format(day); // Shows full weekday name (e.g., "Monday")
//   }

//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       final time = timestamp.toDate();
//       return DateFormat('h:mm a').format(time);
//     } catch (e) {
//       debugPrint('Error formatting time: $e');
//       return 'Invalid time';
//     }
//   }

//   Future<void> _showScheduleDialog(BuildContext context) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctorId)
//           .collection('schedules')
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no available schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       // Convert schedules to DateTime and filter out past schedules
//       final validSchedules = querySnapshot.docs.map((doc) {
//         final schedule = doc.data();
//         return {
//           'day': schedule['day'],
//           'startTime': schedule['startTime'],
//           'endTime': schedule['endTime'],
//         };
//       }).where((schedule) {
//         return schedule['day'].isAfter(today) || 
//                schedule['day'].day == today.day;
//       }).toList();

//       if (validSchedules.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no upcoming schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text('${doctorData['fullName']}\'s Available Schedules'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: validSchedules.map((schedule) {
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _formatScheduleDay(schedule['day']),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '${_formatScheduleTime(schedule['startTime'] as Timestamp?)} - ${_formatScheduleTime(schedule['endTime'] as Timestamp?)}',
//                             style: const TextStyle(fontSize: 15),
//                           ),
//                           if (schedule['address'] != null && (schedule['address'] as String).isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 8),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.location_on, size: 16),
//                                   const SizedBox(width: 4),
//                                   Flexible(child: Text(schedule['address'] as String)),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             )
//           ],
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error showing schedule dialog: $e');
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to load schedules: ${e.toString()}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//     }
//   }

//   void _handleBookNow(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BookingScreen(
//           doctorId: doctorId,
//           doctorData: doctorData,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? (doctorData['fullName'] as String)[0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'Booking_screen.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class DoctorlistScreen extends StatefulWidget {
//   const DoctorlistScreen({super.key});

//   @override
//   State<DoctorlistScreen> createState() => _DoctorlistScreenState();
// }

// class _DoctorlistScreenState extends State<DoctorlistScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late DateTime today;

//   @override
//   void initState() {
//     super.initState();
//     tz.initializeTimeZones();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${doctorsSnapshot.error}'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           return StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection('appointments')
//                 .where('status', isEqualTo: 'pending')
//                 .snapshots(),
//             builder: (context, appointmentsSnapshot) {
//               if (appointmentsSnapshot.hasError) {
//                 return Center(child: Text('Error loading appointments: ${appointmentsSnapshot.error}'));
//               }

//               // Get list of doctor IDs with pending appointments
//               final busyDoctorIds = appointmentsSnapshot.hasData
//                   ? appointmentsSnapshot.data!.docs
//                       .map((doc) => doc['doctorId'] as String?)
//                       .where((id) => id != null)
//                       .toSet()
//                   : <String>{};

//               // Filter doctors to exclude those with pending appointments
//               final availableDoctors = doctorsSnapshot.data!.docs
//                   .where((doctor) => !busyDoctorIds.contains(doctor.id))
//                   .toList();

//               if (availableDoctors.isEmpty) {
//                 return const Center(
//                   child: Text('All doctors are currently busy with pending appointments'),
//                 );
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: availableDoctors.length,
//                 itemBuilder: (context, index) {
//                   final doctor = availableDoctors[index];
//                   return DoctorCard(
//                     doctorId: doctor.id,
//                     doctorData: doctor.data() as Map<String, dynamic>,
//                     today: today,
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

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   final DateTime today;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//     required this.today,
//   });

//   double _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     return 0.01;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   // String _formatScheduleDate(Timestamp? timestamp) {
//   //   if (timestamp == null) return 'Date not specified';
//   //   try {
//   //     final date = timestamp.toDate();
//   //     return DateFormat('EEE, MMM d, y').format(date);
//   //   } catch (e) {
//   //     debugPrint('Error formatting date: $e');
//   //     return 'Invalid date';
//   //   }
//   // }
//   String _formatScheduleDay(Timestamp? timestamp) {
//   if (timestamp == null) return 'Day not specified';
//   try {
//     final date = timestamp.toDate();
//     return DateFormat('EEEE').format(date); // EEEE shows full weekday name
//   } catch (e) {
//     debugPrint('Error formatting day: $e');
//     return 'Invalid day';
//   }
// }


//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       final time = timestamp.toDate();
//       return DateFormat('h:mm a').format(time);
//     } catch (e) {
//       debugPrint('Error formatting time: $e');
//       return 'Invalid time';
//     }
//   }

//   Future<void> _showScheduleDialog(BuildContext context) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctorId)
//           .collection('schedules')
//         .where('day', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
//     // .orderBy('day')
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no available schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       // Filter out past schedules
//       // final validSchedules = querySnapshot.docs.where((doc) {
//       //   final schedule = doc.data();
//       //   final scheduleDate = (schedule['date'] as Timestamp).toDate();
//       //   return scheduleDate.isAfter(today) || 
//       //          scheduleDate == today;
//       // }).toList();
//       final validSchedules = querySnapshot.docs.where((doc) {
//   final schedule = doc.data();
//   final scheduleDay = (schedule['day'] as Timestamp).toDate();
//   return scheduleDay.isAfter(today) || scheduleDay == today;
// }).toList();


//       if (validSchedules.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no upcoming schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text('${doctorData['fullName']}\'s Available Schedules'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: validSchedules.map((doc) {
//                   final schedule = doc.data();
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _formatScheduleDay(schedule['day'] as Timestamp?),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '${_formatScheduleTime(schedule['startTime'] as Timestamp?)} - ${_formatScheduleTime(schedule['endTime'] as Timestamp?)}',
//                             style: const TextStyle(fontSize: 15),
//                           ),
//                           if (schedule['address'] != null && (schedule['address'] as String).isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 8),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.location_on, size: 16),
//                                   const SizedBox(width: 4),
//                                   Flexible(child: Text(schedule['address'] as String)),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             )
//           ],
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error showing schedule dialog: $e');
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to load schedules: ${e.toString()}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//     }
//   }

//   void _handleBookNow(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BookingScreen(
//           doctorId: doctorId,
//           doctorData: doctorData,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? (doctorData['fullName'] as String)[0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'Booking_screen.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class DoctorlistScreen extends StatefulWidget {
//   const DoctorlistScreen({super.key});

//   @override
//   State<DoctorlistScreen> createState() => _DoctorlistScreenState();
// }

// class _DoctorlistScreenState extends State<DoctorlistScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late DateTime today;

//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${doctorsSnapshot.error}'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           return StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection('appointments')
//                 .where('status', isEqualTo: 'pending')
//                 .snapshots(),
//             builder: (context, appointmentsSnapshot) {
//               if (appointmentsSnapshot.hasError) {
//                 return Center(child: Text('Error loading appointments: ${appointmentsSnapshot.error}'));
//               }

//               // Get list of doctor IDs with pending appointments
//               final busyDoctorIds = appointmentsSnapshot.hasData
//                   ? appointmentsSnapshot.data!.docs
//                       .map((doc) => doc['doctorId'] as String?)
//                       .where((id) => id != null)
//                       .toSet()
//                   : <String>{};

//               // Filter doctors to exclude those with pending appointments
//               final availableDoctors = doctorsSnapshot.data!.docs
//                   .where((doctor) => !busyDoctorIds.contains(doctor.id))
//                   .toList();

//               if (availableDoctors.isEmpty) {
//                 return const Center(
//                   child: Text('All doctors are currently busy with pending appointments'),
//                 );
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: availableDoctors.length,
//                 itemBuilder: (context, index) {
//                   final doctor = availableDoctors[index];
//                   return DoctorCard(
//                     doctorId: doctor.id,
//                     doctorData: doctor.data() as Map<String, dynamic>,
//                     today: today,
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

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   final DateTime today;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//     required this.today,
//   });

//   int _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     return 1;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'Date not specified';
//     try {
//       return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid date';
//     }
//   }

//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       return DateFormat('h:mm a').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid time';
//     }
//   }

//   Future<void> _showScheduleDialog(BuildContext context) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctorId)
//           .collection('schedules')
//           .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no available schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text('${doctorData['fullName']}\'s Available Schedules'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: querySnapshot.docs.map((doc) {
//                   final schedule = doc.data();
//                   final scheduleDate = (schedule['date'] as Timestamp).toDate();
                  
//                   if (scheduleDate.isBefore(today)) {
//                     return const SizedBox.shrink();
//                   }
                  
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _formatScheduleDate(schedule['date'] as Timestamp?),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '${_formatScheduleTime(schedule['startTime'] as Timestamp?)} - ${_formatScheduleTime(schedule['endTime'] as Timestamp?)}',
//                             style: const TextStyle(fontSize: 15),
//                           ),
//                           if (schedule['address'] != null && schedule['address'].isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 8),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.location_on, size: 16),
//                                   const SizedBox(width: 4),
//                                   Flexible(child: Text(schedule['address'])),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             )
//           ],
//         ),
//       );
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to load schedules: ${e.toString()}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//     }
//   }

//   void _handleBookNow(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BookingScreen(
//           doctorId: doctorId,
//           doctorData: doctorData,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'Booking_screen.dart';

// class DoctorlistScreen extends StatefulWidget {
//   const DoctorlistScreen({super.key});

//   @override
//   State<DoctorlistScreen> createState() => _DoctorlistScreenState();
// }

// class _DoctorlistScreenState extends State<DoctorlistScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late DateTime today;

//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//          collection('appointments').where('status', isEqualTo: 'pending').snapshots(),//hidden doctor      in same time  hal doctor 2patient booking gareesan karin
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doctor = snapshot.data!.docs[index];
//               return DoctorCard(
//                 doctorId: doctor.id,
//                 doctorData: doctor.data() as Map<String, dynamic>,
//                 today: today,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   final DateTime today;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//     required this.today,
//   });

//   int _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     return 1;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'Date not specified';
//     try {
//       return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid date';
//     }
//   }

//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       return DateFormat('h:mm a').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid time';
//     }
//   }

//   Future<void> _showScheduleDialog(BuildContext context) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctorId)
//           .collection('schedules')
//           .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
//           // .orderBy('date', descending: false)
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no available schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text('${doctorData['fullName']}\'s Available Schedules'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: querySnapshot.docs.map((doc) {
//                   final schedule = doc.data();
//                   final scheduleDate = (schedule['date'] as Timestamp).toDate();
                  
//                   if (scheduleDate.isBefore(today)) {
//                     return const SizedBox.shrink();
//                   }
                  
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _formatScheduleDate(schedule['date'] as Timestamp?),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '${_formatScheduleTime(schedule['startTime'] as Timestamp?)} - ${_formatScheduleTime(schedule['endTime'] as Timestamp?)}',
//                             style: const TextStyle(fontSize: 15),
//                           ),
//                           if (schedule['address'] != null && schedule['address'].isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 8),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.location_on, size: 16),
//                                   const SizedBox(width: 4),
//                                   Flexible(child: Text(schedule['address'])),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             )
//           ],
//         ),
//       );
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to load schedules: ${e.toString()}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//     }
//   }

//   void _handleBookNow(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BookingScreen(
//           doctorId: doctorId,
//           doctorData: doctorData,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'Booking_screen.dart';

// class DoctorlistScreen extends StatefulWidget {
//   const DoctorlistScreen({super.key});

//   @override
//   State<DoctorlistScreen> createState() => _DoctorlistScreenState();
// }

// class _DoctorlistScreenState extends State<DoctorlistScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doctor = snapshot.data!.docs[index];
//               return DoctorCard(
//                 doctorId: doctor.id,
//                 doctorData: doctor.data() as Map<String, dynamic>,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//   });

//   int _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     // if (experience >= 1 && experience <= 4) return 50;
//     // if (experience >= 5 && experience <= 7) return 150;
//     return 10;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'Date not specified';
//     try {
//       return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid date';
//     }
//   }

//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       return DateFormat('h:mm a').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid time';
//     }
//   }

// Future<void> _showScheduleDialog(BuildContext context) async {
//   try {
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(doctorId)
//         .collection('schedules')
//         .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
//         .orderBy('date', descending: false) // Sort by date ascending
//         .get();

//     if (querySnapshot.docs.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text(doctorData['fullName'] ?? 'Doctor'),
//           content: const Text('This doctor has no available schedules.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('${doctorData['fullName']}\'s Available Schedules'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: querySnapshot.docs.map((doc) {
//                 final schedule = doc.data();
//                 final scheduleDate = (schedule['date'] as Timestamp).toDate();
                
//                 // Only show dates that are today or in the future
//                 if (scheduleDate.isBefore(today)) {
//                   return const SizedBox.shrink();
//                 }
                
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _formatScheduleDate(schedule['date'] as Timestamp?),
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           '${_formatScheduleTime(schedule['startTime'] as Timestamp?)} - ${_formatScheduleTime(schedule['endTime'] as Timestamp?)}',
//                           style: const TextStyle(fontSize: 15),
//                         ),
//                         if (schedule['address'] != null && schedule['address'].isNotEmpty)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 8),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.location_on, size: 16),
//                                 const SizedBox(width: 4),
//                                 Flexible(child: Text(schedule['address'])),
//                               ],
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           )
//         ],
//       ),
//     );
//   } catch (e) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Error'),
//         content: Text('Failed to load schedules: ${e.toString()}'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           )
//         ],
//       ),
//     );
//   }
// }

//   void _handleBookNow(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BookingScreen(
//           doctorId: doctorId,
//           doctorData: doctorData,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'Booking_screen.dart';

// class DoctorlistScreen extends StatefulWidget {
//   const DoctorlistScreen({super.key});

//   @override
//   State<DoctorlistScreen> createState() => _DoctorlistScreenState();
// }

// class _DoctorlistScreenState extends State<DoctorlistScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doctor = snapshot.data!.docs[index];
//               return DoctorCard(
//                 doctorId: doctor.id,
//                 doctorData: doctor.data() as Map<String, dynamic>,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//   });

//   int _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     if (experience >= 1 && experience <= 4) return 50;
//     if (experience >= 5 && experience <= 7) return 150;
//     return 200;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'Date not specified';
//     try {
//       return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid date';
//     }
//   }

//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       return DateFormat('h:mm a').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid time';
//     }
//   }

//   Future<void> _showScheduleDialog(BuildContext context) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctorId)
//           .collection('schedules')
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no available schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text('${doctorData['fullName']}\'s Schedules'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: querySnapshot.docs.map((doc) {
//                   final schedule = doc.data();
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _formatScheduleDate(schedule['date'] as Timestamp?),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '${_formatScheduleTime(schedule['startTime'] as Timestamp?)} - ${_formatScheduleTime(schedule['endTime'] as Timestamp?)}',
//                             style: const TextStyle(fontSize: 15),
//                           ),
//                           if (schedule['address'] != null && schedule['address'].isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 8),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.location_on, size: 16),
//                                   const SizedBox(width: 4),
//                                   Flexible(child: Text(schedule['address'])),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             )
//           ],
//         ),
//       );
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to load schedules: ${e.toString()}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//     }
//   }

 
//         void _handleBookNow(BuildContext context) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => BookingScreen(
//         doctorId: doctorId,
//         doctorData: doctorData,
//       ),
//     ),
//   );
// }
//     // TODO: Implement booking logic
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Booking functionality to be implemented')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }









// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class BookingScreen extends StatefulWidget {
//   const BookingScreen({super.key});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doctor = snapshot.data!.docs[index];
//               return DoctorCard(
//                 doctorId: doctor.id,
//                 doctorData: doctor.data() as Map<String, dynamic>,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//   });

//   int _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     if (experience >= 1 && experience <= 4) return 50;
//     if (experience >= 5 && experience <= 7) return 150;
//     return 200;
//   }

//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'Date not specified';
//     try {
//       return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid date';
//     }
//   }

//   String _formatScheduleTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'Time not specified';
//     try {
//       return DateFormat('h:mm a').format(timestamp.toDate());
//     } catch (e) {
//       return 'Invalid time';
//     }
//   }

//   Future<void> _showScheduleDialog(BuildContext context) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctorId)
//           .collection('schedules')
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         if (!mounted) return;
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(doctorData['fullName'] ?? 'Doctor'),
//             content: const Text('This doctor has no available schedules.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               )
//             ],
//           ),
//         );
//         return;
//       }

//       if (!mounted) return;
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text('${doctorData['fullName']}\'s Schedules'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: querySnapshot.docs.map((doc) {
//                   final schedule = doc.data();
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _formatScheduleDate(schedule['date'] as Timestamp?),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '${_formatScheduleTime(schedule['startTime'] as Timestamp?)} - ${_formatScheduleTime(schedule['endTime'] as Timestamp?)}',
//                             style: const TextStyle(fontSize: 15),
//                           ),
//                           if (schedule['address'] != null && schedule['address'].isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 8),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.location_on, size: 16),
//                                   const SizedBox(width: 4),
//                                   Flexible(child: Text(schedule['address'])),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             )
//           ],
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to load schedules: ${e.toString()}'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//     }
//   }

//   void _handleBookNow(BuildContext context) {
//     // TODO: Implement booking logic
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Booking functionality to be implemented')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'Doctor Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _handleBookNow(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class BookingScreen extends StatefulWidget {
//   const BookingScreen({super.key});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final doctors = snapshot.data!.docs;

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               final doctorData = doctor.data() as Map<String, dynamic>;
              
//               // Only show approved doctors
//               if (doctorData['status'] != 'approved') {
//                 return const SizedBox.shrink();
//               }

//               return DoctorCard(
//                 doctorId: doctor.id,
//                 doctorData: doctorData,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//   });

//   // Calculate fee based on experience (1-4 years: 50, 5-7: 150)
//   int _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     if (experience >= 1 && experience <= 4) return 50;
//     if (experience >= 5 && experience <= 7) return 150;
//     return 200; // Default for 8+ years
//   }

//   // Calculate star rating based on points
//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5;
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   String _formatScheduleDate(dynamic timestamp) {
//     try {
//       if (timestamp is Timestamp) {
//         return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//       }
//       return 'Date not specified';
//     } catch (e) {
//       return 'Invalid date';
//     }
//   }

//   String _formatScheduleTime(dynamic timestamp) {
//     try {
//       if (timestamp is Timestamp) {
//         return DateFormat('h:mm a').format(timestamp.toDate());
//       }
//       return 'Time not specified';
//     } catch (e) {
//       return 'Invalid time';
//     }
//   }

//   void _showScheduleDialog(BuildContext context) {
//     final schedules = doctorData['schedules'] is List ? doctorData['schedules'] : [];
    
//     if (schedules.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text(doctorData['fullName'] ?? 'Doctor'),
//           content: const Text('This doctor has no schedule available yet.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('${doctorData['fullName']}\'s Schedule'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               for (final schedule in schedules)
//                 Card(
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Display as "Mon, Jun 9, 2025"
//                         Text(
//                           _formatScheduleDate(schedule['date']),
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           '${_formatScheduleTime(schedule['startTime'])} - ${_formatScheduleTime(schedule['endTime'])}',
//                           style: const TextStyle(fontSize: 15),
//                         ),
//                         if (schedule['address'] != null && schedule['address'].isNotEmpty)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 8),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.location_on, size: 16),
//                                 const SizedBox(width: 4),
//                                 Text(schedule['address']),
//                               ],
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     doctorData['fullName']?[0] ?? '?',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'No Name',
//                         style: const TextStyle(
//                           fontSize: 18, 
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Specialty: ${doctorData['specialties'] ?? 'General'}',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(
//                           fontSize: 14, 
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Fee: \$${_calculateFee()}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     // Handle booking action
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class BookingScreen extends StatefulWidget {
//   const BookingScreen({super.key});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final doctors = snapshot.data!.docs;

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               final doctorData = doctor.data() as Map<String, dynamic>;
              
//               // Only show approved doctors
//               if (doctorData['status'] != 'approved') {
//                 return const SizedBox.shrink();
//               }

//               return DoctorCard(
//                 doctorId: doctor.id,
//                 doctorData: doctorData,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//   });

//   // Calculate fee based on experience
//   int _calculateFee() {
//     final experience = doctorData['experience'] ?? 0;
//     if (experience >= 1 && experience <= 4) return 50;
//     if (experience >= 5 && experience <= 7) return 150;
//     return 200; // Default fee for more than 7 years
//   }

//   // Calculate star rating based on points
//   int _calculateStars() {
//     final points = doctorData['ratingPoints'] ?? 0;
//     if (points <= 3) return 1;
//     if (points <= 7) return 2;
//     if (points <= 10) return 3;
//     if (points <= 14) return 4;
//     return 5; // 15+ points
//   }

//   Widget _buildRatingStars() {
//     final stars = _calculateStars();
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < stars ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   void _showScheduleDialog(BuildContext context) {
//     final schedules = doctorData['schedules'] ?? [];
    
//     if (schedules.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text(doctorData['fullName'] ?? 'Doctor'),
//           content: const Text('This doctor has no schedule available yet.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             )
//           ],
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('${doctorData['fullName']}\'s Schedule'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               for (final schedule in schedules)
//                 ListTile(
//                   title: Text(schedule['day'] ?? ''),
//                   subtitle: Text(schedule['time'] ?? ''),
//                 ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           )
//         ],
//       ),
//     );
//   }

//   void _showBookingOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Book Appointment with ${doctorData['fullName']}',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Consultation Fee: \$${_calculateFee()}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               if (doctorData['schedules'] == null || doctorData['schedules'].isEmpty)
//                 const Text(
//                   'No available schedules',
//                   style: TextStyle(color: Colors.red),
//                 )
//               else
//                 ..._buildScheduleOptions(),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   // Navigate to booking confirmation page
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[800],
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 child: const Text(
//                   'Confirm Booking',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   List<Widget> _buildScheduleOptions() {
//     final schedules = doctorData['schedules'] ?? [];
//     return [
//       const Text(
//         'Available Time Slots:',
//         style: TextStyle(fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 8),
//       ...schedules.map((schedule) => ListTile(
//             title: Text('${schedule['day']} - ${schedule['time']}'),
//             onTap: () {
//               // Handle schedule selection
//             },
//           )),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundImage: doctorData['photoUrl'] != null
//                       ? NetworkImage(doctorData['photoUrl'])
//                       : null,
//                   child: doctorData['photoUrl'] == null
//                       ? Text(doctorData['fullName']?[0] ?? '?')
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'No Name',
//                         style: const TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         doctorData['specialization'] ?? 'No Specialization',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${doctorData['experience'] ?? 0} years experience',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildRatingStars(),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_calculateStars()}.0',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => _showScheduleDialog(context),
//                   child: const Text(
//                     'View Schedule',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _showBookingOptions(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Book Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'set_appointment_screen.dart';

// class BookingScreen extends StatefulWidget {
//   const BookingScreen({super.key});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final doctors = snapshot.data!.docs;

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               return DoctorCard(
//                 doctorId: doctor.id,
//                 doctorData: doctor.data() as Map<String, dynamic>,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//   });

//   void _showScheduleDialog(BuildContext context, String doctorId) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('${doctorData['fullName']}\'s Schedule'),
//         content: StreamBuilder<QuerySnapshot>(
//           stream: FirebaseFirestore.instance
//               .collection('doctors')
//               .doc(doctorId)
//               .collection('schedules')
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const CircularProgressIndicator();
//             }

//             final schedules = snapshot.data!.docs;

//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 DataTable(
//                   columns: const [
//                     DataColumn(label: Text('Day')),
//                     DataColumn(label: Text('Time')),
//                   ],
//                   rows: schedules.map((doc) {
//                     final schedule = doc.data() as Map<String, dynamic>;
//                     return DataRow(cells: [
//                       DataCell(Text(schedule['day'] ?? '')),
//                       DataCell(Text(schedule['time'] ?? '')),
//                     ]);
//                   }).toList(),
//                 ),
//               ],
//             );
//           },
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildRatingStars(double rating) {
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < rating ? Icons.star : Icons.star_border,
//           color: Colors.amber,
//           size: 16,
//         );
//       }),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final rating = doctorData['rating'] != null 
//         ? (doctorData['rating'] is int 
//             ? doctorData['rating'].toDouble() 
//             : doctorData['rating']) 
//         : 0.0;

//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color: Colors.grey[200],
//                     image: doctorData['image'] != null
//                         ? DecorationImage(
//                             image: NetworkImage(doctorData['image']),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//                   ),
//                   child: doctorData['image'] == null
//                       ? const Icon(Icons.person, size: 40, color: Colors.grey)
//                       : null,
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'No Name',
//                         style: const TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         doctorData['specialties'] ?? 'No Specialization',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         doctorData['experience'] ?? 'No Experience',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 8),
//                       GestureDetector(
//                         onTap: () => _showScheduleDialog(context, doctorId),
//                         child: const Text(
//                           'Schedule',
//                           style: TextStyle(
//                             decoration: TextDecoration.underline,
//                             decorationColor: Colors.blue,
//                             color: Colors.blue,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           _buildRatingStars(rating),
//                           const SizedBox(width: 4),
//                           Text(
//                             rating.toStringAsFixed(1),
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             // Align(
//             //   alignment: Alignment.centerRight,
//             //   child: ElevatedButton(
//             //     onPressed: () {
//             //       Navigator.push(
//             //         context,
//             //         MaterialPageRoute(
//             //           builder: (_) => SetAppointmentScreen(doctor: doctorData),
//             //         ),
//             //       );
//             //     },
//             //     style: ElevatedButton.styleFrom(
//             //       backgroundColor: Colors.blue[800],
//             //       shape: RoundedRectangleBorder(
//             //         borderRadius: BorderRadius.circular(10),
//             //       ),
//             //     ),
//             //     child: const Text('Set Appointment', 
//             //         style: TextStyle(color: Colors.white)),
//             //   ),
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'set_appointment_screen.dart';
// // import 'edit_screen.dart';

// class BookingScreen extends StatefulWidget {
//   const BookingScreen ({super.key});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   void updateDoctor(String docId, Map<String, dynamic> updatedDoctor) async {
//     try {
//       await _firestore.collection('doctors').doc(docId).update({
//         'specialization': updatedDoctor['specialization'],
//         'experience': updatedDoctor['experience'],
//         'image': updatedDoctor['image'],
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating doctor: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final doctors = snapshot.data!.docs;

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               return DoctorCard(
//                 doctorId: doctor.id,
//                 doctorData: doctor.data() as Map<String, dynamic>,
//                 // onEdit: () async {
//                 //   final updatedDoctor = await Navigator.push(
//                 //     context,
//                 //     MaterialPageRoute(
//                 //       builder: (_) => EditDoctorScreen(doctor: doctor.data() as Map<String, dynamic>),
//                 //     ),
//                 //   );
//                 //   if (updatedDoctor != null) {
//                 //     updateDoctor(doctor.id, updatedDoctor);
//                 //   }
//                 // },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DoctorCard extends StatelessWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   final VoidCallback onEdit;

//   const DoctorCard({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//     required this.onEdit,
//   });

//   void _showScheduleDialog(BuildContext context, String doctorId) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('${doctorData['fullName']}\'s Schedule'),
//         content: StreamBuilder<QuerySnapshot>(
//           stream: FirebaseFirestore.instance
//               .collection('doctors')
//               .doc(doctorId)
//               .collection('schedules')
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const CircularProgressIndicator();
//             }

//             final schedules = snapshot.data!.docs;

//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 DataTable(
//                   columns: const [
//                     DataColumn(label: Text('Day')),
//                     DataColumn(label: Text('Time')),
//                   ],
//                   rows: schedules.map((doc) {
//                     final schedule = doc.data() as Map<String, dynamic>;
//                     return DataRow(cells: [
//                       DataCell(Text(schedule['day'] ?? '')),
//                       DataCell(Text(schedule['time'] ?? '')),
//                     ]);
//                   }).toList(),
//                 ),
//               ],
//             );
//           },
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color: Colors.grey[200],
//                     image: doctorData['image'] != null
//                         ? DecorationImage(
//                             image: NetworkImage(doctorData['image']),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//                   ),
//                   child: doctorData['image'] == null
//                       ? const Icon(Icons.person, size: 40, color: Colors.grey)
//                       : null,
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctorData['fullName'] ?? 'No Name',
//                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         doctorData['specialties'] ?? 'No Specialization',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         doctorData['experience'] ?? 'No Experience',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 8),
//                       GestureDetector(
//                         onTap: () => _showScheduleDialog(context, doctorId),
//                         child: const Text(
//                           'Schedule',
//                           style: TextStyle(
//                             decoration: TextDecoration.underline,
//                             decorationColor: Colors.blue,
//                             color: Colors.blue,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           const Icon(Icons.star, color: Colors.amber, size: 16),
//                           const SizedBox(width: 4),
//                           Text(
//                             (doctorData['rating'] ?? 0).toString(),
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.edit, size: 20),
//                   onPressed: onEdit,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => SetAppointmentScreen(doctor: doctorData),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[800],
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text('Set Appointment', style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'addDoctor.dart'; // Import the new screen

// class BookingScreen extends StatefulWidget {
//   const BookingScreen({super.key});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctors List'),
//       ),
//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search by username',
//                 prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//                 filled: true,
//                 fillColor: Colors.white,
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: const BorderSide(color: Colors.blueGrey),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.blue[900]!),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//           ),

//           // Doctor list
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .where('title', isEqualTo: 'Doctor')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return const Center(child: Text('Error occurred'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final doctors = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final username = data['username']?.toLowerCase() ?? '';
//                   return username.contains(searchQuery);
//                 }).toList();

//                 if (doctors.isEmpty) {
//                   return const Center(child: Text('No matching doctors found.'));
//                 }

//                 return ListView.builder(
//                   itemCount: doctors.length,
//                   itemBuilder: (context, index) {
//                     final data = doctors[index].data() as Map<String, dynamic>;
//                     final username = data['username'] ?? 'No username';
//                     final userId = doctors[index].id; // Get document ID

//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.2),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: ListTile(
//                         leading: Icon(Icons.person, color: Colors.blue[900], size: 40),
//                         title: Text(
//                           username,
//                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                         ),
//                         subtitle: Text(
//                           'Specialization: ${data['specialization'] ?? 'N/A'}\n'
//                           'Experience: ${data['experience'] ?? 'N/A'} years',
//                           style: TextStyle(color: Colors.grey[700]),
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => AddDoctorScreen(
//                                 username: username,
//                                 userId: userId,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
      
//     );
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'addDoctor.dart'; // Import the new screen

// class BookingScreen extends StatefulWidget {
//   const BookingScreen({super.key});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctors List'),
//       ),
//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search by username',
//                 prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//                 filled: true,
//                 fillColor: Colors.white,
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: const BorderSide(color: Colors.blueGrey),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.blue[900]!),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//           ),

//           // Doctor list
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .where('title', isEqualTo: 'Doctor')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return const Center(child: Text('Error occurred'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final doctors = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final username = data['username']?.toLowerCase() ?? '';
//                   return username.contains(searchQuery);
//                 }).toList();

//                 if (doctors.isEmpty) {
//                   return const Center(child: Text('No matching doctors found.'));
//                 }

//                 return ListView.builder(
//                   itemCount: doctors.length,
//                   itemBuilder: (context, index) {
//                     final data = doctors[index].data() as Map<String, dynamic>;
//                     final username = data['username'] ?? 'No username';

//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.2),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: ListTile(
//                         leading: Icon(Icons.person, color: Colors.blue[900], size: 40),
//                         title: Text(
//                           username,
//                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                         ),
//                         subtitle: Text(
//                           'Specialization: ${data['specialization'] ?? 'N/A'}\n'
//                           'Experience: ${data['experience'] ?? 'N/A'} years',
//                           style: TextStyle(color: Colors.grey[700]),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const AddDoctorScreen()));
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class BookingScreen extends StatefulWidget {
//   const BookingScreen({super.key});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctors List'),
//       ),
//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search by username',
//                 labelStyle: TextStyle(color: Colors.blue[900]),
//                 prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//                 filled: true,
//                 fillColor: Colors.white,
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: const BorderSide(color: Colors.blueGrey),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.blue[900]!),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//           ),

//           // Doctor list
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .where('title', isEqualTo: 'Doctor')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return const Center(child: Text('Error occurred'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final doctors = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final username = data['username']?.toLowerCase() ?? '';
//                   return username.contains(searchQuery);
//                 }).toList();

//                 if (doctors.isEmpty) {
//                   return const Center(child: Text('No matching doctors found.'));
//                 }

//                 return ListView.builder(
//                   itemCount: doctors.length,
//                   itemBuilder: (context, index) {
//                     final data = doctors[index].data() as Map<String, dynamic>;
//                     final username = data['username'] ?? 'No username';

//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.2),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: ListTile(
//                         leading: Icon(Icons.person, color: Colors.blue[900], size: 40),
//                         title: Text(
//                           username,
//                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                         ),
//                         subtitle: Text(
//                           'Specialization: ${data['specialization'] ?? 'N/A'}\n'
//                           'Experience: ${data['experience'] ?? 'N/A'} years',
//                           return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color: Colors.grey[200],
//                     image: doctor['image'] != null
//                         ? DecorationImage(
//                             image: AssetImage(doctor['image']),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//                   ),
//                   child: doctor['image'] == null
//                       ? const Icon(Icons.person, size: 40, color: Colors.grey)
//                       : null,
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctor['fullname'],
//                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         doctor['specialization'],
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 4),
//                        Text(
//                         doctor['experience'],
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 8),
//                       GestureDetector(
//                         onTap: () => _showScheduleDialog(context, doctor),
//                         child: const Text(
//                           'Schedule',
//                           style: TextStyle(
//                             decoration: TextDecoration.underline,
//                             decorationColor: Colors.blue,
//                             color: Colors.blue,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           const Icon(Icons.star, color: Colors.amber, size: 16),
//                           const SizedBox(width: 4),
//                           Text(
//                             doctor['rating'].toString(),
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                          
//                           style: TextStyle(color: Colors.grey[700]),
//                         ),
//                          Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => SetAppointmentScreen(doctor: doctor),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[800],
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text('Set Appointment', style: TextStyle(color: Colors.white)),
//               ),
//             ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'dart:io';

// class BookingScreen extends StatefulWidget {
//   final String title;
  
//   const BookingScreen({super.key, required this.title});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   String searchQuery = '';
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final ImagePicker _picker = ImagePicker();

//   Widget _buildKabixiIcon() {
//     return const Icon(
//       Icons.medical_services,
//       color: Colors.blue,
//       size: 24,
//     );
//   }

//   Future<void> _addNewSpecialist() async {
//     if (widget.title != 'Doctor') return;

//     final fullNameController = TextEditingController();
//     final specializationController = TextEditingController();
//     final experienceController = TextEditingController();
//     List<Map<String, dynamic>> schedule = [];
//     List<String> galleryImages = [];
//     File? selectedImage;

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: Text('Add New ${widget.title}'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   GestureDetector(
//                     onTap: () async {
//                       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       if (image != null) {
//                         setState(() {
//                           selectedImage = File(image.path);
//                         });
//                       }
//                     },
//                     child: Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: Colors.grey[200],
//                           backgroundImage: selectedImage != null 
//                               ? FileImage(selectedImage!) 
//                               : null,
//                           child: selectedImage == null
//                               ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                               : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.edit, size: 20, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   TextField(
//                     controller: fullNameController,
//                     decoration: const InputDecoration(labelText: 'Full Name'),
//                   ),
//                   TextField(
//                     controller: specializationController,
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                   ),
//                   TextField(
//                     controller: experienceController,
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ...schedule.map((item) => ListTile(
//                     title: Text(DateFormat('EEEE').format(item['date'].toDate())),
//                     subtitle: Text('${item['startTime']} - ${item['endTime']}'),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete),
//                       onPressed: () => setState(() => schedule.remove(item)),
//                     ),
//                   )).toList(),
//                   ElevatedButton(
//                     onPressed: () async {
//                       DateTime? selectedDate;
//                       TimeOfDay? startTime;
//                       TimeOfDay? endTime;

//                       await showDialog(
//                         context: context,
//                         builder: (context) => StatefulBuilder(
//                           builder: (context, setState) {
//                             return AlertDialog(
//                               title: const Text('Add Schedule'),
//                               content: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   ListTile(
//                                     title: Text(selectedDate == null 
//                                         ? 'Select date' 
//                                         : 'Date: ${DateFormat('EEEE, MMM d').format(selectedDate!)}'),
//                                     trailing: const Icon(Icons.calendar_today),
//                                     onTap: () async {
//                                       final picked = await showDatePicker(
//                                         context: context,
//                                         initialDate: DateTime.now(),
//                                         firstDate: DateTime.now(),
//                                         lastDate: DateTime.now().add(const Duration(days: 365)),
//                                       );
//                                       if (picked != null) {
//                                         setState(() => selectedDate = picked);
//                                       }
//                                     },
//                                   ),
//                                   ListTile(
//                                     title: Text(startTime == null 
//                                         ? 'Select start time' 
//                                         : 'Start: ${startTime!.format(context)}'),
//                                     trailing: const Icon(Icons.access_time),
//                                     onTap: () async {
//                                       final picked = await showTimePicker(
//                                         context: context,
//                                         initialTime: TimeOfDay.now(),
//                                       );
//                                       if (picked != null) {
//                                         setState(() => startTime = picked);
//                                       }
//                                     },
//                                   ),
//                                   ListTile(
//                                     title: Text(endTime == null 
//                                         ? 'Select end time' 
//                                         : 'End: ${endTime!.format(context)}'),
//                                     trailing: const Icon(Icons.access_time),
//                                     onTap: () async {
//                                       final picked = await showTimePicker(
//                                         context: context,
//                                         initialTime: TimeOfDay.now(),
//                                       );
//                                       if (picked != null) {
//                                         setState(() => endTime = picked);
//                                       }
//                                     },
//                                   ),
//                                 ],
//                               ),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(context),
//                                   child: const Text('Cancel'),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     if (selectedDate == null || startTime == null || endTime == null) {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('Please select date and time range')),
//                                       );
//                                       return;
//                                     }
                                    
//                                     final startDateTime = DateTime(
//                                       selectedDate!.year,
//                                       selectedDate!.month,
//                                       selectedDate!.day,
//                                       startTime!.hour,
//                                       startTime!.minute,
//                                     );
                                    
//                                     final endDateTime = DateTime(
//                                       selectedDate!.year,
//                                       selectedDate!.month,
//                                       selectedDate!.day,
//                                       endTime!.hour,
//                                       endTime!.minute,
//                                     );
                                    
//                                     if (endDateTime.isBefore(startDateTime)) {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('End time must be after start time')),
//                                       );
//                                       return;
//                                     }
                                    
//                                     setState(() {
//                                       schedule.add({
//                                         'date': Timestamp.fromDate(selectedDate!),
//                                         'day': DateFormat('EEEE').format(selectedDate!),
//                                         'startTime': startTime!.format(context),
//                                         'endTime': endTime!.format(context),
//                                       });
//                                     });
//                                     Navigator.pop(context);
//                                   },
//                                   child: const Text('Add'),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                       );
//                     },
//                     child: const Text('Add Schedule'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (fullNameController.text.isEmpty || 
//                       specializationController.text.isEmpty || 
//                       experienceController.text.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please fill all required fields')),
//                     );
//                     return;
//                   }

//                   String? imageUrl;
//                   if (selectedImage != null) {
//                     final ref = _storage.ref().child('${widget.title.toLowerCase()}_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//                     await ref.putFile(selectedImage!);
//                     imageUrl = await ref.getDownloadURL();
//                   }

//                   await _firestore.collection('users').add({
//                     'fullName': fullNameController.text,
//                     'specialization': specializationController.text,
//                     'experience': '${experienceController.text} years',
//                     'title': widget.title,
//                     'schedule': schedule,
//                     'imageUrl': imageUrl,
//                     'rating': 0.0,
//                     'createdAt': FieldValue.serverTimestamp(),
//                   });

//                   Navigator.pop(context);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _editSpecialist(DocumentSnapshot doc) async {
//     if (widget.title != 'Doctor') return;

//     final user = doc.data() as Map<String, dynamic>;
//     final fullNameController = TextEditingController(text: user['fullName']);
//     final specializationController = TextEditingController(text: user['specialization']);
//     final experienceController = TextEditingController(
//       text: user['experience']?.toString().replaceAll(' years', '') ?? '');
    
//     List<Map<String, dynamic>> schedule = List.from(user['schedule'] ?? []);
//     String? imageUrl = user['imageUrl'];
//     File? selectedImage;

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: Text('Edit ${widget.title}'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   GestureDetector(
//                     onTap: () async {
//                       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       if (image != null) {
//                         setState(() {
//                           selectedImage = File(image.path);
//                           imageUrl = null;
//                         });
//                       }
//                     },
//                     child: Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: Colors.grey[200],
//                           backgroundImage: selectedImage != null
//                               ? FileImage(selectedImage!)
//                               : (imageUrl != null 
//                                   ? NetworkImage(imageUrl!) 
//                                   : null),
//                           child: selectedImage == null && imageUrl == null
//                               ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                               : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.edit, size: 20, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   TextField(
//                     controller: fullNameController,
//                     decoration: const InputDecoration(labelText: 'Full Name'),
//                   ),
//                   TextField(
//                     controller: specializationController,
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                   ),
//                   TextField(
//                     controller: experienceController,
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ...schedule.map((item) => ListTile(
//                     title: Text(DateFormat('EEEE').format(item['date'].toDate())),
//                     subtitle: Text('${item['startTime']} - ${item['endTime']}'),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete),
//                       onPressed: () => setState(() => schedule.remove(item)),
//                     ),
//                   )).toList(),
//                   ElevatedButton(
//                     onPressed: () async {
//                       DateTime? selectedDate;
//                       TimeOfDay? startTime;
//                       TimeOfDay? endTime;

//                       await showDialog(
//                         context: context,
//                         builder: (context) => StatefulBuilder(
//                           builder: (context, setState) {
//                             return AlertDialog(
//                               title: const Text('Add Schedule'),
//                               content: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   ListTile(
//                                     title: Text(selectedDate == null 
//                                         ? 'Select date' 
//                                         : 'Date: ${DateFormat('EEEE, MMM d').format(selectedDate!)}'),
//                                     trailing: const Icon(Icons.calendar_today),
//                                     onTap: () async {
//                                       final picked = await showDatePicker(
//                                         context: context,
//                                         initialDate: DateTime.now(),
//                                         firstDate: DateTime.now(),
//                                         lastDate: DateTime.now().add(const Duration(days: 365)),
//                                       );
//                                       if (picked != null) {
//                                         setState(() => selectedDate = picked);
//                                       }
//                                     },
//                                   ),
//                                   ListTile(
//                                     title: Text(startTime == null 
//                                         ? 'Select start time' 
//                                         : 'Start: ${startTime!.format(context)}'),
//                                     trailing: const Icon(Icons.access_time),
//                                     onTap: () async {
//                                       final picked = await showTimePicker(
//                                         context: context,
//                                         initialTime: TimeOfDay.now(),
//                                       );
//                                       if (picked != null) {
//                                         setState(() => startTime = picked);
//                                       }
//                                     },
//                                   ),
//                                   ListTile(
//                                     title: Text(endTime == null 
//                                         ? 'Select end time' 
//                                         : 'End: ${endTime!.format(context)}'),
//                                     trailing: const Icon(Icons.access_time),
//                                     onTap: () async {
//                                       final picked = await showTimePicker(
//                                         context: context,
//                                         initialTime: TimeOfDay.now(),
//                                       );
//                                       if (picked != null) {
//                                         setState(() => endTime = picked);
//                                       }
//                                     },
//                                   ),
//                                 ],
//                               ),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(context),
//                                   child: const Text('Cancel'),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     if (selectedDate == null || startTime == null || endTime == null) {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('Please select date and time range')),
//                                       );
//                                       return;
//                                     }
                                    
//                                     final startDateTime = DateTime(
//                                       selectedDate!.year,
//                                       selectedDate!.month,
//                                       selectedDate!.day,
//                                       startTime!.hour,
//                                       startTime!.minute,
//                                     );
                                    
//                                     final endDateTime = DateTime(
//                                       selectedDate!.year,
//                                       selectedDate!.month,
//                                       selectedDate!.day,
//                                       endTime!.hour,
//                                       endTime!.minute,
//                                     );
                                    
//                                     if (endDateTime.isBefore(startDateTime)) {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('End time must be after start time')),
//                                       );
//                                       return;
//                                     }
                                    
//                                     setState(() {
//                                       schedule.add({
//                                         'date': Timestamp.fromDate(selectedDate!),
//                                         'day': DateFormat('EEEE').format(selectedDate!),
//                                         'startTime': startTime!.format(context),
//                                         'endTime': endTime!.format(context),
//                                       });
//                                     });
//                                     Navigator.pop(context);
//                                   },
//                                   child: const Text('Add'),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                       );
//                     },
//                     child: const Text('Add Schedule'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (fullNameController.text.isEmpty || 
//                       specializationController.text.isEmpty || 
//                       experienceController.text.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please fill all required fields')),
//                     );
//                     return;
//                   }

//                   if (selectedImage != null) {
//                     final ref = _storage.ref().child('${widget.title.toLowerCase()}_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//                     await ref.putFile(selectedImage!);
//                     imageUrl = await ref.getDownloadURL();
//                   }

//                   await doc.reference.update({
//                     'fullName': fullNameController.text,
//                     'specialization': specializationController.text,
//                     'experience': '${experienceController.text} years',
//                     'schedule': schedule,
//                     if (imageUrl != null) 'imageUrl': imageUrl,
//                     'updatedAt': FieldValue.serverTimestamp(),
//                   });

//                   Navigator.pop(context);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _deleteSpecialist(DocumentSnapshot doc) async {
//     if (widget.title != 'Doctor') return;
    
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this specialist?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await doc.reference.delete();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.title}s List'),
//         actions: [
//           if (widget.title == 'Doctor')
//             IconButton(
//               icon: const Icon(Icons.add),
//               onPressed: _addNewSpecialist,
//             ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: Row(
//                   children: [
//                     _buildKabixiIcon(),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: TextField(
//                         decoration: const InputDecoration(
//                           hintText: 'Search doctors...',
//                           border: InputBorder.none,
//                         ),
//                         onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//                       ),
//                     ),
//                     if (searchQuery.isNotEmpty)
//                       IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () => setState(() => searchQuery = ''),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('users')
//                   .where('title', isEqualTo: widget.title)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.person_off, size: 50, color: Colors.grey),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No ${widget.title}s available',
//                           style: const TextStyle(fontSize: 18),
//                         ),
//                         Text(
//                           'Please check back later',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                         if (widget.title == 'Doctor')
//                           Padding(
//                             padding: const EdgeInsets.only(top: 20),
//                             child: ElevatedButton(
//                               onPressed: _addNewSpecialist,
//                               child: Text('Add New ${widget.title}'),
//                             ),
//                           ),
//                       ],
//                     ),
//                   );
//                 }

//                 final filteredUsers = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final fullName = data['fullName']?.toString().toLowerCase() ?? '';
//                   final specialization = data['specialization']?.toString().toLowerCase() ?? '';
//                   return fullName.contains(searchQuery) || specialization.contains(searchQuery);
//                 }).toList();

//                 if (filteredUsers.isEmpty) {
//                   return const Center(
//                     child: Text('No matching results found'),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: filteredUsers.length,
//                   itemBuilder: (context, index) {
//                     final doc = filteredUsers[index];
//                     final user = doc.data() as Map<String, dynamic>;
//                     final schedule = (user['schedule'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ListTile(
//                         leading: Stack(
//                           children: [
//                             CircleAvatar(
//                               radius: 24,
//                               backgroundImage: user['imageUrl'] != null 
//                                   ? NetworkImage(user['imageUrl']) 
//                                   : null,
//                               child: user['imageUrl'] == null 
//                                   ? const Icon(Icons.person) 
//                                   : null,
//                             ),
//                             if (widget.title == 'Doctor')
//                               Positioned(
//                                 bottom: 0,
//                                 right: 0,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: const BoxDecoration(
//                                     color: Colors.white,
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: _buildKabixiIcon(),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'No Name',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(user['specialization'] ?? ''),
//                             Text('Experience: ${user['experience']}'),
//                             if (schedule.isNotEmpty)
//                               GestureDetector(
//                                 onTap: () {
//                                   showDialog(
//                                     context: context,
//                                     builder: (_) => AlertDialog(
//                                       title: Text('${user['fullName']}\'s Schedule'),
//                                       content: SingleChildScrollView(
//                                         child: Column(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: schedule.map((item) => ListTile(
//                                             title: Text(DateFormat('EEEE, MMM d').format(item['date'].toDate())),
//                                             subtitle: Text('${item['startTime']} - ${item['endTime']}'),
//                                           )).toList(),
//                                         ),
//                                       ),
//                                       actions: [
//                                         TextButton(
//                                           onPressed: () => Navigator.pop(context),
//                                           child: const Text('Close'),
//                                         )
//                                       ],
//                                     ),
//                                   );
//                                 },
//                                 child: const Text(
//                                   'View Schedule',
//                                   style: TextStyle(
//                                     color: Colors.blue,
//                                     decoration: TextDecoration.underline,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         trailing: widget.title == 'Doctor'
//                             ? PopupMenuButton<String>(
//                                 onSelected: (value) {
//                                   if (value == 'edit') {
//                                     _editSpecialist(doc);
//                                   } else if (value == 'delete') {
//                                     _deleteSpecialist(doc);
//                                   }
//                                 },
//                                 itemBuilder: (context) => [
//                                   const PopupMenuItem(
//                                     value: 'edit',
//                                     child: Text('Edit'),
//                                   ),
//                                   const PopupMenuItem(
//                                     value: 'delete',
//                                     child: Text('Delete', style: TextStyle(color: Colors.red)),
//                                   ),
//                                 ],
//                               )
//                             : null,
//                         onTap: () {
//                           if (widget.title != 'Doctor') {
//                             showDialog(
//                               context: context,
//                               builder: (_) => AlertDialog(
//                                 title: Text(user['fullName'] ?? 'Specialist Details'),
//                                 content: SingleChildScrollView(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Center(
//                                         child: CircleAvatar(
//                                           radius: 50,
//                                           backgroundImage: user['imageUrl'] != null
//                                               ? NetworkImage(user['imageUrl'])
//                                               : null,
//                                           child: user['imageUrl'] == null
//                                               ? const Icon(Icons.person, size: 50)
//                                               : null,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 16),
//                                       Text('Specialization: ${user['specialization'] ?? ''}'),
//                                       Text('Experience: ${user['experience'] ?? ''}'),
//                                       const SizedBox(height: 16),
//                                       const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                                       ...schedule.map((item) => ListTile(
//                                         title: Text(DateFormat('EEEE, MMM d').format(item['date'].toDate())),
//                                         subtitle: Text('${item['startTime']} - ${item['endTime']}'),
//                                       )).toList(),
//                                     ],
//                                   ),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text('Close'),
//                                   ),
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.pop(context);
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('Booking functionality will be implemented here')),
//                                       );
//                                     },
//                                     child: const Text('Book Appointment'),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class BookingScreen extends StatefulWidget {
//   final String title;
  
//   const BookingScreen({super.key, required this.title});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   String searchQuery = '';
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final ImagePicker _picker = ImagePicker();

//   // Add Kabixi icon
//   Widget _buildKabixiIcon() {
//     return const Icon(
//       Icons.medical_services, // Using medical services icon as Kabixi icon
//       color: Colors.blue,
//       size: 24,
//     );
//   }

//   Future<void> _addNewSpecialist() async {
//     if (widget.title != 'Doctor') return; // Only doctors can add

//     final fullNameController = TextEditingController();
//     final specializationController = TextEditingController();
//     final experienceController = TextEditingController();
//     List<Map<String, String>> schedule = [];
//     List<String> galleryImages = [];
//     File? selectedImage;

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: Text('Add New ${widget.title}'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Profile image circle with edit option
//                   GestureDetector(
//                     onTap: () async {
//                       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       if (image != null) {
//                         setState(() {
//                           selectedImage = File(image.path);
//                         });
//                       }
//                     },
//                     child: Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: Colors.grey[200],
//                           backgroundImage: selectedImage != null 
//                               ? FileImage(selectedImage!) 
//                               : null,
//                           child: selectedImage == null
//                               ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                               : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.edit, size: 20, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   TextField(
//                     controller: fullNameController,
//                     decoration: const InputDecoration(labelText: 'Full Name'),
//                   ),
//                   TextField(
//                     controller: specializationController,
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                   ),
//                   TextField(
//                     controller: experienceController,
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ...schedule.map((day) => ListTile(
//                     title: Text('${day['day']}: ${day['time']}'),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete),
//                       onPressed: () => setState(() => schedule.remove(day)),
//                     ),
//                   )).toList(),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final dayController = TextEditingController();
//                       final timeController = TextEditingController();
                      
//                       await showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: const Text('Add Schedule'),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               TextField(
//                                 controller: dayController,
//                                 decoration: const InputDecoration(labelText: 'Day (e.g., Monday)'),
//                               ),
//                               TextField(
//                                 controller: timeController,
//                                 decoration: const InputDecoration(labelText: 'Time (e.g., 9:00 AM - 5:00 PM)'),
//                               ),
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   schedule.add({
//                                     'day': dayController.text,
//                                     'time': timeController.text,
//                                   });
//                                 });
//                                 Navigator.pop(context);
//                               },
//                               child: const Text('Add'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     child: const Text('Add Schedule'),
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Gallery Images:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   if (selectedImage != null)
//                     Image.file(selectedImage!, height: 100),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (fullNameController.text.isEmpty || 
//                       specializationController.text.isEmpty || 
//                       experienceController.text.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please fill all required fields')),
//                     );
//                     return;
//                   }

//                   // Upload image to Firebase Storage if selected
//                   String? imageUrl;
//                   if (selectedImage != null) {
//                     final ref = _storage.ref().child('${widget.title.toLowerCase()}_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//                     await ref.putFile(selectedImage!);
//                     imageUrl = await ref.getDownloadURL();
//                   }

//                   // Save to Firestore
//                   await _firestore.collection('users').add({
//                     'fullName': fullNameController.text,
//                     'specialization': specializationController.text,
//                     'experience': '${experienceController.text} years',
//                     'title': widget.title,
//                     'schedule': schedule,
//                     'imageUrl': imageUrl,
//                     'rating': 0.0, // Default rating
//                     'createdAt': FieldValue.serverTimestamp(),
//                   });

//                   Navigator.pop(context);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _editSpecialist(DocumentSnapshot doc) async {
//     if (widget.title != 'Doctor') return; // Only doctors can edit

//     final user = doc.data() as Map<String, dynamic>;
//     final fullNameController = TextEditingController(text: user['fullName']);
//     final specializationController = TextEditingController(text: user['specialization']);
//     final experienceController = TextEditingController(
//       text: user['experience']?.toString().replaceAll(' years', '') ?? '');
    
//     List<Map<String, dynamic>> schedule = List.from(user['schedule'] ?? []);
//     String? imageUrl = user['imageUrl'];
//     File? selectedImage;

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: Text('Edit ${widget.title}'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Editable profile image circle
//                   GestureDetector(
//                     onTap: () async {
//                       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       if (image != null) {
//                         setState(() {
//                           selectedImage = File(image.path);
//                           imageUrl = null; // Clear the old URL if new image is selected
//                         });
//                       }
//                     },
//                     child: Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: Colors.grey[200],
//                           backgroundImage: selectedImage != null
//                               ? FileImage(selectedImage!)
//                               : (imageUrl != null 
//                                   ? NetworkImage(imageUrl!) 
//                                   : null),
//                           child: selectedImage == null && imageUrl == null
//                               ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                               : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.edit, size: 20, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   TextField(
//                     controller: fullNameController,
//                     decoration: const InputDecoration(labelText: 'Full Name'),
//                   ),
//                   TextField(
//                     controller: specializationController,
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                   ),
//                   TextField(
//                     controller: experienceController,
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ...schedule.map((day) => ListTile(
//                     title: Text('${day['day']}: ${day['time']}'),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete),
//                       onPressed: () => setState(() => schedule.remove(day)),
//                     ),
//                   )).toList(),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final dayController = TextEditingController();
//                       final timeController = TextEditingController();
                      
//                       await showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: const Text('Add Schedule'),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               TextField(
//                                 controller: dayController,
//                                 decoration: const InputDecoration(labelText: 'Day (e.g., Monday)'),
//                               ),
//                               TextField(
//                                 controller: timeController,
//                                 decoration: const InputDecoration(labelText: 'Time (e.g., 9:00 AM - 5:00 PM)'),
//                               ),
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   schedule.add({
//                                     'day': dayController.text,
//                                     'time': timeController.text,
//                                   });
//                                 });
//                                 Navigator.pop(context);
//                               },
//                               child: const Text('Add'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     child: const Text('Add Schedule'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (fullNameController.text.isEmpty || 
//                       specializationController.text.isEmpty || 
//                       experienceController.text.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please fill all required fields')),
//                     );
//                     return;
//                   }

//                   // Upload new image if selected
//                   if (selectedImage != null) {
//                     final ref = _storage.ref().child('${widget.title.toLowerCase()}_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//                     await ref.putFile(selectedImage!);
//                     imageUrl = await ref.getDownloadURL();
//                   }

//                   // Update in Firestore
//                   await doc.reference.update({
//                     'fullName': fullNameController.text,
//                     'specialization': specializationController.text,
//                     'experience': '${experienceController.text} years',
//                     'schedule': schedule,
//                     if (imageUrl != null) 'imageUrl': imageUrl,
//                     'updatedAt': FieldValue.serverTimestamp(),
//                   });

//                   Navigator.pop(context);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _deleteSpecialist(DocumentSnapshot doc) async {
//     if (widget.title != 'Doctor') return; // Only doctors can delete
    
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this specialist?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await doc.reference.delete();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.title}s List'),
//         actions: [
//           if (widget.title == 'Doctor') // Only show add button for doctors
//             IconButton(
//               icon: const Icon(Icons.add),
//               onPressed: _addNewSpecialist,
//             ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Enhanced search bar with Kabixi icon
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: Row(
//                   children: [
//                     _buildKabixiIcon(),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: TextField(
//                         decoration: const InputDecoration(
//                           hintText: 'Search doctors...',
//                           border: InputBorder.none,
//                         ),
//                         onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//                       ),
//                     ),
//                     if (searchQuery.isNotEmpty)
//                       IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () => setState(() => searchQuery = ''),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('users')
//                   .where('title', isEqualTo: widget.title)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.person_off, size: 50, color: Colors.grey),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No ${widget.title}s available',
//                           style: const TextStyle(fontSize: 18),
//                         ),
//                         Text(
//                           'Please check back later',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                         if (widget.title == 'Doctor')
//                           Padding(
//                             padding: const EdgeInsets.only(top: 20),
//                             child: ElevatedButton(
//                               onPressed: _addNewSpecialist,
//                               child: Text('Add New ${widget.title}'),
//                             ),
//                           ),
//                       ],
//                     ),
//                   );
//                 }

//                 final filteredUsers = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final fullName = data['fullName']?.toString().toLowerCase() ?? '';
//                   final specialization = data['specialization']?.toString().toLowerCase() ?? '';
//                   return fullName.contains(searchQuery) || specialization.contains(searchQuery);
//                 }).toList();

//                 if (filteredUsers.isEmpty) {
//                   return const Center(
//                     child: Text('No matching results found'),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: filteredUsers.length,
//                   itemBuilder: (context, index) {
//                     final doc = filteredUsers[index];
//                     final user = doc.data() as Map<String, dynamic>;
//                     final schedule = (user['schedule'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ListTile(
//                         leading: Stack(
//                           children: [
//                             CircleAvatar(
//                               radius: 24,
//                               backgroundImage: user['imageUrl'] != null 
//                                   ? NetworkImage(user['imageUrl']) 
//                                   : null,
//                               child: user['imageUrl'] == null 
//                                   ? const Icon(Icons.person) 
//                                   : null,
//                             ),
//                             if (widget.title == 'Doctor')
//                               Positioned(
//                                 bottom: 0,
//                                 right: 0,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: const BoxDecoration(
//                                     color: Colors.white,
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: _buildKabixiIcon(),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'No Name',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(user['specialization'] ?? ''),
//                             Text('Experience: ${user['experience']}'),
//                             if (schedule.isNotEmpty)
//                               GestureDetector(
//                                 onTap: () {
//                                   showDialog(
//                                     context: context,
//                                     builder: (_) => AlertDialog(
//                                       title: Text('${user['fullName']}\'s Schedule'),
//                                       content: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: schedule.map((item) => ListTile(
//                                           title: Text(item['day'] ?? ''),
//                                           subtitle: Text(item['time'] ?? ''),
//                                         )).toList(),
//                                       ),
//                                       actions: [
//                                         TextButton(
//                                           onPressed: () => Navigator.pop(context),
//                                           child: const Text('Close'),
//                                         )
//                                       ],
//                                     ),
//                                   );
//                                 },
//                                 child: const Text(
//                                   'View Schedule',
//                                   style: TextStyle(
//                                     color: Colors.blue,
//                                     decoration: TextDecoration.underline,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         trailing: widget.title == 'Doctor'
//                             ? PopupMenuButton<String>(
//                                 onSelected: (value) {
//                                   if (value == 'edit') {
//                                     _editSpecialist(doc);
//                                   } else if (value == 'delete') {
//                                     _deleteSpecialist(doc);
//                                   }
//                                 },
//                                 itemBuilder: (context) => [
//                                   const PopupMenuItem(
//                                     value: 'edit',
//                                     child: Text('Edit'),
//                                   ),
//                                   const PopupMenuItem(
//                                     value: 'delete',
//                                     child: Text('Delete', style: TextStyle(color: Colors.red)),
//                                   ),
//                                 ],
//                               )
//                             : null,
//                         onTap: () {
//                           // For non-doctors, show details when tapped
//                           if (widget.title != 'Doctor') {
//                             showDialog(
//                               context: context,
//                               builder: (_) => AlertDialog(
//                                 title: Text(user['fullName'] ?? 'Specialist Details'),
//                                 content: SingleChildScrollView(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Center(
//                                         child: CircleAvatar(
//                                           radius: 50,
//                                           backgroundImage: user['imageUrl'] != null
//                                               ? NetworkImage(user['imageUrl'])
//                                               : null,
//                                           child: user['imageUrl'] == null
//                                               ? const Icon(Icons.person, size: 50)
//                                               : null,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 16),
//                                       Text('Specialization: ${user['specialization'] ?? ''}'),
//                                       Text('Experience: ${user['experience'] ?? ''}'),
//                                       const SizedBox(height: 16),
//                                       const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                                       ...schedule.map((item) => ListTile(
//                                         title: Text(item['day'] ?? ''),
//                                         subtitle: Text(item['time'] ?? ''),
//                                       )).toList(),
//                                     ],
//                                   ),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text('Close'),
//                                   ),
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.pop(context);
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('Booking functionality will be implemented here')),
//                                       );
//                                     },
//                                     child: const Text('Book Appointment'),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class BookingScreen extends StatefulWidget {
//   final String title;
  
  
//   const BookingScreen({super.key, required this.title});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   String searchQuery = '';
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final ImagePicker _picker = ImagePicker();

//   Future<void> _addNewSpecialist() async {
//     if (widget.title!= 'Doctor') return; // Only doctors can add

//     final fullNameController = TextEditingController();
//     final specializationController = TextEditingController();
//     final experienceController = TextEditingController();
//     List<Map<String, String>> schedule = [];
//     List<String> galleryImages = [];
//     File? selectedImage;

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: Text('Add New ${widget.title}'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: fullNameController,
//                     decoration: const InputDecoration(labelText: 'Full Name'),
//                   ),
//                   TextField(
//                     controller: specializationController,
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                   ),
//                   TextField(
//                     controller: experienceController,
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ...schedule.map((day) => ListTile(
//                     title:  final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _scheduleDate ?? DateTime.now(),
//                         firstDate: DateTime(2020),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null) {
//                         setState(() {
//                           _scheduleDate = picked;
//                         });,
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete),
//                       onPressed: () => setState(() => schedule.remove(day)),
//                     ),
//                   )).toList(),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final dayController = TextEditingController();
//                       final timeController = TextEditingController();
                      
//                       await showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: const Text('Add Schedule'),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               TextField(
//                                 controller: dayController,
//                                 decoration: const InputDecoration(scheduleData),
//                               ),
//                               TextField(
//                                 controller: timeController,
//                                 decoration: const InputDecoration(scheduleData),
//                               ),
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   schedule.add({
//                                     'day': dayController.text,
//                                     'time': timeController.text,
//                                   });
//                                 });
//                                 Navigator.pop(context);
//                               },
//                               child: const Text('Add'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     child: const Text('Add Schedule'),
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Gallery Images:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   if (selectedImage != null)
//                     Image.file(selectedImage!, height: 100),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       if (image != null) {
//                         setState(() {
//                           selectedImage = File(image.path);
//                         });
//                       }
//                     },
//                     child: const Text('Select Profile Image'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (fullNameController.text.isEmpty || 
//                       specializationController.text.isEmpty || 
//                       experienceController.text.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please fill all required fields')),
//                     );
//                     return;
//                   }

//                   // Upload image to Firebase Storage if selected
//                   String? imageUrl;
//                   if (selectedImage != null) {
//                     final ref = _storage.ref().child('${widget.title.toLowerCase()}_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//                     await ref.putFile(selectedImage!);
//                     imageUrl = await ref.getDownloadURL();
//                   }

//                   // Save to Firestore
//                   await _firestore.collection('users').add({
//                     'fullName': fullNameController.text,
//                     'specialization': specializationController.text,
//                     'experience': '${experienceController.text} years',
//                     'title': widget.title,
//                     'schedule': schedule,
//                     'imageUrl': imageUrl,
//                     'rating': 0.0, // Default rating
//                     'createdAt': FieldValue.serverTimestamp(),
//                   });

//                   Navigator.pop(context);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _editSpecialist(DocumentSnapshot doc) async {
//     if (widget.title!= 'Doctor') return; // Only doctors can edit

//     final user = doc.data() as Map<String, dynamic>;
//     final fullNameController = TextEditingController(text: user['fullName']);
//     final specializationController = TextEditingController(text: user['specialization']);
//     final experienceController = TextEditingController(
//       text: user['experience']?.toString().replaceAll(' years', '') ?? '');
    
//     List<Map<String, dynamic>> schedule = List.from(user['schedule'] ?? []);
//     String? imageUrl = user['imageUrl'];
//     File? selectedImage;

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: Text('Edit ${widget.title}'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: fullNameController,
//                     decoration: const InputDecoration(labelText: 'Full Name'),
//                   ),
//                   TextField(
//                     controller: specializationController,
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                   ),
//                   TextField(
//                     controller: experienceController,
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ...schedule.map((day) => ListTile(
//                     title: Text('${day['day']}: ${day['time']}'),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete),
//                       onPressed: () => setState(() => schedule.remove(day)),
//                     ),
//                   )).toList(),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final dayController = TextEditingController();
//                       final timeController = TextEditingController();
                      
//                       await showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: const Text('Add Schedule'),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               TextField(
//                                 controller: dayController,
//                                 decoration: const InputDecoration(labelText: 'Day (e.g., Monday)'),
//                               ),
//                               TextField(
//                                 controller: timeController,
//                                 decoration: const InputDecoration(labelText: 'Time (e.g., 9:00 AM - 5:00 PM)'),
//                               ),
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   schedule.add({
//                                     'day': dayController.text,
//                                     'time': timeController.text,
//                                   });
//                                 });
//                                 Navigator.pop(context);
//                               },
//                               child: const Text('Add'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     child: const Text('Add Schedule'),
//                   ),
                  
//                   const SizedBox(height: 16),
//                   const Text('Profile Image:', style: TextStyle(fontWeight: FontWeight.bold)),
//                   if (imageUrl != null || selectedImage != null)
//                     Image(
//                       image: selectedImage != null
//                           ? FileImage(selectedImage!)
//                           : NetworkImage(imageUrl!) as ImageProvider,
//                       height: 100,
//                     ),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       if (image != null) {
//                         setState(() {
//                           selectedImage = File(image.path);
//                           imageUrl = null; // Clear the old URL if new image is selected
//                         });
//                       }
//                     },
//                     child: const Text('Change Image'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (fullNameController.text.isEmpty || 
//                       specializationController.text.isEmpty || 
//                       experienceController.text.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please fill all required fields')),
//                     );
//                     return;
//                   }

//                   // Upload new image if selected
//                   if (selectedImage != null) {
//                     final ref = _storage.ref().child('${widget.title.toLowerCase()}_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//                     await ref.putFile(selectedImage!);
//                     imageUrl = await ref.getDownloadURL();
//                   }

//                   // Update in Firestore
//                   await doc.reference.update({
//                     'fullName': fullNameController.text,
//                     'specialization': specializationController.text,
//                     'experience': '${experienceController.text} years',
//                     'schedule': schedule,
//                     if (imageUrl != null) 'imageUrl': imageUrl,
//                     'updatedAt': FieldValue.serverTimestamp(),
//                   });

//                   Navigator.pop(context);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _deleteSpecialist(DocumentSnapshot doc) async {
//     if (widget.title!= 'Doctor') return; // Only doctors can delete
    
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this specialist?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await doc.reference.delete();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.title}s List'),
//         actions: [
//           if (widget.title == 'Doctor') // Only show add button for doctors
//             IconButton(
//               icon: const Icon(Icons.add),
//               onPressed: _addNewSpecialist,
//             ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search by full name . . . . .',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('users')
//                   .where('title', isEqualTo: widget.title)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.person_off, size: 50, color: Colors.grey),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No ${widget.title}s available',
//                           style: const TextStyle(fontSize: 18),
//                         ),
//                         Text(
//                           'Please check back later',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                         if (widget.title == 'Doctor')
//                           Padding(
//                             padding: const EdgeInsets.only(top: 20),
//                             child: ElevatedButton(
//                               onPressed: _addNewSpecialist,
//                               child: Text('Add New ${widget.title}'),
//                             ),
//                           ),
//                       ],
//                     ),
//                   );
//                 }

//                 final filteredUsers = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final fullName = data['fullName']?.toString().toLowerCase() ?? '';
//                   return fullName.contains(searchQuery);
//                 }).toList();

//                 if (filteredUsers.isEmpty) {
//                   return const Center(
//                     child: Text('No matching results found'),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: filteredUsers.length,
//                   itemBuilder: (context, index) {
//                     final doc = filteredUsers[index];
//                     final user = doc.data() as Map<String, dynamic>;
//                     final schedule = (user['schedule'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundImage: user['imageUrl'] != null 
//                               ? NetworkImage(user['imageUrl']) 
//                               : null,
//                           child: user['imageUrl'] == null 
//                               ? const Icon(Icons.person) 
//                               : null,
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'No Name',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(user['specialization'] ?? ''),
//                             Text('Experience: ${user['experience']}'),
//                             if (schedule.isNotEmpty)
//                               GestureDetector(
//                                 onTap: () {
//                                   showDialog(
//                                     context: context,
//                                     builder: (_) => AlertDialog(
//                                       title: Text('${user['fullName']}\'s Schedule'),
//                                       content: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: schedule.map((item) => ListTile(
//                                           title: Text(item['day'] ?? ''),
//                                           subtitle: Text(item['time'] ?? ''),
//                                         )).toList(),
//                                       ),
//                                       actions: [
//                                         TextButton(
//                                           onPressed: () => Navigator.pop(context),
//                                           child: const Text('Close'),
//                                         )
//                                       ],
//                                     ),
//                                   );
//                                 },
//                                 child: const Text(
//                                   'View Schedule',
//                                   style: TextStyle(
//                                     color: Colors.blue,
//                                     decoration: TextDecoration.underline,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         trailing: widget.title == 'Doctor'
//                             ? PopupMenuButton<String>(
//                                 onSelected: (value) {
//                                   if (value == 'edit') {
//                                     _editSpecialist(doc);
//                                   } else if (value == 'delete') {
//                                     _deleteSpecialist(doc);
//                                   }
//                                 },
//                                 itemBuilder: (context) => [
//                                   const PopupMenuItem(
//                                     value: 'edit',
//                                     child: Text('Edit'),
//                                   ),
//                                   const PopupMenuItem(
//                                     value: 'delete',
//                                     child: Text('Delete', style: TextStyle(color: Colors.red)),
//                                   ),
//                                 ],
//                               )
//                             : null,
//                         onTap: () {
//                           // For non-doctors, show details when tapped
//                           if (widget.title != 'Doctor') {
//                             showDialog(
//                               context: context,
//                               builder: (_) => AlertDialog(
//                                 title: Text(user['fullName'] ?? 'Specialist Details'),
//                                 content: SingleChildScrollView(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       if (user['imageUrl'] != null)
//                                         Center(
//                                           child: CircleAvatar(
//                                             radius: 50,
//                                             backgroundImage: NetworkImage(user['imageUrl']),
//                                           ),
//                                         ),
//                                       const SizedBox(height: 16),
//                                       Text('Specialization: ${user['specialization'] ?? ''}'),
//                                       Text('Experience: ${user['experience'] ?? ''}'),
//                                       const SizedBox(height: 16),
//                                       const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
//                                       ...schedule.map((item) => ListTile(
//                                         title: Text(item['day'] ?? ''),
//                                         subtitle: Text(item['time'] ?? ''),
//                                       )).toList(),
//                                     ],
//                                   ),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text('Close'),
//                                   ),
//                                   TextButton(
//                                     onPressed: () {
//                                       // TODO: Implement booking functionality
//                                       Navigator.pop(context);
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('Booking functionality will be implemented here')),
//                                       );
//                                     },
//                                     child: const Text('Book Appointment'),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class BookingScreen extends StatefulWidget {
//   final String title;
  
//   const BookingScreen({super.key, required this.title});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.title}s List'),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search by full name . . . . .',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .where('title', isEqualTo: widget.title)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.person_off, size: 50, color: Colors.grey),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No ${widget.title}s available',
//                           style: const TextStyle(fontSize: 18),
//                         ),
//                         Text(
//                           'Please check back later',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 final filteredUsers = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final username = data['fullName']?.toString().toLowerCase() ?? '';
//                   return username.contains(searchQuery);
//                 }).toList();

//                 if (filteredUsers.isEmpty) {
//                   return const Center(
//                     child: Text('No matching results found'),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: filteredUsers.length,
//                   itemBuilder: (context, index) {
//                     final doc = filteredUsers[index];
//                     final user = doc.data() as Map<String, dynamic>;

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         leading: const CircleAvatar(
//                           child: Icon(Icons.person),
//                         ),
//                         title: Text(
//                           user['fullName'] ?? 'No Name',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
                        
//                         trailing: const Icon(Icons.arrow_forward),
//                         onTap: () {
//                           // Navigate to doctor details
//                         },
//                         import 'package:flutter/material.dart';
// import 'set_appointment_screen.dart';



//   final List<Map<String, dynamic>> doctors = [
//   {
//     'fullname': 'Dr. Ahmed Mohamed',
//     'specialization': 'Cardiologist',
//     'experience': '5 years',
//     'rating': 4.8,
//     'image': 'assets/images/7.jpg',
//     'schedule': [
//       {'day': 'Monday', 'time': '9:00 AM - 12:00 PM'},
//       {'day': 'Wednesday', 'time': '1:00 PM - 4:00 PM'},
//       {'day': 'Friday', 'time': '10:00 AM - 2:00 PM'},
//     ],
//   },
//   {
    
//     'specialization': 'Pediatrician',
//     'experience': '2 years',
//     'rating': 4.9,
//     'image': 'assets/images/6.jpg',
//     'schedule': [
//       {'day': 'Tuesday', 'time': '8:00 AM - 11:00 AM'},
//       {'day': 'Thursday', 'time': '3:00 PM - 6:00 PM'},
//     ],
//   },
//   {
   
//     'specialization': 'Neurologist',
//     'experience': '3 years',
//     'rating': 4.7,
//     'image': 'assets/images/5.jpg',
//     'schedule': [
//       {'day': 'Monday', 'time': '10:00 AM - 1:00 PM'},
//       {'day': 'Thursday', 'time': '2:00 PM - 5:00 PM'},
//     ],
//   },
//   {
   
//     'specialization': 'Dermatologist',
//     'experience': '4 years',
//     'rating': 4.6,
//     'image': 'assets/images/4.jpg',
//     'schedule': [
//       {'day': 'Wednesday', 'time': '11:00 AM - 2:00 PM'},
//       {'day': 'Friday', 'time': '9:00 AM - 12:00 PM'},
//     ],
//   },
// ];

//   void updateDoctor(int index, Map<String, dynamic> updatedDoctor) {
//     setState(() {
//       doctors[index]['specialization'] = updatedDoctor['specialization'];
//       doctors[index]['experience'] = updatedDoctor['experience'];
//       doctors[index]['image'] = updatedDoctor['image'];
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('List of Doctors', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: doctors.length,
//         itemBuilder: (context, index) {
//           final doctor = doctors[index];
//           return DoctorCard(
//             doctor: doctor,
//             onEdit: () async {
//               final updatedDoctor = await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => EditDoctorScreen(doctor: doctor),
//                 ),
//               );
//               if (updatedDoctor != null) {
//                 updateDoctor(index, updatedDoctor);
//               }
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class DoctorCard extends StatelessWidget {
//   final Map<String, dynamic> doctor;
//   final VoidCallback onEdit;

//   const DoctorCard({
//     super.key,
//     required this.doctor,
//     required this.onEdit,
//   });

//   void _showScheduleDialog(BuildContext context, Map<String, dynamic> doctor) {
//   final schedule = doctor['schedule'] as List<dynamic>;

//   showDialog(
//     context: context,
//     builder: (_) => AlertDialog(
//       title: Text('${doctor['fullname']}\'s Schedule'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           DataTable(
//             columns: const [
//               DataColumn(label: Text('Day')),
//               DataColumn(label: Text('Time')),
//             ],
//             rows: schedule.map((item) {
//               return DataRow(cells: [
//                 DataCell(Text(item['day'])),
//                 DataCell(Text(item['time'])),
//               ]);
//             }).toList(),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Close'),
//         )
//       ],
//     ),
//   );
// }


//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color: Colors.grey[200],
//                     image: doctor['image'] != null
//                         ? DecorationImage(
//                             image: AssetImage(doctor['image']),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//                   ),
//                   child: doctor['image'] == null
//                       ? const Icon(Icons.person, size: 40, color: Colors.grey)
//                       : null,
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doctor['fullname'],
//                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         doctor['specialization'],
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 4),
//                        Text(
//                         doctor['experience'],
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 8),
//                       GestureDetector(
//                         onTap: () => _showScheduleDialog(context, doctor),
//                         child: const Text(
//                           'Schedule',
//                           style: TextStyle(
//                             decoration: TextDecoration.underline,
//                             decorationColor: Colors.blue,
//                             color: Colors.blue,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           const Icon(Icons.star, color: Colors.amber, size: 16),
//                           const SizedBox(width: 4),
//                           Text(
//                             doctor['rating'].toString(),
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.edit, size: 20),
//                   onPressed: onEdit,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => SetAppointmentScreen(doctor: doctor),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[800],
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text('Set Appointment', style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }






























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class BookingScreen extends StatefulWidget {
//   final String title;
  
//   const BookingScreen({super.key, required this.title});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.title}s List'),
//       ),
//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search by username',
//                 labelStyle: TextStyle(color: Colors.blue[900]),
//                 prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//                 filled: true,
//                 fillColor: Colors.white,
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: const BorderSide(color: Colors.blueGrey),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.blue[900]!),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//             ),
//           ),

//           // StreamBuilder
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .where('title', isEqualTo: widget.title)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(child: Text('No ${widget.title}s found.'));
//                 }

//                 final users = snapshot.data!.docs.where((doc) {
//                   final user = doc.data() as Map<String, dynamic>;
//                   final username = user['username']?.toLowerCase() ?? '';
//                   return username.contains(searchQuery);
//                 }).toList();

//                 if (users.isEmpty) {
//                   return const Center(child: Text('No matching results.'));
//                 }

//                 return ListView.builder(
//                   itemCount: users.length,
//                   itemBuilder: (context, index) {
//                     final doc = users[index];
//                     final user = doc.data() as Map<String, dynamic>;

//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.2),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: ListTile(
//                         leading: Icon(Icons.person, color: Colors.blue[900], size: 40),
//                         contentPadding: const EdgeInsets.all(10.0),
//                         title: Text(
//                           user['username'] ?? 'No Name',
//                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                         ),
//                         subtitle: Text(
//                           widget.title,
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                         trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[900]),
//                         onTap: () {
//                           // Add navigation to doctor details or booking page
//                         },
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class BookingScreen extends StatelessWidget {
//   const BookingScreen ({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctors List'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//          String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Search bar
//         Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: TextField(
//             decoration: InputDecoration(
//               labelText: 'Search by username',
//               labelStyle: TextStyle(color: Colors.blue[900]),
//               prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//               filled: true,
//               fillColor: Colors.white,
//               enabledBorder: OutlineInputBorder(
//                 borderSide: const BorderSide(color: Colors.blueGrey),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.blue[900]!),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//           ),
//         ),

//         // StreamBuilder
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('users')
//                 .where('title', isEqualTo: widget.title)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return Center(child: Text('No ${widget.title}s found.'));
//               }

//               final users = snapshot.data!.docs.where((doc) {
//                 final user = doc.data() as Map<String, dynamic>;
//                 final username = user['username']?.toLowerCase() ?? '';
//                 return username.contains(searchQuery);
//               }).toList();

//               if (users.isEmpty) {
//                 return const Center(child: Text('No matching results.'));
//               }

//               return ListView.builder(
//                 itemCount: users.length,
//                 itemBuilder: (context, index) {
//                   final doc = users[index];
//                   final user = doc.data() as Map<String, dynamic>;

//                   return Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.2),
//                           blurRadius: 8,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: ListTile(
//                       leading: Icon(Icons.person, color: Colors.blue[900], size: 40),
//                       contentPadding: const EdgeInsets.all(10.0),
//                       title: Text(
//                         user['username'] ?? 'No Name',
//                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                       ),
//         stream: FirebaseFirestore.instance
//             .collection('users')
//             .where('title', isEqualTo: 'Doctor')
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error occurred'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final doctors = snapshot.data!.docs;

//           if (doctors.isEmpty) {
//             return const Center(child: Text('No doctors found'));
//           }

//           return ListView.builder(
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final data = doctors[index].data() as Map<String, dynamic>;
//               final username = data['username'] ?? 'No username';

//               return ListTile(
//                 leading: const Icon(Icons.person),
//                 title: Text(username),
//                 subtitle: const Text('Doctor'),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';

// class BookingScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Pregnancy Tracker')),
//       body: Center(child: Text('Week-by-week pregnancy updates')),
//     );
//   }
// }