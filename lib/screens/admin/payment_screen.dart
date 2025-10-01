import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _paymentData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    
    try {
      final payments = await _firestore.collection('payments').get();
      
      _paymentData = payments.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'patient': data['fullName'] ?? 'Unknown Patient',
          'doctor': data['doctorName'] ?? 'Unknown Doctor',
          'pPhone': data['patientPhone'] ?? 'Unknown',
          'dPhone': data['doctorPhone'] ?? 'Unknown',
          'amount': data['amount']?.toString() ?? 'N/A',
          'transaction': data['transactionId'] ?? 'Unknown transaction',
          'createdAt': data['createdAt'] != null 
              ? DateFormat('dd MMM yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())
              : 'N/A',
        };
      }).toList();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payments: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Payment Records - ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headers: ['Patient', 'Doctor', 'Patient Phone', 'Doctor Phone', 'Amount', 'Transaction ID', 'Date'],
            data: _paymentData.map((payment) => [
              payment['patient'],
              payment['doctor'],
              payment['pPhone'],
              payment['dPhone'],
              payment['amount'],
              payment['transaction'],
              payment['createdAt'],
            ]).toList(),
          ),
        ],
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
        title: const Text('Payment Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Generate PDF Report',
          ),

        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Patient')),
                  DataColumn(label: Text('Doctor')),
                  DataColumn(label: Text('Patient Phone')),
                  DataColumn(label: Text('Doctor Phone')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Transaction ID')),
                  DataColumn(label: Text('Date')),
                ],
                rows: _paymentData.map((payment) {
                  return DataRow(cells: [
                    DataCell(Text(payment['patient'])),
                    DataCell(Text(payment['doctor'])),
                    DataCell(Text(payment['pPhone'])),
                    DataCell(Text(payment['dPhone'])),
                    DataCell(Text(payment['amount'])),
                    DataCell(Text(payment['transaction'])),
                    DataCell(Text(payment['createdAt'])),
                  ]);
                }).toList(),
              ),
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

// class PaymentScreen extends StatefulWidget {
//   const PaymentScreen({Key? key}) : super(key: key);

//   @override
//   _PaymentScreenState createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> _paymentData = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadPayments();
//   }

//   Future<void> _loadPayments() async {
//     setState(() => _isLoading = true);
    
//     try {
//       final payments = await _firestore.collection('payments').get();
      
//       _paymentData = payments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown Patient',
//           'doctor': data['doctorName'] ?? 'Unknown Doctor',
//           'pPhone': data['patientPhone'] ?? 'Unknown',
//           'dPhone': data['doctorPhone'] ?? 'Unknown',
//           'amount': data['amount']?.toString() ?? 'N/A',
//           'transaction': data['transactionId'] ?? 'Unknown transaction',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading payments: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Payment Records'),
//          actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//         ],
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadPayments,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: DataTable(
//                 columns: const [
//                   DataColumn(label: Text('Patient')),
//                   DataColumn(label: Text('Doctor')),
//                   DataColumn(label: Text('Patient Phone')),
//                   DataColumn(label: Text('Doctor Phone')),
//                   DataColumn(label: Text('Amount')),
//                   DataColumn(label: Text('Transaction ID')),
//                   DataColumn(label: Text('Date')),
//                 ],
//                 rows: _paymentData.map((payment) {
//                   return DataRow(cells: [
//                     DataCell(Text(payment['patient'])),
//                     DataCell(Text(payment['doctor'])),
//                     DataCell(Text(payment['pPhone'])),
//                     DataCell(Text(payment['dPhone'])),
//                     DataCell(Text(payment['amount'])),
//                     DataCell(Text(payment['transaction'])),
//                     DataCell(Text(payment['createdAt'])),
//                   ]);
//                 }).toList(),
//               ),
//             ),
//     );
//   }
// }