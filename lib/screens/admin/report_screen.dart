import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'patient_screen.dart';
import 'doctor_screen.dart';
import 'appoint.dart';
import 'conscreen.dart';
import 'canscreen.dart';
import 'symp_screen.dart';
import 'track_screen.dart';
import 'payment_screen.dart';


class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();
  
  // Statistics variables
  int _totalDoctors = 0;
  int _totalPatients = 0;
  int _totalAppointments = 0;
  int _totalPayments =0;
  int _totalSymptoms = 0;
  int _totalPregnancies = 0;
  int _totalConfirmed = 0;
  int _totalCancelled = 0;
  int _totalTreatedSymptoms = 0;
  
  // Most frequent data
  String _mostBookedDoctor = 'Loading...';
  String _mostFrequentPatient = 'Loading...';
  String _mostCommonSymptom = 'Loading...';
  
  // Patient data lists
  List<Map<String, dynamic>> _patientData = [];
  List<Map<String, dynamic>> _doctorData = [];
  List<Map<String, dynamic>> _appointmentData = [];
  List<Map<String, dynamic>> _paymentData = [];
  List<Map<String, dynamic>> _symptomData = [];
  List<Map<String, dynamic>> _pregnancyData = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    
    try {
      // Reset all counters
      _resetCounters();

      // Get all collections
      final doctors = await _firestore.collection('doctors').get();
      final users = await _firestore.collection('users').get();
      final appointments = await _firestore.collection('appointments').get();
      final payments = await _firestore.collection('payments').get();
      final symptoms = await _firestore.collection('symptoms').get();
      final pregnancies = await _firestore.collection('trackingweeks').get();

      // Set total counts
      _totalDoctors = doctors.size;
      _totalPatients = users.size;
      _totalAppointments = appointments.size;
      _totalPayments = payments.size;
      _totalSymptoms = symptoms.size;
      _totalPregnancies = pregnancies.size;
      _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
      _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;
      _totalTreatedSymptoms = symptoms.docs.where((doc) => doc['status'] == 'treated').length;

      // Process patient data
      _patientData = users.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'fullName': data['fullName'] ?? 'Unknown',
          'address': data['address'] ?? 'N/A',
          'dateOfBirth': data['dateOfBirth'] ?? 'N/A',
          'createdAt': data['createdAt'] != null 
              ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
              : 'N/A',
        };
      }).toList();

      // Process doctor data
      _doctorData = doctors.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        dynamic specialties = data['specialties'] ?? data['specialty'];
        List<String> specialtiesList = [];
        
        if (specialties is String) {
          specialtiesList = [specialties];
        } else if (specialties is List) {
          specialtiesList = List<String>.from(specialties.map((item) => item.toString()));
        } else {
          specialtiesList = ['General'];
        }

        return {
          'fullName': data['fullName'] ?? 'Unknown Doctor',
          'specialties': specialtiesList,
          'gender': data['gender'] ?? 'N/A',
         'experience': data['experience']?.toString() ?? 'N/A',
          'createdAt': data['createdAt'] != null 
              ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
              : 'N/A',
        };
      }).toList();
      // Process appointment data
_appointmentData = appointments.docs.map((doc) {
  final data = doc.data() as Map<String, dynamic>;
  return {
    'patient': data['fullName'] ?? 'Unknown Patient',
    'doctor': data['doctorName'] ?? 'Unknown Doctor',
    'date': data['date'] != null 
        ? DateFormat('dd MMM yyyy').format((data['date'] as Timestamp).toDate())
        : 'N/A',
    'startTime': data['startTime'] != null
        ? (data['startTime'] is Timestamp 
            ? DateFormat('HH:mm').format((data['startTime'] as Timestamp).toDate())
            : data['startTime'].toString())
        : 'N/A',
    'endTime': data['endTime'] != null
        ? (data['endTime'] is Timestamp 
            ? DateFormat('HH:mm').format((data['endTime'] as Timestamp).toDate())
            : data['endTime'].toString())
        : 'N/A',
    'fee': data['fee']?.toString() ?? 'N/A',
    'status': data['status'] ?? 'unknown',
    'updatedAt': data['updatedAt'] != null 
        ? DateFormat('dd MMM yyyy').format((data['updatedAt'] as Timestamp).toDate())
        : 'N/A',
  };
}).toList();
 // Process payments
_paymentData = payments.docs.map((doc) {
  final data = doc.data() as Map<String, dynamic>;
  return {
    'patient': data['fullName'] ?? 'Unknown Patient',
    'doctor': data['doctorName'] ?? 'Unknown Doctor',
    'pPhone': data['patientPhone'] ?? 'Unknown',
    'dPhone': data['doctorPhone'] ?? 'Unknown',
     'amount': data['amount']?.toString() ?? 'N/A',
     'transaction': data['transactionId'] ?? 'Unknown transaction',
    // 'status': data['status'] ?? 'unknown',
    'createdAt': data['createdAt'] != null 
        ? DateFormat('dd MMM yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())
        : 'N/A',
  };
}).toList();

      // Process symptom data with all fields
      _symptomData = symptoms.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'patient': data['fullName'] ?? 'Unknown',
          'age': data['age']?.toString() ?? 'N/A',
          'doctor': data['doctorName'] ?? 'N/A',
          'week': data['currentWeek']?.toString() ?? data['week']?.toString() ?? 'N/A',
          'symptoms': data['customSymptoms'] ?? 'No symptoms',
          'selected': data['selectedSymptoms'] ?? 'No selected symptoms',
          'treatment': data['treatment'] ?? 'N/A',
          'status': data['status'] ?? 'unknown',
          'createdAt': data['createdAt'] != null 
              ? DateFormat('dd MMM yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())
              : 'N/A',
          'updatedAt': data['updatedAt'] != null
              ? DateFormat('dd MMM yyyy HH:mm').format((data['updatedAt'] as Timestamp).toDate())
              : 'N/A',
          'assignedDoctorId': data['assignedDoctorId'] ?? 'N/A',
          'userId': data['userId'] ?? 'N/A',
          'treatedBy': data['treatedBy'] ?? 'N/A',
        };
      }).toList();

      // Process pregnancy data with all fields
      _pregnancyData = pregnancies.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'patient': data['fullName'] ?? 'Unknown',
          'age': data['age']?.toString() ?? 'N/A',
          'lastPeriod': data['lastPeriodDate'] != null 
              ? DateFormat('dd MMM yyyy').format((data['lastPeriodDate'] as Timestamp).toDate())
              : 'N/A',
          'dueDate': data['dueDate'] != null 
              ? DateFormat('dd MMM yyyy').format((data['dueDate'] as Timestamp).toDate())
              : 'N/A',
          'week': data['currentWeek']?.toString() ?? '0',
          'date': data['createdAt'] != null 
              ? DateFormat('dd MMM yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())
              : 'N/A',
          'updatedAt': data['updatedAt'] != null
              ? DateFormat('dd MMM yyyy HH:mm').format((data['updatedAt'] as Timestamp).toDate())
              : 'N/A',
        };
      }).toList();

      // Calculate most booked doctor
      final doctorAppointments = <String, int>{};
      for (var app in _appointmentData) {
        final doctor = app['doctor'];
        doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
      }
      if (doctorAppointments.isNotEmpty) {
        final sortedDoctors = doctorAppointments.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _mostBookedDoctor = sortedDoctors.first.key;
      }

      // Calculate most frequent patient
      final patientAppointments = <String, int>{};
      for (var app in _appointmentData) {
        final patient = app['patient'];
        patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
      }
      if (patientAppointments.isNotEmpty) {
        final sortedPatients = patientAppointments.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _mostFrequentPatient = sortedPatients.first.key;
      }

      // Calculate most common symptom
      final symptomCounts = <String, int>{};
      for (var symptom in _symptomData) {
        final symptoms = symptom['symptoms'];
        if (symptoms is String) {
          symptomCounts[symptoms] = (symptomCounts[symptoms] ?? 0) + 1;
        }
      }
      if (symptomCounts.isNotEmpty) {
        final sortedSymptoms = symptomCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _mostCommonSymptom = sortedSymptoms.first.key;
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reports: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetCounters() {
    _totalDoctors = 0;
    _totalPatients = 0;
    _totalAppointments = 0;
    _totalPayments = 0;
    _totalSymptoms = 0;
    _totalPregnancies = 0;
    _totalConfirmed = 0;
    _totalCancelled = 0;
    _totalTreatedSymptoms = 0;
    _mostBookedDoctor = 'Loading...';
    _mostFrequentPatient = 'Loading...';
    _mostCommonSymptom = 'Loading...';
    _patientData = [];
    _doctorData = [];
    _appointmentData = [];
    _symptomData = [];
    _pregnancyData = [];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadReports();
    }
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Maternity Care Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
          pw.SizedBox(height: 20),
          pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            context: context,
            data: [
              ['Metric', 'Count'],
              ['Total Doctors', _totalDoctors.toString()],
              ['Total Patients', _totalPatients.toString()],
              ['Total Appointments', _totalAppointments.toString()],
               ['Total Payments', _totalPayments.toString()],
              ['Confirmed Appointments', _totalConfirmed.toString()],
              ['Cancelled Appointments', _totalCancelled.toString()],
              ['Total Symptoms Reported', _totalSymptoms.toString()],
              ['Treated Symptoms', _totalTreatedSymptoms.toString()],
              ['Total Pregnancies Tracked', _totalPregnancies.toString()],
              ['Most Booked Doctor', _mostBookedDoctor],
              ['Most Frequent Patient', _mostFrequentPatient],
              ['Most Common Symptom', _mostCommonSymptom],
            ],
          ),
          
          pw.SizedBox(height: 20),
          pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            context: context,
            headers: ['Name', 'Address', 'Date of Birth', 'Joined Date'],
            data: _patientData.take(10).map((p) => [p['fullName'], p['address'], p['dateOfBirth'], p['createdAt']]).toList(),
          ),
          
          pw.SizedBox(height: 20),
          pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            context: context,
            headers: ['Name', 'Gender', 'Experience', 'Specialties', 'Joined Date'],
            data: _doctorData.take(10).map((d) => [
              d['fullName'], 
              d['gender'], 
              d['experience'],
              (d['specialties'] as List).join(', '), 
              d['createdAt']
            ]).toList(),
          ),
          
          pw.SizedBox(height: 20),
          pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            context: context,
            headers: ['Patient', 'Doctor', 'Date', 'Start Time', 'End Time', 'Fee', 'Status', 'Updated At'],
            data: _appointmentData.take(10).map((a) => [
              a['patient'], 
              a['doctor'], 
              a['date'], 
              a['startTime'], 
              a['endTime'], 
              a['fee'], 
              a['status'],
              a['updatedAt'],
            ]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Recent Payments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            context: context,
            headers: ['Patient', 'Doctor', 'PatientP', 'DoctorP', 'Amount', 'Transaction', 'Created At'],
            data: _paymentData.take(10).map((a) => [
              a['patient'], 
              a['doctor'], 
              a['pPhone'], 
              a['dPhone'], 
              a['amount'],
              a['transaction'], 
              // a['status'],
              a['createdAt'],
            ]).toList(),
          ),
          
          pw.SizedBox(height: 20),
          pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            context: context,
            headers: ['Patient', 'Age', 'Week', 'Symptoms','Selected', 'Treatment', 'Status', 'Created At', 'Updated At'],
            data: _symptomData.take(10).map((s) => [
              s['patient'], 
              s['age'], 
              s['week'], 
              s['symptoms'], 
              s['selected'],
              s['treatment'], 
              s['status'],
              s['createdAt'],
              s['updatedAt']
            ]).toList(),
          ),
          
          pw.SizedBox(height: 20),
          pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            context: context,
            headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Week', 'Created At'],
            data: _pregnancyData.take(10).map((p) => [
              p['patient'], 
              p['age'], 
              p['lastPeriod'], 
              p['dueDate'], 
              'Week ${p['week']}',
              p['date']
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maternity Care Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Generate PDF Report',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            // color: Colors.blue[900]!,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Statistics
                  const Text(
                    'Summary Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 2 : 4,
                    childAspectRatio: isMobile ? 1.2 : 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildStatCard(
                        'Doctors', 
                        _totalDoctors, 
                        Icons.medical_services, 
                        Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DoctorScreen()),
                          );
                        },
                      ),
                      _buildStatCard(
                        'Patients', 
                        _totalPatients, 
                        Icons.people, 
                        Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PatientScreen()),
                          );
                        },
                      ),
                      _buildStatCard(
                        'Appointments', 
                        _totalAppointments, 
                        Icons.calendar_today, 
                        Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AppointScreen()),
                          );
                        },
                      ),
                      _buildStatCard(
                        'Payments', 
                        _totalPayments , 
                        Icons.attach_money, 
                        Colors.indigo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PaymentScreen()),
                          );
                        },
                      ),
                      _buildStatCard(
                        'Confirmed', 
                        _totalConfirmed, 
                        Icons.check_circle, 
                        Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Confrimscreen()),
                          );
                        },
                      ),
                       _buildStatCard(
                        'Cancelled', 
                        _totalCancelled, 
                        Icons.cancel, 
                        Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Cancelcreen()),
                          );
                        },
                      ),
                      _buildStatCard(
                        'Symptoms', 
                        _totalSymptoms, 
                        Icons.health_and_safety, 
                        Colors.purple,
                         onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SympScreen()),
                          );
                        },
                      ),
                
                      _buildStatCard(
                        'Pregnancies', 
                        _totalPregnancies, 
                        Icons.pregnant_woman, 
                        Colors.pink,
                         onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TrackScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Most frequent info
                  const Text(
                    'Most Active',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 1 : 3,
                    childAspectRatio: isMobile ? 2.5 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
                      _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
                       _buildInfoCard('Most Common Symptom', _mostCommonSymptom, Icons.warning),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Recent Patients
                  const Text(
                    'Recent Patients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      dataRowHeight: isMobile ? 40 : 56,
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Address')),
                        DataColumn(label: Text('Date of Birth')),
                        DataColumn(label: Text('Joined Date')),
                      ],
                      rows: _patientData.take(isMobile ? 20 : 10).map((patient) {
                        return DataRow(cells: [
                          DataCell(Text(patient['fullName'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(patient['address'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(patient['dateOfBirth'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(patient['createdAt'], overflow: TextOverflow.ellipsis)),
                        ]);
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Recent Doctors
                  const Text(
                    'Recent Doctors',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      dataRowHeight: isMobile ? 40 : 56,
                      columns: [
                        const DataColumn(label: Text('Name')),
                        const DataColumn(label: Text('Gender')),
                        const DataColumn(label: Text('Experience')),
                        const DataColumn(label: Text('Specialties')),
                        const DataColumn(label: Text('Joined Date')),
                      ],
                      rows: _doctorData.take(isMobile ? 20 : 10).map((doctor) {
                        return DataRow(cells: [
                          DataCell(Text(doctor['fullName'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(doctor['gender'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(doctor['experience'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text((doctor['specialties'] as List).join(', '), overflow: TextOverflow.ellipsis)),
                          DataCell(Text(doctor['createdAt'], overflow: TextOverflow.ellipsis)),
                        ]);
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Recent Appointments
                  const Text(
                    'Recent Appointments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      dataRowHeight: isMobile ? 40 : 56,
                      columns: [
                        const DataColumn(label: Text('Patient')),
                        const DataColumn(label: Text('Doctor')),
                        // if (!isMobile) const DataColumn(label: Text('Time')),
                        const DataColumn(label: Text('Start Time')),
                        const DataColumn(label: Text('End Time')),
                        const DataColumn(label: Text('Fee')),
                        const DataColumn(label: Text('Status')),
                        const DataColumn(label: Text('Created At')),
                        const DataColumn(label: Text('Updated At')),
                      ],
                      rows: _appointmentData.take(isMobile ? 50 : 10).map((app) {
                        return DataRow(cells: [
                          DataCell(Text(app['patient'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['doctor'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['startTime'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['endTime'], overflow: TextOverflow.ellipsis)),
                          // if (!isMobile) DataCell(
                          //   Text('${app['startTime']} - ${app['endTime']}', 
                          //   overflow: TextOverflow.ellipsis
                          // ),
                          // ),
                          DataCell(Text(app['fee'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['status'], overflow: TextOverflow.ellipsis)),
                         DataCell(Text(app['date'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['updatedAt'], overflow: TextOverflow.ellipsis)),
                        ]);
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 20),
                  
                  // Recent Payment
                  const Text(
                    'Recent Payment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      dataRowHeight: isMobile ? 40 : 56,
                      columns: [
                        const DataColumn(label: Text('Patient')),
                        const DataColumn(label: Text('Doctor')),
                        const DataColumn(label: Text('PatientP')),
                        const DataColumn(label: Text('DoctorP')),
                        const DataColumn(label: Text('Amount')),
                        const DataColumn(label: Text('Transaction')),
                        // const DataColumn(label: Text('Status')),
                        const DataColumn(label: Text('Created At')),
                      ],
                      rows: _paymentData.take(isMobile ? 50 : 10).map((app) {
                        return DataRow(cells: [
                          DataCell(Text(app['patient'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['doctor'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['pPhone'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['dPhone'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['amount'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['transaction'], overflow: TextOverflow.ellipsis)),
                          // DataCell(Text(app['status'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(app['createdAt'], overflow: TextOverflow.ellipsis)),
                        ]);
                      }).toList(),
                    ),
                  ),
                    
                
                  const SizedBox(height: 20),
                  
                  // Recent Symptoms
                  const Text(
                    'Recent Symptoms',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      dataRowHeight: isMobile ? 40 : 56,
                      columns: [
                        const DataColumn(label: Text('Patient')),
                        const DataColumn(label: Text('Age')),
                        const DataColumn(label: Text('Week')),
                        const DataColumn(label: Text('Doctor')),
                        const DataColumn(label: Text('Symptoms')),
                        const DataColumn(label: Text('Selected')),
                        const DataColumn(label: Text('Treatment')),
                        const DataColumn(label: Text('Status')), 
                         const DataColumn(label: Text('Created At')),
                         const DataColumn(label: Text('Updated At')),
                      ],
                      rows: _symptomData.take(isMobile ? 5 : 10).map((symptom) {
                        return DataRow(cells: [
                          DataCell(Text(symptom['patient'], overflow: TextOverflow.ellipsis)),
                           DataCell(Text(symptom['age'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text('Week ${symptom['week']}', overflow: TextOverflow.ellipsis)),
                          DataCell(Text(symptom['doctor'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(symptom['symptoms'].toString(), overflow: TextOverflow.ellipsis)), 
                          DataCell(Text(symptom['selected'].toString(), overflow: TextOverflow.ellipsis)), 
                          DataCell(Text(symptom['treatment'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(symptom['status'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(symptom['createdAt'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(symptom['updatedAt'], overflow: TextOverflow.ellipsis)),
                        ]);
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Pregnancy Tracking
                  const Text(
                    'Pregnancy Tracking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      dataRowHeight: isMobile ? 40 : 56,
                      columns: [
                        const DataColumn(label: Text('Patient')),
                        const DataColumn(label: Text('Age')),
                        const DataColumn(label: Text('Last Period')),
                        const DataColumn(label: Text('Due Date')),
                        const DataColumn(label: Text('Week')),
                        const DataColumn(label: Text('Created At')),
                        const DataColumn(label: Text('Updated At')),
                      ],
                      rows: _pregnancyData.take(isMobile ? 5 : 10).map((preg) {
                        return DataRow(cells: [
                          DataCell(Text(preg['patient'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(preg['age'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(preg['lastPeriod'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(preg['dueDate'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text('Week ${preg['week']}', overflow: TextOverflow.ellipsis)),
                          DataCell(Text(preg['date'], overflow: TextOverflow.ellipsis)),
                         DataCell(Text(preg['updatedAt'], overflow: TextOverflow.ellipsis)),
                        ]);
                      }).toList(),
                    ),
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
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Patient data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Process patient data
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': data['fullName'] ?? 'Unknown',
//           'gender': data['gender'] ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth'] ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process doctor data - fixed specialties handling
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         // Handle specialties - convert to List if it's a single string or null
//         dynamic specialties = data['specialties'] ?? data['specialty'];
//         List<String> specialtiesList = [];
        
//         if (specialties is String) {
//           specialtiesList = [specialties];
//         } else if (specialties is List) {
//           specialtiesList = List<String>.from(specialties.map((item) => item.toString()));
//         } else {
//           specialtiesList = ['General'];
//         }

//         return {
//           'fullName': data['fullName'] ?? 'Unknown Doctor',
//           'specialties': specialtiesList,
//           'gender': data['gender'] ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth'] ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//           'appointments': 0,
//         };
//       }).toList();

//       // Process appointment data
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['patientName'] ?? 'Unknown',
//           'doctor': data['doctorName'] ?? 'Unknown Doctor',
//           'date': data['date'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['date'] as Timestamp).toDate())
//               : 'N/A',
//           'startTime': data['startTime'] ?? 'N/A',
//           'endTime': data['endTime'] ?? 'N/A',
//           'fee': data['fee']?.toString() ?? 'N/A',
//           'status': data['status'] ?? 'unknown',
//           'updatedAt': data['updatedAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['updatedAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process symptom data
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'doctor': data['doctorName'] ?? 'N/A',
//           'week': data['currentWeek']?.toString() ?? 'N/A',
//           'symptoms': data['symptoms'] ?? 'No symptoms',
//           'treatment': data['treatment'] ?? 'N/A',
//           'status': data['status'] ?? 'unknown',
//           'date': data['timestamp'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['timestamp'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process pregnancy data
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'lastPeriod': data['lastPeriodDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['lastPeriodDate'] as Timestamp).toDate())
//               : 'N/A',
//           'dueDate': data['dueDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['dueDate'] as Timestamp).toDate())
//               : 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'date': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'];
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'];
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _loadReports();
//     }
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Specialties', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [
//               d['fullName'], 
//               d['gender'], 
//               d['dateOfBirth'], 
//               (d['specialties'] as List).join(', '), 
//               d['createdAt']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Date', 'Start Time', 'End Time', 'Fee', 'Status', 'Updated At'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['date'], 
//               a['startTime'], 
//               a['endTime'], 
//               a['fee'], 
//               a['status'],
//               a['updatedAt']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient'], 
//               s['age'], 
//               s['week'], 
//               s['doctor'], 
//               s['symptoms'], 
//               s['treatment'], 
//               s['status'],
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Date'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient'], 
//               p['age'], 
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}',
//               p['date']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Flexible(
//                     child: Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Flexible(
//                   child: Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900]!,
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Statistics
//                   const Text(
//                     'Summary Statistics',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: isMobile ? 2 : 4,
//                     childAspectRatio: isMobile ? 1.2 : 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildStatCard(
//                         'Doctors', 
//                         _totalDoctors, 
//                         Icons.medical_services, 
//                         Colors.blue,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Patients', 
//                         _totalPatients, 
//                         Icons.people, 
//                         Colors.green,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const PatientScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Appointments', 
//                         _totalAppointments, 
//                         Icons.calendar_today, 
//                         Colors.orange,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const AppointScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Confirmed', 
//                         _totalConfirmed, 
//                         Icons.check_circle, 
//                         Colors.teal,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                           );
//                         },
//                       ),
//                       if (!isMobile) _buildStatCard(
//                         'Cancelled', 
//                         _totalCancelled, 
//                         Icons.cancel, 
//                         Colors.red,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                           );
//                         },
//                       ),
//                       if (!isMobile) _buildStatCard(
//                         'Symptoms', 
//                         _totalSymptoms, 
//                         Icons.health_and_safety, 
//                         Colors.purple
//                       ),
//                       if (!isMobile) _buildStatCard(
//                         'Pregnancies', 
//                         _totalPregnancies, 
//                         Icons.pregnant_woman, 
//                         Colors.pink
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Most frequent info
//                   const Text(
//                     'Most Active',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: isMobile ? 1 : 2,
//                     childAspectRatio: isMobile ? 2.5 : 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                       _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Patients
//                   const Text(
//                     'Recent Patients',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columnSpacing: 20,
//                       dataRowHeight: isMobile ? 40 : 56,
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Date of Birth')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _patientData.take(isMobile ? 5 : 10).map((patient) {
//                         return DataRow(cells: [
//                           DataCell(Text(patient['fullName'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(patient['gender'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(patient['dateOfBirth'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(patient['createdAt'], overflow: TextOverflow.ellipsis)),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Doctors
//                   const Text(
//                     'Recent Doctors',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columnSpacing: 20,
//                       dataRowHeight: isMobile ? 40 : 56,
//                       columns: [
//                         const DataColumn(label: Text('Name')),
//                         const DataColumn(label: Text('Gender')),
//                         if (!isMobile) const DataColumn(label: Text('Date of Birth')),
//                         const DataColumn(label: Text('Specialties')),
//                         const DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _doctorData.take(isMobile ? 5 : 10).map((doctor) {
//                         return DataRow(cells: [
//                           DataCell(Text(doctor['fullName'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(doctor['gender'], overflow: TextOverflow.ellipsis)),
//                           if (!isMobile) DataCell(Text(doctor['dateOfBirth'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text((doctor['specialties'] as List).join(', '), overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(doctor['createdAt'], overflow: TextOverflow.ellipsis)),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Appointments
//                   const Text(
//                     'Recent Appointments',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columnSpacing: 20,
//                       dataRowHeight: isMobile ? 40 : 56,
//                       columns: [
//                         const DataColumn(label: Text('Patient')),
//                         const DataColumn(label: Text('Doctor')),
//                         const DataColumn(label: Text('Date')),
//                         if (!isMobile) const DataColumn(label: Text('Start Time')),
//                         if (!isMobile) const DataColumn(label: Text('End Time')),
//                         const DataColumn(label: Text('Fee')),
//                         const DataColumn(label: Text('Status')),
//                       ],
//                       rows: _appointmentData.take(isMobile ? 5 : 10).map((app) {
//                         return DataRow(cells: [
//                           DataCell(Text(app['patient'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(app['doctor'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(app['date'], overflow: TextOverflow.ellipsis)),
//                           if (!isMobile) DataCell(Text(app['startTime'], overflow: TextOverflow.ellipsis)),
//                           if (!isMobile) DataCell(Text(app['endTime'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(app['fee'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(app['status'], overflow: TextOverflow.ellipsis)),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Symptoms
//                   const Text(
//                     'Recent Symptoms',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columnSpacing: 20,
//                       dataRowHeight: isMobile ? 40 : 56,
//                       columns: [
//                         const DataColumn(label: Text('Patient')),
//                         if (!isMobile) const DataColumn(label: Text('Age')),
//                         const DataColumn(label: Text('Week')),
//                         if (!isMobile) const DataColumn(label: Text('Doctor')),
//                         const DataColumn(label: Text('Symptoms')),
//                         const DataColumn(label: Text('Status')), 
//                       ],
//                       rows: _symptomData.take(isMobile ? 5 : 10).map((symptom) {
//                         return DataRow(cells: [
//                           DataCell(Text(symptom['patient'], overflow: TextOverflow.ellipsis)),
//                           if (!isMobile) DataCell(Text(symptom['age'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text('Week ${symptom['week']}', overflow: TextOverflow.ellipsis)),
//                           if (!isMobile) DataCell(Text(symptom['doctor'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(symptom['symptoms'].toString(), overflow: TextOverflow.ellipsis)), 
//                           DataCell(Text(symptom['status'], overflow: TextOverflow.ellipsis)),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Pregnancy Tracking
//                   const Text(
//                     'Pregnancy Tracking',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columnSpacing: 20,
//                       dataRowHeight: isMobile ? 40 : 56,
//                       columns: [
//                         const DataColumn(label: Text('Patient')),
//                         if (!isMobile) const DataColumn(label: Text('Age')),
//                         const DataColumn(label: Text('Last Period')),
//                         if (!isMobile) const DataColumn(label: Text('Due Date')),
//                         const DataColumn(label: Text('Week')),
//                         const DataColumn(label: Text('Date')),
//                       ],
//                       rows: _pregnancyData.take(isMobile ? 5 : 10).map((preg) {
//                         return DataRow(cells: [
//                           DataCell(Text(preg['patient'], overflow: TextOverflow.ellipsis)),
//                           if (!isMobile) DataCell(Text(preg['age'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(preg['lastPeriod'], overflow: TextOverflow.ellipsis)),
//                           if (!isMobile) DataCell(Text(preg['dueDate'], overflow: TextOverflow.ellipsis)),
//                           DataCell(Text('Week ${preg['week']}', overflow: TextOverflow.ellipsis)),
//                           DataCell(Text(preg['date'], overflow: TextOverflow.ellipsis)),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }




























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Patient data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Process patient data
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': data['fullName'] ?? 'Unknown',
//           'gender': data['gender'] ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth'] ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process doctor data
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': data['fullName'] ?? 'Unknown Doctor',
//           'specialties': data['specialties'] ?? ['General'],
//           'gender': data['gender'] ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth'] ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//           'appointments': 0, // Will be updated below
//         };
//       }).toList();

//       // Process appointment data
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['patientName'] ?? 'Unknown',
//           'doctor': data['doctorName'] ?? 'Unknown Doctor',
//           'date': data['date'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['date'] as Timestamp).toDate())
//               : 'N/A',
//           'startTime': data['startTime'] ?? 'N/A',
//           'endTime': data['endTime'] ?? 'N/A',
//           'fee': data['fee']?.toString() ?? 'N/A',
//           'status': data['status'] ?? 'unknown',
//           'updatedAt': data['updatedAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['updatedAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process symptom data
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'doctor': data['doctorName'] ?? 'N/A',
//           'week': data['currentWeek']?.toString() ?? 'N/A',
//           'symptoms': data['symptoms'] ?? 'No symptoms',
//           'treatment': data['treatment'] ?? 'N/A',
//           'status': data['status'] ?? 'unknown',
//           'date': data['timestamp'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['timestamp'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process pregnancy data
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'lastPeriod': data['lastPeriodDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['lastPeriodDate'] as Timestamp).toDate())
//               : 'N/A',
//           'dueDate': data['dueDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['dueDate'] as Timestamp).toDate())
//               : 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'date': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'];
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'];
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _loadReports();
//     }
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Specialties', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [
//               d['fullName'], 
//               d['gender'], 
//               d['dateOfBirth'], 
//               (d['specialties'] as List).join(', '), 
//               d['createdAt']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Date', 'Start Time', 'End Time', 'Fee', 'Status', 'Updated At'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['date'], 
//               a['startTime'], 
//               a['endTime'], 
//               a['fee'], 
//               a['status'],
//               a['updatedAt']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient'], 
//               s['age'], 
//               s['week'], 
//               s['doctor'], 
//               s['symptoms'], 
//               s['treatment'], 
//               s['status'],
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Date'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient'], 
//               p['age'], 
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}',
//               p['date']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900]!,
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Statistics
//                   const Text(
//                     'Summary Statistics',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildStatCard(
//                         'Total Doctors', 
//                         _totalDoctors, 
//                         Icons.medical_services, 
//                         Colors.blue,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Patients', 
//                         _totalPatients, 
//                         Icons.people, 
//                         Colors.green,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const PatientScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Appointments', 
//                         _totalAppointments, 
//                         Icons.calendar_today, 
//                         Colors.orange,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const AppointScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Confirmed', 
//                         _totalConfirmed, 
//                         Icons.check_circle, 
//                         Colors.teal,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Cancelled', 
//                         _totalCancelled, 
//                         Icons.cancel, 
//                         Colors.red,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Symptoms Reported', 
//                         _totalSymptoms, 
//                         Icons.health_and_safety, 
//                         Colors.purple
//                       ),
//                       _buildStatCard(
//                         'Pregnancies Tracked', 
//                         _totalPregnancies, 
//                         Icons.pregnant_woman, 
//                         Colors.teal
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Most frequent info
//                   const Text(
//                     'Most Active',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                       _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Patients
//                   const Text(
//                     'Recent Patients',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Date of Birth')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _patientData.take(10).map((patient) {
//                         return DataRow(cells: [
//                           DataCell(Text(patient['fullName'])),
//                           DataCell(Text(patient['gender'])),
//                           DataCell(Text(patient['dateOfBirth'])),
//                           DataCell(Text(patient['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Doctors
//                   const Text(
//                     'Recent Doctors',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Date of Birth')),
//                         DataColumn(label: Text('Specialties')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _doctorData.take(10).map((doctor) {
//                         return DataRow(cells: [
//                           DataCell(Text(doctor['fullName'])),
//                           DataCell(Text(doctor['gender'])),
//                           DataCell(Text(doctor['dateOfBirth'])),
//                           DataCell(Text((doctor['specialties'] as List).join(', '))),
//                           DataCell(Text(doctor['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Appointments
//                   const Text(
//                     'Recent Appointments',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Date')),
//                         DataColumn(label: Text('Start Time')),
//                         DataColumn(label: Text('End Time')),
//                         DataColumn(label: Text('Fee')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Updated At')),
//                       ],
//                       rows: _appointmentData.take(10).map((app) {
//                         return DataRow(cells: [
//                           DataCell(Text(app['patient'])),
//                           DataCell(Text(app['doctor'])),
//                           DataCell(Text(app['date'])),
//                           DataCell(Text(app['startTime'])),
//                           DataCell(Text(app['endTime'])),
//                           DataCell(Text(app['fee'])),
//                           DataCell(Text(app['status'])),
//                           DataCell(Text(app['updatedAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Symptoms
//                   const Text(
//                     'Recent Symptoms',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Symptoms')),
//                         DataColumn(label: Text('Treatment')),
//                         DataColumn(label: Text('Status')), 
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _symptomData.take(10).map((symptom) {
//                         return DataRow(cells: [
//                           DataCell(Text(symptom['patient'])),
//                           DataCell(Text(symptom['age'])),
//                           DataCell(Text('Week ${symptom['week']}')),
//                           DataCell(Text(symptom['doctor'])),
//                           DataCell(Text(symptom['symptoms'])), 
//                           DataCell(Text(symptom['treatment'])),
//                           DataCell(Text(symptom['status'])),
//                           DataCell(Text(symptom['date'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Pregnancy Tracking
//                   const Text(
//                     'Pregnancy Tracking',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Last Period')),
//                         DataColumn(label: Text('Due Date')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _pregnancyData.take(10).map((preg) {
//                         return DataRow(cells: [
//                           DataCell(Text(preg['patient'])),
//                           DataCell(Text(preg['age'])),
//                           DataCell(Text(preg['lastPeriod'])),
//                           DataCell(Text(preg['dueDate'])),
//                           DataCell(Text('Week ${preg['week']}')),
//                           DataCell(Text(preg['date'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Patient data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Process patient data
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': data['fullName'] ?? 'Unknown',
//           'gender': data['gender']?.toString() ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth']?.toString() ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process doctor data - fixed specialty handling
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': data['fullName'] ?? 'Unknown Doctor',
//           'gender': data['gender']?.toString() ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth']?.toString() ?? 'N/A',
//           'specialties': (data['specialties'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['General'],
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process appointment data
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['patientName'] ?? 'Unknown',
//           'doctor': data['doctorName'] ?? 'Unknown Doctor',
//           'date': data['date'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['date'] as Timestamp).toDate())
//               : 'N/A',
//           'status': data['status'] ?? 'unknown',
//           'startTime': data['startTime'] ?? 'N/A',
//           'endTime': data['endTime'] ?? 'N/A',
//           'fee': data['fee']?.toString() ?? 'N/A',
//           'updatedAt': data['updatedAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['updatedAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process symptom data
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'doctor': data['doctorName'] ?? 'N/A',
//           'symptoms': (data['symptoms'] as List<dynamic>?)?.join(', ') ?? 'No symptoms',
//           'treatment': data['treatment'] ?? 'N/A',
//           'status': data['status'] ?? 'unknown',
//           'date': data['timestamp'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['timestamp'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process pregnancy data
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'lastPeriod': data['lastPeriodDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['lastPeriodDate'] as Timestamp).toDate())
//               : 'N/A',
//           'dueDate': data['dueDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['dueDate'] as Timestamp).toDate())
//               : 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'date': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'];
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'];
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _loadReports();
//     }
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Specialties', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [
//               d['fullName'], 
//               d['gender'], 
//               (d['specialties'] as List).join(', '), 
//               d['createdAt']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Date', 'Status', 'Fee', 'Updated At'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['date'], 
//               a['status'],
//               a['fee'],
//               a['updatedAt']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient'], 
//               s['age'], 
//               'Week ${s['week']}', 
//               s['doctor'],
//               s['symptoms'],
//               s['status'],
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Date'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient'], 
//               p['age'], 
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}',
//               p['date']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900]!,
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Statistics
//                   const Text(
//                     'Summary Statistics',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildStatCard(
//                         'Total Doctors', 
//                         _totalDoctors, 
//                         Icons.medical_services, 
//                         Colors.blue,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Patients', 
//                         _totalPatients, 
//                         Icons.people, 
//                         Colors.green,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const PatientScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Appointments', 
//                         _totalAppointments, 
//                         Icons.calendar_today, 
//                         Colors.orange,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const AppointScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Confirmed', 
//                         _totalConfirmed, 
//                         Icons.check_circle, 
//                         Colors.teal,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Cancelled', 
//                         _totalCancelled, 
//                         Icons.cancel, 
//                         Colors.red,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Symptoms Reported', 
//                         _totalSymptoms, 
//                         Icons.health_and_safety, 
//                         Colors.purple
//                       ),
//                       _buildStatCard(
//                         'Pregnancies Tracked', 
//                         _totalPregnancies, 
//                         Icons.pregnant_woman, 
//                         Colors.teal
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Most frequent info
//                   const Text(
//                     'Most Active',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                       _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Patients
//                   const Text(
//                     'Recent Patients',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Date of Birth')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _patientData.take(10).map((patient) {
//                         return DataRow(cells: [
//                           DataCell(Text(patient['fullName'])),
//                           DataCell(Text(patient['gender'])),
//                           DataCell(Text(patient['dateOfBirth'])),
//                           DataCell(Text(patient['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Doctors
//                   const Text(
//                     'Recent Doctors',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Specialties')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _doctorData.take(10).map((doctor) {
//                         return DataRow(cells: [
//                           DataCell(Text(doctor['fullName'])),
//                           DataCell(Text(doctor['gender'])),
//                           DataCell(Text((doctor['specialties'] as List).join(', '))),
//                           DataCell(Text(doctor['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Appointments
//                   const Text(
//                     'Recent Appointments',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Start Time')),
//                         DataColumn(label: Text('End Time')),
//                         DataColumn(label: Text('Fee')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Date')),
//                         DataColumn(label: Text('Updated At')),
//                       ],
//                       rows: _appointmentData.take(10).map((app) {
//                         return DataRow(cells: [
//                           DataCell(Text(app['patient'])),
//                           DataCell(Text(app['doctor'])),
//                           DataCell(Text(app['startTime'])),
//                           DataCell(Text(app['endTime'])),
//                           DataCell(Text(app['fee'])),
//                           DataCell(Text(app['status'])),
//                           DataCell(Text(app['date'])),
//                           DataCell(Text(app['updatedAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Symptoms
//                   const Text(
//                     'Recent Symptoms',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Symptoms')),
//                         DataColumn(label: Text('Treatment')),
//                         DataColumn(label: Text('Status')), 
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _symptomData.take(10).map((symptom) {
//                         return DataRow(cells: [
//                           DataCell(Text(symptom['patient'])),
//                           DataCell(Text(symptom['age'])),
//                           DataCell(Text('Week ${symptom['week']}')),
//                           DataCell(Text(symptom['doctor'])),
//                           DataCell(Text(symptom['symptoms'])), 
//                           DataCell(Text(symptom['treatment'])),
//                           DataCell(Text(symptom['status'])),
//                           DataCell(Text(symptom['date'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Pregnancy Tracking
//                   const Text(
//                     'Pregnancy Tracking',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Last Period')),
//                         DataColumn(label: Text('Due Date')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _pregnancyData.take(10).map((preg) {
//                         return DataRow(cells: [
//                           DataCell(Text(preg['patient'])),
//                           DataCell(Text(preg['age'])),
//                           DataCell(Text(preg['lastPeriod'])),
//                           DataCell(Text(preg['dueDate'])),
//                           DataCell(Text('Week ${preg['week']}')),
//                           DataCell(Text(preg['date'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Process patient data with proper null checks
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': _getString(data, 'fullName', 'Unknown'),
//           'gender': _getString(data, 'gender', 'N/A'),
//           'dateOfBirth': _getString(data, 'dateOfBirth', 'N/A'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process doctor data with proper null checks
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': _getString(data, 'fullName', 'Unknown Doctor'),
//           'gender': _getString(data, 'gender', 'N/A'),
//           'specialties': _getString(data, 'specialties', 'General'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process appointment data with proper null checks
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'patientName', 'Unknown'),
//           'doctor': _getString(data, 'doctorName', 'Unknown Doctor'),
//           'startTime': _getString(data, 'startTime', 'N/A'),
//           'endTime': _getString(data, 'endTime', 'N/A'),
//           'fee': _getString(data, 'fee', 'N/A'),
//           'date': _formatTimestamp(data['date']),
//           'status': _getString(data, 'status', 'unknown'),
//           'updatedAt': _formatTimestamp(data['updatedAt']),
//         };
//       }).toList();

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = _appointmentData.where((a) => a['status']?.toLowerCase() == 'confirmed').length;
//       _totalCancelled = _appointmentData.where((a) => a['status']?.toLowerCase() == 'cancelled').length;

//       // Process symptom data with proper null checks
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'fullName', 'Unknown'),
//           'age': _getString(data, 'age', 'N/A'),
//           'week': _getString(data, 'currentWeek', '0'),
//           'doctor': _getString(data, 'doctorName', 'N/A'),
//           'symptoms': _getString(data, 'symptoms', 'No symptoms'),
//           'treatment': _getString(data, 'treatment', 'N/A'),
//           'status': _getString(data, 'status', 'unknown'),
//           'date': _formatTimestamp(data['timestamp']),
//         };
//       }).toList();

//       // Process pregnancy data with proper null checks
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'fullName', 'Unknown'),
//           'age': _getString(data, 'age', 'N/A'),
//           'lastPeriod': _formatTimestamp(data['lastPeriodDate']),
//           'dueDate': _formatTimestamp(data['dueDate']),
//           'week': _getString(data, 'currentWeek', '0'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'] ?? 'Unknown';
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'] ?? 'Unknown';
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   String _getString(Map<String, dynamic> data, String key, String defaultValue) {
//     final value = data[key];
//     if (value == null) return defaultValue;
//     return value.toString();
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     if (timestamp is Timestamp) {
//       return DateFormat('dd MMM yyyy').format(timestamp.toDate());
//     }
//     return 'N/A';
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _loadReports();
//     }
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Specialties', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [d['fullName'], d['gender'], d['specialties'], d['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Start Time', 'End Time', 'Fee', 'Date', 'Status'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['startTime'], 
//               a['endTime'], 
//               a['fee'],
//               a['date'], 
//               a['status']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient'], 
//               s['age'], 
//               'Week ${s['week']}',
//               s['doctor'],
//               s['symptoms'], 
//               s['treatment'],
//               s['status'],
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Created At'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient'], 
//               p['age'],
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}',
//               p['createdAt']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSpecialtyItem(String specialty, bool isMobile) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       margin: const EdgeInsets.only(right: 4, bottom: 4),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         specialty,
//         style: TextStyle(
//           fontSize: isMobile ? 12 : 14,
//           color: Colors.blue[800],
//         ),
//       ),
//     );
//   }

//   Widget _buildSpecialtiesCell(String specialties, bool isMobile) {
//     final specialtyList = specialties.split(',');
//     return Wrap(
//       children: specialtyList.map((s) => _buildSpecialtyItem(s.trim(), isMobile)).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900],
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : LayoutBuilder(
//               builder: (context, constraints) {
//                 final isMobile = constraints.maxWidth < 600;
//                 return SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Summary Statistics
//                       const Text(
//                         'Summary Statistics',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       GridView.count(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         crossAxisCount: isMobile ? 2 : 4,
//                         childAspectRatio: isMobile ? 1.2 : 1.5,
//                         crossAxisSpacing: 10,
//                         mainAxisSpacing: 10,
//                         children: [
//                           _buildStatCard(
//                             'Total Doctors', 
//                             _totalDoctors, 
//                             Icons.medical_services, 
//                             Colors.blue,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Total Patients', 
//                             _totalPatients, 
//                             Icons.people, 
//                             Colors.green,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const PatientScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Total Appointments', 
//                             _totalAppointments, 
//                             Icons.calendar_today, 
//                             Colors.orange,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const AppointScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Confirmed', 
//                             _totalConfirmed, 
//                             Icons.check_circle, 
//                             Colors.teal,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Cancelled', 
//                             _totalCancelled, 
//                             Icons.cancel, 
//                             Colors.red,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Symptoms', 
//                             _totalSymptoms, 
//                             Icons.health_and_safety, 
//                             Colors.purple
//                           ),
//                           _buildStatCard(
//                             'Pregnancies', 
//                             _totalPregnancies, 
//                             Icons.pregnant_woman, 
//                             Colors.teal
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       // Most frequent info
//                       const Text(
//                         'Most Active',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       GridView.count(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         crossAxisCount: isMobile ? 1 : 2,
//                         childAspectRatio: 2,
//                         crossAxisSpacing: 10,
//                         mainAxisSpacing: 10,
//                         children: [
//                           _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                           _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                         ],
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Patients',
//                         ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//                         _patientData.take(10).map((p) => [
//                           p['fullName'],
//                           p['gender'],
//                           p['dateOfBirth'],
//                           p['createdAt']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Doctors',
//                         ['Name', 'Gender', 'Specialties', 'Joined Date'],
//                         _doctorData.take(10).map((d) => [
//                           d['fullName'],
//                           d['gender'],
//                           d['specialties'],
//                           d['createdAt']
//                         ]).toList(),
//                         isMobile,
//                         isDoctorTable: true,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Appointments',
//                         ['Patient', 'Doctor', 'Date', 'Status'],
//                         _appointmentData.take(10).map((a) => [
//                           a['patient'],
//                           a['doctor'],
//                           a['date'],
//                           a['status']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Symptoms',
//                         ['Patient', 'Symptoms', 'Status', 'Date'],
//                         _symptomData.take(10).map((s) => [
//                           s['patient'],
//                           s['symptoms'],
//                           s['status'],
//                           s['date']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Pregnancy Tracking',
//                         ['Patient', 'Due Date', 'Current Week'],
//                         _pregnancyData.take(10).map((p) => [
//                           p['patient'],
//                           p['dueDate'],
//                           'Week ${p['week']}'
//                         ]).toList(),
//                         isMobile,
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget _buildDataTableSection(
//     String title, 
//     List<String> headers, 
//     List<List<String>> data, 
//     bool isMobile, {
//     bool isDoctorTable = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 20),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//         const SizedBox(height: 16),
//         isMobile
//             ? _buildMobileDataTable(headers, data, isDoctorTable: isDoctorTable)
//             : _buildDesktopTable(headers, data, isDoctorTable: isDoctorTable),
//       ],
//     );
//   }

//   Widget _buildDesktopTable(
//     List<String> headers, 
//     List<List<String>> data, {
//     bool isDoctorTable = false,
//   }) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         columnSpacing: 20,
//         horizontalMargin: 12,
//         columns: headers.map((header) => DataColumn(
//           label: Text(
//             header,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         )).toList(),
//         rows: data.map((row) => DataRow(
//           cells: row.asMap().entries.map((entry) {
//             final index = entry.key;
//             final value = entry.value;
//             return DataCell(
//               isDoctorTable && headers[index] == 'Specialties'
//                 ? _buildSpecialtiesCell(value, false)
//                 : Text(value),
//             );
//           }).toList(),
//         )).toList(),
//       ),
//     );
//   }

//   Widget _buildMobileDataTable(
//     List<String> headers, 
//     List<List<String>> data, {
//     bool isDoctorTable = false,
//   }) {
//     return Table(
//       border: TableBorder.all(
//         color: Colors.grey[300]!,
//         width: 1,
//       ),
//       columnWidths: {
//         for (var i = 0; i < headers.length; i++)
//           i: const FlexColumnWidth(1),
//       },
//       children: [
//         TableRow(
//           decoration: BoxDecoration(
//             color: Colors.blue[50],
//           ),
//           children: headers.map((header) => Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               header,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           )).toList(),
//         ),
//         for (var row in data)
//           TableRow(
//             children: row.asMap().entries.map((entry) {
//               final index = entry.key;
//               final value = entry.value;
//               return Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: isDoctorTable && headers[index] == 'Specialties'
//                   ? _buildSpecialtiesCell(value, true)
//                   : Text(value),
//               );
//             }).toList(),
//           ),
//       ],
//     );
//   }
// }






















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Process patient data with proper null checks
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': _getString(data, 'fullName', 'Unknown'),
//           'gender': _getString(data, 'gender', 'N/A'),
//           'dateOfBirth': _getString(data, 'dateOfBirth', 'N/A'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process doctor data with proper null checks
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': _getString(data, 'fullName', 'Unknown Doctor'),
//           'gender': _getString(data, 'gender', 'N/A'),
//           'specialties': _getString(data, 'specialties', 'General'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process appointment data with proper null checks
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'patientName', 'Unknown'),
//           'doctor': _getString(data, 'doctorName', 'Unknown Doctor'),
//           'startTime': _getString(data, 'startTime', 'N/A'),
//           'endTime': _getString(data, 'endTime', 'N/A'),
//           'fee': _getString(data, 'fee', 'N/A'),
//           'date': _formatTimestamp(data['date']),
//           'status': _getString(data, 'status', 'unknown'),
//           'updatedAt': _formatTimestamp(data['updatedAt']),
//         };
//       }).toList();

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = _appointmentData.where((a) => a['status']?.toLowerCase() == 'confirmed').length;
//       _totalCancelled = _appointmentData.where((a) => a['status']?.toLowerCase() == 'cancelled').length;

//       // Process symptom data with proper null checks
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'fullName', 'Unknown'),
//           'age': _getString(data, 'age', 'N/A'),
//           'week': _getString(data, 'currentWeek', '0'),
//           'doctor': _getString(data, 'doctorName', 'N/A'),
//           'symptoms': _getString(data, 'symptoms', 'No symptoms'),
//           'treatment': _getString(data, 'treatment', 'N/A'),
//           'status': _getString(data, 'status', 'unknown'),
//           'date': _formatTimestamp(data['timestamp']),
//         };
//       }).toList();

//       // Process pregnancy data with proper null checks
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'fullName', 'Unknown'),
//           'age': _getString(data, 'age', 'N/A'),
//           'lastPeriod': _formatTimestamp(data['lastPeriodDate']),
//           'dueDate': _formatTimestamp(data['dueDate']),
//           'week': _getString(data, 'currentWeek', '0'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'] ?? 'Unknown';
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'] ?? 'Unknown';
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   // Helper method to safely get string values
//   String _getString(Map<String, dynamic> data, String key, String defaultValue) {
//     final value = data[key];
//     if (value == null) return defaultValue;
//     return value.toString();
//   }

//   // Helper method to format timestamps
//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     if (timestamp is Timestamp) {
//       return DateFormat('dd MMM yyyy').format(timestamp.toDate());
//     }
//     return 'N/A';
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _loadReports();
//     }
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Specialties', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [d['fullName'], d['gender'], d['specialties'], d['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Start Time', 'End Time', 'Fee', 'Date', 'Status'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['startTime'], 
//               a['endTime'], 
//               a['fee'],
//               a['date'], 
//               a['status']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient'], 
//               s['age'], 
//               'Week ${s['week']}',
//               s['doctor'],
//               s['symptoms'], 
//               s['treatment'],
//               s['status'],
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Created At'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient'], 
//               p['age'],
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}',
//               p['createdAt']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSpecialtyChip(String specialty) {
//     return Chip(
//       label: Text(
//         specialty,
//         style: const TextStyle(fontSize: 12),
//       ),
//       backgroundColor: Colors.blue[50],
//       visualDensity: VisualDensity.compact,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }

//   Widget _buildSpecialtiesDisplay(String specialties, bool isMobile) {
//     final specialtyList = specialties.split(',');
    
//     if (isMobile) {
//       return Tooltip(
//         message: specialties,
//         child: Text(
//           specialtyList.first,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(fontSize: 14),
//         ),
//       );
//     }
    
//     return Wrap(
//       spacing: 4,
//       runSpacing: 4,
//       children: specialtyList.map((s) => _buildSpecialtyChip(s.trim())).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900],
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : LayoutBuilder(
//               builder: (context, constraints) {
//                 final isMobile = constraints.maxWidth < 600;
//                 return SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Summary Statistics
//                       const Text(
//                         'Summary Statistics',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       GridView.count(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         crossAxisCount: isMobile ? 2 : 4,
//                         childAspectRatio: isMobile ? 1.2 : 1.5,
//                         crossAxisSpacing: 10,
//                         mainAxisSpacing: 10,
//                         children: [
//                           _buildStatCard(
//                             'Total Doctors', 
//                             _totalDoctors, 
//                             Icons.medical_services, 
//                             Colors.blue,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Total Patients', 
//                             _totalPatients, 
//                             Icons.people, 
//                             Colors.green,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const PatientScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Total Appointments', 
//                             _totalAppointments, 
//                             Icons.calendar_today, 
//                             Colors.orange,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const AppointScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Confirmed', 
//                             _totalConfirmed, 
//                             Icons.check_circle, 
//                             Colors.teal,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Cancelled', 
//                             _totalCancelled, 
//                             Icons.cancel, 
//                             Colors.red,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Symptoms', 
//                             _totalSymptoms, 
//                             Icons.health_and_safety, 
//                             Colors.purple
//                           ),
//                           _buildStatCard(
//                             'Pregnancies', 
//                             _totalPregnancies, 
//                             Icons.pregnant_woman, 
//                             Colors.teal
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       // Most frequent info
//                       const Text(
//                         'Most Active',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       GridView.count(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         crossAxisCount: isMobile ? 1 : 2,
//                         childAspectRatio: 2,
//                         crossAxisSpacing: 10,
//                         mainAxisSpacing: 10,
//                         children: [
//                           _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                           _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                         ],
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Patients',
//                         ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//                         _patientData.take(10).map((p) => [
//                           p['fullName'],
//                           p['gender'],
//                           p['dateOfBirth'],
//                           p['createdAt']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Doctors',
//                         ['Name', 'Gender', 'Specialties', 'Joined Date'],
//                         _doctorData.take(10).map((d) => [
//                           d['fullName'],
//                           d['gender'],
//                           d['specialties'],
//                           d['createdAt']
//                         ]).toList(),
//                         isMobile,
//                         isDoctorTable: true,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Appointments',
//                         ['Patient', 'Doctor', 'Date', 'Status'],
//                         _appointmentData.take(10).map((a) => [
//                           a['patient'],
//                           a['doctor'],
//                           a['date'],
//                           a['status']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Symptoms',
//                         ['Patient', 'Symptoms', 'Status', 'Date'],
//                         _symptomData.take(10).map((s) => [
//                           s['patient'],
//                           s['symptoms'],
//                           s['status'],
//                           s['date']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Pregnancy Tracking',
//                         ['Patient', 'Due Date', 'Current Week'],
//                         _pregnancyData.take(10).map((p) => [
//                           p['patient'],
//                           p['dueDate'],
//                           'Week ${p['week']}'
//                         ]).toList(),
//                         isMobile,
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget _buildDataTableSection(
//     String title, 
//     List<String> headers, 
//     List<List<String>> data, 
//     bool isMobile, {
//     bool isDoctorTable = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 20),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//         const SizedBox(height: 16),
//         isMobile
//             ? _buildMobileDataTable(headers, data, isDoctorTable: isDoctorTable)
//             : SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: DataTable(
//                   columns: headers.map((header) => DataColumn(
//                     label: Text(header),
//                   )).toList(),
//                   rows: data.map((row) => DataRow(
//                     cells: row.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final value = entry.value;
//                       return DataCell(
//                         isDoctorTable && headers[index] == 'Specialties'
//                           ? _buildSpecialtiesDisplay(value, false)
//                           : Text(value),
//                       );
//                     }).toList(),
//                   )).toList(),
//                 ),
//               ),
//       ],
//     );
//   }

//   Widget _buildMobileDataTable(
//     List<String> headers, 
//     List<List<String>> data, {
//     bool isDoctorTable = false,
//   }) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: data.length,
//       itemBuilder: (context, index) {
//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 for (int i = 0; i < headers.length; i++)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 4.0),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         SizedBox(
//                           width: 100,
//                           child: Text(
//                             '${headers[i]}: ',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                         Expanded(
//                           child: isDoctorTable && headers[i] == 'Specialties'
//                             ? _buildSpecialtiesDisplay(data[index][i], true)
//                             : Text(
//                                 data[index][i],
//                                 overflow: TextOverflow.ellipsis,
//                                 maxLines: 2,
//                               ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Process patient data with proper null checks
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': _getString(data, 'fullName', 'Unknown'),
//           'gender': _getString(data, 'gender', 'N/A'),
//           'dateOfBirth': _getString(data, 'dateOfBirth', 'N/A'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process doctor data with proper null checks
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': _getString(data, 'fullName', 'Unknown Doctor'),
//           'gender': _getString(data, 'gender', 'N/A'),
//           'specialties': _getString(data, 'specialties', 'General'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process appointment data with proper null checks
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'patientName', 'Unknown'),
//           'doctor': _getString(data, 'doctorName', 'Unknown Doctor'),
//           'startTime': _getString(data, 'startTime', 'N/A'),
//           'endTime': _getString(data, 'endTime', 'N/A'),
//           'fee': _getString(data, 'fee', 'N/A'),
//           'date': _formatTimestamp(data['date']),
//           'status': _getString(data, 'status', 'unknown'),
//           'updatedAt': _formatTimestamp(data['updatedAt']),
//         };
//       }).toList();

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = _appointmentData.where((a) => a['status']?.toLowerCase() == 'confirmed').length;
//       _totalCancelled = _appointmentData.where((a) => a['status']?.toLowerCase() == 'cancelled').length;

//       // Process symptom data with proper null checks
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'fullName', 'Unknown'),
//           'age': _getString(data, 'age', 'N/A'),
//           'week': _getString(data, 'currentWeek', '0'),
//           'doctor': _getString(data, 'doctorName', 'N/A'),
//           'symptoms': _getString(data, 'symptoms', 'No symptoms'),
//           'treatment': _getString(data, 'treatment', 'N/A'),
//           'status': _getString(data, 'status', 'unknown'),
//           'date': _formatTimestamp(data['timestamp']),
//         };
//       }).toList();

//       // Process pregnancy data with proper null checks
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'fullName', 'Unknown'),
//           'age': _getString(data, 'age', 'N/A'),
//           'lastPeriod': _formatTimestamp(data['lastPeriodDate']),
//           'dueDate': _formatTimestamp(data['dueDate']),
//           'week': _getString(data, 'currentWeek', '0'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'] ?? 'Unknown';
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'] ?? 'Unknown';
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   // Helper method to safely get string values
//   String _getString(Map<String, dynamic> data, String key, String defaultValue) {
//     final value = data[key];
//     if (value == null) return defaultValue;
//     return value.toString();
//   }

//   // Helper method to format timestamps
//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     if (timestamp is Timestamp) {
//       return DateFormat('dd MMM yyyy').format(timestamp.toDate());
//     }
//     return 'N/A';
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _loadReports();
//     }
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [
//               p['fullName']?.toString() ?? '',
//               p['gender']?.toString() ?? '',
//               p['dateOfBirth']?.toString() ?? '',
//               p['createdAt']?.toString() ?? ''
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Specialties', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [
//               d['fullName']?.toString() ?? '',
//               d['gender']?.toString() ?? '',
//               d['specialties']?.toString() ?? '',
//               d['createdAt']?.toString() ?? ''
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Start Time', 'End Time', 'Fee', 'Date', 'Status'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient']?.toString() ?? '',
//               a['doctor']?.toString() ?? '',
//               a['startTime']?.toString() ?? '',
//               a['endTime']?.toString() ?? '',
//               a['fee']?.toString() ?? '',
//               a['date']?.toString() ?? '',
//               a['status']?.toString() ?? ''
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient']?.toString() ?? '',
//               s['age']?.toString() ?? '',
//               'Week ${s['week']?.toString() ?? '0'}',
//               s['doctor']?.toString() ?? '',
//               s['symptoms']?.toString() ?? '',
//               s['treatment']?.toString() ?? '',
//               s['status']?.toString() ?? '',
//               s['date']?.toString() ?? ''
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Created At'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient']?.toString() ?? '',
//               p['age']?.toString() ?? '',
//               p['lastPeriod']?.toString() ?? '',
//               p['dueDate']?.toString() ?? '',
//               'Week ${p['week']?.toString() ?? '0'}',
//               p['createdAt']?.toString() ?? ''
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900],
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : LayoutBuilder(
//               builder: (context, constraints) {
//                 final isMobile = constraints.maxWidth < 600;
//                 return SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Summary Statistics
//                       const Text(
//                         'Summary Statistics',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       GridView.count(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         crossAxisCount: isMobile ? 2 : 4,
//                         childAspectRatio: isMobile ? 1.2 : 1.5,
//                         crossAxisSpacing: 10,
//                         mainAxisSpacing: 10,
//                         children: [
//                           _buildStatCard(
//                             'Total Doctors', 
//                             _totalDoctors, 
//                             Icons.medical_services, 
//                             Colors.blue,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Total Patients', 
//                             _totalPatients, 
//                             Icons.people, 
//                             Colors.green,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const PatientScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Total Appointments', 
//                             _totalAppointments, 
//                             Icons.calendar_today, 
//                             Colors.orange,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const AppointScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Confirmed', 
//                             _totalConfirmed, 
//                             Icons.check_circle, 
//                             Colors.teal,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Cancelled', 
//                             _totalCancelled, 
//                             Icons.cancel, 
//                             Colors.red,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Symptoms', 
//                             _totalSymptoms, 
//                             Icons.health_and_safety, 
//                             Colors.purple
//                           ),
//                           _buildStatCard(
//                             'Pregnancies', 
//                             _totalPregnancies, 
//                             Icons.pregnant_woman, 
//                             Colors.teal
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       // Most frequent info
//                       const Text(
//                         'Most Active',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       GridView.count(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         crossAxisCount: isMobile ? 1 : 2,
//                         childAspectRatio: 2,
//                         crossAxisSpacing: 10,
//                         mainAxisSpacing: 10,
//                         children: [
//                           _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                           _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                         ],
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Patients',
//                         ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//                         _patientData.take(10).map((p) => [
//                           p['fullName']?.toString() ?? '',
//                           p['gender']?.toString() ?? '',
//                           p['dateOfBirth']?.toString() ?? '',
//                           p['createdAt']?.toString() ?? ''
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Doctors',
//                         ['Name', 'Gender', 'Specialties', 'Joined Date'],
//                         _doctorData.take(10).map((d) => [
//                           d['fullName']?.toString() ?? '',
//                           d['gender']?.toString() ?? '',
//                           d['specialties']?.toString() ?? '',
//                           d['createdAt']?.toString() ?? ''
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Appointments',
//                         ['Patient', 'Doctor', 'Date', 'Status'],
//                         _appointmentData.take(10).map((a) => [
//                           a['patient']?.toString() ?? '',
//                           a['doctor']?.toString() ?? '',
//                           a['date']?.toString() ?? '',
//                           a['status']?.toString() ?? ''
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Symptoms',
//                         ['Patient', 'Symptoms', 'Status', 'Date'],
//                         _symptomData.take(10).map((s) => [
//                           s['patient']?.toString() ?? '',
//                           s['symptoms']?.toString() ?? '',
//                           s['status']?.toString() ?? '',
//                           s['date']?.toString() ?? ''
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Pregnancy Tracking',
//                         ['Patient', 'Due Date', 'Current Week'],
//                         _pregnancyData.take(10).map((p) => [
//                           p['patient']?.toString() ?? '',
//                           p['dueDate']?.toString() ?? '',
//                           'Week ${p['week']?.toString() ?? '0'}'
//                         ]).toList(),
//                         isMobile,
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget _buildDataTableSection(String title, List<String> headers, List<List<String>> data, bool isMobile) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 20),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//         const SizedBox(height: 16),
//         isMobile
//             ? _buildMobileDataTable(headers, data)
//             : SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: DataTable(
//                   columns: headers.map((header) => DataColumn(label: Text(header))).toList(),
//                   rows: data.map((row) => DataRow(
//                     cells: row.map((cell) => DataCell(Text(cell))).toList(),
//                   )).toList(),
//                 ),
//               ),
//       ],
//     );
//   }

//   Widget _buildMobileDataTable(List<String> headers, List<List<String>> data) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: data.length,
//       itemBuilder: (context, index) {
//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 for (int i = 0; i < headers.length; i++)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 4.0),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           '${headers[i]}: ',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         Expanded(
//                           child: Text(data[index][i]),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }


























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Process patient data with proper null checks
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': _getString(data, 'fullName', 'Unknown'),
//           'gender': _getString(data, 'gender', 'N/A'),
//           'dateOfBirth': _getString(data, 'dateOfBirth', 'N/A'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process doctor data with proper null checks
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': _getString(data, 'fullName', 'Unknown Doctor'),
//           'gender': _getString(data, 'gender', 'N/A'),
//           'specialties': _getString(data, 'specialties', 'General'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process appointment data with proper null checks
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'patientName', 'Unknown'),
//           'doctor': _getString(data, 'doctorName', 'Unknown Doctor'),
//           'startTime': _getString(data, 'startTime', 'N/A'),
//           'endTime': _getString(data, 'endTime', 'N/A'),
//           'fee': _getString(data, 'fee', 'N/A'),
//           'date': _formatTimestamp(data['date']),
//           'status': _getString(data, 'status', 'unknown'),
//           'updatedAt': _formatTimestamp(data['updatedAt']),
//         };
//       }).toList();

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = _appointmentData.where((a) => a['status']?.toLowerCase() == 'confirmed').length;
//       _totalCancelled = _appointmentData.where((a) => a['status']?.toLowerCase() == 'cancelled').length;

//       // Process symptom data with proper null checks
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'fullName', 'Unknown'),
//           'age': _getString(data, 'age', 'N/A'),
//           'week': _getString(data, 'currentWeek', '0'),
//           'doctor': _getString(data, 'doctorName', 'N/A'),
//           'symptoms': _getString(data, 'symptoms', 'No symptoms'),
//           'treatment': _getString(data, 'treatment', 'N/A'),
//           'status': _getString(data, 'status', 'unknown'),
//           'date': _formatTimestamp(data['timestamp']),
//         };
//       }).toList();

//       // Process pregnancy data with proper null checks
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': _getString(data, 'fullName', 'Unknown'),
//           'age': _getString(data, 'age', 'N/A'),
//           'lastPeriod': _formatTimestamp(data['lastPeriodDate']),
//           'dueDate': _formatTimestamp(data['dueDate']),
//           'week': _getString(data, 'currentWeek', '0'),
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'] ?? 'Unknown';
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'] ?? 'Unknown';
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   // Helper method to safely get string values
//   String _getString(Map<String, dynamic> data, String key, String defaultValue) {
//     final value = data[key];
//     if (value == null) return defaultValue;
//     return value.toString();
//   }

//   // Helper method to format timestamps
//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     if (timestamp is Timestamp) {
//       return DateFormat('dd MMM yyyy').format(timestamp.toDate());
//     }
//     return 'N/A';
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _loadReports();
//     }
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Specialties', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [d['fullName'], d['gender'], d['specialties'], d['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Start Time', 'End Time', 'Fee', 'Date', 'Status'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['startTime'], 
//               a['endTime'], 
//               a['fee'],
//               a['date'], 
//               a['status']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient'], 
//               s['age'], 
//               'Week ${s['week']}',
//               s['doctor'],
//               s['symptoms'], 
//               s['treatment'],
//               s['status'],
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Created At'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient'], 
//               p['age'],
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}',
//               p['createdAt']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900],
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : LayoutBuilder(
//               builder: (context, constraints) {
//                 final isMobile = constraints.maxWidth < 600;
//                 return SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Summary Statistics
//                       const Text(
//                         'Summary Statistics',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       GridView.count(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         crossAxisCount: isMobile ? 2 : 4,
//                         childAspectRatio: isMobile ? 1.2 : 1.5,
//                         crossAxisSpacing: 10,
//                         mainAxisSpacing: 10,
//                         children: [
//                           _buildStatCard(
//                             'Total Doctors', 
//                             _totalDoctors, 
//                             Icons.medical_services, 
//                             Colors.blue,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Total Patients', 
//                             _totalPatients, 
//                             Icons.people, 
//                             Colors.green,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const PatientScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Total Appointments', 
//                             _totalAppointments, 
//                             Icons.calendar_today, 
//                             Colors.orange,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const AppointScreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Confirmed', 
//                             _totalConfirmed, 
//                             Icons.check_circle, 
//                             Colors.teal,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Cancelled', 
//                             _totalCancelled, 
//                             Icons.cancel, 
//                             Colors.red,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                               );
//                             },
//                           ),
//                           _buildStatCard(
//                             'Symptoms', 
//                             _totalSymptoms, 
//                             Icons.health_and_safety, 
//                             Colors.purple
//                           ),
//                           _buildStatCard(
//                             'Pregnancies', 
//                             _totalPregnancies, 
//                             Icons.pregnant_woman, 
//                             Colors.teal
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       // Most frequent info
//                       const Text(
//                         'Most Active',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       GridView.count(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         crossAxisCount: isMobile ? 1 : 2,
//                         childAspectRatio: 2,
//                         crossAxisSpacing: 10,
//                         mainAxisSpacing: 10,
//                         children: [
//                           _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                           _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                         ],
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Patients',
//                         ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//                         _patientData.take(10).map((p) => [
//                           p['fullName'],
//                           p['gender'],
//                           p['dateOfBirth'],
//                           p['createdAt']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Doctors',
//                         ['Name', 'Gender', 'Specialties', 'Joined Date'],
//                         _doctorData.take(10).map((d) => [
//                           d['fullName'],
//                           d['gender'],
//                           d['specialties'],
//                           d['createdAt']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Appointments',
//                         ['Patient', 'Doctor', 'Date', 'Status'],
//                         _appointmentData.take(10).map((a) => [
//                           a['patient'],
//                           a['doctor'],
//                           a['date'],
//                           a['status']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Recent Symptoms',
//                         ['Patient', 'Symptoms', 'Status', 'Date'],
//                         _symptomData.take(10).map((s) => [
//                           s['patient'],
//                           s['symptoms'],
//                           s['status'],
//                           s['date']
//                         ]).toList(),
//                         isMobile,
//                       ),
                      
//                       _buildDataTableSection(
//                         'Pregnancy Tracking',
//                         ['Patient', 'Due Date', 'Current Week'],
//                         _pregnancyData.take(10).map((p) => [
//                           p['patient'],
//                           p['dueDate'],
//                           'Week ${p['week']}'
//                         ]).toList(),
//                         isMobile,
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget _buildDataTableSection(String title, List<String> headers, List<List<String>> data, bool isMobile) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 20),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//         const SizedBox(height: 16),
//         isMobile
//             ? _buildMobileDataTable(headers, data)
//             : SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: DataTable(
//                   columns: headers.map((header) => DataColumn(label: Text(header))).toList(),
//                   rows: data.map((row) => DataRow(
//                     cells: row.map((cell) => DataCell(Text(cell))).toList(),
//                   )).toList(),
//                 ),
//               ),
//       ],
//     );
//   }

//   Widget _buildMobileDataTable(List<String> headers, List<List<String>> data) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: data.length,
//       itemBuilder: (context, index) {
//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 for (int i = 0; i < headers.length; i++)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 4.0),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           '${headers[i]}: ',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         Expanded(
//                           child: Text(data[index][i]),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Process patient data
//       _patientData = users.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'fullName': data['fullName']?.toString() ?? 'Unknown',
//           'gender': data['gender']?.toString() ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth']?.toString() ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process doctor data
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'fullName': data['fullName']?.toString() ?? 'Unknown Doctor',
//           'gender': data['gender']?.toString() ?? 'N/A',
//           'specialties': data['specialties']?.toString() ?? 'General',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process appointment data
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['patientName']?.toString() ?? 'Unknown',
//           'doctor': data['doctorName']?.toString() ?? 'Unknown Doctor',
//           'startTime': data['startTime']?.toString() ?? 'N/A',
//           'endTime': data['endTime']?.toString() ?? 'N/A',
//           'fee': data['fee']?.toString() ?? 'N/A',
//           'date': data['date'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['date'] as Timestamp).toDate())
//               : 'N/A',
//           'status': data['status']?.toString() ?? 'unknown',
//           'updatedAt': data['updatedAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['updatedAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = _appointmentData.where((a) => a['status'] == 'confirmed').length;
//       _totalCancelled = _appointmentData.where((a) => a['status'] == 'cancelled').length;

//       // Process symptom data
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['fullName']?.toString() ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'doctor': data['doctorName']?.toString() ?? 'N/A',
//           'symptoms': data['symptoms']?.toString() ?? 'No symptoms',
//           'treatment': data['treatment']?.toString() ?? 'N/A',
//           'status': data['status']?.toString() ?? 'unknown',
//           'date': data['timestamp'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['timestamp'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process pregnancy data
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['fullName']?.toString() ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'lastPeriod': data['lastPeriodDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['lastPeriodDate'] as Timestamp).toDate())
//               : 'N/A',
//           'dueDate': data['dueDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['dueDate'] as Timestamp).toDate())
//               : 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'];
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'];
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _loadReports();
//     }
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Start Time', 'End Time', 'Fee', 'Date', 'Status'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['startTime'], 
//               a['endTime'], 
//               a['fee'],
//               a['date'], 
//               a['status']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient'], 
//               s['age'], 
//               'Week ${s['week']}',
//               s['doctor'],
//               s['symptoms'], 
//               s['treatment'],
//               s['status'],
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Created At'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient'], 
//               p['age'],
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}',
//               p['createdAt']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900],
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Statistics
//                   const Text(
//                     'Summary Statistics',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildStatCard(
//                         'Total Doctors', 
//                         _totalDoctors, 
//                         Icons.medical_services, 
//                         Colors.blue,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Patients', 
//                         _totalPatients, 
//                         Icons.people, 
//                         Colors.green,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const PatientScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Appointments', 
//                         _totalAppointments, 
//                         Icons.calendar_today, 
//                         Colors.orange,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const AppointScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Confirmed', 
//                         _totalConfirmed, 
//                         Icons.check_circle, 
//                         Colors.teal,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Cancelled', 
//                         _totalCancelled, 
//                         Icons.cancel, 
//                         Colors.red,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Symptoms Reported', 
//                         _totalSymptoms, 
//                         Icons.health_and_safety, 
//                         Colors.purple
//                       ),
//                       _buildStatCard(
//                         'Pregnancies Tracked', 
//                         _totalPregnancies, 
//                         Icons.pregnant_woman, 
//                         Colors.teal
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Most frequent info
//                   const Text(
//                     'Most Active',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                       _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Patients
//                   const Text(
//                     'Recent Patients',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Date of Birth')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _patientData.take(10).map((patient) {
//                         return DataRow(cells: [
//                           DataCell(Text(patient['fullName'])),
//                           DataCell(Text(patient['gender'])),
//                           DataCell(Text(patient['dateOfBirth'])),
//                           DataCell(Text(patient['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Doctors
//                   const Text(
//                     'Recent Doctors',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('specialties')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _doctorData.take(10).map((doctor) {
//                         return DataRow(cells: [
//                           DataCell(Text(doctor['fullName'])),
//                           DataCell(Text(doctor['gender'])),
//                           DataCell(Text(doctor['specialties'])),
//                           DataCell(Text(doctor['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Appointments
//                   const Text(
//                     'Recent Appointments',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Start Time')),
//                         DataColumn(label: Text('End Time')),
//                         DataColumn(label: Text('Fee')),
//                         DataColumn(label: Text('Date')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Updated At')),
//                       ],
//                       rows: _appointmentData.take(10).map((app) {
//                         return DataRow(cells: [
//                           DataCell(Text(app['patient'])),
//                           DataCell(Text(app['doctor'])),
//                           DataCell(Text(app['startTime'])),
//                           DataCell(Text(app['endTime'])),
//                           DataCell(Text(app['fee'])),
//                           DataCell(Text(app['date'])),
//                           DataCell(Text(app['status'])),
//                           DataCell(Text(app['updatedAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Symptoms
//                   const Text(
//                     'Recent Symptoms',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Week')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Symptoms')),
//                         DataColumn(label: Text('Treatment')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _symptomData.take(10).map((symptom) {
//                         return DataRow(cells: [
//                           DataCell(Text(symptom['patient'])),
//                           DataCell(Text(symptom['age'])),
//                           DataCell(Text('Week ${symptom['week']}')),
//                           DataCell(Text(symptom['doctor'])),
//                           DataCell(Text(symptom['symptoms'])),
//                           DataCell(Text(symptom['treatment'])),
//                           DataCell(Text(symptom['status'])),
//                           DataCell(Text(symptom['date'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Pregnancy Tracking
//                   const Text(
//                     'Pregnancy Tracking',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Last Period')),
//                         DataColumn(label: Text('Due Date')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Created At')),
//                       ],
//                       rows: _pregnancyData.take(10).map((preg) {
//                         return DataRow(cells: [
//                           DataCell(Text(preg['patient'])),
//                           DataCell(Text(preg['age'])),
//                           DataCell(Text(preg['lastPeriod'])),
//                           DataCell(Text(preg['dueDate'])),
//                           DataCell(Text('Week ${preg['week']}')),
//                           DataCell(Text(preg['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }











































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Patient data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     if (timestamp is Timestamp) {
//       return DateFormat('dd MMM yyyy').format(timestamp.toDate());
//     }
//     if (timestamp is String) {
//       try {
//         final date = DateTime.parse(timestamp);
//         return DateFormat('dd MMM yyyy').format(date);
//       } catch (e) {
//         return timestamp;
//       }
//     }
//     return 'N/A';
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Process patient data
//       _patientData = users.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'fullName': data['fullName'] ?? 'Unknown',
//           'gender': data['gender'] ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth']?.toString() ?? 'N/A',
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process doctor data
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'fullName': data['fullName'] ?? 'Unknown Doctor',
//           'gender': data['gender'] ?? 'N/A',
//           'address': data['address']?.toString() ?? 'N/A',
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process appointment data
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'doctor': data['doctorName'] ?? 'Unknown Doctor',
//           'startTime': data['startTime']?.toString() ?? 'N/A',
//           'endTime': data['endTime']?.toString() ?? 'N/A',
//           'fee': data['fee']?.toString() ?? 'N/A',
//           'date': _formatTimestamp(data['date']),
//           'status': data['status'] ?? 'unknown',
//           'updatedAt': _formatTimestamp(data['updatedAt']),
//         };
//       }).toList();

//       // Process symptom data
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'doctor': data['doctorName'] ?? 'No doctor assigned',
//           'symptoms': data['symptoms']?.toString() ?? 'No symptoms',
//           'treatment': data['treatment']?.toString() ?? 'No treatment yet',
//           'status': data['status']?.toString() ?? 'pending',
//           'date': _formatTimestamp(data['timestamp']),
//         };
//       }).toList();

//       // Process pregnancy data
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'lastPeriod': _formatTimestamp(data['lastPeriodDate']),
//           'dueDate': _formatTimestamp(data['dueDate']),
//           'week': data['currentWeek']?.toString() ?? '0',
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'];
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'];
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }



// Future<void> _generatePdfReport() async {
//   final pdf = pw.Document();

//   pdf.addPage(
//     pw.MultiPage(
//       pageFormat: PdfPageFormat.a4,
//       build: (pw.Context context) => [
//         pw.Header(
//           level: 0,
//           child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
//         ),
        
//         pw.SizedBox(height: 20),
//         pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//         pw.Table.fromTextArray(
//           context: context,
//           data: [
//             ['Metric', 'Count'],
//             ['Total Doctors', _totalDoctors.toString()],
//             ['Total Patients', _totalPatients.toString()],
//             ['Total Appointments', _totalAppointments.toString()],
//             ['Confirmed Appointments', _totalConfirmed.toString()],
//             ['Cancelled Appointments', _totalCancelled.toString()],
//             ['Total Symptoms Reported', _totalSymptoms.toString()],
//             ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//             ['Most Booked Doctor', _mostBookedDoctor],
//             ['Most Frequent Patient', _mostFrequentPatient],
//           ],
//         ),
        
//         pw.SizedBox(height: 20),
//         pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//         pw.Table.fromTextArray(
//           context: context,
//           headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//           data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//         ),
        
//         pw.SizedBox(height: 20),
//         pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//         pw.Table.fromTextArray(
//           context: context,
//           headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//           data: _doctorData.take(10).map((d) => [d['fullName'], d['gender'], d['address'], d['createdAt']]).toList(),
//         ),
        
//         pw.SizedBox(height: 20),
//         pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//         pw.Table.fromTextArray(
//           context: context,
//           headers: ['Patient', 'Doctor', 'Start Time', 'End Time', 'Fee', 'Date', 'Status', 'Updated At'],
//           data: _appointmentData.take(20).map((a) => [
//             a['patient'], 
//             a['doctor'], 
//             a['startTime'], 
//             a['endTime'], 
//             a['fee'], 
//             a['date'], 
//             a['status'], 
//             a['updatedAt']
//           ]).toList(),
//         ),
        
//         pw.SizedBox(height: 20),
//         pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//         pw.Table.fromTextArray(
//           context: context,
//           headers: ['Patient', 'Age', 'week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//           data: _symptomData.take(20).map((s) => [
//             s['patient'], 
//             s['age'], 
//             'week ${s['week']}', 
//             s['doctor'], 
//             s['symptoms'], 
//             s['treatment'], 
//             s['status'], 
//             s['date']
//           ]).toList(),
//         ),
        
//         pw.SizedBox(height: 20),
//         pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//         pw.Table.fromTextArray(
//           context: context,
//           headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Created At'],
//           data: _pregnancyData.take(20).map((p) => [
//             p['patient'], 
//             p['age'], 
//             p['lastPeriod'], 
//             p['dueDate'], 
//             'Week ${p['week']}', 
//             p['createdAt']
//           ]).toList(),
//         ),
//       ],
//     ),
//   );

//   await Printing.layoutPdf(
//     onLayout: (PdfPageFormat format) async => pdf.save(),
//   );
// }


//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white, size: 20),
//                   const SizedBox(width: 8),
//                   Flexible(
//                     child: Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 20,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue, size: 20),
//                 const SizedBox(width: 8),
//                 Flexible(
//                   child: Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 16,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDataTable(String title, List<Map<String, dynamic>> data, List<String> columns) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.blue,
//             ),
//           ),
//         ),
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: DataTable(
//             columnSpacing: 16,
//             dataRowHeight: 48,
//             headingRowHeight: 40,
//             horizontalMargin: 8,
//             columns: columns.map((col) => DataColumn(label: Text(col))).toList(),
//             rows: data.take(5).map((row) {
//               return DataRow(
//                 cells: columns.map((col) {
//                   return DataCell(
//                     Container(
//                       constraints: BoxConstraints(maxWidth: 150),
//                       child: Text(
//                         row[col.toLowerCase().replaceAll(' ', '')]?.toString() ?? 'N/A',
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Statistics
//                   const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 8.0),
//                     child: Text(
//                       'Summary Statistics',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: isPortrait ? 2 : 4,
//                     childAspectRatio: isPortrait ? 1.2 : 1.5,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                     children: [
//                       _buildStatCard(
//                         'Doctors', 
//                         _totalDoctors, 
//                         Icons.medical_services, 
//                         Colors.blue,
//                         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorScreen())),
//                       ),
//                       _buildStatCard(
//                         'Patients', 
//                         _totalPatients, 
//                         Icons.people, 
//                         Colors.green,
//                         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientScreen())),
//                       ),
//                       _buildStatCard(
//                         'Appointments', 
//                         _totalAppointments, 
//                         Icons.calendar_today, 
//                         Colors.orange,
//                         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointScreen())),
//                       ),
//                       _buildStatCard(
//                         'Confirmed', 
//                         _totalConfirmed, 
//                         Icons.check_circle, 
//                         Colors.teal,
//                         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Confrimscreen())),
//                       ),
//                       _buildStatCard(
//                         'Cancelled', 
//                         _totalCancelled, 
//                         Icons.cancel, 
//                         Colors.red,
//                         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Cancelcreen())),
//                       ),
//                       _buildStatCard(
//                         'Symptoms', 
//                         _totalSymptoms, 
//                         Icons.health_and_safety, 
//                         Colors.purple
//                       ),
//                       _buildStatCard(
//                         'Pregnancies', 
//                         _totalPregnancies, 
//                         Icons.pregnant_woman, 
//                         Colors.pink
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 12),
                  
//                   // Most frequent info
//                   const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 8.0),
//                     child: Text(
//                       'Most Active',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: isPortrait ? 1 : 2,
//                     childAspectRatio: 3,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                     children: [
//                       _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                       _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 12),
                  
//                   // Recent Patients
//                   _buildDataTable(
//                     'Recent Patients',
//                     _patientData,
//                     ['Name', 'Gender', 'Date of Birth', 'Joined Date']
//                   ),
                  
//                   const SizedBox(height: 12),
                  
//                   // Recent Doctors
//                   _buildDataTable(
//                     'Recent Doctors',
//                     _doctorData,
//                     ['Name', 'Gender', 'Address', 'Joined Date']
//                   ),
                  
//                   const SizedBox(height: 12),
                  
//                   // Recent Appointments
//                   _buildDataTable(
//                     'Recent Appointments',
//                     _appointmentData,
//                     ['Patient', 'Doctor', 'Date', 'Status']
//                   ),
                  
//                   const SizedBox(height: 12),
                  
//                   // Recent Symptoms
//                   _buildDataTable(
//                     'Recent Symptoms',
//                     _symptomData,
//                     ['Patient', 'Week', 'Doctor', 'Status']
//                   ),
                  
//                   const SizedBox(height: 12),
                  
//                   // Pregnancy Tracking
//                   _buildDataTable(
//                     'Pregnancy Tracking',
//                     _pregnancyData,
//                     ['Patient', 'Last Period', 'Due Date', 'Current Week']
//                   ),
                  
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//     );
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Patient data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   // Helper method to safely convert Timestamp to formatted date string
//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
//     if (timestamp is Timestamp) {
//       return DateFormat('dd MMM yyyy').format(timestamp.toDate());
//     }
//     if (timestamp is String) {
//       try {
//         final date = DateTime.parse(timestamp);
//         return DateFormat('dd MMM yyyy').format(date);
//       } catch (e) {
//         return timestamp;
//       }
//     }
//     return 'N/A';
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Process patient data
//       _patientData = users.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'fullName': data['fullName'] ?? 'Unknown',
//           'gender': data['gender'] ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth']?.toString() ?? 'N/A',
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process doctor data
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'fullName': data['fullName'] ?? 'Unknown Doctor',
//           'gender': data['gender'] ?? 'N/A',
//           'address': data['address']?.toString() ?? 'N/A',
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Process appointment data
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['fullName']  ?? 'Unknown',//userId
//           'doctor': data['doctorName'] ?? 'Unknown Doctor',
//           'startTime': data['startTime']?.toString() ?? 'N/A',
//           'endTime': data['endTime']?.toString() ?? 'N/A',
//           'fee': data['fee']?.toString() ?? 'N/A',
//           'date': _formatTimestamp(data['date']),
//           'status': data['status'] ?? 'unknown',
//           'updatedAt': _formatTimestamp(data['updatedAt']),
//         };
//       }).toList();

//       // Process symptom data
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'doctor': data['doctorName'] ?? 'No doctor assigned',
//           'symptoms': data['symptoms']?.toString() ?? 'No symptoms',
//           'treatment': data['treatment']?.toString() ?? 'No treatment yet',
//           'status': data['status']?.toString() ?? 'pending',
//           'date': _formatTimestamp(data['timestamp']),
//         };
//       }).toList();

//       // Process pregnancy data
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'lastPeriod': _formatTimestamp(data['lastPeriodDate']),
//           'dueDate': _formatTimestamp(data['dueDate']),
//           'week': data['currentWeek']?.toString() ?? '0',
//           'createdAt': _formatTimestamp(data['createdAt']),
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'];
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'];
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [d['fullName'], d['gender'], d['address'], d['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Start Time', 'End Time', 'Fee', 'Date', 'Status', 'Updated At'],
//             data: _appointmentData.take(20).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['startTime'], 
//               a['endTime'], 
//               a['fee'], 
//               a['date'], 
//               a['status'], 
//               a['updatedAt']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(20).map((s) => [
//               s['patient'], 
//               s['age'], 
//               'week ${s['week']}', 
//               s['doctor'], 
//               s['symptoms'], 
//               s['treatment'], 
//               s['status'], 
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Created At'],
//             data: _pregnancyData.take(20).map((p) => [
//               p['patient'], 
//               p['age'], 
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}', 
//               p['createdAt']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Statistics
//                   const Text(
//                     'Summary Statistics',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildStatCard(
//                         'Total Doctors', 
//                         _totalDoctors, 
//                         Icons.medical_services, 
//                         Colors.blue,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Patients', 
//                         _totalPatients, 
//                         Icons.people, 
//                         Colors.green,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const PatientScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Appointments', 
//                         _totalAppointments, 
//                         Icons.calendar_today, 
//                         Colors.orange,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const AppointScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Confirmed', 
//                         _totalConfirmed, 
//                         Icons.check_circle, 
//                         Colors.teal,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Cancelled', 
//                         _totalCancelled, 
//                         Icons.cancel, 
//                         Colors.red,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Symptoms Reported', 
//                         _totalSymptoms, 
//                         Icons.health_and_safety, 
//                         Colors.purple
//                       ),
//                       _buildStatCard(
//                         'Pregnancies Tracked', 
//                         _totalPregnancies, 
//                         Icons.pregnant_woman, 
//                         Colors.teal
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Most frequent info
//                   const Text(
//                     'Most Active',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                       _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Patients
//                   const Text(
//                     'Recent Patients',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Date of Birth')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _patientData.take(10).map((patient) {
//                         return DataRow(cells: [
//                           DataCell(Text(patient['fullName'])),
//                           DataCell(Text(patient['gender'])),
//                           DataCell(Text(patient['dateOfBirth'])),
//                           DataCell(Text(patient['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Doctors
//                   const Text(
//                     'Recent Doctors',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Address')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _doctorData.take(10).map((doctor) {
//                         return DataRow(cells: [
//                           DataCell(Text(doctor['fullName'])),
//                           DataCell(Text(doctor['gender'])),
//                           DataCell(Text(doctor['address'])),
//                           DataCell(Text(doctor['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Appointments
//                   const Text(
//                     'Recent Appointments',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Start Time')),
//                         DataColumn(label: Text('End Time')),
//                         DataColumn(label: Text('Fee')),
//                         DataColumn(label: Text('Date')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Updated At')),
//                       ],
//                       rows: _appointmentData.take(10).map((app) {
//                         return DataRow(cells: [
//                           DataCell(Text(app['fullName'])),
//                           DataCell(Text(app['doctor'])),
//                           DataCell(Text(app['startTime'])),
//                           DataCell(Text(app['endTime'])),
//                           DataCell(Text(app['fee'])),
//                           DataCell(Text(app['date'])),
//                           DataCell(Text(app['status'])),
//                           DataCell(Text(app['updatedAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Symptoms
//                   const Text(
//                     'Recent Symptoms',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Week')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Symptoms')),
//                         DataColumn(label: Text('Treatment')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _symptomData.take(10).map((symptom) {
//                         return DataRow(cells: [
//                           DataCell(Text(symptom['patient'])),
//                           DataCell(Text(symptom['age'])),
//                           DataCell(Text('Week ${symptom['week']}')),
//                           DataCell(Text(symptom['doctor'])),
//                           DataCell(Text(symptom['symptoms'])),
//                           DataCell(Text(symptom['treatment'])),
//                           DataCell(Text(symptom['status'])),
//                           DataCell(Text(symptom['date'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Pregnancy Tracking
//                   const Text(
//                     'Pregnancy Tracking',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Last Period')),
//                         DataColumn(label: Text('Due Date')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Created At')),
//                       ],
//                       rows: _pregnancyData.take(10).map((preg) {
//                         return DataRow(cells: [
//                           DataCell(Text(preg['patient'])),
//                           DataCell(Text(preg['age'])),
//                           DataCell(Text(preg['lastPeriod'])),
//                           DataCell(Text(preg['dueDate'])),
//                           DataCell(Text('Week ${preg['week']}')),
//                           DataCell(Text(preg['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }


























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Patient data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Count confirmed and cancelled appointments
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Process patient data
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': data['fullName'] ?? 'Unknown',
//           'gender': data['gender'] ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth'] ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process doctor data
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'fullName': data['fullName'] ?? 'Unknown Doctor',
//           'gender': data['gender'] ?? 'N/A',
//           'dateOfBirth': data['dateOfBirth'] ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process appointment data
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['patientName'] ?? 'Unknown',
//           'doctor': data['doctorName'] ?? 'Unknown Doctor',
//           'startTime': data['startTime'] ?? 'N/A',
//           'endTime': data['endTime'] ?? 'N/A',
//           'fee': data['fee']?.toString() ?? 'N/A',
//           'date': data['date'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['date'] as Timestamp).toDate())
//               : 'N/A',
//           'status': data['status'] ?? 'unknown',
//           'updatedAt': data['updatedAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['updatedAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process symptom data
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'doctor': data['doctorName'] ?? 'No doctor assigned',
//           'symptoms': data['symptoms'] ?? 'No symptoms',
//           'treatment': data['treatment'] ?? 'No treatment yet',
//           'status': data['status'] ?? 'pending',
//           'date': data['timestamp'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['timestamp'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process pregnancy data
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'lastPeriod': data['lastPeriodDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['lastPeriodDate'] as Timestamp).toDate())
//               : 'N/A',
//           'dueDate': data['dueDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['dueDate'] as Timestamp).toDate())
//               : 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'];
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'];
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Confirmed Appointments', _totalConfirmed.toString()],
//               ['Cancelled Appointments', _totalCancelled.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['gender'], p['dateOfBirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Doctors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Name', 'Gender', 'Date of Birth', 'Joined Date'],
//             data: _doctorData.take(10).map((d) => [d['fullName'], d['gender'], d['dateOfBirth'], d['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Start Time', 'End Time', 'Fee', 'Date', 'Status', 'Updated At'],
//             data: _appointmentData.take(10).map((a) => [
//               a['patient'], 
//               a['doctor'], 
//               a['startTime'], 
//               a['endTime'], 
//               a['fee'], 
//               a['date'], 
//               a['status'], 
//               a['updatedAt']
//             ],
//             ).toList(),
        
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Week', 'Doctor', 'Symptoms', 'Treatment', 'Status', 'Date'],
//             data: _symptomData.take(10).map((s) => [
//               s['patient'], 
//               s['age'], 
//               'Week ${s['week']}', 
//               s['doctor'], 
//               s['symptoms'], 
//               s['treatment'], 
//               s['status'], 
//               s['date']
//             ]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Age', 'Last Period', 'Due Date', 'Current Week', 'Created At'],
//             data: _pregnancyData.take(10).map((p) => [
//               p['patient'], 
//               p['age'], 
//               p['lastPeriod'], 
//               p['dueDate'], 
//               'Week ${p['week']}', 
//               p['createdAt']
//             ]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
     
//       ),

//       body:    actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
            
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//       _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Statistics
//                   const Text(
//                     'Summary Statistics',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildStatCard(
//                         'Total Doctors', 
//                         _totalDoctors, 
//                         Icons.medical_services, 
//                         Colors.blue,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Patients', 
//                         _totalPatients, 
//                         Icons.people, 
//                         Colors.green,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const PatientScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Total Appointments', 
//                         _totalAppointments, 
//                         Icons.calendar_today, 
//                         Colors.orange,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const AppointScreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Confirmed', 
//                         _totalConfirmed, 
//                         Icons.check_circle, 
//                         Colors.teal,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Confrimscreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Cancelled', 
//                         _totalCancelled, 
//                         Icons.cancel, 
//                         Colors.red,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Cancelcreen()),
//                           );
//                         },
//                       ),
//                       _buildStatCard(
//                         'Symptoms Reported', 
//                         _totalSymptoms, 
//                         Icons.health_and_safety, 
//                         Colors.purple
//                       ),
//                       _buildStatCard(
//                         'Pregnancies Tracked', 
//                         _totalPregnancies, 
//                         Icons.pregnant_woman, 
//                         Colors.teal
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Most frequent info
//                   const Text(
//                     'Most Active',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                       _buildInfoCard('Most Frequent Patient', _mostFrequentPatient, Icons.person),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Patients
//                   const Text(
//                     'Recent Patients',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Date of Birth')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _patientData.take(10).map((patient) {
//                         return DataRow(cells: [
//                           DataCell(Text(patient['fullName'])),
//                           DataCell(Text(patient['gender'])),
//                           DataCell(Text(patient['dateOfBirth'])),
//                           DataCell(Text(patient['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Doctors
//                   const Text(
//                     'Recent Doctors',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Name')),
//                         DataColumn(label: Text('Gender')),
//                         DataColumn(label: Text('Date of Birth')),
//                         DataColumn(label: Text('Joined Date')),
//                       ],
//                       rows: _doctorData.take(10).map((doctor) {
//                         return DataRow(cells: [
//                           DataCell(Text(doctor['fullName'])),
//                           DataCell(Text(doctor['gender'])),
//                           DataCell(Text(doctor['dateOfBirth'])),
//                           DataCell(Text(doctor['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Appointments
//                   const Text(
//                     'Recent Appointments',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Start Time')),
//                         DataColumn(label: Text('End Time')),
//                         DataColumn(label: Text('Fee')),
//                         DataColumn(label: Text('Date')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Updated At')),
//                       ],
//                       rows: _appointmentData.take(10).map((app) {
//                         return DataRow(cells: [
//                           DataCell(Text(app['patient'])),
//                           DataCell(Text(app['doctor'])),
//                           DataCell(Text(app['startTime'])),
//                           DataCell(Text(app['endTime'])),
//                           DataCell(Text(app['fee'])),
//                           DataCell(Text(app['date'])),
//                           DataCell(Text(app['status'])),
//                           DataCell(Text(app['updatedAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Symptoms
//                   const Text(
//                     'Recent Symptoms',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Week')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Symptoms')),
//                         DataColumn(label: Text('Treatment')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _symptomData.take(10).map((symptom) {
//                         return DataRow(cells: [
//                           DataCell(Text(symptom['patient'])),
//                           DataCell(Text(symptom['age'])),
//                           DataCell(Text('Week ${symptom['week']}')),
//                           DataCell(Text(symptom['doctor'])),
//                           DataCell(Text(symptom['symptoms'])),
//                           DataCell(Text(symptom['treatment'])),
//                           DataCell(Text(symptom['status'])),
//                           DataCell(Text(symptom['date'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Pregnancy Tracking
//                   const Text(
//                     'Pregnancy Tracking',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Last Period')),
//                         DataColumn(label: Text('Due Date')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Created At')),
//                       ],
//                       rows: _pregnancyData.take(10).map((preg) {
//                         return DataRow(cells: [
//                           DataCell(Text(preg['patient'])),
//                           DataCell(Text(preg['age'])),
//                           DataCell(Text(preg['lastPeriod'])),
//                           DataCell(Text(preg['dueDate'])),
//                           DataCell(Text('Week ${preg['week']}')),
//                           DataCell(Text(preg['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }




























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalDoctors = 0;
//   int _totalPatients = 0;
//   int _totalAppointments = 0;
//   int _totalSymptoms = 0;
//   int _totalPregnancies = 0;
  
//   // Most frequent data
//   String _mostBookedDoctor = 'Loading...';
//   String _mostFrequentPatient = 'Loading...';
  
//   // Patient data lists
//   List<Map<String, dynamic>> _patientData = [];
//   List<Map<String, dynamic>> _doctorData = [];
//   List<Map<String, dynamic>> _appointmentData = [];
//   List<Map<String, dynamic>> _symptomData = [];
//   List<Map<String, dynamic>> _pregnancyData = [];

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final doctors = await _firestore.collection('doctors').get();
//       final users = await _firestore.collection('users').get();
//       final appointments = await _firestore.collection('appointments').get();
//       final symptoms = await _firestore.collection('symptoms').get();
//       final pregnancies = await _firestore.collection('trackingweeks').get();

//       // Set total counts
//       _totalDoctors = doctors.size;
//       _totalPatients = users.size;
//       _totalAppointments = appointments.size;
//       _totalSymptoms = symptoms.size;
//       _totalPregnancies = pregnancies.size;

//       // Process patient data
//       _patientData = users.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'name': data['fullName'] ?? 'Unknown',
//           'age': data['age']?.toString() ?? 'N/A',
//           'createdAt': data['createdAt'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process doctor data
//       _doctorData = doctors.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'name': data['fullName'] ?? 'Unknown Doctor',
//           'specialty': data['specialty'] ?? 'General',
//           'appointments': 0, // Will be updated below
//         };
//       }).toList();

//       // Process appointment data
//       _appointmentData = appointments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['patientName'] ?? 'Unknown',
//           'doctor': data['doctorName'] ?? 'Unknown Doctor',
//           'date': data['date'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['date'] as Timestamp).toDate())
//               : 'N/A',
//           'status': data['status'] ?? 'unknown',
//         };
//       }).toList();

//       // Process symptom data
//       _symptomData = symptoms.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'symptoms': data['symptoms'] ?? 'No symptoms',
//           'status': data['status'] ?? 'unknown',
//           'date': data['timestamp'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['timestamp'] as Timestamp).toDate())
//               : 'N/A',
//         };
//       }).toList();

//       // Process pregnancy data
//       _pregnancyData = pregnancies.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'patient': data['fullName'] ?? 'Unknown',
//           'lastPeriod': data['lastPeriodDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['lastPeriodDate'] as Timestamp).toDate())
//               : 'N/A',
//           'dueDate': data['dueDate'] != null 
//               ? DateFormat('dd MMM yyyy').format((data['dueDate'] as Timestamp).toDate())
//               : 'N/A',
//           'week': data['currentWeek']?.toString() ?? '0',
//         };
//       }).toList();

//       // Calculate most booked doctor
//       final doctorAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final doctor = app['doctor'];
//         doctorAppointments[doctor] = (doctorAppointments[doctor] ?? 0) + 1;
//       }
//       if (doctorAppointments.isNotEmpty) {
//         final sortedDoctors = doctorAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostBookedDoctor = sortedDoctors.first.key;
//       }

//       // Calculate most frequent patient
//       final patientAppointments = <String, int>{};
//       for (var app in _appointmentData) {
//         final patient = app['patient'];
//         patientAppointments[patient] = (patientAppointments[patient] ?? 0) + 1;
//       }
//       if (patientAppointments.isNotEmpty) {
//         final sortedPatients = patientAppointments.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));
//         _mostFrequentPatient = sortedPatients.first.key;
//       }

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalDoctors = 0;
//     _totalPatients = 0;
//     _totalAppointments = 0;
//     _totalSymptoms = 0;
//     _totalPregnancies = 0;
//     _mostBookedDoctor = 'Loading...';
//     _mostFrequentPatient = 'Loading...';
//     _patientData = [];
//     _doctorData = [];
//     _appointmentData = [];
//     _symptomData = [];
//     _pregnancyData = [];
//   }

//   Future<void> _generatePdfReport() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => [
//           pw.Header(level: 0, child: pw.Text('Admin Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}')),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             data: [
//               ['Metric', 'Count'],
//               ['Total Doctors', _totalDoctors.toString()],
//               ['Total Patients', _totalPatients.toString()],
//               ['Total Appointments', _totalAppointments.toString()],
//               ['Total Symptoms Reported', _totalSymptoms.toString()],
//               ['Total Pregnancies Tracked', _totalPregnancies.toString()],
//               ['Most Booked Doctor', _mostBookedDoctor],
//               ['Most Frequent Patient', _mostFrequentPatient],
//             ],
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Patients', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['fullName', 'dateofbirth', 'Joined Date'],
//             data: _patientData.take(10).map((p) => [p['fullName'], p['dateofbirth'], p['createdAt']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Appointments', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Doctor', 'Date', 'Status'],
//             data: _appointmentData.take(10).map((a) => [a['patient'], a['doctor'], a['date'], a['status']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Recent Symptoms', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Symptoms', 'Date', 'Status'],
//             data: _symptomData.take(10).map((s) => [s['patient'], s['symptoms'], s['date'], s['status']]).toList(),
//           ),
          
//           pw.SizedBox(height: 20),
//           pw.Text('Pregnancy Tracking', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             context: context,
//             headers: ['Patient', 'Last Period', 'Due Date', 'Current Week'],
//             data: _pregnancyData.take(10).map((p) => [p['patient'], p['lastPeriod'], p['dueDate'], p['week']]).toList(),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Widget _buildStatCard(String title, int value, IconData icon, Color color) {
//     return Card(
//       color: color,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value.toString(),
//               style: const TextStyle(
//                 fontSize: 24,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
        
//       ),
//       body: _isLoading
//       actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
                      
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900]!,

//           ),

//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             tooltip: 'Refresh Data',
//           ),
//         ],
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Statistics
//                   const Text(
//                     'Summary Statistics',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                           onTap: () {
//               _buildStatCard('Total Doctors', _totalDoctors, Icons.medical_services, Colors.blue,
//                        onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const DoctorScreen()),
//         );
//       },),
//                       _buildStatCard('Total Patients', _totalPatients, Icons.people, Colors.green,
//                       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const PatientScreen()),
//         );
//       },),
//                       _buildStatCard('Total Appointments', _totalAppointments, Icons.calendar_today, Colors.
//                       orange, onTap: () {
//         Navigator.push(
//           c,
//           ontext,
//           MaterialPageRoute(builder: (context) => const AppointScreen()),
//         );
//       },),
//                           _buildStatCard('Confirmed', _totalConfirmed, Colors.teal,
//     onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const Confrimscreen()),
//         );
//       },
//     ),
//     _buildStatCard('Cancelled', _totalCancelled, Colors.red,
//     onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const Cancelcreen()),
//         );
//       },
//     ),
//                       _buildStatCard('Symptoms Reported', _totalSymptoms, Icons.health_and_safety, Colors.purple),
//                       _buildStatCard('Pregnancies Tracked', _totalPregnancies, Icons.pregnant_woman, Colors.teal),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Most frequent info
//                   const Text(
//                     'Most Active',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildInfoCard('Most Booked Doctor', _mostBookedDoctor, Icons.star),
//                       _buildInfoCard('Most Frequent symptoms Patient', _mostFrequentPatient, Icons.person),
                      
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Patients
//                   const Text(
//                     'Recent Patients',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('fullName')),
//                         DataColumn(label: Text('dateOfBirth')),
//                         DataColumn(label: Text('Joined Date')),

//                       ],
//                       rows: _patientData.take(all).map((patient) {
//                         return DataRow(cells: [
//                           DataCell(Text(patient['fullName'])),
//                           DataCell(Text(patient['gender'])),
//                           DataCell(Text(patient['dateOfBirth'])),
//                           DataCell(Text(patient['createdAt'])),
//                         ]);
//                       }).toList(),
//                       rows: _doctorData.take(all).map((doctor) {
//                         return DataRow(cells: [
//                           DataCell(Text(doctor['fullName'])),
//                           DataCell(Text(doctor['gender'])),
//                           DataCell(Text(doctor['dateOfBirth'])),
//                           DataCell(Text(doctor['createdAt'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Appointments
//                   const Text(
//                     'Recent Appointments',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('start time')),
//                         DataColumn(label: Text('fee ')),
//                         DataColumn(label: Text('end time')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Status')),
//                         DataColumn(label: Text('Date')),
//                         DataColumn(label: Text('updatedAt')),
//                       ],
//                       rows: _appointmentData.take(all).map((app) {
//                         return DataRow(cells: [
//                           DataCell(Text(app['patient'])),
//                           DataCell(Text(app['doctor'])),
//                           DataCell(Text(app['date'])),
//                           DataCell(Text(app['status'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Recent Symptoms
//                   const Text(
//                     'Recent Symptoms',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Doctor')),
//                         DataColumn(label: Text('Symptoms')),
//                         DataColumn(label: Text('treatment')),
//                         DataColumn(label: Text('Status')), 
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _symptomData.take(all).map((symptom) {
//                         return DataRow(cells: [
//                           DataCell(Text(symptom['patient'])),
//                           DataCell(Text(symptom['age'])),
//                           DataCell(Text('Week ${symptom['week']}')),
//                           DataCell(Text(symptom['doctor'])),
//                           DataCell(Text(symptom['symptoms'])), 
//                           DataCell(Text(symptom['treatment'])),
//                           DataCell(Text(symptom['status'])), //see pending or treated
//                           DataCell(Text(symptom['date'])),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Pregnancy Tracking
//                   const Text(
//                     'Pregnancy Tracking',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columns: const [
//                         DataColumn(label: Text('Patient')),
//                         DataColumn(label: Text('Age')),
//                         DataColumn(label: Text('Last Period')),
//                         DataColumn(label: Text('Due Date')),
//                         DataColumn(label: Text('Current Week')),
//                         DataColumn(label: Text('Date')),
//                       ],
//                       rows: _pregnancyData.take(all).map((preg) {
//                         return DataRow(cells: [
//                           DataCell(Text(preg['patient'])),
//                           DataCell(Text(preg['Age'])),
//                           DataCell(Text(preg['lastPeriod'])),
//                           DataCell(Text(preg['dueDate'])),
//                           DataCell(Text('Week ${preg['week']}')),
//                           DataCell(Text('createdAt${preg['Date']}')),
                          
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }






















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';
// import 'conscreen.dart';
// import 'canscreen.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _totalAppointments = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Time-based statistics
//   final Map<String, Map<String, int>> _stats = {
//     'today': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//     'yesterday': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//     'weekly': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//     'monthly': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//     'yearly': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//   };

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Calculate date ranges based on selected date
//       final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//       final yesterday = today.subtract(const Duration(days: 1));
//       final weekStart = today.subtract(Duration(days: today.weekday - 1));
//       final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
//       final yearStart = DateTime(selectedDate.year, 1, 1);

//       // Get all collections
//       final users = await _firestore.collection('users').get();
//       final doctors = await _firestore.collection('doctors').get();
//       final appointments = await _firestore.collection('appointments').get();

//       // Set total counts
//       _totalUsers = users.size;
//       _totalDoctors = doctors.size;
//       _totalAppointments = appointments.size;
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Helper function to count documents in date range
//       int countInRange(List<QueryDocumentSnapshot> docs, DateTime start, DateTime end, {String? status, String? collection}) {
//         return docs.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           if (status != null && data['status'] != status) return false;
//           if (!data.containsKey('createdAt')) return false;
          
//           final createdAt = (data['createdAt'] as Timestamp).toDate();
//           return createdAt.isAfter(start) && createdAt.isBefore(end);
//         }).length;
//       }

//       // Calculate statistics for each time period
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'today', today, today.add(const Duration(days: 1)));
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'yesterday', yesterday, today);
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'weekly', weekStart, today.add(const Duration(days: 1)));
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'monthly', monthStart, today.add(const Duration(days: 1)));
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'yearly', yearStart, today.add(const Duration(days: 1)));

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _calculatePeriodStats(
//     List<QueryDocumentSnapshot> users,
//     List<QueryDocumentSnapshot> doctors,
//     List<QueryDocumentSnapshot> appointments,
//     String period,
//     DateTime start,
//     DateTime end,
//   ) {
//     _stats[period]!['users'] = users.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;

//     _stats[period]!['doctors'] = doctors.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;

//     _stats[period]!['appointments'] = appointments.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;

//     _stats[period]!['confirmed'] = appointments.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (data['status'] != 'confirmed') return false;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;

//     _stats[period]!['cancelled'] = appointments.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (data['status'] != 'cancelled') return false;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;
//   }

//   void _resetCounters() {
//     _totalUsers = 0;
//     _totalDoctors = 0;
//     _totalAppointments = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;

//     // Reset all period stats
//     for (var period in _stats.keys) {
//       _stats[period]!.updateAll((key, value) => 0);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );
    
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       await _loadReports();
//     }
//   }

//   Widget _buildStatCard(String title, int value, Color color, {VoidCallback? onTap}) {
//   return InkWell(
//     onTap: onTap,
//     child: Card(
//       color: color,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value.toString(),
//               style: const TextStyle(
//                 fontSize: 24,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

//   Widget _buildPeriodRow(String period) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               period[0].toUpperCase() + period.substring(1),
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['users'].toString()),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['doctors'].toString()),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['appointments'].toString()),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['confirmed'].toString()),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['cancelled'].toString()),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                         style: const TextStyle(
//                            color: Colors.blue,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(width: 16), // Add some spacing
                       
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900]!,

//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             color: Colors.blue[900]!,
//           ),
         
        
//                     ],
//                   ),
//                   const SizedBox(height: 20),
                  
             
//               GridView.count(
//   shrinkWrap: true,
//   physics: const NeverScrollableScrollPhysics(),
//   crossAxisCount: 2,
//   childAspectRatio: 1.5,
//   crossAxisSpacing: 10,
//   mainAxisSpacing: 10,
//   children: [
//     _buildStatCard(
//       'Total Users', 
//       _totalUsers, 
//       Colors.blue,
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const PatientScreen()),
//         );
//       },
//     ),
//     _buildStatCard(
//       'Total Doctors', 
//       _totalDoctors, 
//       Colors.green,
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const DoctorScreen()),
//         );
//       },
//     ),
//     _buildStatCard(
//       'Total Appointments', 
//       _totalAppointments, 
//       Colors.orange,
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const AppointScreen()),
//         );
//       },
//     ),
//     _buildStatCard('Confirmed', _totalConfirmed, Colors.teal,
//     onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const Confrimscreen()),
//         );
//       },
//     ),
//     _buildStatCard('Cancelled', _totalCancelled, Colors.red,
//     onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const Cancelcreen()),
//         );
//       },
//     ),
//   ],
// ),
                  
//                   const SizedBox(height: 30),
//                   const Text(
//                     'Detailed Statistics',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
                  
//                   // Table Header
//                   const Row(
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: Text(
//                           'Period',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Users',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Doctors',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Appointment',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       const SizedBox(width: 5),
//                       Expanded(
//                         child: Text(
//                           'Confirmed',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Cancelled',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Divider(thickness: 2),
                  
//                   // Table Rows
//                   _buildPeriodRow('today'),
//                   _buildPeriodRow('yesterday'),
//                   _buildPeriodRow('weekly'),
//                   _buildPeriodRow('monthly'),
//                   _buildPeriodRow('yearly'),
                  
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// class  import 'package:flutter/material.dart';
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
//                     DataCell(Text('\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}')),
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



// class TrakerScreen extends StatefulWidget {
//   const TrakerScreen({Key? key}) : super(key: key);

//   @override
//   State<TrakerScreen> createState() => _TrakerScreenState();
// }

// class _TrakerScreenState extends State<TrakerScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//    final querySnapshot = await _firestore
//          .collection('trackingweeks')
  

 

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
//                     DataCell(Text('\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}')),
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


// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   State<Symptoms> createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Map<String, String> _fullNameCache = {};

   
//     final querySnapshot = await _firestore
//          .collection('symptoms')
  
    
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'teated':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
     
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
//                     DataCell(Text('\$${data['fee']?.toStringAsFixed(2) ?? '0.00'}')),
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



































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'patient_screen.dart';
// import 'doctor_screen.dart';
// import 'appoint.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _totalAppointments = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
//   int _activeUsers = 0;
  
//   // Pregnancy statistics
//   int _totalPregnantWomen = 0;
//   Map<String, int> _pregnancyWeeks = {};
//   Map<String, int> _doctorAppointments = {};
//   Map<String, int> _commonConditions = {};
  
//   // Appointment statistics
//   Map<String, int> _todayAppointments = {'total': 0, 'confirmed': 0, 'cancelled': 0};
//   Map<String, int> _weeklyAppointments = {'total': 0, 'confirmed': 0, 'cancelled': 0};
//   Map<String, int> _totalAppointmentsStats = {'total': 0, 'confirmed': 0, 'cancelled': 0};

//   bool _isLoading = true;
//   int _selectedTabIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get all collections
//       final users = await _firestore.collection('users').get();
//       final doctors = await _firestore.collection('doctors').get();
//       final appointments = await _firestore.collection('appointments').get();

//       // Set total counts
//       _totalUsers = users.size;
//       _totalDoctors = doctors.size;
//       _totalAppointments = appointments.size;
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;
      
//       // Calculate active users (logged in last 30 days)
//       final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
//       _activeUsers = users.docs.where((doc) {
//         final lastLogin = doc['lastLogin'] as Timestamp?;
//         return lastLogin != null && lastLogin.toDate().isAfter(thirtyDaysAgo);
//       }).length;

//       // Calculate pregnancy statistics
//       _calculatePregnancyStats(users.docs);
      
//       // Calculate doctor statistics
//       _calculateDoctorStats(doctors.docs, appointments.docs);
      
//       // Calculate appointment statistics
//       _calculateAppointmentStats(appointments.docs);

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _calculatePregnancyStats(List<QueryDocumentSnapshot> users) {
//     _pregnancyWeeks = {};
//     _totalPregnantWomen = 0;
    
//     for (var user in users) {
//       final data = user.data() as Map<String, dynamic>;
//       if (data['isPregnant'] == true) {
//         _totalPregnantWomen++;
        
//         // Track pregnancy weeks
//         final week = data['trackingweeks']?.toString() ?? 'unknown';
//         _pregnancyWeeks[week] = (_pregnancyWeeks[week] ?? 0) + 1;
//       }
//     }
//   }

//   void _calculateDoctorStats(List<QueryDocumentSnapshot> doctors, List<QueryDocumentSnapshot> appointments) {
//     _doctorAppointments = {};
//     _commonConditions = {};
    
//     // Count appointments per doctor
//     for (var appointment in appointments) {
//       final data = appointment.data() as Map<String, dynamic>;
//       final doctorId = data['doctorId'];
//       if (doctorId != null) {
//         _doctorAppointments[doctorId] = (_doctorAppointments[doctorId] ?? 0) + 1;
//       }
      
//       // Track common conditions
//       final condition = data['symptoms']?.toString() ?? 'unknown';
//       _commonConditions[condition] = (_commonConditions[condition] ?? 0) + 1;
//     }
//   }

//   void _calculateAppointmentStats(List<QueryDocumentSnapshot> appointments) {
//     final now = DateTime.now();
//     final todayStart = DateTime(now.year, now.month, now.day);
//     final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
//     _todayAppointments = {'total': 0, 'confirmed': 0, 'cancelled': 0};
//     _weeklyAppointments = {'total': 0, 'confirmed': 0, 'cancelled': 0};
//     _totalAppointmentsStats = {'total': 0, 'confirmed': 0, 'cancelled': 0};
    
//     for (var appointment in appointments) {
//       final data = appointment.data() as Map<String, dynamic>;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       final status = data['status']?.toString() ?? 'unknown';
      
//       // Today's appointments
//       if (createdAt.isAfter(todayStart)) {
//         _todayAppointments['total'] = _todayAppointments['total']! + 1;
//         if (status == 'confirmed') _todayAppointments['confirmed'] = _todayAppointments['confirmed']! + 1;
//         if (status == 'cancelled') _todayAppointments['cancelled'] = _todayAppointments['cancelled']! + 1;
//       }
      
//       // Weekly appointments
//       if (createdAt.isAfter(weekStart)) {
//         _weeklyAppointments['total'] = _weeklyAppointments['total']! + 1;
//         if (status == 'confirmed') _weeklyAppointments['confirmed'] = _weeklyAppointments['confirmed']! + 1;
//         if (status == 'cancelled') _weeklyAppointments['cancelled'] = _weeklyAppointments['cancelled']! + 1;
//       }
      
//       // Total appointments by status
//       _totalAppointmentsStats['total'] = _totalAppointmentsStats['total']! + 1;
//       if (status == 'confirmed') _totalAppointmentsStats['confirmed'] = _totalAppointmentsStats['confirmed']! + 1;
//       if (status == 'cancelled') _totalAppointmentsStats['cancelled'] = _totalAppointmentsStats['cancelled']! + 1;
//     }
//   }

//   void _resetCounters() {
//     _totalUsers = 0;
//     _totalDoctors = 0;
//     _totalAppointments = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
//     _activeUsers = 0;
//     _totalPregnantWomen = 0;
//     _pregnancyWeeks.clear();
//     _doctorAppointments.clear();
//     _commonConditions.clear();
//     _todayAppointments = {'total': 0, 'confirmed': 0, 'cancelled': 0};
//     _weeklyAppointments = {'total': 0, 'confirmed': 0, 'cancelled': 0};
//     _totalAppointmentsStats = {'total': 0, 'confirmed': 0, 'cancelled': 0};
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );
    
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       await _loadReports();
//     }
//   }

//   Widget _buildStatCard(String title, int value, Color color, {VoidCallback? onclick}) {
//     return GestureDetector(
//       onTap: onclick,
//       child: Card(
//         color: color,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value.toString(),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPregnancyReport() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildStatCard('Total Pregnant Women', _totalPregnantWomen, Colors.purple),
          
//           const SizedBox(height: 20),
//           const Text(
//             'Pregnancy by Week',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
          
//           // Pregnancy weeks distribution
//           if (_pregnancyWeeks.isNotEmpty)
//             Column(
//               children: _pregnancyWeeks.entries.map((entry) => 
//                 ListTile(
//                   title: Text('Week ${entry.key}'),
//                   trailing: Text(entry.value.toString()),
//                 ),
//               ).toList(),
//             )
//           else
//             const Text('No pregnancy data available'),
//         ],
//       ),
//     );
//   }

//   Widget _buildDoctorReport() {
//     // Sort and take top 5 doctors
//     final sortedDoctors = _doctorAppointments.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
//     final topDoctors = sortedDoctors.take(5).toList();

//     // Sort and take top 5 conditions
//     final sortedConditions = _commonConditions.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
//     final topConditions = sortedConditions.take(5).toList();

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildStatCard('Total Doctors', _totalDoctors, Colors.green),
          
//           const SizedBox(height: 20),
//           const Text(
//             'Doctors with Most Appointments',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
          
//           // Top doctors by appointments
//           if (topDoctors.isNotEmpty)
//             Column(
//               children: topDoctors.map((entry) => 
//                 ListTile(
//                   title: FutureBuilder<DocumentSnapshot>(
//                     future: _firestore.collection('doctors').doc(entry.key).get(),
//                     builder: (context, snapshot) {
//                       if (snapshot.hasData) {
//                         return Text(snapshot.data!['name'] ?? 'Unknown Doctor');
//                       }
//                       return const Text('Loading...');
//                     },
//                   ),
//                   trailing: Text(entry.value.toString()),
//                 ),
//               ).toList(),
//             )
//           else
//             const Text('No doctor appointment data available'),
          
//           const SizedBox(height: 20),
//           const Text(
//             'Most Common Conditions',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
          
//           // Common conditions
//           if (topConditions.isNotEmpty)
//             Column(
//               children: topConditions.map((entry) => 
//                 ListTile(
//                   title: Text(entry.key),
//                   trailing: Text(entry.value.toString()),
//                 ),
//               ).toList(),
//             )
//           else
//             const Text('No condition data available'),
//         ],
//       ),
//     );
//   }

//   Widget _buildAppointmentReport() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(child: _buildStatCard('Today', _todayAppointments['total']!, Colors.blue)),
//               Expanded(child: _buildStatCard('Confirmed', _todayAppointments['confirmed']!, Colors.green)),
//               Expanded(child: _buildStatCard('Cancelled', _todayAppointments['cancelled']!, Colors.red)),
//             ],
//           ),
          
//           const SizedBox(height: 20),
//           const Text(
//             'Appointment Statistics',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
          
//           DataTable(
//             columns: const [
//               DataColumn(label: Text('Period')),
//               DataColumn(label: Text('Total'), numeric: true),
//               DataColumn(label: Text('Confirmed'), numeric: true),
//               DataColumn(label: Text('Cancelled'), numeric: true),
//             ],
//             rows: [
//               DataRow(cells: [
//                 const DataCell(Text('Today')),
//                 DataCell(Text(_todayAppointments['total']!.toString())),
//                 DataCell(Text(_todayAppointments['confirmed']!.toString())),
//                 DataCell(Text(_todayAppointments['cancelled']!.toString())),
//               ]),
//               DataRow(cells: [
//                 const DataCell(Text('This Week')),
//                 DataCell(Text(_weeklyAppointments['total']!.toString())),
//                 DataCell(Text(_weeklyAppointments['confirmed']!.toString())),
//                 DataCell(Text(_weeklyAppointments['cancelled']!.toString())),
//               ]),
//               DataRow(cells: [
//                 const DataCell(Text('Total')),
//                 DataCell(Text(_totalAppointmentsStats['total']!.toString())),
//                 DataCell(Text(_totalAppointmentsStats['confirmed']!.toString())),
//                 DataCell(Text(_totalAppointmentsStats['cancelled']!.toString())),
//               ]),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDashboard() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                 style: const TextStyle(
//                   color: Colors.blue,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.calendar_today),
//                     onPressed: () => _selectDate(context),
//                     color: Colors.blue[900]!,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.refresh),
//                     onPressed: _loadReports,
//                     color: Colors.blue[900]!,
//                   ),
//                 ],
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 20),
          
//           // Summary Cards
//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             childAspectRatio: 1.5,
//             crossAxisSpacing: 10,
//             mainAxisSpacing: 10,
//             children: [
//               _buildStatCard(
//                 'Total Users', 
//                 _totalUsers, 
//                 Colors.blue,
//                 onclick: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const PatientScreen()),
//                   );
//                 },
//               ),
//               _buildStatCard(
//                 'Total Doctors', 
//                 _totalDoctors, 
//                 Colors.green,
//                 onclick: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                   );
//                 },
//               ),
//               _buildStatCard('Active Users', _activeUsers, Colors.orange),
//               _buildStatCard('Total Appointments', _totalAppointments, Colors.teal,
//                onclick: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const AppointScreen()),
//                   );
//                 },
//                ),
//               _buildStatCard('Confirmed', _totalConfirmed, Colors.green),
//               _buildStatCard('Cancelled', _totalCancelled, Colors.red),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reports Dashboard'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Tab bar
//                 DefaultTabController(
//                   length: 4,
//                   child: Column(
//                     children: [
//                       TabBar(
//                         onTap: (index) {
//                           setState(() {
//                             _selectedTabIndex = index;
//                           });
//                         },
//                         tabs: const [
//                           Tab(text: 'Dashboard'),
//                           Tab(text: 'Pregnancy'),
//                           Tab(text: 'Doctors'),
//                           Tab(text: 'Appointments'),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Tab content
//                 Expanded(
//                   child: IndexedStack(
//                     index: _selectedTabIndex,
//                     children: [
//                       _buildDashboard(),
//                       _buildPregnancyReport(),
//                       _buildDoctorReport(),
//                       _buildAppointmentReport(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }




























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _totalAppointments = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
  
//   // Time-based statistics
//   final Map<String, Map<String, int>> _stats = {
//     'today': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//     'yesterday': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//     'weekly': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//     'monthly': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//     'yearly': {'users': 0, 'doctors': 0, 'appointments': 0, 'confirmed': 0, 'cancelled': 0},
//   };

//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Calculate date ranges based on selected date
//       final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//       final yesterday = today.subtract(const Duration(days: 1));
//       final weekStart = today.subtract(Duration(days: today.weekday - 1));
//       final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
//       final yearStart = DateTime(selectedDate.year, 1, 1);

//       // Get all collections
//       final users = await _firestore.collection('users').get();
//       final doctors = await _firestore.collection('doctors').get();
//       final appointments = await _firestore.collection('appointments').get();

//       // Set total counts
//       _totalUsers = users.size;
//       _totalDoctors = doctors.size;
//       _totalAppointments = appointments.size;
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Helper function to count documents in date range
//       int countInRange(List<QueryDocumentSnapshot> docs, DateTime start, DateTime end, {String? status, String? collection}) {
//         return docs.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           if (status != null && data['status'] != status) return false;
//           if (!data.containsKey('createdAt')) return false;
          
//           final createdAt = (data['createdAt'] as Timestamp).toDate();
//           return createdAt.isAfter(start) && createdAt.isBefore(end);
//         }).length;
//       }

//       // Calculate statistics for each time period
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'today', today, today.add(const Duration(days: 1)));
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'yesterday', yesterday, today);
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'weekly', weekStart, today.add(const Duration(days: 1)));
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'monthly', monthStart, today.add(const Duration(days: 1)));
//       _calculatePeriodStats(users.docs, doctors.docs, appointments.docs, 'yearly', yearStart, today.add(const Duration(days: 1)));

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _calculatePeriodStats(
//     List<QueryDocumentSnapshot> users,
//     List<QueryDocumentSnapshot> doctors,
//     List<QueryDocumentSnapshot> appointments,
//     String period,
//     DateTime start,
//     DateTime end,
//   ) {
//     _stats[period]!['users'] = users.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//]//     }).length;

//     _stats[period]!['doctors'] = doctors.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;

//     _stats[period]!['appointments'] = appointments.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;

//     _stats[period]!['confirmed'] = appointments.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (data['status'] != 'confirmed') return false;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;

//     _stats[period]!['cancelled'] = appointments.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (data['status'] != 'cancelled') return false;
//       if (!data.containsKey('createdAt')) return false;
//       final createdAt = (data['createdAt'] as Timestamp).toDate();
//       return createdAt.isAfter(start) && createdAt.isBefore(end);
//     }).length;
//   }

//   void _resetCounters() {
//     _totalUsers = 0;
//     _totalDoctors = 0;
//     _totalAppointments = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;

//     // Reset all period stats
//     for (var period in _stats.keys) {
//       _stats[period]!.updateAll((key, value) => 0);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );
    
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       await _loadReports();
//     }
//   }

//   Widget _buildStatCard(String title, int value, Color color) {
//     return Card(
//       color: color,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value.toString(),
//               style: const TextStyle(
//                 fontSize: 24,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPeriodRow(String period) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               period[0].toUpperCase() + period.substring(1),
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['users'].toString()),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['doctors'].toString()),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['appointments'].toString()),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['confirmed'].toString()),
//           ),
//           Expanded(
//             child: Text(_stats[period]!['cancelled'].toString()),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                         style: const TextStyle(
//                            color: Colors.blue,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(width: 16), // Add some spacing
                       
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//             color: Colors.blue[900]!,

//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//             color: Colors.blue[900]!,
//           ),
//           // const SizedBox(width: 16), // Add some spacing
        
//                     ],
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Summary Cards
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       // _buildStatCard('Total Users', _totalUsers, Colors.blue),
//                       // _buildStatCard('Total Doctors', _totalDoctors, Colors.green),
//                       // _buildStatCard('Total Appointments', _totalAppointments, Colors.orange),
//                       _buildStatCard(
//                 'Total Users', 
//                 _totalUsers, 
//                 Colors.blue,
//                 onclick: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const PatientScreen()),
//                   );
//                 },
//               ),
//               _buildStatCard(
//                 'Total Doctors', 
//                 _totalDoctors, 
//                 Colors.green,
//                 onclick: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const DoctorScreen()),
//                   );
//                 },
//               ),
//               _buildStatCard('Active Users', _activeUsers, Colors.orange),
//               _buildStatCard('Total Appointments', _totalAppointments, Colors.teal,
//                onclick: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const AppointScreen()),
//                   );
//                 },
//                ),
//                       _buildStatCard('Confirmed', _totalConfirmed, Colors.teal),
//                       _buildStatCard('Cancelled', _totalCancelled, Colors.red),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 30),
//                   const Text(
//                     'Detailed Statistics',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
                  
//                   // Table Header
//                   const Row(
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: Text(
//                           'Period',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Users',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Doctors',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Appointment',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       const SizedBox(width: 5),
//                       Expanded(
//                         child: Text(
//                           'Confirmed',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           'Cancelled',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Divider(thickness: 2),
                  
//                   // Table Rows
//                   _buildPeriodRow('today'),
//                   _buildPeriodRow('yesterday'),
//                   _buildPeriodRow('weekly'),
//                   _buildPeriodRow('monthly'),
//                   _buildPeriodRow('yearly'),
                  
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//     );
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _totalAppointments = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
//   int _activeUsers = 0;
//   int _inactiveUsers = 0;
  
//   // New registration statistics
//   int _todayDoctor = 0;
//   int _yesterdayDoctor = 0;
//   int _weeklyDoctor = 0;
//   int _monthlyDoctor = 0;
//   int _yearlyDoctor = 0;
//   int _todayUser = 0;
//   int _yesterdayUser = 0;
//   int _weeklyUser = 0;
//   int _monthlyUser = 0;
//   int _yearlyUser = 0;
  
//   // Appointments statistics 
//   int _todayApp = 0;
//   int _yesterdayApp = 0;
//   int _weeklyApp = 0;
//   int _monthlyApp = 0;
//   int _yearlyApp = 0;
  
//   /// New appointments statistics
//   int _todayConfirmed = 0;
//   int _todayCancelled = 0;
//   int _yesterdayConfirmed = 0;
//   int _yesterdayCancelled = 0;
//   int _weeklyConfirmed = 0;
//   int _weeklyCancelled = 0;
//   int _monthlyConfirmed = 0;
//   int _monthlyCancelled = 0;
//   int _yearlyConfirmed = 0;
//   int _yearlyCancelled = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Reset all counters
//       _resetCounters();

//       // Get current date at midnight
//       final now = DateTime.now();
//       final today = DateTime(now.year, now.month, now.day);
//       final yesterday = today.subtract(const Duration(days: 1));
//       final weekStart = today.subtract(Duration(days: today.weekday));
//       final monthStart = DateTime(now.year, now.month, 1);
//       final yearStart = DateTime(now.year, 1, 1);
//       final activeThreshold = now.subtract(const Duration(days: 5));

//       // Get all collections first
//       final users = await _firestore.collection('users').get();
//       final doctors = await _firestore.collection('doctors').get();
//       final appointments = await _firestore.collection('appointments').get();

//       // Set total counts
//       _totalUsers = users.size;
//       _totalDoctors = doctors.size;
//       _totalAppointments = appointments.size;

 
     
//       // Count confirmed and cancelled appointments
//       _totalConfirmed = appointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Helper function to count documents in date range
//       int countInRange(List<QueryDocumentSnapshot> docs, DateTime start, DateTime end, {String? status}) {
//         return docs.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           if (status != null && data['status'] != status) return false;
//           if (!data.containsKey('createdAt')) return false;
//           final createdAt = data['createdAt'] as Timestamp;
//           final date = createdAt.toDate();
//           return date.isAfter(start) && date.isBefore(end);
//         }).length;
//       }

//       // Count registrations and appointments by time period
//       _todayUser = countInRange(users.docs, today, today.add(const Duration(days: 1)));
//       _yesterdayUser = countInRange(users.docs, yesterday, today);
//       _weeklyUser = countInRange(users.docs, weekStart, today.add(const Duration(days: 7)));
//       _monthlyUser = countInRange(users.docs, monthStart, today.add(const Duration(days: 30)));
//       _yearlyUser = countInRange(users.docs, yearStart, today.add(const Duration(days: 365)));

//       _todayDoctor = countInRange(doctors.docs, today, today.add(const Duration(days: 1)));
//       _yesterdayDoctor = countInRange(doctors.docs, yesterday, today);
//       _weeklyDoctor = countInRange(doctors.docs, weekStart, today.add(const Duration(days: 7)));
//       _monthlyDoctor = countInRange(doctors.docs, monthStart, today.add(const Duration(days: 30)));
//       _yearlyDoctor = countInRange(doctors.docs, yearStart, today.add(const Duration(days: 365)));

//       _todayApp = countInRange(appointments.docs, today, today.add(const Duration(days: 1)));
//       _yesterdayApp = countInRange(appointments.docs, yesterday, today);
//       _weeklyApp = countInRange(appointments.docs, weekStart, today.add(const Duration(days: 7)));
//       _monthlyApp = countInRange(appointments.docs, monthStart, today.add(const Duration(days: 30)));
//       _yearlyApp = countInRange(appointments.docs, yearStart, today.add(const Duration(days: 365)));

//       _todayConfirmed = countInRange(appointments.docs, today, today.add(const Duration(days: 1)), status: 'confirmed');
//       _todayCancelled = countInRange(appointments.docs, today, today.add(const Duration(days: 1)), status: 'cancelled');
//       _yesterdayConfirmed = countInRange(appointments.docs, yesterday, today, status: 'confirmed');
//       _yesterdayCancelled = countInRange(appointments.docs, yesterday, today, status: 'cancelled');
//       _weeklyConfirmed = countInRange(appointments.docs, weekStart, today.add(const Duration(days: 7)), status: 'confirmed');
//       _weeklyCancelled = countInRange(appointments.docs, weekStart, today.add(const Duration(days: 7)), status: 'cancelled');
//       _monthlyConfirmed = countInRange(appointments.docs, monthStart, today.add(const Duration(days: 30)), status: 'confirmed');
//       _monthlyCancelled = countInRange(appointments.docs, monthStart, today.add(const Duration(days: 30)), status: 'cancelled');
//       _yearlyConfirmed = countInRange(appointments.docs, yearStart, today.add(const Duration(days: 365)), status: 'confirmed');
//       _yearlyCancelled = countInRange(appointments.docs, yearStart, today.add(const Duration(days: 365)), status: 'cancelled');

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _resetCounters() {
//     _totalUsers = 0;
//     _totalDoctors = 0;
//     _totalAppointments = 0;
//     _totalConfirmed = 0;
//     _totalCancelled = 0;
  
    
//     _todayDoctor = 0;
//     _yesterdayDoctor = 0;
//     _weeklyDoctor = 0;
//     _monthlyDoctor = 0;
//     _yearlyDoctor = 0;
//     _todayUser = 0;
//     _yesterdayUser = 0;
//     _weeklyUser = 0;
//     _monthlyUser = 0;
//     _yearlyUser = 0;
    
//     _todayApp = 0;
//     _yesterdayApp = 0;
//     _weeklyApp = 0;
//     _monthlyApp = 0;
//     _yearlyApp = 0;
    
//     _todayConfirmed = 0;
//     _todayCancelled = 0;
//     _yesterdayConfirmed = 0;
//     _yesterdayCancelled = 0;
//     _weeklyConfirmed = 0;
//     _weeklyCancelled = 0;
//     _monthlyConfirmed = 0;
//     _monthlyCancelled = 0;
//     _yearlyConfirmed = 0;
//     _yearlyCancelled = 0;
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//     //   firstDate: DateTime(2000),
//     //   lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildTableSection(String title, List<TableRow> rows) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Table(
//           border: TableBorder.all(color: Colors.grey),
//           columnWidths: const {
//             0: FlexColumnWidth(2),
//             1: FlexColumnWidth(1),
//           },
//           children: rows,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // System Overview Table
//                   _buildTableSection(
//                     'System Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalDoctors.toString()),
//                           ),
//                         ],
//                       ), 
//                     ],
//                   ),
                  
//                   // Appointments Overview Table
//                   _buildTableSection(
//                     'Appointments Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   _buildTableSection(
//                     'New Registrations',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Historical Appointments Table
//                   _buildTableSection(
//                     'Historical Appointments',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _totalAppointments = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
//   int _activeUsers = 0;
//   int _inactiveUsers = 0;
  
//   // New registration statistics
//   int _todayDoctor = 0;
//   int _yesterdayDoctor = 0;
//   int _weeklyDoctor = 0;
//   int _monthlyDoctor = 0;
//   int _yearlyDoctor = 0;
//   int _todayUser = 0;
//   int _yesterdayUser = 0;
//   int _weeklyUser = 0;
//   int _monthlyUser = 0;
//   int _yearlyUser = 0;
  
//   // Appointments statistics 
//   int _todayApp = 0;
//   int _yesterdayApp = 0;
//   int _weeklyApp = 0;
//   int _monthlyApp = 0;
//   int _yearlyApp = 0;
  
//   /// New appointments statistics
//   int _todayConfirmed = 0;
//   int _todayCancelled = 0;
//   int _yesterdayConfirmed = 0;
//   int _yesterdayCancelled = 0;
//   int _weeklyConfirmed = 0;
//   int _weeklyCancelled = 0;
//   int _monthlyConfirmed = 0;
//   int _monthlyCancelled = 0;
//   int _yearlyConfirmed = 0;
//   int _yearlyCancelled = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     // Calculate date ranges
//     final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final weekStart = today.subtract(Duration(days: today.weekday));
//     final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
//     final yearStart = DateTime(selectedDate.year, 1, 1);
//     final activeThreshold = DateTime.now().subtract(const Duration(days: 5));

//     try {
//       // Get all users and doctors
//       final usersQuery = await _firestore.collection('users').get();
//       final doctorsQuery = await _firestore.collection('doctors').get();
//       final appointmentsQuery = await _firestore.collection('appointments').get();
//       final confirmedQuery = await _firestore.collection('appointments')
//         .where('status', isEqualTo: 'confirmed').get();
//       final cancelQuery = await _firestore.collection('appointments')
//         .where('status', isEqualTo: 'cancelled')
//         .get();
      
//       // Calculate active/inactive users
//       _activeUsers = usersQuery.docs.where((doc) {
//         final lastActive = doc['lastActive'] as Timestamp?;
//         return lastActive != null && lastActive.toDate().isAfter(activeThreshold);
//       }).length;
      
//       _inactiveUsers = _totalUsers - _activeUsers;
      
//       // User registrations
//       final todayUserRegistrations = await _firestore.collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       final yesterdayUserRegistrations = await _firestore.collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       final weeklyUserRegistrations = await _firestore.collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//           .get();
//       final monthlyUserRegistrations = await _firestore.collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//           .get();
//       final yearlyUserRegistrations = await _firestore.collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//           .get();
      
//       // Doctor registrations
//       final todayDoctorRegistrations = await _firestore.collection('doctors')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       final yesterdayDoctorRegistrations = await _firestore.collection('doctors')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       final weeklyDoctorRegistrations = await _firestore.collection('doctors')
//           .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//           .get();
//       final monthlyDoctorRegistrations = await _firestore.collection('doctors')
//           .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//           .get();
//       final yearlyDoctorRegistrations = await _firestore.collection('doctors')
//           .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//           .get();
      
//       // Appointments
//       final todayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       final yesterdayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       final weeklyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//           .get();
//       final monthlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//           .get();
//       final yearlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//           .get();
      
//       // Appointments status
//       final todayConfirmedAppointments = await _firestore.collection('appointments')  
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .where('status', isEqualTo: 'confirmed')
//           .get();
//       final todayCancelledAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .where('status', isEqualTo: 'cancelled')
//           .get();
//       final yesterdayConfirmedAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .where('status', isEqualTo: 'confirmed')
//           .get();
//       final yesterdayCancelledAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .where('status', isEqualTo: 'cancelled')
//           .get();
//       final weeklyConfirmedAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//           .where('status', isEqualTo: 'confirmed')
//           .get();
//       final weeklyCancelledAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//           .where('status', isEqualTo: 'cancelled')
//           .get();
//       final monthlyConfirmedAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//           .where('status', isEqualTo: 'confirmed')
//           .get();
//       final monthlyCancelledAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//           .where('status', isEqualTo: 'cancelled')
//           .get();
//       final yearlyConfirmedAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//           .where('status', isEqualTo: 'confirmed')
//           .get();
//       final yearlyCancelledAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//           .where('status', isEqualTo: 'cancelled')
//           .get();

//       // Set all the values
//       _totalUsers = usersQuery.size;
//       _totalDoctors = doctorsQuery.size;
//       _totalAppointments = appointmentsQuery.size;
//       _totalConfirmed = confirmedQuery.size;
//       _totalCancelled = cancelQuery.size;
      
//       // User registrations
//       _todayUser = todayUserRegistrations.size;
//       _yesterdayUser = yesterdayUserRegistrations.size;
//       _weeklyUser = weeklyUserRegistrations.size;
//       _monthlyUser = monthlyUserRegistrations.size;
//       _yearlyUser = yearlyUserRegistrations.size;
      
//       // Doctor registrations
//       _todayDoctor = todayDoctorRegistrations.size;
//       _yesterdayDoctor = yesterdayDoctorRegistrations.size;
//       _weeklyDoctor = weeklyDoctorRegistrations.size;
//       _monthlyDoctor = monthlyDoctorRegistrations.size;
//       _yearlyDoctor = yearlyDoctorRegistrations.size;
      
//       // Appointments
//       _todayApp = todayAppointments.size;
//       _yesterdayApp = yesterdayAppointments.size;
//       _weeklyApp = weeklyAppointments.size;
//       _monthlyApp = monthlyAppointments.size;
//       _yearlyApp = yearlyAppointments.size;
      
//       // Appointments status
//       _todayConfirmed = todayConfirmedAppointments.size;
//       _todayCancelled = todayCancelledAppointments.size;
//       _yesterdayConfirmed = yesterdayConfirmedAppointments.size;
//       _yesterdayCancelled = yesterdayCancelledAppointments.size;
//       _weeklyConfirmed = weeklyConfirmedAppointments.size;
//       _weeklyCancelled = weeklyCancelledAppointments.size;
//       _monthlyConfirmed = monthlyConfirmedAppointments.size;
//       _monthlyCancelled = monthlyCancelledAppointments.size;
//       _yearlyConfirmed = yearlyConfirmedAppointments.size;
//       _yearlyCancelled = yearlyCancelledAppointments.size;

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildTableSection(String title, List<TableRow> rows) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Table(
//           border: TableBorder.all(color: Colors.grey),
//           columnWidths: const {
//             0: FlexColumnWidth(2),
//             1: FlexColumnWidth(1),
//           },
//           children: rows,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // System Overview Table
//                   _buildTableSection(
//                     'System Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalDoctors.toString()),
//                           ),
//                         ],
//                       ),
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Active Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Inactive Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_activeUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_inactiveUsers.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Appointments Overview Table
//                   _buildTableSection(
//                     'Appointments Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   _buildTableSection(
//                     'New Registrations',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Historical Appointments Table
//                   _buildTableSection(
//                     'Historical Appointments',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyApp.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables (Ka saaray _totalPending, _todayAccepted, _todayCancelled)
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _totalAppointments = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
//   int _activeUsers = 0;

  
//   // New registration statistics
//   int _todayDoctor = 0;
//   int _yesterdayDoctor = 0;
//   int _weeklyDoctor = 0;
//   int _monthlyDoctor = 0;
//   int _yearlyDoctor = 0;
//   int _todayUser = 0;
//   int _yesterdayUser = 0;
//   int _weekUser = 0;
//   int _monthlyUser = 0;
//   int _yearlyUser = 0;
//   // Appointments statistics 
//     int _todayApp = 0;
//     int _yesterdayApp = 0;
//     int _weekApp = 0;
//     int _monthlyApp = 0;
//     int _yearlyApp = 0;
//   /// New appointments statistics (Ka saaray _Confrim iyo _todayCancelled)
//     int _todayConfrimed = 0;
//     int _todayCancelled = 0;
//     int _yesterdayConfrimed = 0;
//     int _yesterdayCancelled = 0;
//     int _weeklyConfrimed = 0;
//     int _weeklyCancelled = 0;
//     int _monthlyConfrimed = 0;
//     int _monthlyCancelled = 0;
//     int _yearlyConfrimed = 0;
//     int _yearlyCancelled = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     // Calculate date ranges
//     final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final weekStart = today.subtract(Duration(days: today.weekday));
//     final monthStart = DateTime(selectedDate.year, selectedDate.month, 30);
//     final yearStart = DateTime(selectedDate.year);365
//     final activeUser = DateTime.now().add(const Duration());
//     final inactive = DateTime.now().subtract(const Duration(days: 5));

//     try {
//            // Calculate in inactive users (non using  this app in last 5 days)
//       _inactiveUsers = usersQuery.docs collection('users')
//           .where((user) => 
//               user['inActive'] != null && 
//               (user['inActive'] as Timestamp).toDate().isAfter(inactiveUser))
//           .length;
//           // Calculate active users (used app in last 5 days)
//           _activeUsers = usersQuery.docs collection('users')
//             .where((user) => 
//                 user['active'] != null && 
//                 (user['active'] as Timestamp).toDate().isAfter(activeUser))
//             .length;

//       // Get all users and doctors
//       final usersQuery = await _firestore.collection('users').get();
//       final doctorsQuery = await _firestore.collection('doctors').get();
//       final appointmentsQuery = await _firestore.collection('appointments').get();
//       final confirmedQuery = await _firestore .collection('appointments')
//         .where('status', isEqualTo: 'confirmed').get();
//       final cancelQuery = await _firestore .collection('appointments')
//         .where('status', isEqualTo: 'cancelled')
//         .get();
//        /// user registrations
        
//        final todayUserRegistrations = await _firestore.collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//         final yesterdayUserRegistrations = await _firestore.collection('users')
//             .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//             .where('createdAt', isLessThan: today)
//             .get();
//         final weekUserRegistrations = await _firestore.collection('users')
//             .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//             .get();
//         final monthUserRegistrations = await _firestore.collection('users')
//             .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//             .get();
//         final yearUserRegistrations = await _firestore.collection('users')
//             .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//             .get();
//         /// doctor registrations
//         final todayDoctorRegistrations = await _firestore.collection('doctors')
//             .where('createdAt', isGreaterThanOrEqualTo: today)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//             .get();
//         final yesterdayDoctorRegistrations = await _firestore.collection('doctors')
//             .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//             .where('createdAt', isLessThan: today)
//             .get();
//         final weekDoctorRegistrations = await _firestore.collection('doctors')
//             .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//             .get();
//         final monthDoctorRegistrations = await _firestore.collection('doctors')
//             .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//             .get();
//         final yearDoctorRegistrations = await _firestore.collection('doctors')
//             .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//             .get();
//             // Historical appointments
//         /// appointments
//             final todayAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: today)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//             .get();
//         final yesterdayAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//             .where('createdAt', isLessThan: today)
//             .get();
//         final weekAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//             .get();
//         final monthlyAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//             .get();
//         final yearlyAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//             .get();
//         /// appointments confirmed and cancelled

//             final todayConfrimedAppointments = await _firestore.collection('appointments')  
//             .where('createdAt', isGreaterThanOrEqualTo: today)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//             .where('status', isEqualTo: 'confirmed')
//             .get();
//         final todayCancelledAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: today)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//             .where('status', isEqualTo: 'cancelled')
//             .get();
//         final yesterdayConfrimedAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//             .where('createdAt', isLessThan: today)
//             .where('status', isEqualTo: 'confirmed')
//             .get();
//         final yesterdayCancelledAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//             .where('createdAt', isLessThan: today)
//             .where('status', isEqualTo: 'cancelled')
//             .get();
//         final weeklyConfrimedAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//             .where('status', isEqualTo: 'confirmed')
//             .get();
//         final weeklyCancelledAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//             .where('status', isEqualTo: 'cancelled')
//             .get();
//         final monthlyConfrimedAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//             .where('status', isEqualTo: 'confirmed')
//             .get();
//         final monthlyCancelledAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//             .where('status', isEqualTo: 'cancelled')
//             .get();
//         final yearlyConfrimedAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//             .where('status', isEqualTo: 'confirmed')
//             .get();
//         final yearlyCancelledAppointments = await _firestore.collection('appointments')
//             .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//             .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//             .where('status', isEqualTo: 'cancelled')
//             .get();
//             ////

      
//       _totalUsers = usersQuery.size;
//       _totalDoctors = doctorsQuery.size;
//       _totalAppointments = appointmentsQuery.size;
//       _totalConfirmed = confirmedQuery.size;
//       _totalCancelled = cancelQuery.size;
//       //user firebase
//       _todayUser = todayUserRegistrations.size;
//       _yesterdayUser = yesterdayUserRegistrations.size;
//       _weekUser = weekUserRegistrations.size;
//       _monthlyUser = monthUserRegistrations.size;
//       _yearlyUser = yearUserRegistrations.size;
//         //doctor firebase
//       _todayDoctor = todayDoctorRegistrations.size;
//       _yesterdayDoctor = yesterdayDoctorRegistrations.size;
//       _weeklyDoctor = weekDoctorRegistrations.size;
//       _monthlyDoctor = monthDoctorRegistrations.size;
//       _yearlyDoctor = yearDoctorRegistrations.size;
//         // appointments firebase
//        _todayApp = todayAppointments.size;
//        _yesterdayApp = yesterdayAppointments.size;
//        _weekApp = weekAppointments.size;
//        _monthlyApp = monthlyAppointments.size;
//        _yearlyApp = yearlyAppointments.size;
//           // appointments confirmed and cancelled firebase
//         _todayConfrimed = todayConfrimedAppointments.size;
//         _todayCancelled = todayCancelledAppointments.size;
//         _yesterdayConfrimed = yesterdayConfrimedAppointments.size;
//         _yesterdayCancelled = yesterdayCancelledAppointments.size;
//         _weeklyConfrimed = weeklyConfrimedAppointments.size;
//         _weeklyCancelled = weeklyCancelledAppointments.size;
//         _monthlyConfrimed = monthlyConfrimedAppointments.size;
//         _monthlyCancelled = monthlyCancelledAppointments.size;
//         _yearlyConfrimed = yearlyConfrimedAppointments.size;
//         _yearlyCancelled = yearlyCancelledAppointments.size;

      
   

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildTableSection(String title, List<TableRow> rows) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Table(
//           border: TableBorder.all(color: Colors.grey),
//           columnWidths: const {
//             0: FlexColumnWidth(2),
//             1: FlexColumnWidth(1),
//           },
//           children: rows,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // System Overview Table
//                   _buildTableSection(
//                     'System Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalDoctors.toString()),
//                           ),
//                         ],
//                       ),
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Active Users ', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Inactive Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_activeUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text((_inactiveUsers).toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Appointments Overview Table (Ka saaray Pending iyo Cancelled)
//                   _buildTableSection(
//                     'Appointments Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),

//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalConfirmed.toString()),
//                           ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_totalCancelled.toString()),
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   _buildTableSection(
//                     'New Registrations',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weekUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyUser.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyDoctor.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Historical Appointments Table
//                   _buildTableSection(
//                     'Historical Appointments',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                            Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confrimed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                            Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                         TableRow(
//                             children: [
//                             const Padding(
//                                 padding: EdgeInsets.all(8.0),
//                                 child: Text('Today'),
//                             ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_todayApp.toString()),
//                             ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_todayConfrimed.toString()),
//                             ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_todayCancelled.toString()),
//                             ),
//                             ],
//                         ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayApp.toString()),
//                           ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_yesterdayConfrimed.toString()),
//                             ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_yesterdayCancelled.toString()),
//                             ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weekApp.toString()),
//                           ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_weeklyConfrimed.toString()),
//                             ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_weeklyCancelled.toString()),
//                             ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyApp.toString()),
//                           ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_monthlyConfrimed.toString()),
//                             ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_monthlyCancelled.toString()),
//                             ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyApp.toString()),
//                           ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_yearlyConfrimed.toString()),
//                             ),
//                             Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_yearlyCancelled.toString()),
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _totalAppointments = 0;
//   int _totalPending = 0;
//   int _totalConfirmed = 0;
//   int _totalCancelled = 0;
//   int _activeUsers = 0;
//   int _todayAppointments = 0;
//   int _todayAccepted = 0;
//   int _todayCancelled = 0;
//   int _yesterdayAppointments = 0;
//   int _weekAppointments = 0;
//   int _monthlyAppointments = 0;
//   int _yearlyAppointments = 0;
  
//   // New registration statistics
//   int _todayDoctorRegistrations = 0;
//   int _yesterdayDoctorRegistrations = 0;
//   int _weeklyDoctorRegistrations = 0;
//   int _monthlyDoctorRegistrations = 0;
//   int _yearlyDoctorRegistrations = 0;
//   int _todayUserRegistrations = 0;
//   int _yesterdayUserRegistrations = 0;
//   int _weekUserRegistrations = 0;
//   int _monthlyUserRegistrations = 0;
//   int _yearlyUserRegistrations = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     // Calculate date ranges
//     final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final weekStart = today.subtract(Duration(days: today.weekday));
//     final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
//     final yearStart = DateTime(selectedDate.year, 1, 1);
//     final activeUserThreshold = DateTime.now().subtract(const Duration(days: 5));

//     try {
//       // Get all users and doctors
//       final usersQuery = await _firestore.collection('users').get();
//       final doctorsQuery = await _firestore.collection('doctors').get();
//       final appointmentsQuery = await _firestore.collection('appointments').get();
      
//       _totalUsers = usersQuery.size;
//       _totalDoctors = doctorsQuery.size;
      
//       // Calculate active users (used app in last 5 days)
//       _activeUsers = usersQuery.docs
//           .where((user) => 
//               user['lastActive'] != null && 
//               (user['lastActive'] as Timestamp).toDate().isAfter(activeUserThreshold))
//           .length;

//       // Total appointments statistics
//       _totalAppointments = appointmentsQuery.size;
//       _totalPending = appointmentsQuery.docs.where((doc) => doc['status'] == 'pending').length;
//       _totalConfirmed = appointmentsQuery.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalCancelled = appointmentsQuery.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Today's appointments
//       final todayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
      
//       _todayAppointments = todayAppointments.size;
//       _todayAccepted = todayAppointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _todayCancelled = todayAppointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Yesterday's appointments
//       final yesterdayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       _yesterdayAppointments = yesterdayAppointments.size;
 
//       // Weekly appointments
//       final weekAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: weekStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _weekAppointments = weekAppointments.size;

//       // Monthly appointments
//       final monthlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: monthStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _monthlyAppointments = monthlyAppointments.size;

//       // Yearly appointments
//       final yearlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yearStart)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _yearlyAppointments = yearlyAppointments.size;

//       // New doctor registrations
//       _todayDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(today))
//           .length;
      
//       _yesterdayDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(yesterday) &&
//               (doctor['createdAt'] as Timestamp).toDate().isBefore(today))
//           .length;
      
//       _weeklyDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(weekStart))
//           .length;
      
//       _monthlyDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(monthStart))
//           .length;
      
//       _yearlyDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(yearStart))
//           .length;

//       // New user registrations
//       _todayUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(today))
//           .length;
      
//       _yesterdayUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(yesterday) &&
//               (user['createdAt'] as Timestamp).toDate().isBefore(today))
//           .length;
      
//       _weekUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(weekStart))
//           .length;

//       _monthlyUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(monthStart))
//           .length;
      
//       _yearlyUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(yearStart))
//           .length;

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildTableSection(String title, List<TableRow> rows) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Table(
//           border: TableBorder.all(color: Colors.grey),
//           columnWidths: const {
//             0: FlexColumnWidth(2),
//             1: FlexColumnWidth(1),
//           },
//           children: rows,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // System Overview Table
//                   _buildTableSection(
//                     'System Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalDoctors.toString()),
//                           ),
//                         ],
//                       ),
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Active Users (last 5 days)', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Inactive Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_activeUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text((_totalUsers - _activeUsers).toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Appointments Overview Table
//                   _buildTableSection(
//                     'Appointments Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalPending.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalConfirmed.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Today's Appointments Table
//                   _buildTableSection(
//                     "Today's Appointments",
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAccepted.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // New Registrations Table
//                   _buildTableSection(
//                     'New Registrations',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weekUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Historical Appointments Table
//                   _buildTableSection(
//                     'Historical Appointments',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weekAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }






















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _totalAppointments = 0;//calculate total appointments pending, confirmed, cancelled
//   int _activeUsers = 0;
//   int _totalconfrimed = 0;
//   int _totalcancelled = 0;.
//   int _todayAppointments = 0;
//   int _yesterdayAppointments = 0;
//   int _weekappointment = 0;
//   int _monthlyAppointments = 0;
//   int _yearlyAppointments = 0;
  
//   // New registration statistics
 
//   int _todayDoctorRegistrations = 0;
//   int _yesterdayDoctorRegistrations = 0;
//   int _weeklyDoctorRegistrations = 0;
//   int _monthlyDoctorRegistrations = 0;
//   int _yearlyDoctorRegistrations = 0;
//    int _todayUserRegistrations = 0;
//   int _yesterdayUserRegistrations = 0;
//   int _weekUserRegistrations = 0;
//   int _monthlyUserRegistrations = 0;
//   int _yearlyUserRegistrations = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     // Calculate date ranges
//     final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//     final yesterday = yesterday.subtract(const Duration(1));
//     final week = today.subtract(Duration(days: today.weekday - 7));
//     final month = DateTime(selectedDate.year, selectedDate.month, 1);//30
//     final year = DateTime(selectedDate.year, 1, 1);//365
//     final activeUserThreshold = DateTime.now().subtract(const Duration(days: 5));

//     try {
//       // Get all users and doctors
//       final usersQuery = await _firestore.collection('users').get();
//       final doctorsQuery = await _firestore.collection('doctors').get();
//       final doctorsQuery = await _firestore.collection('appointments').get();//total apointments
      
//       _totalUsers = usersQuery.size;
//       _totalDoctors = doctorsQuery.size;
      
//       // Calculate active users (used app in last 5 days)
//       _activeUsers = usersQuery.docs
//           .where((user) => 
//               user['lastActive'] != null && 
//               (user['lastActive'] as Timestamp).toDate().isAfter(activeUserThreshold))
//           .length;

//     final totalAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: total)
//           .get();
      
//       _totalAppointments = totalAppointments.size;
//       _totalconfirmed = totalAppointments.docs.where((doc) => doc['status'] == 'pending').length;
//       _totalconfirmed = totalAppointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _totalcancelled = totalAppointments.docs.where((doc) => doc['status'] == 'cancelled').length;
//       .get();
//       _totalAppointments = totalAppointments.size;



//       // Today's appointments
//       final todayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
      
//       _todayAppointments = todayAppointments.size;
//       _todayAccepted = todayAppointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _todayCancelled = todayAppointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Yesterday's appointments
//       final yesterdayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _yesterdayAppointments = yesterdayAppointments.size;
 
//        final weekAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: week)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 7)))
//           .get();
//       _weekAppointments = weekAppointments.size;

//       // Monthly appointments
//       final monthlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: month)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 30)))
//           .get();
//       _monthAppointments = monthlyAppointments.size;

//       // Yearly appointments
//       final yearlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: year)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 365)))
//           .get();
//       _yearlyAppointments = yearlyAppointments.size;
// //      // New registrations doctor 
//   _todayDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(today))
//           .length;
//   _yesterdayDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(yesterday) &&
//               (doctor['createdAt'] as Timestamp).toDate().isBefore(yesterday.add(const Duration(days: 1))))
//           .length;
//         _weeklyDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(week))
//               (doctor['createdAt'] as Timestamp).toDate().isBefore(week.add(const Duration(days: 7)))
//           .length;
//   _monthlyDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(month))
//               (doctor['createdAt'] as Timestamp).toDate().isBefore(month.add(const Duration(days: 30)))
//           .length;
//         _yearlyDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(year))
//               (doctor['createdAt'] as Timestamp).toDate().isBefore(year.add(const Duration(days: 365)))
//           .length;
//       // New registrations
//       _todayUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(today))

//           .length;
      
//       _yesterdayUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(yesterday) &&
//               (user['createdAt'] as Timestamp).toDate().isBefore(yesterday.add(const Duration(days: 1))))
//           .length;
      
//         _weekUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(week) &&
//               (user['createdAt'] as Timestamp).toDate().isBefore(week.add(const Duration(days: 7))))
//           .length;

//       _monthlyUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(month) &&)
//               (user['createdAt'] as Timestamp).toDate().isBefore(month.add(const Duration(days: 30)))
//           .length;
      
//       _yearlyUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(year))
//               (user['createdAt'] as Timestamp).toDate().isBefore(year.add(const Duration(days: 365)))
//           .length;

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildTableSection(String title, List<TableRow> rows) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Table(
//           border: TableBorder.all(color: Colors.grey),
//           columnWidths: const {
//             0: FlexColumnWidth(2),
//             1: FlexColumnWidth(1),
//           },
//           children: rows,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // System Overview Table
//                   _buildTableSection(
//                     'System Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalDoctors.toString()),
//                           ),
//                         ],
//                       ),
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Active Users (last 5 days)', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Inactive Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_activeUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text((_totalUsers - _activeUsers).toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Today's Appointments Table
//                   _buildTableSection(
//                     "Today's Appointments",
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAccepted.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // New Registrations Table
//                   _buildTableSection(
//                     'New Registrations',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                     //   TableRow(
//                     //     children: [
//                     //       const Padding(
//                     //         padding: EdgeInsets.all(8.0),
//                     //         child: Text('week'),
//                     //       ),
//                     //       Padding(
//                     //         padding: const EdgeInsets.all(8.0),
//                     //         child: Text(_weekUserRegistrations.toString()),
//                     //       ),
//                     //       const Padding(
//                     //         padding: EdgeInsets.all(8.0),
//                     //         child: Text('-'),
//                     //       ),
//                     //     ],
//                     //   ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Historical Appointments Table
//                   _buildTableSection(
//                     'Historical Appointments',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_lastMonthAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // User statistics
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _activeUsers = 0;
  
//   // Registration statistics
//   int _todayUserRegistrations = 0;
//   int _todayDoctorRegistrations = 0;
//   int _weeklyUserRegistrations = 0;
//   int _monthlyUserRegistrations = 0;
  
//   // Appointment statistics
//   int _totalAppointments = 0;
//   int _pendingAppointments = 0;
//   int _confirmedAppointments = 0;
//   int _cancelledAppointments = 0;
  
//   // Time-based appointment counts
//   int _todayAppointments = 0;
//   int _todayPending = 0;
//   int _todayConfirmed = 0;
//   int _todayCancelled = 0;
//   int _yesterdayAppointments = 0;
//   int _weeklyAppointments = 0;
//   int _monthlyAppointments = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
//     final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
//     final activeThreshold = DateTime.now().subtract(const Duration(days: 5));

//     try {
//       // Load users and doctors
//       final users = await _firestore.collection('users').get();
//       final doctors = await _firestore.collection('doctors').get();
      
//       _totalUsers = users.size;
//       _totalDoctors = doctors.size;
//       _activeUsers = users.docs
//           .where((u) => (u['lastActive'] as Timestamp).toDate().isAfter(activeThreshold))
//           .length;
      
//       // Registration stats
//       _todayUserRegistrations = users.docs
//           .where((u) => (u['createdAt'] as Timestamp).toDate().isAfter(today))
//           .length;
//       _todayDoctorRegistrations = doctors.docs
//           .where((d) => (d['createdAt'] as Timestamp).toDate().isAfter(today))
//           .length;
//       _weeklyUserRegistrations = users.docs
//           .where((u) => (u['createdAt'] as Timestamp).toDate().isAfter(firstDayOfWeek))
//           .length;
//       _monthlyUserRegistrations = users.docs
//           .where((u) => (u['createdAt'] as Timestamp).toDate().isAfter(firstDayOfMonth))
//           .length;

//       // Appointment stats
//       final allAppointments = await _firestore.collection('appointments').get();
//       _totalAppointments = allAppointments.size;
//       _pendingAppointments = allAppointments.docs.where((d) => d['status'] == 'pending').length;
//       _confirmedAppointments = allAppointments.docs.where((d) => d['status'] == 'confirmed').length;
//       _cancelledAppointments = allAppointments.docs.where((d) => d['status'] == 'cancelled').length;

//       final todayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .get();
//       _todayAppointments = todayAppointments.size;
//       _todayPending = todayAppointments.docs.where((d) => d['status'] == 'pending').length;
//       _todayConfirmed = todayAppointments.docs.where((d) => d['status'] == 'confirmed').length;
//       _todayCancelled = todayAppointments.docs.where((d) => d['status'] == 'cancelled').length;

//       final yesterdayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       _yesterdayAppointments = yesterdayAppointments.size;

//       final weeklyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfWeek)
//           .get();
//       _weeklyAppointments = weeklyAppointments.size;

//       final monthlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfMonth)
//           .get();
//       _monthlyAppointments = monthlyAppointments.size;

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildStatCard(String title, String value) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//             const SizedBox(height: 8),
//             Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('System Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadReports,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat.yMMMMd().format(selectedDate)}',
//                     // style: Theme.of(context).textTheme.headline6,
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Quick Stats Row
//                   Wrap(
//                     spacing: 12,
//                     runSpacing: 12,
//                     children: [
//                       _buildStatCard('Total Users', _totalUsers.toString()),
//                       _buildStatCard('Total Doctors', _totalDoctors.toString()),
//                       _buildStatCard('Active Users', _activeUsers.toString()),
//                       _buildStatCard('Today Appointments', _todayAppointments.toString()),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 24),
//                   const Text('User Registrations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   DataTable(
//                     columns: const [
//                       DataColumn(label: Text('Period')),
//                       DataColumn(label: Text('Users')),
//                       DataColumn(label: Text('Doctors')),
//                     ],
//                     rows: [
//                       _buildDataRow('Today', _todayUserRegistrations, _todayDoctorRegistrations),
//                       _buildDataRow('This Week', _weeklyUserRegistrations, null),
//                       _buildDataRow('This Month', _monthlyUserRegistrations, null),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 24),
//                   const Text('Appointments Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   DataTable(
//                     columns: const [
//                       DataColumn(label: Text('Status')),
//                       DataColumn(label: Text('Count')),
//                     ],
//                     rows: [
//                       _buildSimpleDataRow('Total', _totalAppointments),
//                       _buildSimpleDataRow('Pending', _pendingAppointments),
//                       _buildSimpleDataRow('Confirmed', _confirmedAppointments),
//                       _buildSimpleDataRow('Cancelled', _cancelledAppointments),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   DataRow _buildDataRow(String label, int? users, int? doctors) {
//     return DataRow(cells: [
//       DataCell(Text(label)),
//       DataCell(Text(users?.toString() ?? '-')),
//       DataCell(Text(doctors?.toString() ?? '-')),
//     ]);
//   }

//   DataRow _buildSimpleDataRow(String label, int value) {
//     return DataRow(cells: [
//       DataCell(Text(label)),
//       DataCell(Text(value.toString())),
//     ]);
//   }
// }





























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _activeUsers = 0;
//   int _todayAppointments = 0;
//   int _todayAccepted = 0;
//   int _todayCancelled = 0;
//   int _yesterdayAppointments = 0;
//   int _lastMonthAppointments = 0;
//   int _yearlyAppointments = 0;
  
//   // New registration statistics
//   int _todayUserRegistrations = 0;
//   int _todayDoctorRegistrations = 0;
//   int _yesterdayUserRegistrations = 0;
//   int _weeklyUserRegistrations = 0;
//   int _monthlyUserRegistrations = 0;
//   int _yearlyUserRegistrations = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     // Calculate date ranges
//     final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
//     final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
//     final firstDayOfYear = DateTime(selectedDate.year, 1, 1);
//     final activeUserThreshold = DateTime.now().subtract(const Duration(days: 5));

//     try {
//       // Get all users and doctors
//       final usersQuery = await _firestore.collection('users').get();
//       final doctorsQuery = await _firestore.collection('doctors').get();
      
//       _totalUsers = usersQuery.size;
//       _totalDoctors = doctorsQuery.size;
      
//       // Calculate active users (used app in last 5 days) with null check
//       _activeUsers = usersQuery.docs
//           .where((user) {
//             final lastActive = user.data()['lastActive'];
//             return lastActive != null && 
//                 (lastActive as Timestamp).toDate().isAfter(activeUserThreshold);
//           })
//           .length;

//       // Today's appointments
//       final todayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
      
//       _todayAppointments = todayAppointments.size;
//       _todayAccepted = todayAppointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _todayCancelled = todayAppointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Yesterday's appointments
//       final yesterdayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       _yesterdayAppointments = yesterdayAppointments.size;

//       // Monthly appointments
//       final monthlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfMonth)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _lastMonthAppointments = monthlyAppointments.size;

//       // Yearly appointments
//       final yearlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfYear)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _yearlyAppointments = yearlyAppointments.size;

//       // New registrations with null checks
//       _todayUserRegistrations = usersQuery.docs
//           .where((user) {
//             final createdAt = user.data()['createdAt'];
//             return createdAt != null && 
//                 (createdAt as Timestamp).toDate().isAfter(today);
//           })
//           .length;
      
//       _todayDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) {
//             final createdAt = doctor.data()['createdAt'];
//             return createdAt != null && 
//                 (createdAt as Timestamp).toDate().isAfter(today);
//           })
//           .length;
      
//       _yesterdayUserRegistrations = usersQuery.docs
//           .where((user) {
//             final createdAt = user.data()['createdAt'];
//             return createdAt != null && 
//                 (createdAt as Timestamp).toDate().isAfter(yesterday) &&
//                 (createdAt as Timestamp).toDate().isBefore(today);
//           })
//           .length;
      
//       _weeklyUserRegistrations = usersQuery.docs
//           .where((user) {
//             final createdAt = user.data()['createdAt'];
//             return createdAt != null && 
//                 (createdAt as Timestamp).toDate().isAfter(firstDayOfWeek);
//           })
//           .length;
      
//       _monthlyUserRegistrations = usersQuery.docs
//           .where((user) {
//             final createdAt = user.data()['createdAt'];
//             return createdAt != null && 
//                 (createdAt as Timestamp).toDate().isAfter(firstDayOfMonth);
//           })
//           .length;
      
//       _yearlyUserRegistrations = usersQuery.docs
//           .where((user) {
//             final createdAt = user.data()['createdAt'];
//             return createdAt != null && 
//                 (createdAt as Timestamp).toDate().isAfter(firstDayOfYear);
//           })
//           .length;

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildTableSection(String title, List<TableRow> rows) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Table(
//           border: TableBorder.all(color: Colors.grey),
//           columnWidths: const {
//             0: FlexColumnWidth(2),
//             1: FlexColumnWidth(1),
//           },
//           children: rows,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // System Overview Table
//                   _buildTableSection(
//                     'System Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalDoctors.toString()),
//                           ),
//                         ],
//                       ),
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Active Users (last 5 days)', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Inactive Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_activeUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text((_totalUsers - _activeUsers).toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Today's Appointments Table
//                   _buildTableSection(
//                     "Today's Appointments",
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAccepted.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // New Registrations Table
//                   _buildTableSection(
//                     'New Registrations',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Historical Appointments Table
//                   _buildTableSection(
//                     'Historical Appointments',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_lastMonthAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _activeUsers = 0;
  
//   // Appointment statistics
//   int _todayAppointments = 0;
//   int _todayAccepted = 0;
//   int _todayCancelled = 0;
//   int _yesterdayAppointments = 0;
//   int _lastWeekAppointments = 0;
//   int _lastTwoWeeksAppointments = 0;
//   int _lastMonthAppointments = 0;
//   int _yearlyAppointments = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     // Calculate date ranges
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final lastWeek = today.subtract(const Duration(days: 7));
//     final lastTwoWeeks = today.subtract(const Duration(days: 14));
//     final firstDayOfMonth = DateTime(now.year, now.month, 1);
//     final firstDayOfYear = DateTime(now.year, 1, 1);
//     final activeUserThreshold = now.subtract(const Duration(days: 5));

//     try {
//       // Get all users
//       final usersQuery = await _firestore.collection('users').get();
//       _totalUsers = usersQuery.size;
      
//       // Get all doctors
//       final doctorsQuery = await _firestore.collection('doctors').get();
//       _totalDoctors = doctorsQuery.size;
      
//       // Calculate active users (used app in last 5 days)
//       _activeUsers = usersQuery.docs.where((user) {
//         final lastActive = user.data()['lastActive'];
//         return lastActive != null && (lastActive as Timestamp).toDate().isAfter(activeUserThreshold);
//       }).length;

//       // Today's appointments
//       final todayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
      
//       _todayAppointments = todayAppointments.size;
//       _todayAccepted = todayAppointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _todayCancelled = todayAppointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Yesterday's appointments
//       final yesterdayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       _yesterdayAppointments = yesterdayAppointments.size;

//       // Last week appointments
//       final lastWeekAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: lastWeek)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _lastWeekAppointments = lastWeekAppointments.size;

//       // Last two weeks appointments
//       final lastTwoWeeksAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: lastTwoWeeks)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _lastTwoWeeksAppointments = lastTwoWeeksAppointments.size;

//       // Monthly appointments
//       final monthlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfMonth)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _lastMonthAppointments = monthlyAppointments.size;

//       // Yearly appointments
//       final yearlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfYear)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _yearlyAppointments = yearlyAppointments.size;

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Widget _buildTimePeriodCard(String title, int count, Color color) {
//     return Card(
//       color: color,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               count.toString(),
//               style: const TextStyle(
//                 fontSize: 24,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // System Overview
//                   const Text(
//                     'System Overview',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   GridView.count(
//                     crossAxisCount: 2,
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildTimePeriodCard('Total Users', _totalUsers, Colors.blue),
//                       _buildTimePeriodCard('Total Doctors', _totalDoctors, Colors.green),
//                       _buildTimePeriodCard('Active Users', _activeUsers, Colors.teal),
//                       _buildTimePeriodCard('Inactive Users', _totalUsers - _activeUsers, Colors.orange),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Today's Appointments
//                   const Text(
//                     "Today's Appointments",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   GridView.count(
//                     crossAxisCount: 3,
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     childAspectRatio: 1.2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildTimePeriodCard('Total', _todayAppointments, Colors.purple),
//                       _buildTimePeriodCard('confirmed', _todayAccepted, Colors.green),
//                       _buildTimePeriodCard('cancelled', _todayCancelled, Colors.red),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Historical Appointments
//                   const Text(
//                     'Historical Appointments',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   GridView.count(
//                     crossAxisCount: 2,
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     children: [
//                       _buildTimePeriodCard('Yesterday', _yesterdayAppointments, Colors.indigo),
//                       _buildTimePeriodCard('Last Week', _lastWeekAppointments, Colors.deepOrange),
//                       _buildTimePeriodCard('Last 2 Weeks', _lastTwoWeeksAppointments, Colors.pink),
//                       _buildTimePeriodCard('This Month', _lastMonthAppointments, Colors.deepPurple),
//                       _buildTimePeriodCard('This Year', _yearlyAppointments, Colors.brown),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _activeUsers = 0;
//   int _todayAppointments = 0;
//   int _todayAccepted = 0;
//   int _todayCancelled = 0;
//   int _yesterdayAppointments = 0;
//   int _lastWeekAppointments = 0;
//   int _lastMonthAppointments = 0;
//   int _yearlyAppointments = 0;
  
//   // New registration statistics
//   int _todayUserRegistrations = 0;
//   int _todayDoctorRegistrations = 0;
//   int _yesterdayUserRegistrations = 0;
//   int _weeklyUserRegistrations = 0;
//   int _monthlyUserRegistrations = 0;
//   int _yearlyUserRegistrations = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     // Calculate date ranges
//     final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
//     final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
//     final firstDayOfYear = DateTime(selectedDate.year, 1, 1);
//     final activeUserThreshold = DateTime.now().subtract(const Duration(days: 5));

//     try {
//       // Get all users and doctors
//       final usersQuery = await _firestore.collection('users').get();
//       final doctorsQuery = await _firestore.collection('doctors').get();
      
//       _totalUsers = usersQuery.size;
//       _totalDoctors = doctorsQuery.size;
      
//       // Calculate active users (used app in last 5 days)
//       _activeUsers = usersQuery.docs.where((user) {
//         final lastActive = user.data()['lastActive'];
//         return lastActive != null && (lastActive as Timestamp).toDate().isAfter(activeUserThreshold);
//       }).length;

//       // Today's appointments
//       final todayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
      
//       _todayAppointments = todayAppointments.size;
//       _todayAccepted = todayAppointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _todayCancelled = todayAppointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Yesterday's appointments
//       final yesterdayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       _yesterdayAppointments = yesterdayAppointments.size;

//       // Weekly appointments
//       final weeklyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfWeek)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _lastWeekAppointments = weeklyAppointments.size;

//       // Monthly appointments
//       final monthlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfMonth)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _lastMonthAppointments = monthlyAppointments.size;

//       // Yearly appointments
//       final yearlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfYear)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _yearlyAppointments = yearlyAppointments.size;

//       // New registrations
//       _todayUserRegistrations = usersQuery.docs.where((user) {
//         final createdAt = user.data()['createdAt'] as Timestamp;
//         return createdAt.toDate().isAfter(today);
//       }).length;
      
//       _todayDoctorRegistrations = doctorsQuery.docs.where((doctor) {
//         final createdAt = doctor.data()['createdAt'] as Timestamp;
//         return createdAt.toDate().isAfter(today);
//       }).length;
      
//       _yesterdayUserRegistrations = usersQuery.docs.where((user) {
//         final createdAt = user.data()['createdAt'] as Timestamp;
//         return createdAt.toDate().isAfter(yesterday) && createdAt.toDate().isBefore(today);
//       }).length;
      
//       _weeklyUserRegistrations = usersQuery.docs.where((user) {
//         final createdAt = user.data()['createdAt'] as Timestamp;
//         return createdAt.toDate().isAfter(firstDayOfWeek);
//       }).length;
      
//       _monthlyUserRegistrations = usersQuery.docs.where((user) {
//         final createdAt = user.data()['createdAt'] as Timestamp;
//         return createdAt.toDate().isAfter(firstDayOfMonth);
//       }).length;
      
//       _yearlyUserRegistrations = usersQuery.docs.where((user) {
//         final createdAt = user.data()['createdAt'] as Timestamp;
//         return createdAt.toDate().isAfter(firstDayOfYear);
//       }).length;

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildTableSection(String title, List<TableRow> rows) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Table(
//           border: TableBorder.all(color: Colors.grey),
//           columnWidths: const {
//             0: FlexColumnWidth(2),
//             1: FlexColumnWidth(1),
//           },
//           children: rows,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // System Overview Table
//                   _buildTableSection(
//                     'System Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalDoctors.toString()),
//                           ),
//                         ],
//                       ),
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Active Users (last 5 days)', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Inactive Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_activeUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text((_totalUsers - _activeUsers).toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Today's Appointments Table
//                   _buildTableSection(
//                     "Today's Appointments",
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAccepted.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // New Registrations Table
//                   _buildTableSection(
//                     'New Registrations',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weeklyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Historical Appointments Table
//                   _buildTableSection(
//                     'Historical Appointments',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_lastWeekAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_lastMonthAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }






















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({Key? key}) : super(key: key);

//   @override
//   _ReportScreenState createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   DateTime selectedDate = DateTime.now();
  
//   // Statistics variables
//   int _totalUsers = 0;
//   int _totalDoctors = 0;
//   int _activeUsers = 0;
//   int _todayAppointments = 0;
//   int _todayAccepted = 0;
//   int _todayCancelled = 0;
//   int _yesterdayAppointments = 0;
//   int _lastMonthAppointments = 0;
//   int _yearlyAppointments = 0;
  
//   // New registration statistics
//   int _todayUserRegistrations = 0;
//   int _todayDoctorRegistrations = 0;
//   int _yesterdayUserRegistrations = 0;
//   int _monthlyUserRegistrations = 0;
//   int _yearlyUserRegistrations = 0;
  
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadReports();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoading = true);
    
//     // Calculate date ranges
//     final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
//     final firstDayOfYear = DateTime(selectedDate.year, 1, 1);
//     final activeUserThreshold = DateTime.now().subtract(const Duration(days: 5));

//     try {
//       // Get all users and doctors
//       final usersQuery = await _firestore.collection('users').get();
//       final doctorsQuery = await _firestore.collection('doctors').get();
      
//       _totalUsers = usersQuery.size;
//       _totalDoctors = doctorsQuery.size;
      
//       // Calculate active users (used app in last 5 days)
//       _activeUsers = usersQuery.docs
//           .where((user) => 
//               user['lastActive'] != null && 
//               (user['lastActive'] as Timestamp).toDate().isAfter(activeUserThreshold))
//           .length;

//       // Today's appointments
//       final todayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: today)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
      
//       _todayAppointments = todayAppointments.size;
//       _todayAccepted = todayAppointments.docs.where((doc) => doc['status'] == 'confirmed').length;
//       _todayCancelled = todayAppointments.docs.where((doc) => doc['status'] == 'cancelled').length;

//       // Yesterday's appointments
//       final yesterdayAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: yesterday)
//           .where('createdAt', isLessThan: today)
//           .get();
//       _yesterdayAppointments = yesterdayAppointments.size;

//       // Monthly appointments
//       final monthlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfMonth)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _lastMonthAppointments = monthlyAppointments.size;

//       // Yearly appointments
//       final yearlyAppointments = await _firestore.collection('appointments')
//           .where('createdAt', isGreaterThanOrEqualTo: firstDayOfYear)
//           .where('createdAt', isLessThan: today.add(const Duration(days: 1)))
//           .get();
//       _yearlyAppointments = yearlyAppointments.size;

//       // New registrations
//       _todayUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(today))
//           .length;
      
//       _todayDoctorRegistrations = doctorsQuery.docs
//           .where((doctor) => 
//               (doctor['createdAt'] as Timestamp).toDate().isAfter(today))
//           .length;
      
//       _yesterdayUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(yesterday) &&
//               (user['createdAt'] as Timestamp).toDate().isBefore(today))
//           .length;
      
//       _monthlyUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(firstDayOfMonth))
//           .length;
      
//       _yearlyUserRegistrations = usersQuery.docs
//           .where((user) => 
//               (user['createdAt'] as Timestamp).toDate().isAfter(firstDayOfYear))
//           .length;

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading reports: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         _loadReports();
//       });
//     }
//   }

//   Widget _buildTableSection(String title, List<TableRow> rows) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Table(
//           border: TableBorder.all(color: Colors.grey),
//           columnWidths: const {
//             0: FlexColumnWidth(2),
//             1: FlexColumnWidth(1),
//           },
//           children: rows,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointment Reports'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Report for ${DateFormat('MMMM d, y').format(selectedDate)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // System Overview Table
//                   _buildTableSection(
//                     'System Overview',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_totalDoctors.toString()),
//                           ),
//                         ],
//                       ),
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Active Users (last 5 days)', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Inactive Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_activeUsers.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text((_totalUsers - _activeUsers).toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Today's Appointments Table
//                   _buildTableSection(
//                     "Today's Appointments",
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAppointments.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayAccepted.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayCancelled.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // New Registrations Table
//                   _buildTableSection(
//                     'New Registrations',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Today'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayUserRegistrations.toString()),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_todayDoctorRegistrations.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('week'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_weekUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_monthlyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyUserRegistrations.toString()),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('-'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   // Historical Appointments Table
//                   _buildTableSection(
//                     'Historical Appointments',
//                     [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Yesterday'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yesterdayAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Month'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_lastMonthAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('This Year'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(_yearlyAppointments.toString()),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }





// import 'package:flutter/material.dart';

// class ReportScreen extends StatelessWidget {
//     const ReportScreen ({Key? key}) : super(key: key);

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold(
//             body: const Center(
//                 child: Text(' ReportScreen'),
//             ),
//         );
//     }
// }