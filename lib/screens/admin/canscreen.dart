import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Cancelcreen extends StatefulWidget {
  const Cancelcreen({Key? key}) : super(key: key);

  @override
  State<Cancelcreen> createState() => _CancelcreenState();
}

class _CancelcreenState extends State<Cancelcreen> {
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

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final appointments = await _firestore.collection('appointments')
      .where('status', isEqualTo: 'cancelled')
      .get();

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
                  data['startTime'] is Timestamp 
                    ? DateFormat('HH:mm').format((data['startTime'] as Timestamp).toDate())
                    : data['startTime']?.toString() ?? 'N/A',
                  data['endTime'] is Timestamp
                    ? DateFormat('HH:mm').format((data['endTime'] as Timestamp).toDate())
                    : data['endTime']?.toString() ?? 'N/A',
                  '\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}',
                  data['status']?.toString().toUpperCase() ?? 'CANCELLED',
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
        title: const Text('Cancelled Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('appointments')
          .where('status', isEqualTo: 'cancelled')
          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No cancelled appointments found'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('Patient')),
                DataColumn(label: Text('Doctor')),
                DataColumn(label: Text('Start Time')),
                DataColumn(label: Text('End Time')),
                DataColumn(label: Text('Fee'), numeric: true),
                 DataColumn(label: Text('Created At')),
                DataColumn(label: Text('Updated At')),
                DataColumn(label: Text('Status')),
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
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['status']?.toString() ?? 'N/A',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
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

// class Cancelcreen extends StatefulWidget {
//   const Cancelcreen({Key? key}) : super(key: key);

//   @override
//   State<Cancelcreen> createState() => _CancelcreenState();
// }

// class _CancelcreenState extends State<Cancelcreen> {
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

//   String __formatDate(dynamic date) {
//     if (date == null) return 'N/A';
//     try {
//       return DateFormat('dd MMM yyyy').format(
//           (date as Timestamp).toDate());
//     } catch (e) {
//       return 'Invalid Date';
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Cancel Appointments'),
//          actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         // Add where clause to filter only confirmed appointments
//         stream: _firestore.collection('appointments')
//           .where('status', isEqualTo: 'cancelled')
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No cancelled appointments found'));
//           }

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               columnSpacing: 20,
//               horizontalMargin: 12,
//               columns: const [
//                 DataColumn(label: Text('Patient')),
//                 DataColumn(label: Text('Doctor')),
//                 DataColumn(label: Text('Date')),
//                 DataColumn(label: Text('Start Time')),
//                 DataColumn(label: Text('End Time')),
//                 DataColumn(label: Text('Fee'), numeric: true),
//                 DataColumn(label: Text('Updated At')),
//                 DataColumn(label: Text('Status')),
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
//                     DataCell(Text(__formatDate(data['date']))),
//                     DataCell(Text(data['startTime'] != null
//           ? (data['startTime'] is Timestamp
//               ? DateFormat('HH:mm').format((data['startTime'] as Timestamp).toDate())
//               : data['startTime'].toString())
//           : 'N/A')),
//       DataCell(Text(data['endTime'] != null
//           ? (data['endTime'] is Timestamp
//               ? DateFormat('HH:mm').format((data['endTime'] as Timestamp).toDate())
//               : data['endTime'].toString())
//           : 'N/A')),
//                     DataCell(Text('\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}')),
//                     DataCell(Text(_formatTimestamp(data['updatedAt']))),
//                     // DataCell(Text(data['status']?.toString() ?? 'N/A')),
//                     DataCell(
//   Container(
//     padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
//     decoration: BoxDecoration(
//       color: Colors.red,
//       borderRadius: BorderRadius.circular(12),
//     ),
//     child: Text(
//       data['status']?.toString() ?? 'N/A',
//       style: TextStyle(color: Colors.white),
//     ),
//   ),
// ),
//                   ],
//                 );
//               }).toList(),
//             ),
//              await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }
//           );
//         },
//       ),
//     );
//   }
// }
