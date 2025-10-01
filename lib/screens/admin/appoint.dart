import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AppointScreen extends StatefulWidget {
  const AppointScreen({Key? key}) : super(key: key);

  @override
  State<AppointScreen> createState() => _AppointScreenState();
}

class _AppointScreenState extends State<AppointScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _fullNameCache = {};

  Future<String> _getFullName(String userId) async {
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy HH:mm').format(
          (timestamp as Timestamp).toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(
          (date as Timestamp).toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(String docId, String newStatus) async {
    try {
      await _firestore.collection('appointments').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }

  Widget _buildActionButton(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status']?.toString().toLowerCase() ?? 'pending';

    if (status != 'pending') {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.edit, size: 20),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'confirmed',
          child: Text('Confirm Appointment'),
        ),
        const PopupMenuItem(
          value: 'cancelled',
          child: Text('Cancel Appointment'),
        ),
      ],
      onSelected: (value) async {
        await _updateAppointmentStatus(doc.id, value);
      },
    );
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final appointments = await _firestore.collection('appointments').get();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            context: context,
            data: [
              ['Patient', 'Doctor', 'Date', 'Start Time', 'End Time', 'Fee', 'Status'],
              ...appointments.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return [
                  data['userId'] ?? 'N/A',
                  data['doctorName'] ?? 'N/A',
                  _formatDate(data['date']),
                  data['startTime']?.toString() ?? 'N/A',
                  data['endTime']?.toString() ?? 'N/A',
                  '\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}',
                  data['status']?.toString().toUpperCase() ?? 'PENDING',
                ];
              }).toList(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('appointments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No appointments found'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) => Colors.blue,
              ),
              columnSpacing: 20,
              horizontalMargin: 12,
              columns: const [
                DataColumn(
                  label: Text('Patient', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Doctor', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Start Time', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('End Time', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Fee', style: TextStyle(color: Colors.white)),
                  numeric: true,
                ),
                 DataColumn(
                  label: Text('Created At', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Updated At', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Status', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Actions', style: TextStyle(color: Colors.white)),
                ),
              ],
              rows: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(FutureBuilder<String>(
                      future: _getFullName(data['userId'] ?? ''),
                      builder: (context, snapshot) {
                        return Text(snapshot.data ?? 'Loading...');
                      },
                    )),
                    DataCell(Text(data['doctorName']?.toString() ?? 'N/A')),
                    DataCell(Text(data['startTime'] != null
                        ? (data['startTime'] is Timestamp
                            ? DateFormat('HH:mm').format((data['startTime'] as Timestamp).toDate())
                            : data['startTime'].toString())
                        : 'N/A')),
                    DataCell(Text(data['endTime'] != null
                        ? (data['endTime'] is Timestamp
                            ? DateFormat('HH:mm').format((data['endTime'] as Timestamp).toDate())
                            : data['endTime'].toString())
                        : 'N/A')),
                    DataCell(Text('\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}')),
                    DataCell(Text(_formatDate(data['date']))),
                    DataCell(Text(_formatTimestamp(data['updatedAt']))),
                    DataCell(_buildStatusBadge(data['status']?.toString().toLowerCase() ?? 'pending')),
                    DataCell(_buildActionButton(doc)),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class AppointScreen extends StatefulWidget {
//   const AppointScreen({Key? key}) : super(key: key);

//   @override
//   State<AppointScreen> createState() => _AppointScreenState();
// }

// class _AppointScreenState extends State<AppointScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Map<String, String> _fullNameCache = {};

//   Future<String> _getFullName(String userId) async {
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
//     String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     try {
//       return DateFormat('dd MMM yyyy HH:mm').format(
//           (timestamp as Timestamp).toDate());
//     } catch (e) {
//       return 'Invalid Date';
//     }
//   }

//   String __formatDate(dynamic date) {
//     if (date == null) return 'N/A';
//     try {
//       return DateFormat('dd MMM yyyy').format(
//           (date as Timestamp).toDate());
//     } catch (e) {
//       return 'Invalid Date';
//     }
//   }
  
    
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   Widget _buildStatusBadge(String status) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: _getStatusColor(status).withOpacity(0.2),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         status.toUpperCase(),
//         style: TextStyle(
//           color: _getStatusColor(status),
//           fontWeight: FontWeight.bold,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   Future<void> _updateAppointmentStatus(String docId, String newStatus) async {
//     try {
//       await _firestore.collection('appointments').doc(docId).update({
//         'status': newStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       debugPrint('Error updating appointment: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update appointment: $e')),
//       );
//     }
//   }

//   Widget _buildActionButton(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     final status = data['status']?.toString().toLowerCase() ?? 'pending';

//     if (status != 'pending') {
//       return const SizedBox.shrink();
//     }

//     return PopupMenuButton<String>(
//       icon: const Icon(Icons.edit, size: 20),
//       itemBuilder: (context) => [
//         const PopupMenuItem(
//           value: 'confirmed',
//           child: Text('Confirm Appointment'),
//         ),
//         const PopupMenuItem(
//           value: 'cancelled',
//           child: Text('Cancel Appointment'),
//         ),
//       ],
//       onSelected: (value) async {
//         await _updateAppointmentStatus(doc.id, value);
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointments'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('appointments').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No appointments found'));
//           }

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//                 headingRowColor: MaterialStateProperty.resolveWith<Color>(
//                 (Set<MaterialState> states) => Colors.blue,
//                 ),
//               columnSpacing: 20,
//               horizontalMargin: 12,
//               columns: const [
//                 // DataColumn(label: Text('Patient')),
//                 // DataColumn(label: Text('Doctor')),
//                 // DataColumn(label: Text('Date')),
//                 // DataColumn(label: Text('Fee'), numeric: true),
//                 // DataColumn(label: Text('Updated At')),
//                 // DataColumn(label: Text('Status')),
//                 // DataColumn(label: Text('Actions')),
//               DataColumn(
//   label: Text('Patient', style: TextStyle(color: Colors.white)),
// ),
// DataColumn(
//   label: Text('Doctor', style: TextStyle(color: Colors.white)),
// ),
// DataColumn(
//   label: Text('Date', style: TextStyle(color: Colors.white)),
// ),
// DataColumn(
//   label: Text('Start Time', style: TextStyle(color: Colors.white)),
// ),
// DataColumn(
//   label: Text('End Time', style: TextStyle(color: Colors.white)),
// ),
// DataColumn(
//   label: Text('Fee', style: TextStyle(color: Colors.white)),
//   numeric: true,
// ),
// DataColumn(
//   label: Text('Updated At', style: TextStyle(color: Colors.white)),
// ),
// DataColumn(
//   label: Text('Status', style: TextStyle(color: Colors.white)),
// ),
// DataColumn(
//   label: Text('Actions', style: TextStyle(color: Colors.white)),
// ),
// ],
// rows: snapshot.data!.docs.map((doc) {
//   final data = doc.data() as Map<String, dynamic>;
//   return DataRow(
//     cells: [
//       DataCell(FutureBuilder<String>(
//         future: _getFullName(data['userId'] ?? ''),
//         builder: (context, snapshot) {
//           return Text(snapshot.data ?? 'Loading...');
//         },
//       )),
//       DataCell(Text(data['doctorName']?.toString() ?? 'N/A')),
//       DataCell(Text(__formatDate(data['date']))),
//       DataCell(Text(data['startTime'] != null
//           ? (data['startTime'] is Timestamp
//               ? DateFormat('HH:mm').format((data['startTime'] as Timestamp).toDate())
//               : data['startTime'].toString())
//           : 'N/A')),
//       DataCell(Text(data['endTime'] != null
//           ? (data['endTime'] is Timestamp
//               ? DateFormat('HH:mm').format((data['endTime'] as Timestamp).toDate())
//               : data['endTime'].toString())
//           : 'N/A')),
//       DataCell(Text('\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}')),
//       DataCell(Text(_formatTimestamp(data['updatedAt']))),
//       DataCell(_buildStatusBadge(data['status']?.toString().toLowerCase() ?? 'pending')),
//       DataCell(_buildActionButton(doc)),
//     ],
//   );
// }).toList(),
// ),

// await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//           );
//         },
//       ),
//     );
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class AppointScreen extends StatefulWidget {
//   const AppointScreen({Key? key}) : super(key: key);

//   @override
//   State<AppointScreen> createState() => _AppointScreenState();
// }

// class _AppointScreenState extends State<AppointScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Map<String, String> _fullNameCache = {};

//   Future<String> _getFullName(String userId) async {
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

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     try {
//       return DateFormat('dd MMM yyyy HH:mm').format(
//           (timestamp as Timestamp).toDate());
//     } catch (e) {
//       return 'Invalid Date';
//     }
//   }

//   String _formatDate(dynamic date) {
//     if (date == null) return 'N/A';
//     try {
//       return DateFormat('dd MMM yyyy').format(
//           (date as Timestamp).toDate());
//     } catch (e) {
//       return 'Invalid Date';
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   Widget _buildStatusBadge(String status) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: _getStatusColor(status).withOpacity(0.2),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         status.toUpperCase(),
//         style: TextStyle(
//           color: _getStatusColor(status),
//           fontWeight: FontWeight.bold,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointments'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('appointments').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No appointments found'));
//           }

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               columnSpacing: 20,
//               horizontalMargin: 12,
//               columns: const [
//                 DataColumn(label: Text('Patient')),
//                 DataColumn(label: Text('Doctor')),
//                 DataColumn(label: Text('Date'), numeric: false),
//                 DataColumn(label: Text('Time'), numeric: false),
//                 DataColumn(label: Text('Fee'), numeric: true),
//                 DataColumn(label: Text('Status')),
//                 DataColumn(label: Text('Created At')),
//                 DataColumn(label: Text('Updated At')),
//               ],
//               rows: snapshot.data!.docs.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 return DataRow(
//                   cells: [
//                     DataCell(FutureBuilder<String>(
//                       future: _getFullName(data['userId'] ?? ''),
//                       builder: (context, snapshot) {
//                         return Text(snapshot.data ?? 'Loading...');
//                       },
//                     )),
//                     DataCell(Text(data['doctorName']?.toString() ?? 'N/A')),
//                     DataCell(Text(_formatDate(data['date']))),
//                     // DataCell(Text(_formatTimestamp(data['time'] ?? data['date']))),
//                     DataCell(Text('\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}')),
//                     DataCell(_buildStatusBadge(data['status']?.toString().toLowerCase() ?? 'pending')),
//                     // DataCell(Text(_formatTimestamp(data['createdAt']))),
//                     DataCell(Text(_formatTimestamp(data['updatedAt']))),
//                   ],
//                 );
//               }).toList(),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class AppointScreen extends StatefulWidget {
//   const AppointScreen({Key? key}) : super(key: key);

//   @override
//   State<AppointScreen> createState() => _AppointScreenState();
// }

// class _AppointScreenState extends State<AppointScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Map<String, String> _fullNameCache = {};

//   Future<String> _getFullName(String userId) async {
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

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     try {
//       return DateFormat('dd MMM yyyy HH:mm').format(
//           (timestamp as Timestamp).toDate());
//     } catch (e) {
//       return 'Invalid Date';
//     }
//   }

//   String _formatDate(dynamic date) {
//     if (date == null) return 'N/A';
//     try {
//       return DateFormat('dd MMM yyyy').format(
//           (date as Timestamp).toDate());
//     } catch (e) {
//       return 'Invalid Date';
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
//     final patientNameFuture = _getFullName(data['userId'] ?? '');

//     return FutureBuilder<String>(
//       future: patientNameFuture,
//       builder: (context, fullNameSnapshot) {
//         final patientName = fullNameSnapshot.data ?? 'Loading...';

//         return Card(
//           margin: const EdgeInsets.all(8.0),
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header row with patient name and status
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         'Patient: $patientName',
//                         style: const TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(data['status'] ?? 'pending')
//                             .withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         data['status']?.toString().toUpperCase() ?? 'PENDING',
//                         style: TextStyle(
//                           color: _getStatusColor(data['status'] ?? 'pending'),
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),

//                 // Doctor and Date row
//                 Row(
//                   children: [
//                     const Icon(Icons.person, size: 16, color: Colors.blue),
//                     const SizedBox(width: 4),
//                     Text('Dr. ${data['doctorName'] ?? 'N/A'}'),
//                     const Spacer(),
//                     const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
//                     const SizedBox(width: 4),
//                     Text(_formatDate(data['date'])),
//                   ],
//                 ),
//                 const SizedBox(height: 8),

//                 // Fee and time row
//                 Row(
//                   children: [
//                     const Icon(Icons.attach_money, size: 16, color: Colors.green),
//                     const SizedBox(width: 4),
//                     Text('Fee: \$${data['fee']?.toString() ?? '0'}'),
//                     const Spacer(),
//                     const Icon(Icons.access_time, size: 16, color: Colors.blue),
//                     const SizedBox(width: 4),
//                     Text(_formatTimestamp(data['time'] ?? data['date'])),
//                   ],
//                 ),
//                 const SizedBox(height: 8),

//                 // Dates footer
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Created: ${_formatTimestamp(data['createdAt'])}',
//                       style: const TextStyle(fontSize: 10, color: Colors.grey),
//                     ),
//                     Text(
//                       'Updated: ${_formatTimestamp(data['updatedAt'])}',
//                       style: const TextStyle(fontSize: 10, color: Colors.grey),
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

//   Widget _buildDesktopView(List<DocumentSnapshot> docs) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         columns: const [
//           DataColumn(label: Text('Patient')),
//           DataColumn(label: Text('Doctor')),
//           DataColumn(label: Text('Date')),
//           DataColumn(label: Text('Fee')),
//           DataColumn(label: Text('Status')),
//           DataColumn(label: Text('Created')),
//           DataColumn(label: Text('Updated')),
//         ],
//         rows: docs.map((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           return DataRow(
//             cells: [
//               DataCell(FutureBuilder<String>(
//                 future: _getFullName(data['userId'] ?? ''),
//                 builder: (context, snapshot) {
//                   return Text(snapshot.data ?? 'Loading...');
//                 },
//               )),
//               DataCell(Text(data['doctorName']?.toString() ?? 'N/A')),
//               DataCell(Text(_formatDate(data['date']))),
//               DataCell(Text('\$${data['fee']?.toString() ?? '0'}')),
//               DataCell(
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(data['status'] ?? 'pending')
//                         .withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     data['status']?.toString().toUpperCase() ?? 'PENDING',
//                     style: TextStyle(
//                       color: _getStatusColor(data['status'] ?? 'pending'),
//                     ),
//                   ),
//                 ),
//               ),
//               DataCell(Text(_formatTimestamp(data['createdAt']))),
//               DataCell(Text(_formatTimestamp(data['updatedAt']))),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointments'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('appointments').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No appointments found'));
//           }

//           final docs = snapshot.data!.docs;

//           return LayoutBuilder(
//             builder: (context, constraints) {
//               if (constraints.maxWidth > 600) {
//                 return _buildDesktopView(docs);
//               } else {
//                 return ListView.builder(
//                   itemCount: docs.length,
//                   itemBuilder: (context, index) {
//                     var appointment = docs[index];
//                     var data = appointment.data() as Map<String, dynamic>;
//                     return _buildAppointmentCard(appointment, data);
//                   },
//                 );
//               }
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

// class AppointScreen extends StatefulWidget {
//   const AppointScreen({Key? key}) : super(key: key);

//   @override
//   State<AppointScreen> createState() => _AppointScreenState();
// }

// class _AppointScreenState extends State<AppointScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Map<String, String> _fullNameCache = {};

//   Future<String> _getFullName(String userId) async {
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
//     // Format timestamps
//     String formattedCreatedAt = DateFormat('dd MMM yyyy HH:mm').format(
//         (data['createdAt'] as Timestamp).toDate());
//     String formattedDate = DateFormat('dd MMM yyyy').format(
//         (data['date'] as Timestamp).toDate());
//     String formattedUpdatedAt = DateFormat('dd MMM yyyy HH:mm').format(
//         (data['updatedAt'] as Timestamp).toDate());

//     return FutureBuilder<String>(
//       future: _getFullName(data['userId']),
//       builder: (context, fullNameSnapshot) {
//         final patientName = fullNameSnapshot.data ?? 'Loading...';

//         return Card(
//           margin: const EdgeInsets.all(8.0),
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Patient: $patientName',
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text('Doctor: ${data['doctorName']}'),
//                 Text('Appointment Date: $formattedDate'),
//                 Text('Fee: \$${data['fee'].toString()}'),
//                 Text('Status: ${data['status']}'),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Created: $formattedCreatedAt',
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 Text(
//                   'Last Updated: $formattedUpdatedAt',
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
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
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointments'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('appointments')
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No appointments found'));
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               var appointment = snapshot.data!.docs[index];
//               var data = appointment.data() as Map<String, dynamic>;
//               return _buildAppointmentCard(appointment, data);
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

// class AppointScreen  extends StatelessWidget {
//   const AppointScreen ({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointments'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('appointments')
//             // .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No appointments found'));
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               var appointment = snapshot.data!.docs[index];
//               var data = appointment.data() as Map<String, dynamic>;

//               // Format timestamps
//               String formattedCreatedAt = DateFormat('dd MMM yyyy HH:mm').format(
//                   (data['createdAt'] as Timestamp).toDate());
//               String formattedDate = DateFormat('dd MMM yyyy').format(
//                   (data['date'] as Timestamp).toDate());
//               String formattedUpdatedAt = DateFormat('dd MMM yyyy HH:mm').format(
//                   (data['updatedAt'] as Timestamp).toDate());
//                     Future<String> _getfullName(String userId) async {
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

//               return Card(
//                 margin: const EdgeInsets.all(8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Patient: ${data[ $patientName',']}',
//                         style: const TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),
//                       Text('Doctor: ${data['doctorName']}'),
//                       Text('Appointment Date: $formattedDate'),
//                       Text('Fee: \$${data['fee'].toString()}'),
//                       Text('Status: ${data['status']}'),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Created: $formattedCreatedAt',
//                         style: const TextStyle(fontSize: 12, color: Colors.grey),
//                       ),
//                       Text(
//                         'Last Updated: $formattedUpdatedAt',
//                         style: const TextStyle(fontSize: 12, color: Colors.grey),
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
// }
















// import 'package:flutter/material.dart';

// class Appoint extends StatelessWidget {
//     const Appoint({Key? key}) : super(key: key);

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold(
//             appBar: AppBar(
//                 title: const Text('Appointments'),
//             ),
//             body: const Center(
//                 child: Text('Admin Appointments Screen'),
//             ),
//         );
//     }
// }