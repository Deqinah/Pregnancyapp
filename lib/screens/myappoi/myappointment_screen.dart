import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Myappointment extends StatefulWidget {
  const Myappointment({Key? key}) : super(key: key);

  @override
  State<Myappointment> createState() => _MyappointmentState();
}

class _MyappointmentState extends State<Myappointment> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
  }

  Future<List<QueryDocumentSnapshot>> fetchAppointments() async {
    if (_userId == null) return [];

    // Soo qaado appointments userka leh oo status-koodu yahay confirmed ama cancelled (lowercase)
    final querySnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .where('status', whereIn: ['confirmed', 'cancelled']) // Changed to lowercase
        .get();

    return querySnapshot.docs;
  }

  String getStatusMessage(String status) {
    if (status.toLowerCase() == 'confirmed') { // Handle case sensitivity
      return 'Dhaqtarku wuu ku aqbalay codsigaaga';
    } else if (status.toLowerCase() == 'cancelled') { // Handle case sensitivity
      return 'Dhaqtarku wuu kansalay codsigaaga';
    } else {
      return '';
    }
  }

  String getDisplayStatus(String status) {
    if (status.toLowerCase() == 'confirmed') return 'Confirmed';
    if (status.toLowerCase() == 'cancelled') return 'Cancelled';
    return status;
  }

  Color getStatusColor(String status) {
    if (status.toLowerCase() == 'confirmed') return Colors.green;
    if (status.toLowerCase() == 'cancelled') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: _userId == null
          ? const Center(child: Text('Fadlan gal si aad u aragto codsiyadaada'))
          : FutureBuilder<List<QueryDocumentSnapshot>>(
              future: fetchAppointments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Ma jiraan codsiyo la xaqiijiyay ama la kansalay.'));
                }

                final appointments = snapshot.data!;
                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointmentData = appointments[index].data() as Map<String, dynamic>;
                    final status = appointmentData['status'] ?? '';
                    final doctorName = appointmentData['doctorName'] ?? 'Dhaqtarka aan la garanayn';
                    

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.medical_services, color: Colors.blue),
                        title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(getStatusMessage(status)),
                           
                          ],
                        ),
                        trailing: Chip(
                          label: Text(getDisplayStatus(status), 
                                    style: const TextStyle(color: Colors.white)),
                          backgroundColor: getStatusColor(status),
                        ),
                      ),
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

// class Myappointment extends StatefulWidget {
//   const Myappointment({Key? key}) : super(key: key);

//   @override
//   State<Myappointment> createState() => _MyappointmentState();
// }

// class _MyappointmentState extends State<Myappointment> {
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _userId = user?.uid;
//   }

//   Future<List<QueryDocumentSnapshot>> fetchAppointments() async {
//     if (_userId == null) return [];

//     // Only fetch appointments with 'Confirmed' or 'Cancelled' status
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: _userId)
//         .where('status', whereIn: ['Confirmed', 'Cancelled'])
//         // .orderBy('timestamp', descending: true) // Optional: sort by timestamp
//         .get();

//     return querySnapshot.docs;
//   }

//   String getStatusMessage(String status) {
//     if (status == 'Confirmed') {
//       return 'Dhaqtarku wuu ku aqbalay codsigaaga';
//     } else if (status == 'Cancelled') {
//       return 'Dhaqtarku wuu kansalay codsigaaga';
//     } else {
//       return '';
//     }
//   }

//   Color getStatusColor(String status) {
//     if (status == 'Confirmed') return Colors.green;
//     if (status == 'Cancelled') return Colors.red;
//     return Colors.grey;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Codsiyada Dhaqtarka')),
//       body: _userId == null
//           ? const Center(child: Text('Fadlan gal si aad u aragto codsiyadaada'))
//           : FutureBuilder<List<QueryDocumentSnapshot>>(
//               future: fetchAppointments(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.data == null || snapshot.data!.isEmpty) {
//                   return const Center(
//                       child: Text('Ma jiraan codsiyo la xaqiijiyay ama la kansalay.'));
//                 }

//                 final appointments = snapshot.data!;
//                 return ListView.builder(
//                   itemCount: appointments.length,
//                   itemBuilder: (context, index) {
//                     final appointmentData = appointments[index].data() as Map<String, dynamic>;
//                     final status = appointmentData['status'] ?? '';
//                     final doctorName = appointmentData['doctorName'] ?? 'Dhaqtarka aan la garanayn';

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       child: ListTile(
//                         leading: const Icon(Icons.medical_services, color: Colors.blue),
//                         title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                         subtitle: Text(getStatusMessage(status)),
//                         trailing: Chip(
//                           label: Text(status, style: const TextStyle(color: Colors.white)),
//                           backgroundColor: getStatusColor(status),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Myappointment extends StatefulWidget {
//   const Myappointment({Key? key}) : super(key: key);

//   @override
//   State<Myappointment> createState() => _MyappointmentState();
// }

// class _MyappointmentState extends State<Myappointment> {
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _userId = user?.uid;
//   }

//   Future<List<QueryDocumentSnapshot>> fetchAppointments() async {
//     if (_userId == null) return [];

//     // Soo qaado appointments userka leh oo status-koodu yahay Confirmed ama Cancelled
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: _userId)
//         .where('status', whereIn: ['Confirmed', 'Cancelled'])
//         .get();

//     return querySnapshot.docs;
//   }

//   String getStatusMessage(String status) {
//     if (status == 'Confirmed') {
//       return 'Dhaqtarku wuu ku aqbalay codsigaaga';
//     } else if (status == 'Cancelled') {
//       return 'Dhaqtarku wuu kansalay codsigaaga';
//     } else {
//       return '';
//     }
//   }

//   Color getStatusColor(String status) {
//     if (status == 'Confirmed') return Colors.green;
//     if (status == 'Cancelled') return Colors.red;
//     return Colors.grey;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Codsiyada Dhaqtarka')),
//       body: _userId == null
//           ? const Center(child: Text('Fadlan gal si aad u aragto codsiyadaada'))
//           : FutureBuilder<List<QueryDocumentSnapshot>>(
//               future: fetchAppointments(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.data == null || snapshot.data!.isEmpty) {
//                   return const Center(child: Text('Ma jiraan codsiyo la xaqiijiyay ama la kansalay.'));
//                 }

//                 final appointments = snapshot.data!;
//                 return ListView.builder(
//                   itemCount: appointments.length,
//                   itemBuilder: (context, index) {
//                     final appointmentData = appointments[index].data() as Map<String, dynamic>;
//                     final status = appointmentData['status'] ?? '';
//                     final doctorName = appointmentData['doctorName'] ?? 'Dhaqtarka aan la garanayn';

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       child: ListTile(
//                         leading: const Icon(Icons.medical_services, color: Colors.blue),
//                         title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                         subtitle: Text(getStatusMessage(status)),
//                         trailing: Chip(
//                           label: Text(status, style: const TextStyle(color: Colors.white)),
//                           backgroundColor: getStatusColor(status),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Myappointment extends StatefulWidget {
//   const Myappointment({Key? key}) : super(key: key);

//   @override
//   State<Myappointment> createState() => _MyappointmentState();
// }

// class _MyappointmentState extends State<Myappointment> {
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _userId = user?.uid;
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return Colors.green;
//       case 'Cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   Future<List<QueryDocumentSnapshot>> _getUserAppointments() async {
//     if (userId == null) return [];
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: userId)
//         .where('status', whereIn: ['Confirmed', 'Cancelled'])
//         .get();

//     return querySnapshot.docs;
//   }

//   String _getStatusMessage(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return 'The doctor has accepted your appointment';
//       case 'Cancelled':
//         return 'The appointment was cancelled by the doctor';
//       default:
//         return '';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: userId == null
//           ? const Center(child: Text('Please log in to view your appointments'))
//           : FutureBuilder<List<QueryDocumentSnapshot>>(
//               future: _getUserAppointments(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.data == null || snapshot.data!.isEmpty) {
//                   return const Center(
//                       child: Text('No confirmed or cancelled appointments'));
//                 }

//                 final appointments = snapshot.data!;

//                 return ListView.builder(
//                   itemCount: appointments.length,
//                   itemBuilder: (context, index) {
//                     final appointment = appointments[index];
//                     final data = appointment.data() as Map<String, dynamic>;

//                     final status = data['status'];
//                     final message = _getStatusMessage(status);

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       child: ListTile(
//                         leading: const Icon(Icons.calendar_today, color: Colors.blue),
//                         title: Text(
//                           data['doctorName'] ?? 'No name provided',
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
                        
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Myappointment extends StatefulWidget {
//   const Myappointment ({Key? key}) : super(key: key);

//   @override
//   State<Myappointment> createState() => _MyappointmentState();
// }

// class _MyappointmentState extends State<Myappointment> {
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _userId = user?.uid;
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return Colors.green;
//       case 'Cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   Stream<QuerySnapshot> _getUserAppointments() {
//     if (_userId == null) return const Stream.empty();
//     return FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: _userId)
//         .where('status', whereIn: ['Confirmed', 'Cancelled'])
//         .get(),
//   }

//   String _getStatusMessage(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return 'The doctor has accepted your appointment';
//       case 'Cancelled':
//         return 'The appointment was cancelled by the doctor';
//       default:
//         return '';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _userId == null
//           ? const Center(child: Text('Please log in to view your appointments'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: _getUserAppointments(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                       child: Text('No confirmed or cancelled appointments'));
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final appointment = snapshot.data!.docs[index];
//                     final data = appointment.data() as Map<String, dynamic>;

//                     final status = data['status'];
//                     final message = _getStatusMessage(status);

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       child: ListTile(
//                         leading: const Icon(Icons.calendar_today, color: Colors.blue),
//                         title: Text(
//                           data['doctorName'] ?? 'No name provided',
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Text(message),
//                         trailing: Chip(
//                           label: Text(
//                             status,
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                           backgroundColor: _statusColor(status),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Myappointment extends StatefulWidget {
//   const Myappointment({Key? key}) : super(key: key);

//   @override
//   State<Myappointment> createState() => _MyappointmentState();
// }

// class _MyappointmentState extends State<Myappointment> {
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _userId = user?.uid;
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return Colors.green;
//       case 'Cancelled':
//         return Colors.red;
//       default: // This case shouldn't occur with our filtering
//         return Colors.grey;
//     }
//   }

//   Stream<QuerySnapshot> _getUserAppointments() {
//     if (_userId == null) return const Stream.empty();
//     return FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: _userId)
//         .where('status', whereIn: ['Confirmed', 'Cancelled'])
//         .snapshots();
//   }

//   String _getStatusMessage(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return 'Dhaqtarku wuu ku aqbalay';
//       case 'Cancelled':
//         return 'Saacad helbel, dhaqtarka macagiisa ayaa cancel sameeyay';
//       default:
//         return '';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _userId == null
//           ? const Center(child: Text('Fadlan gal si aad u aragto codsiyadaada'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: _getUserAppointments(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text('appointment lagu aqbalay majiro ama appointment la cancelay majiro'));
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final appointment = snapshot.data!.docs[index];
//                     final data = appointment.data() as Map<String, dynamic>;

//                     final status = data['status'];
//                     final message = _getStatusMessage(status);

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       child: ListTile(
//                         leading: const Icon(Icons.calendar_today, color: Colors.blue),
//                         title: Text(
//                           data['doctorName'] ?? 'None name',
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
                       
//                         trailing: Chip(
//                           label: Text(
//                             status,
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                           backgroundColor: _statusColor(status),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Myappointment extends StatefulWidget {
//   const Myappointment({Key? key}) : super(key: key);

//   @override
//   State<Myappointment> createState() => _MyappointmentState();
// }

// class _MyappointmentState extends State<Myappointment> {
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _userId = user?.uid;
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return Colors.green;
//       case 'Cancelled':
//         return Colors.red;
//       default: // Pending or others
//         return Colors.orange;
//     }
//   }

//   Stream<QuerySnapshot> _getUserAppointments() {
//     if (_userId == null) return const Stream.empty();
//     return FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: _userId)
//         .snapshots(); // Changed from get() to snapshots()
//   }

//   String _getStatusMessage(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return 'Dhaqtarku wuu ku aqbalay';
//       case 'Cancelled':
//         return 'Saacad helbel, dhaqtarka macagiisa ayaa cancel sameeyay';
//       default:
//         return 'Majiro dhaqtar ku aqbalay wali';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Your Appointments'),
//         backgroundColor: Colors.blue,
//       ),
//       body: _userId == null
//           ? const Center(child: Text('Fadlan gal si aad u aragto codsiyadaada'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: _getUserAppointments(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text('Ma jiraan codsiyo la helay'));
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final appointment = snapshot.data!.docs[index];
//                     final data = appointment.data() as Map<String, dynamic>;

//                     final status = data['status'] ?? 'Pending';
//                     final message = _getStatusMessage(status);

//                     return Card(
//                       margin:
//                           const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       child: ListTile(
//                         leading:
//                             const Icon(Icons.calendar_today, color: Colors.blue),
//                         title: Text(
//                           data['doctorName'] ?? 'Magac la\'aan',
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
                        
                            
//                           ],
//                         ),
//                         trailing: Chip(
//                           label: Text(
//                             status,
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                           backgroundColor: _statusColor(status),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Myappointment extends StatefulWidget {
//   const Myappointment({Key? key}) : super(key: key);

//   @override
//   State<Myappointment> createState() => _MyappointmentState();
// }

// class _MyappointmentState extends State<Myappointment> {
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _userId = user?.uid;
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return Colors.green;
//       case 'Cancelled':
//         return Colors.red;
//       default: // Pending or others
//         return Colors.orange;
//     }
//   }

//   Stream<QuerySnapshot> _getUserAppointments() {
//     if (_userId == null) return const Stream.empty();
//     return FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: _userId)
//         .get(),
//   }

//   String _getStatusMessage(String status) {
//     switch (status) {
//       case 'Confirmed':
//         return 'Dhaqtarku wuu ku aqbalay';
//       case 'Cancelled':
//         return 'Saacad helbel, dhaqtarka macagiisa ayaa cancel sameeyay';
//       default:
//         return 'Majiro dhaqtar ku aqbalay wali';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Your Appointments'),
//         backgroundColor: Colors.blue,
//       ),
//       body: _userId == null
//           ? const Center(child: Text('Fadlan gal si aad u aragto codsiyadaada'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: _getUserAppointments(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text('Ma jiraan codsiyo la helay'));
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final appointment = snapshot.data!.docs[index];
//                     final data = appointment.data()! as Map<String, dynamic>;

//                     final status = data['status'] ?? 'Pending';
//                     final message = _getStatusMessage(status);

//                     return Card(
//                       margin:
//                           const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       child: ListTile(
//                         leading:
//                             const Icon(Icons.calendar_today, color: Colors.blue),
//                         title: Text(
//                           data['doctorName'] ?? 'Magac la\'aan',
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('Taariikh: ${data['date'] ?? 'N/A'}',
//                                 style: const TextStyle(fontSize: 14)),
//                             Text('Waqti: ${data['time'] ?? 'N/A'}',
//                                 style: const TextStyle(fontSize: 14)),
//                             const SizedBox(height: 4),
//                             Text(
//                               message,
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: _statusColor(status),
//                               ),
//                             ),
//                           ],
//                         ),
//                         trailing: Chip(
//                           label: Text(
//                             status,
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                           backgroundColor: _statusColor(status),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';


// class Myappointment extends StatefulWidget {
//   const  Myappointment ({Key? key}) : super(key: key);

//   @override
//   State<Myappointment> createState() => _MyappointmentState();
// }

// class _MyappointmentState extends State< Myappointment> {
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




























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class CalenderScreen extends StatefulWidget {
//   @override
//   _CalenderScreenState createState() => _CalenderScreenState();
// }

// class _CalenderScreenState extends State<CalenderScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   DateTime _selectedDate = DateTime.now();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Calendar and Diary'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: [
//             Tab(text: 'Calendar'),
//             Tab(text: 'Notes'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           CalendarTab(
//             selectedDate: _selectedDate,
//             onDateSelected: (date) {
//               setState(() {
//                 _selectedDate = date;
//               });
//             },
//             firestore: _firestore,
//           ),
//           NotesTab(
//             selectedDate: _selectedDate,
//             firestore: _firestore,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class CalendarTab extends StatelessWidget {
//   final DateTime selectedDate;
//   final Function(DateTime) onDateSelected;
//   final FirebaseFirestore firestore;

//   CalendarTab({
//     required this.selectedDate,
//     required this.onDateSelected,
//     required this.firestore,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           _buildMonthHeader(),
//           _buildCalendarGrid(),
//           _buildWeekIndicator(),
//           _buildDayDetails(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMonthHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Text(
//         DateFormat('MMMM yyyy').format(selectedDate),
//         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _buildCalendarGrid() {
//     final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
//     final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
//     final daysInMonth = lastDayOfMonth.day;
//     final firstWeekday = firstDayOfMonth.weekday;

//     List<TableRow> rows = [];
//     List<Widget> currentRow = [];

//     for (int i = 1; i < firstWeekday; i++) {
//       currentRow.add(Container());
//     }

//     for (int day = 1; day <= daysInMonth; day++) {
//       final date = DateTime(selectedDate.year, selectedDate.month, day);
//       final isSelected = date.day == selectedDate.day &&
//           date.month == selectedDate.month &&
//           date.year == selectedDate.year;

//       final isToday = date.day == DateTime.now().day &&
//           date.month == DateTime.now().month &&
//           date.year == DateTime.now().year;

//       currentRow.add(
//         GestureDetector(
//           onTap: () => onDateSelected(date),
//           child: Container(
//             margin: EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? Colors.blue
//                   : (isToday ? Colors.blue[100] : Colors.transparent),
//               shape: BoxShape.circle,
//             ),
//             alignment: Alignment.center,
//             width: 40,
//             height: 40,
//             child: Text(
//               '$day',
//               style: TextStyle(
//                 color: isSelected ? Colors.white : Colors.black,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ),
//         ),
//       );

//       if (currentRow.length == 7) {
//         rows.add(TableRow(children: currentRow));
//         currentRow = [];
//       }
//     }

//     if (currentRow.isNotEmpty) {
//       while (currentRow.length < 7) {
//         currentRow.add(Container());
//       }
//       rows.add(TableRow(children: currentRow));
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Table(
//         columnWidths: {for (int i = 0; i < 7; i++) i: FixedColumnWidth(40)},
//         children: [
//           TableRow(
//             children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
//                 .map((d) => Center(child: Text(d)))
//                 .toList(),
//           ),
//           ...rows,
//         ],
//       ),
//     );
//   }

//   Widget _buildWeekIndicator() {
//     final weekNumber = _getWeekNumber(selectedDate);
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Text(
//         'Week $weekNumber',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _buildDayDetails() {
//     return StreamBuilder<DocumentSnapshot>(
//       stream: firestore
//           .collection('notes')
//           .doc(_getDateKey(selectedDate))
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) return Text('Error: ${snapshot.error}');
//         if (!snapshot.hasData) return CircularProgressIndicator();

//         final data = snapshot.data?.data() as Map<String, dynamic>?;
//         final notes = data?['notes'] ?? 'No notes for this day';

//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat('MMMM d, yyyy').format(selectedDate),
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10),
//               Text(notes, style: TextStyle(fontSize: 16)),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   int _getWeekNumber(DateTime date) {
//     final firstDay = DateTime(date.year, 1, 1);
//     final days = date.difference(firstDay).inDays;
//     return ((days + firstDay.weekday) / 7).ceil();
//   }

//   String _getDateKey(DateTime date) {
//     return DateFormat('yyyy-MM-dd').format(date);
//   }
// }

// class NotesTab extends StatefulWidget {
//   final DateTime selectedDate;
//   final FirebaseFirestore firestore;

//   NotesTab({required this.selectedDate, required this.firestore});

//   @override
//   _NotesTabState createState() => _NotesTabState();
// }

// class _NotesTabState extends State<NotesTab> {
//   late TextEditingController _controller;
//   bool _isEditing = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = TextEditingController();
//     _loadNote();
//   }

//   @override
//   void didUpdateWidget(covariant NotesTab oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.selectedDate != widget.selectedDate) {
//       _loadNote();
//     }
//   }

//   void _loadNote() async {
//     final doc = await widget.firestore
//         .collection('notes')
//         .doc(_getDateKey(widget.selectedDate))
//         .get();

//     if (doc.exists) {
//       _controller.text = doc['notes'] ?? '';
//     } else {
//       _controller.clear();
//     }
//     setState(() => _isEditing = false);
//   }

//   void _saveNote() async {
//     await widget.firestore
//         .collection('notes')
//         .doc(_getDateKey(widget.selectedDate))
//         .set({
//       'notes': _controller.text,
//       'date': widget.selectedDate,
//       'timestamp': FieldValue.serverTimestamp(),
//     });

//     setState(() => _isEditing = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Note saved successfully')),
//     );
//   }

//   String _getDateKey(DateTime date) {
//     return DateFormat('yyyy-MM-dd').format(date);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Notes for ${DateFormat('MMMM d, yyyy').format(widget.selectedDate)}',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 10),
//           Expanded(
//             child: TextField(
//               controller: _controller,
//               maxLines: null,
//               expands: true,
//               enabled: _isEditing,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//                 hintText: 'Enter your notes...',
//               ),
//             ),
//           ),
//           SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               if (!_isEditing)
//                 ElevatedButton(
//                   onPressed: () => setState(() => _isEditing = true),
//                   child: Text('Edit'),
//                 ),
//               if (_isEditing) ...[
//                 ElevatedButton(
//                   onPressed: () {
//                     _loadNote();
//                   },
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
//                   child: Text('Cancel'),
//                 ),
//                 SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _saveNote,
//                   child: Text('Save'),
//                 ),
//               ],
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }







































// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';


// class CalenderScreen extends StatefulWidget {
//   @override
//   _CalenderScreenState createState() => _CalenderScreenState();
// }

// class _CalenderScreenState extends State<CalenderScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   DateTime _selectedDate = DateTime.now();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Calendar and Diary'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: [
//             Tab(text: 'Calendar'),
//             Tab(text: 'Notes'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           CalendarTab(
//             selectedDate: _selectedDate,
//             onDateSelected: (date) {
//               setState(() {
//                 _selectedDate = date;
//               });
//             },
//             firestore: _firestore,
//           ),
//           NotesTab(
//             selectedDate: _selectedDate,
//             firestore: _firestore,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class CalendarTab extends StatelessWidget {
//   final DateTime selectedDate;
//   final Function(DateTime) onDateSelected;
//   final FirebaseFirestore firestore;

//   CalendarTab({
//     required this.selectedDate,
//     required this.onDateSelected,
//     required this.firestore,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           _buildMonthHeader(),
//           _buildCalendarGrid(),
//           _buildWeekIndicator(),
//           _buildDayDetails(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMonthHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Text(
//         DateFormat('MMMM yyyy').format(selectedDate),
//         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _buildCalendarGrid() {
//     final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
//     final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
//     final daysInMonth = lastDayOfMonth.day;
//     final firstWeekday = firstDayOfMonth.weekday;

//     List<TableRow> rows = [];
//     List<Widget> currentRow = [];

//     // Add empty cells for days before the first day of the month
//     for (int i = 1; i < firstWeekday; i++) {
//       currentRow.add(TableCell(child: Container()));
//     }

//     for (int day = 1; day <= daysInMonth; day++) {
//       final date = DateTime(selectedDate.year, selectedDate.month, day);
//       final isSelected = day == selectedDate.day && selectedDate.month == DateTime.now().month && selectedDate.year == DateTime.now().year;
//       final isToday = day == DateTime.now().day && selectedDate.month == DateTime.now().month && selectedDate.year == DateTime.now().year;

//       currentRow.add(
//         TableCell(
//           child: GestureDetector(
//             onTap: () => onDateSelected(date),
//             child: Container(
//               margin: EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: isSelected ? Colors.blue : (isToday ? Colors.blue[100] : null),
//                 shape: BoxShape.circle,
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 day.toString(),
//                 style: TextStyle(
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                   color: isSelected ? Colors.white : null,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );

//       if (currentRow.length == 7) {
//         rows.add(TableRow(children: currentRow));
//         currentRow = [];
//       }
//     }

//     // Add remaining cells
//     if (currentRow.isNotEmpty) {
//       while (currentRow.length < 7) {
//         currentRow.add(TableCell(child: Container()));
//       }
//       rows.add(TableRow(children: currentRow));
//     }

//     return Table(
//       columnWidths: {
//         for (var i = 0; i < 7; i++) i: FixedColumnWidth(40.0),
//       },
//       children: [
//         TableRow(
//           children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
//               .map((day) => Center(child: Text(day)))
//               .toList(),
//         ),
//         ...rows,
//       ],
//     );
//   }

//   Widget _buildWeekIndicator() {
//     final weekNumber = _getWeekNumber(selectedDate);
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Text(
//         'Week $weekNumber',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _buildDayDetails() {
//     return StreamBuilder<DocumentSnapshot>(
//       stream: firestore.collection('notes').doc(_getDateKey(selectedDate)).snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Text('Error: ${snapshot.error}');
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return CircularProgressIndicator();
//         }

//         final noteData = snapshot.data?.data() as Map<String, dynamic>?;
//         final notes = noteData?['notes'] ?? 'No notes for this day';

//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat('MMMM d, yyyy').format(selectedDate),
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 notes,
//                 style: TextStyle(fontSize: 16),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   int _getWeekNumber(DateTime date) {
//     final firstDayOfYear = DateTime(date.year, 1, 1);
//     final daysDiff = date.difference(firstDayOfYear).inDays;
//     return ((daysDiff + firstDayOfYear.weekday) / 7).ceil();
//   }

//   String _getDateKey(DateTime date) {
//     return DateFormat('yyyy-MM-dd').format(date);
//   }
// }

// class NotesTab extends StatefulWidget {
//   final DateTime selectedDate;
//   final FirebaseFirestore firestore;

//   NotesTab({required this.selectedDate, required this.firestore});

//   @override
//   _NotesTabState createState() => _NotesTabState();
// }

// class _NotesTabState extends State<NotesTab> {
//   late TextEditingController _noteController;
//   bool _isEditing = false;

//   @override
//   void initState() {
//     super.initState();
//     _noteController = TextEditingController();
//     _loadNote();
//   }

//   @override
//   void didUpdateWidget(NotesTab oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.selectedDate != widget.selectedDate) {
//       _loadNote();
//     }
//   }

//   @override
//   void dispose() {
//     _noteController.dispose();
//     super.dispose();
//   }

//   void _loadNote() {
//     widget.firestore
//         .collection('notes')
//         .doc(_getDateKey(widget.selectedDate))
//         .get()
//         .then((doc) {
//       if (doc.exists) {
//         _noteController.text = doc['notes'] ?? '';
//       } else {
//         _noteController.clear();
//       }
//       setState(() {
//         _isEditing = false;
//       });
//     });
//   }

//   void _saveNote() {
//     widget.firestore
//         .collection('notes')
//         .doc(_getDateKey(widget.selectedDate))
//         .set({
//       'date': widget.selectedDate,
//       'notes': _noteController.text,
//       'timestamp': FieldValue.serverTimestamp(),
//     }).then((_) {
//       setState(() {
//         _isEditing = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Note saved successfully')),
//       );
//     });
//   }

//   String _getDateKey(DateTime date) {
//     return DateFormat('yyyy-MM-dd').format(date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Notes for ${DateFormat('MMMM d, yyyy').format(widget.selectedDate)}',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 16),
//           Expanded(
//             child: TextField(
//               controller: _noteController,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//                 hintText: 'Add your notes here...',
//               ),
//               maxLines: null,
//               expands: true,
//               enabled: _isEditing,
//             ),
//           ),
//           SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               if (!_isEditing)
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _isEditing = true;
//                     });
//                   },
//                   child: Text('Edit'),
//                 ),
//               if (_isEditing) ...[
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _isEditing = false;
//                       _loadNote();
//                     });
//                   },
//                   child: Text('Cancel'),
//                   style: ElevatedButton.styleFrom(
//                     primary: Colors.grey,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _saveNote,
//                   child: Text('Save'),
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }