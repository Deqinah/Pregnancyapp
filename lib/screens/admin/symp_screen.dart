import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SympScreen extends StatefulWidget {
  const SympScreen({Key? key}) : super(key: key);

  @override
  State<SympScreen> createState() => _SympScreenState();
}

class _SympScreenState extends State<SympScreen> {
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
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'treated':
        return Colors.green;
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

  Widget _buildSymptomsDisplay(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    
    if (status == 'pending' || status == 'treated') {
      // Your logic here
    }
    return const Text('N/A');
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final symptoms = await _firestore.collection('symptoms').get();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            context: context,
            data: [
              ['Patient', 'Doctor', 'Symptoms', 'Selected', 'Treatment', 'Status', 'Created At', 'Updated At'],
              ...symptoms.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return [
                  data['fullName'] ?? 'N/A',
                  data['doctorName'] ?? 'N/A',
                  data['customSymptoms'] ?? 'N/A',
                  data['selectedSymptoms']?.toString() ?? 'N/A',
                  data['status']?.toString().toUpperCase() ?? 'PENDING',
                  data['createdAt'] != null 
                      ? DateFormat('dd MMM yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())
                      : 'N/A',
                  data['updatedAt'] != null
                      ? DateFormat('dd MMM yyyy HH:mm').format((data['updatedAt'] as Timestamp).toDate())
                      : 'N/A',
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
        title: const Text('Patient Symptoms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('symptoms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No symptoms found'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 12,
              columns: const [
                DataColumn(
                  label: Text('Patient'),
                ),
                DataColumn(
                  label: Text('Doctor'),
                ),
                DataColumn(
                  label: Text('Symptoms'),
                ),
                DataColumn(
                  label: Text('Selected'),
                ),
                DataColumn(
                  label: Text('Treated'),
                ),
                DataColumn(
                  label: Text('Status'),
                ),
                DataColumn(
                  label: Text('Created At'),
                ),
                DataColumn(
                  label: Text('Updated At'),
                ),
              ],
              rows: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(data['fullName']?.toString() ?? 'N/A')),
                    DataCell(Text(data['doctorName']?.toString() ?? 'N/A')),
                    DataCell(Text(data['customSymptoms']?.toString() ?? 'N/A')),
                    DataCell(Text(data['selectedSymptoms']?.toString() ?? 'N/A')),
                    DataCell(Text(data['treatment']?.toString() ?? 'N/A')),
                    DataCell(_buildStatusBadge(data['status']?.toString() ?? 'pending')),
                    DataCell(Text(_formatTimestamp(data['createdAt']))),
                    DataCell(Text(_formatTimestamp(data['updatedAt']))),
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

// class SympScreen extends StatefulWidget {
//   const SympScreen({Key? key}) : super(key: key);

//   @override
//   State<SympScreen> createState() => _SympScreenState();
// }

// class _SympScreenState extends State<SympScreen> {
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
  
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'treated':
//         return Colors.green;
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

//   Widget _buildSymptomsDisplay(Map<String, dynamic> data) {
//     final status = data['status']?.toString().toLowerCase() ?? 'pending';
  
    
//     if (status == 'pending' || status == 'treated') {
    
//     }
//     return const Text('N/A');
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();
//     final symptoms = await _firestore.collection('symptoms').get();

//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//           return pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Patient', 'Doctor','Symptoms','Selected','Treatment', 'Status','Created At','Updated At'],
//               ...symptoms.docs.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 return [
//                   data['fullName'] ?? 'N/A',
//                   data['doctorName'] ?? 'N/A',
//                   data['customSymptoms'] ??'N/A',
//                    data['selectedSymptoms']?? 'N/A',
//                     data['treatment']?? 'N/A',
//                   data['status']?.toString().toUpperCase() ?? 'PENDING',
//                   data[]
//                   'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//           'updatedAt': data['updatedAt'] != null
//               ? DateFormat('dd MMM yyyy HH:mm').format((data['updatedAt'] as Timestamp).toDate())
//               : 'N/A',

//                 ];
//               }).toList(),
//             ],
//           );
//         },
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient Symptoms'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('symptoms').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No symptoms found'));
//           }

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               columnSpacing: 20,
//               horizontalMargin: 12,
//               columns: const [
//                 DataColumn(
//                   label: Text('Patient' ),
//                 ),
//                 DataColumn(
//                   label: Text('Doctor'),
//                 ),
//                 DataColumn(
//                   label: Text('Date'),
//                 ),
//                 DataColumn(
//                   label: Text('Symptoms'),
//                 ),
//                 DataColumn(
//                   label: Text('Slected'),
//                 ),
//                 DataColumn(
//                   label: Text('Treated'),
//                 ),
                
//                 DataColumn(
//                   label: Text('Status'),
//                 ),
//                 DataColumn(
//                   label: Text('Created At'),
//                 ),
//                 DataColumn(
//                   label: Text('Updated At'),
//                 ),
//               ],
//               rows: snapshot.data!.docs.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 return DataRow(
//                   cells: [
//                     DataCell(Text(data['fullName']?.toString() ?? 'N/A')),
//                     DataCell(Text(data['doctorName']?.toString() ?? 'N/A')),
//                     DataCell(Text(_formatDate(data['timestamp']))),
//                     DataCell(Text(data['customSymptoms']?.toString() ?? 'N/A')),
//                     DataCell(Text(data['selectedSymptoms']?.toString() ?? 'N/A')),
//                     DataCell(Text(data['treatment']?.toString() ?? 'N/A')),
//                     DataCell(_buildStatusBadge(data['status']?.toString() ?? 'pending')),
//                     DataCell(Text(_formatTimestamp(data['createdAt']))),
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
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class SympScreen extends StatefulWidget {
//   const SympScreen({Key? key}) : super(key: key);

//   @override
//   State<SympScreen> createState() => _SympScreenState();
// }

// class _SympScreenState extends State<SympScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Map<String, String> _fullNameCache = {};

//   Future<String> _getFullName(String userId) async {
//     if (userId.isEmpty) return 'Unknown Patient';
    
//     // Check cache first
//     if (_fullNameCache.containsKey(userId)) {
//       return _fullNameCache[userId]!;
//     }

//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
      
//       if (!userDoc.exists) {
//         _fullNameCache[userId] = 'Unknown Patient';
//         return 'Unknown Patient';
//       }
      
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
//       case 'pending':
//         return Colors.orange;
//       case 'treated':
//         return Colors.green;
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

//   Widget _buildSymptomsDisplay(Map<String, dynamic> data) {
//     final status = data['status']?.toString().toLowerCase() ?? 'pending';
//     final xanuun = data['xanuun']?.toString() ?? '';
//     final symptoms = data['symptoms']?.toString() ?? '';
    
//     if (status == 'pending' || status == 'treated') {
//       return Text(xanuun.isNotEmpty ? xanuun : symptoms);
//     }
//     return const Text('N/A');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient Symptoms'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('symptoms').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No symptoms found'));
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
//                 DataColumn(
//                   label: Text('Doctor', style: TextStyle(color: Colors.white)),
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
//                     DataCell(Text(data['doctorName']?.toString() ?? 'N/A')),
//                     DataCell(Text(_formatDate(data['timestamp']))),
//                     DataCell(_buildSymptomsDisplay(data)),
//                     DataCell(Text(_formatTimestamp(data['treatedAt']))),
//                     DataCell(_buildStatusBadge(data['status']?.toString() ?? 'pending')),
//                   ],
//                 );
//               }).toList(),
//             ),
//             await Printing.layoutPdf(
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

// class SympScreen extends StatefulWidget {
//   const SympScreen({Key? key}) : super(key: key);

//   @override
//   State<SympScreen> createState() => _SympScreenState();
// }

// class _SympScreenState extends State<SympScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
//     }

//     try {
//       final userDoc = await _firestore.collection('symptoms').doc(userId).get();
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
  
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'treated':
//         return Colors.green;
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

//   // Future<void> _updateSymptomStatus(String docId, String newStatus) async {
//   //   try {
//   //     setState(() {
//   //       _isUpdating[docId] = true;
//   //     });
      
//   //     await _firestore.collection('symptoms').doc(docId).update({
//   //       'status': newStatus,
//   //       if (newStatus == 'treated') {
//   //         'treatedAt': FieldValue.serverTimestamp(),
//   //         'treatedBy': 'currentDoctorId', // You should replace this with the actual doctor ID
//   //       },
//   //       'updatedAt': FieldValue.serverTimestamp(),
//   //     });
//   //   } catch (e) {
//   //     debugPrint('Error updating symptom: $e');
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Failed to update symptom: $e')),
//   //     );
//   //   } finally {
//   //     setState(() {
//   //       _isUpdating[docId] = false;
//   //     });
//   //   }
//   // }

//   // Widget _buildActionButton(DocumentSnapshot doc) {
//   //   final data = doc.data() as Map<String, dynamic>;
//   //   final status = data['status']?.toString().toLowerCase() ?? 'pending';

//   //   if (status != 'pending') {
//   //     return const SizedBox.shrink();
//   //   }

//   //   return PopupMenuButton<String>(
//   //     icon: const Icon(Icons.edit, size: 20),
//   //     itemBuilder: (context) => [
//   //       const PopupMenuItem(
//   //         value: 'treated',
//   //         child: Text('Mark as Treated'),
//   //       ),
//   //     ],
//   //     onSelected: (value) async {
//   //       await _updateSymptomStatus(doc.id, value);
//   //     },
//   //   );
//   // }

//   Widget _buildSymptomsDisplay(Map<String, dynamic> data) {
//     final status = data['status']?.toString().toLowerCase() ?? 'pending';
//     final xanuun = data['xanuun']?.toString() ?? '';
//     final symptoms = data['symptoms']?.toString() ?? '';
    
//     if (status == 'pending' || status == 'treated') {
//       return Text(xanuun.isNotEmpty ? xanuun : symptoms);
//     }
//     return const Text('N/A');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient Symptoms'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('symptoms').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No symptoms found'));
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
//                 DataColumn(
//                   label: Text('Doctor', style: TextStyle(color: Colors.white)),
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
//                 DataColumn(
//                   label: Text('Actions', style: TextStyle(color: Colors.white)),
//                 ),
//               ],
//               rows: snapshot.data!.docs.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 final docId = doc.id;
//                 return DataRow(
//                   cells: [
//                     DataCell(FutureBuilder<String>(
//                       future: _getFullName(data['userId'] ?? ''),
//                       builder: (context, snapshot) {
//                         return Text(snapshot.data ?? 'Loading...');
//                       },
//                     )),
//                     DataCell(Text(data['doctorName']?.toString() ?? 'N/A')),
//                     DataCell(Text(__formatDate(data['timestamp']))),
//                     DataCell(_buildSymptomsDisplay(data)),
//                     DataCell(Text(_formatTimestamp(data['updatedAt']))),
//                     DataCell(_buildStatusBadge(data['status']?.toString() ?? 'pending')),
//                     // DataCell(
//                     //   _isUpdating[docId] == true
//                     //       ? const CircularProgressIndicator()
//                     //       : _buildActionButton(doc),
//                     // ),
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

// class SympScreen extends StatefulWidget {
//   const SympScreen({Key? key}) : super(key: key);

//   @override
//   State<SympScreen> createState() => _SympScreenState();
// }

// class _SympScreenState extends State<SympScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Map<String, String> _fullNameCache = {};

//   Future<String> _getFullName(String userId) async {
//     if (_fullNameCache.containsKey(userId)) {
//       return _fullNameCache[userId]!;
//     }

//     try {
//       final userDoc = await _firestore.collection('symptoms').doc(userId).get();
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
//       case 'pending':
//         return Colors.orange;
//       case 'treated':
//         return Colors.green;
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

//   Future<void> _updateSymptomStatus(String docId, String newStatus) async {
//     try {
//       await _firestore.collection('symptoms').doc(docId).update({
//         'status': newStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       debugPrint('Error updating symptom: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update symptom: $e')),
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
//           value: 'treated',
//           child: Text('treated symptom'),
//         ),
//       ],
//       onSelected: (value) async {
//         await _updateAppointmentStatus(doc.id, value);
//       },
//     );
//   }

//    final isUpdating = _isUpdating[docId] ?? false;
//     final hasSelectedSymptom = data['xanuun'] != null && data['xanuun'].toString().isNotEmpty;
//     final hasCustomSymptoms = data['symptoms'] != null && data['symptoms'].toString().isNotEmpty;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient Symptoms'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('symptoms').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No symptoms found'));
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
               
//                 DataColumn(
//                   label: Text('Patient', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('Doctor', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('Date', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('Symptoms', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('xanuun', style: TextStyle(color: Colors.white)),
//                 ),

//                 DataColumn(
//                   label: Text('Updated At', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('Fee', style: TextStyle(color: Colors.white)),
//                   numeric: true,
//                 ),
//                 DataColumn(
//                     label: Text('Updated At',style: TextStyle(color: Colors.white)),
//                     ),
//                 DataColumn(
//                   label: Text('Status', style: TextStyle(color: Colors.white)),
//                 ),
//                 DataColumn(
//                   label: Text('Actions', style: TextStyle(color: Colors.white)),
//                 ),
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
//                     DataCell(Text(_formatTimestamp(data['updatedAt']))),
//                     DataCell(_buildStatusBadge(data['status']?.toString().toLowerCase() ?? 'pending')),
//                     DataCell(_buildActionButton(doc)),
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