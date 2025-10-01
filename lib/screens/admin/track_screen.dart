import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({Key? key}) : super(key: key);

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Color _getStatusColor(int currentWeek) {
    if (currentWeek >= 37) return Colors.green; // Full term
    if (currentWeek >= 28) return Colors.blue; // Third trimester
    if (currentWeek >= 14) return Colors.orange; // Second trimester
    return Colors.red; // First trimester
  }

  Widget _buildStatusBadge(int currentWeek) {
    String status;
    if (currentWeek >= 37) {
      status = 'FULL TERM';
    } else if (currentWeek >= 28) {
      status = 'THIRD TRIMESTER';
    } else if (currentWeek >= 14) {
      status = 'SECOND TRIMESTER';
    } else {
      status = 'FIRST TRIMESTER';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(currentWeek).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(currentWeek),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final trackingData = await _firestore.collection('trackingweeks').get();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            context: context,
            data: [
              ['Patient Name', 'Age', 'Current Week', 'Last Period', 'Due Date', 'Status'],
              ...trackingData.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final currentWeek = int.tryParse(data['currentWeek']?.toString() ?? '0') ?? 0;
                return [
                  data['fullName']?.toString() ?? 'N/A',
                  data['age']?.toString() ?? 'N/A',
                  data['currentWeek']?.toString() ?? 'N/A',
                  _formatDate(data['lastPeriodDate']),
                  _formatDate(data['dueDate']),
                  currentWeek >= 37 ? 'FULL TERM' :
                    currentWeek >= 28 ? 'THIRD TRIMESTER' :
                    currentWeek >= 14 ? 'SECOND TRIMESTER' : 'FIRST TRIMESTER',
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
        title: const Text('Patient Pregnancy Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('trackingweeks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pregnancy tracking data found'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(
                    label: Text('Patient Name'),
                  ),
                  DataColumn(
                    label: Text('Age'),
                  ),
                  DataColumn(
                    label: Text('Current Week'),
                  ),
                  DataColumn(
                    label: Text('Last Period'),
                  ),
                  DataColumn(
                    label: Text('Due Date'),
                  ),
                  DataColumn(
                    label: Text('Created At'),
                  ),
                  DataColumn(
                    label: Text('Status'),
                  ),
                ],
                rows: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final currentWeek = int.tryParse(data['currentWeek']?.toString() ?? '0') ?? 0;
                  return DataRow(
                    cells: [
                      DataCell(Text(data['fullName']?.toString() ?? 'N/A')),
                      DataCell(Text(data['age']?.toString() ?? 'N/A')),
                      DataCell(Text(data['currentWeek']?.toString() ?? 'N/A')),
                      DataCell(Text(_formatDate(data['lastPeriodDate']))),
                      DataCell(Text(_formatDate(data['dueDate']))),
                      DataCell(Text(_formatTimestamp(data['createdAt']))),
                      DataCell(_buildStatusBadge(currentWeek)),
                    ],
                  );
                }).toList(),
              ),
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

// class TrackScreen extends StatefulWidget {
//   const TrackScreen({Key? key}) : super(key: key);

//   @override
//   State<TrackScreen> createState() => _TrackScreenState();
// }

// class _TrackScreenState extends State<TrackScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

//   Color _getStatusColor(int currentWeek) {
//     if (currentWeek >= 37) return Colors.green; // Full term
//     if (currentWeek >= 28) return Colors.blue; // Third trimester
//     if (currentWeek >= 14) return Colors.orange; // Second trimester
//     return Colors.red; // First trimester
//   }

//   Widget _buildStatusBadge(int currentWeek) {
//     String status;
//     if (currentWeek >= 37) {
//       status = 'FULL TERM';
//     } else if (currentWeek >= 28) {
//       status = 'THIRD TRIMESTER';
//     } else if (currentWeek >= 14) {
//       status = 'SECOND TRIMESTER';
//     } else {
//       status = 'FIRST TRIMESTER';
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: _getStatusColor(currentWeek).withOpacity(0.2),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           color: _getStatusColor(currentWeek),
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
//         title: const Text('Patient Pregnancy Tracking'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('trackingweeks').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No pregnancy tracking data found'));
//           }

//           return SingleChildScrollView(
//             scrollDirection: Axis.vertical,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: DataTable(
//                 headingRowColor: MaterialStateProperty.resolveWith<Color>(
//                   (Set<MaterialState> states) => Colors.blue,
//                 ),
//                 columnSpacing: 20,
//                 horizontalMargin: 12,
//                 columns: const [
//                   DataColumn(
//                     label: Text('Patient Name', style: TextStyle(color: Colors.white)),
//                   ),
//                   DataColumn(
//                     label: Text('Age', style: TextStyle(color: Colors.white)),
//                   ),
//                   DataColumn(
//                     label: Text('Current Week', style: TextStyle(color: Colors.white)),
//                   ),
//                   DataColumn(
//                     label: Text('Last Period', style: TextStyle(color: Colors.white)),
//                   ),
//                   DataColumn(
//                     label: Text('Due Date', style: TextStyle(color: Colors.white)),
//                   ),
//                   DataColumn(
//                     label: Text('Created At', style: TextStyle(color: Colors.white)),
//                   ),
//                   DataColumn(
//                     label: Text('Status', style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//                 rows: snapshot.data!.docs.map((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   return DataRow(
//                     cells: [
//                       DataCell(Text(data['fullName']?.toString() ?? 'N/A')),
//                       DataCell(Text(data['age']?.toString() ?? 'N/A')),
//                       DataCell(Text(data['currentWeek']?.toString() ?? 'N/A')),
//                       DataCell(Text(_formatDate(data['lastPeriodDate']))),
//                       DataCell(Text(_formatDate(data['dueDate']))),
//                       DataCell(Text(_formatTimestamp(data['createdAt']))),
//                       DataCell(_buildStatusBadge(int.tryParse(data['currentWeek']?.toString() ?? '0') ?? 0)),
//                     ],
//                   );
//                 }).toList(),
//               ),
//               await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
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

// class TrackScreen extends StatefulWidget {
//   const TrackScreen({Key? key}) : super(key: key);

//   @override
//   State<TrackScreen> createState() => _TrackScreenState();
// }

// class _TrackScreenState extends State<TrackScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 

 
    
//     // Check cache first
 
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

//   Color _getStatusColor(String duedate) {
//     switch (duedate.toLowerCase()) {
//       default:
//         return Colors.green;
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
//         title: const Text('Patient Tracking pregnancy'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('trackingweeks').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No tracking pregnancy found'));
//           }

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               headingRowColor: MaterialStateProperty.resolveWith<Color>(
//                 (Set<MaterialState> states) => Colors.blue,
//               ),
//               columnSpacing: 20,
//               horizontalMargin: 12,
//               columns: const [
//                 DataColumn(
//                   label: Text('Patient', style: TextStyle(color: Colors.white)),
//                 ),
//                  DataColumn(
//                   label: Text('age', style: TextStyle(color: Colors.white)),
//                 ),
//                  DataColumn(
//                   label: Text('currentWeek', style: TextStyle(color: Colors.white)),
//                 ),
//                  DataColumn(
//                   label: Text('lastPeriodDate', style: TextStyle(color: Colors.white)),
//                 ),
//                  DataColumn(
//                   label: Text('dueDate', style: TextStyle(color: Colors.white)),
//                 ),

               
//                 DataColumn(
//                   label: Text('Date', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('Symptoms/Xanuun', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('Updated At', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('Status', style: TextStyle(color: Colors.white)),
//                 ),
//               ],
//               rows: snapshot.data!.docs.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 return DataRow(
//                   cells: [
//                     DataCell(FutureBuilder<String>(
//                       future: _getFullName(data['userId']?.toString() ?? ''),
//                       builder: (context, snapshot) {
//                         return Text(snapshot.data ?? 'Loading...');
//                       },
//                     )),
//                     DataCell(Text(data['fullName']?.toString() ?? 'N/A')),
//                     DataCell(Text(_formatDate(data['createdAt']))),
//                     DataCell(_buildSymptomsDisplay(data)),
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