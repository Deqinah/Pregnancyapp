import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _editingDocId;
  bool _isAdding = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _selectedGender;
  String? _selectedStatus;
  String? _selectedSpecialty;

  final List<String> _genderOptions = ['male', 'female'];
  final List<String> _statusOptions = ['pending', 'approved'];
  final List<String> _specialties = [
    'OB-GYN',
    'Neonatologist',
    'Genetic Counselor/Geneticist',
    'Reproductive Endocrinologist',
    'Maternal-Fetal Medicine (MFM)',
    'Anesthesiologist (Obstetric)',
    'Psychiatrist (Perinatal)',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _startAdding() {
    setState(() {
      _isAdding = true;
      _editingDocId = null;
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _experienceController.clear();
      _selectedGender = null;
      _selectedStatus = null;
      _selectedSpecialty = null;
    });
  }

  void _startEditing(Map<String, dynamic> doctorData, String docId) {
    setState(() {
      _isAdding = false;
      _editingDocId = docId;
      _nameController.text = doctorData['fullName'] ?? '';
      _emailController.text = doctorData['email'] ?? '';
      _phoneController.text = doctorData['phone'] ?? '';
      _addressController.text = doctorData['address'] ?? '';
      _experienceController.text = doctorData['experience']?.toString() ?? '';
      _selectedGender = doctorData['gender']?.toLowerCase();
      _selectedStatus = doctorData['status']?.toLowerCase();
      _selectedSpecialty = doctorData['specialties'];
    });
  }

  void _cancelEditing() {
    setState(() {
      _isAdding = false;
      _editingDocId = null;
    });
  }

  Future<void> _saveDoctor() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedSpecialty == null ||
        _experienceController.text.isEmpty ||
        _selectedGender == null ||
        _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final doctorData = {
        'fullName': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'specialties': _selectedSpecialty,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'gender': _selectedGender,
        'status': _selectedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
      };

      if (_isAdding) {
        await FirebaseFirestore.instance.collection('doctors').add(doctorData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor added successfully')),
        );
      } else {
        await FirebaseFirestore.instance.collection('doctors').doc(_editingDocId).update(doctorData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor updated successfully')),
        );
      }

      _cancelEditing();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteDoctor(String doctorId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this doctor account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting doctor: $e')),
        );
      }
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, y').format(timestamp.toDate());
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    // Get all doctors data
    final querySnapshot = await FirebaseFirestore.instance.collection('doctors').get();
    final doctors = querySnapshot.docs;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Doctors Report', style: pw.TextStyle(fontSize: 24)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Generated on: ${DateFormat('MMM d, y').format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Name', 'Specialty', 'Gender', 'Email', 'Phone', 'Status', 'Experience'],
                data: doctors.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return [
                    data['fullName'] ?? 'N/A',
                    data['specialties'] ?? 'N/A',
                    data['gender']?.toString().toUpperCase() ?? 'N/A',
                    data['email'] ?? 'N/A',
                    data['phone'] ?? 'N/A',
                    data['status']?.toString().toUpperCase() ?? 'N/A',
                    '${data['experience']?.toString() ?? '0'} yrs',
                  ];
                }).toList(),
              ),
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
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with search and buttons
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search doctors...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: _generatePdfReport,
                    tooltip: 'Generate PDF Report',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _startAdding,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),

            // Editing form
            if (_editingDocId != null || _isAdding)
              SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                    TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                    TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                    TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
                    DropdownButtonFormField<String>(
                      value: _selectedSpecialty,
                      decoration: const InputDecoration(labelText: 'Specialty'),
                      items: _specialties.map((specialty) => 
                        DropdownMenuItem(
                          value: specialty,
                          child: Text(specialty),
                        )).toList(),
                      onChanged: (val) => setState(() => _selectedSpecialty = val),
                    ),
                    TextField(
                      controller: _experienceController, 
                      decoration: const InputDecoration(labelText: 'Experience (years)'), 
                      keyboardType: TextInputType.number
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: _genderOptions.map((gender) => 
                        DropdownMenuItem(
                          value: gender, 
                          child: Text(gender))
                      ).toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _statusOptions.map((status) => 
                        DropdownMenuItem(
                          value: status, 
                          child: Text(status))
                      ).toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(onPressed: _saveDoctor, child: const Text('Save')),
                        const SizedBox(width: 8),
                        TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

            // Doctors table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No doctors found'));
                  }

                  final docs = snapshot.data!.docs;
                  final filtered = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No matching doctors found'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Specialty')),
                          DataColumn(label: Text('Gender')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Experience')),
                          DataColumn(label: Text('Registered')),
                          DataColumn(label: Text('Updated')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filtered.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DataRow(
                            cells: [
                              DataCell(Text(data['fullName'] ?? 'N/A')),
                              DataCell(Text(data['specialties'] ?? 'N/A')),
                              DataCell(
                                Chip(
                                  label: Text(
                                    data['gender']?.toString().toUpperCase() ?? 'N/A',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: data['gender'] == 'male'
                                      ? Colors.blue[100]
                                      : Colors.pink[100],
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                              DataCell(Text(data['email'] ?? 'N/A')),
                              DataCell(Text(data['phone'] ?? 'N/A')),
                              DataCell(Text(data['address'] ?? 'N/A')),
                              DataCell(
                                Chip(
                                  label: Text(
                                    data['status']?.toString().toUpperCase() ?? 'N/A',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: data['status'] == 'approved'
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                              DataCell(Text('${data['experience']?.toString() ?? '0'} yrs')),
                              DataCell(Text(_formatDate(data['createdAt'] as Timestamp?))),
                              DataCell(Text(_formatDate(data['updatedAt'] as Timestamp?))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _startEditing(data, doc.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _deleteDoctor(doc.id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
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

// class DoctorScreen extends StatefulWidget {
//   const DoctorScreen({super.key});

//   @override
//   State<DoctorScreen> createState() => _DoctorScreenState();
// }

// class _DoctorScreenState extends State<DoctorScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;
//   String? _selectedSpecialty;

//   final List<String> _genderOptions = ['male', 'female'];
//   final List<String> _statusOptions = ['pending', 'approved'];
//    final List<String> _specialties = [
//     'OB-GYN',
//     'Neonatologist',
//     'Genetic Counselor/Geneticist',
//     'Reproductive Endocrinologist',
//     'Maternal-Fetal Medicine (MFM)',
//     'Anesthesiologist (Obstetric)',
//     'Psychiatrist (Perinatal)',
//   ];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _specialtyController.dispose();
//     _experienceController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingDocId = null;
//       _nameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _specialtyController.clear();
//       _experienceController.clear();
//       _selectedGender = null;
//       _selectedStatus = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> doctorData, String docId) {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = docId;
//       _nameController.text = doctorData['fullName'] ?? '';
//       _emailController.text = doctorData['email'] ?? '';
//       _phoneController.text = doctorData['phone'] ?? '';
//       _addressController.text = doctorData['address'] ?? '';
//       _specialtyController.text = doctorData['specialties'] ?? '';
//       _experienceController.text = doctorData['experience']?.toString() ?? '';
//       _selectedGender = doctorData['gender']?.toLowerCase();
//       _selectedStatus = doctorData['status']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = null;
//     });
//   }

//   Future<void> _saveDoctor() async {
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _specialtyController.text.isEmpty ||
//         _experienceController.text.isEmpty ||
//         _selectedGender == null ||
//         _selectedStatus == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final doctorData = {
//         'fullName': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         // 'specialties': _specialtyController.text,
//         'specialties': _selectedSpecialty,
//         'experience': int.tryParse(_experienceController.text) ?? 0,
//         'gender': _selectedGender,
//         'status': _selectedStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('doctors').add(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('doctors').doc(_editingDocId).update(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteDoctor(String doctorId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this doctor account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting doctor: $e')),
//         );
//       }
//     }
//   }

//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     return DateFormat('MMM d, y').format(timestamp.toDate());
//   }

//   Future<void> _generatePdfReport() async {
//   final pdf = pw.Document();

//   // Get all doctors data
//   final querySnapshot = await FirebaseFirestore.instance.collection('doctors').get();
//   final doctors = querySnapshot.docs;

//   pdf.addPage(
//     pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       build: (pw.Context context) {
//         return pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Header(
//               level: 0,
//               child: pw.Text('Doctors Report', style: pw.TextStyle(fontSize: 24)),
//             ),
//             pw.SizedBox(height: 20),
//             pw.Text('Generated on: ${DateFormat('MMM d, y').format(DateTime.now())}'),
//             pw.SizedBox(height: 20),
//             pw.Table.fromTextArray(
//               headers: ['Name', 'Specialty', 'Gender', 'Email', 'Phone', 'Status', 'Experience'],
//               data: doctors.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 return [
//                   data['fullName'] ?? 'N/A',
//                   data['specialties'] ?? 'N/A',
//                   data['gender']?.toString().toUpperCase() ?? 'N/A',
//                   data['email'] ?? 'N/A',
//                   data['phone'] ?? 'N/A',
//                   data['status']?.toString().toUpperCase() ?? 'N/A',
//                   '${data['experience']?.toString() ?? '0'} yrs',
//                 ];
//               }).toList(),
//             ),
//           ],
//         );
//       },
//     ),
//   );

//   await Printing.layoutPdf(
//     onLayout: (PdfPageFormat format) async => pdf.save(),
//   );
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar with search and buttons
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       onChanged: (value) => setState(() => _searchQuery = value),
//                       decoration: const InputDecoration(
//                         hintText: 'Search doctors...',
//                         prefixIcon: Icon(Icons.search),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     icon: const Icon(Icons.picture_as_pdf),
//                     onPressed: _generatePdfReport,
//                     tooltip: 'Generate PDF Report',
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton.icon(
//                     onPressed: _startAdding,
//                     icon: const Icon(Icons.add),
//                     label: const Text('Add'),
//                   ),
//                 ],
//               ),
//             ),

//             // Editing form
//             if (_editingDocId != null || _isAdding)
//               SingleChildScrollView(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   children: [
//                     TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
//                     TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
//                     TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
//                     TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
//                     TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialties')),
//                     TextField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience (years)'), keyboardType: TextInputType.number),
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: const InputDecoration(labelText: 'Gender'),
//                       items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
//                       onChanged: (val) => setState(() => _selectedGender = val),
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: _selectedStatus,
//                       decoration: const InputDecoration(labelText: 'Status'),
//                       items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
//                       onChanged: (val) => setState(() => _selectedStatus = val),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         ElevatedButton(onPressed: _saveDoctor, child: const Text('Save')),
//                         const SizedBox(width: 8),
//                         TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),

//             // Doctors table
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text('No doctors found'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
//                   }).toList();

//                   if (filtered.isEmpty) {
//                     return const Center(child: Text('No matching doctors found'));
//                   }

//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: SingleChildScrollView(
//                       child: DataTable(
//                         columns: const [
//                           DataColumn(label: Text('Name')),
//                           DataColumn(label: Text('Specialty')),
//                           DataColumn(label: Text('Gender')),
//                           DataColumn(label: Text('Email')),
//                           DataColumn(label: Text('Phone')),
//                           DataColumn(label: Text('Address')),
//                           DataColumn(label: Text('Status')),
//                           DataColumn(label: Text('Experience')),
//                           DataColumn(label: Text('Registered')),
//                           DataColumn(label: Text('Updated')),
//                           DataColumn(label: Text('Actions')),
//                         ],
//                         rows: filtered.map((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           return DataRow(
//                             cells: [
//                               DataCell(Text(data['fullName'] ?? 'N/A')),
//                               DataCell(Text(data['specialties'] ?? 'N/A')),
//                               DataCell(
//                                 Chip(
//                                   label: Text(
//                                     data['gender']?.toString().toUpperCase() ?? 'N/A',
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                   backgroundColor: data['gender'] == 'male'
//                                       ? Colors.blue[100]
//                                       : Colors.pink[100],
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 ),
//                               ),
//                               DataCell(Text(data['email'] ?? 'N/A')),
//                               DataCell(Text(data['phone'] ?? 'N/A')),
//                               DataCell(Text(data['address'] ?? 'N/A')),
//                               DataCell(
//                                 Chip(
//                                   label: Text(
//                                     data['status']?.toString().toUpperCase() ?? 'N/A',
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                   backgroundColor: data['status'] == 'approved'
//                                       ? Colors.green[100]
//                                       : Colors.orange[100],
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 ),
//                               ),
//                               DataCell(Text('${data['experience']?.toString() ?? '0'} yrs')),
//                               DataCell(Text(_formatDate(data['createdAt'] as Timestamp?))),
//                               DataCell(Text(_formatDate(data['updatedAt'] as Timestamp?))),
//                               DataCell(
//                                 Row(
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.edit, size: 20),
//                                       onPressed: () => _startEditing(data, doc.id),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                                       onPressed: () => _deleteDoctor(doc.id),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   );
//                 },
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
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class DoctorScreen extends StatefulWidget {
//   const DoctorScreen({super.key});

//   @override
//   State<DoctorScreen> createState() => _DoctorScreenState();
// }

// class _DoctorScreenState extends State<DoctorScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

//   final List<String> _genderOptions = ['male', 'female'];
//   final List<String> _statusOptions = ['pending', 'approved'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _specialtyController.dispose();
//     _experienceController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingDocId = null;
//       _nameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _specialtyController.clear();
//       _experienceController.clear();
//       _selectedGender = null;
//       _selectedStatus = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> doctorData, String docId) {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = docId;
//       _nameController.text = doctorData['fullName'] ?? '';
//       _emailController.text = doctorData['email'] ?? '';
//       _phoneController.text = doctorData['phone'] ?? '';
//       _addressController.text = doctorData['address'] ?? '';
//       _specialtyController.text = doctorData['specialties'] ?? '';
//       _experienceController.text = doctorData['experience']?.toString() ?? '';
//       _selectedGender = doctorData['gender']?.toLowerCase();
//       _selectedStatus = doctorData['status']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = null;
//     });
//   }

//   Future<void> _saveDoctor() async {
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _specialtyController.text.isEmpty ||
//         _experienceController.text.isEmpty ||
//         _selectedGender == null ||
//         _selectedStatus == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final doctorData = {
//         'fullName': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'specialties': _specialtyController.text,
//         'experience': int.tryParse(_experienceController.text) ?? 0,
//         'gender': _selectedGender,
//         'status': _selectedStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('doctors').add(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('doctors').doc(_editingDocId).update(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteDoctor(String doctorId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this doctor account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting doctor: $e')),
//         );
//       }
//     }
//   }

//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     return DateFormat('MMM d, y').format(timestamp.toDate());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//          actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//         ],
//         child: Column(
//           children: [
//             // Top bar
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       onChanged: (value) => setState(() => _searchQuery = value),
//                       decoration: const InputDecoration(
//                         hintText: 'Search doctors...',
//                         prefixIcon: Icon(Icons.search),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton.icon(
//                     onPressed: _startAdding,
//                     icon: const Icon(Icons.add),
//                     label: const Text('Add'),
//                   ),
//                 ],
//               ),
//             ),

//             // Editing form
//             if (_editingDocId != null || _isAdding)
//               SingleChildScrollView(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   children: [
//                     TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
//                     TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
//                     TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
//                     TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
//                     TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialties')),
//                     TextField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience (years)'), keyboardType: TextInputType.number),
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: const InputDecoration(labelText: 'Gender'),
//                       items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
//                       onChanged: (val) => setState(() => _selectedGender = val),
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: _selectedStatus,
//                       decoration: const InputDecoration(labelText: 'Status'),
//                       items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
//                       onChanged: (val) => setState(() => _selectedStatus = val),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         ElevatedButton(onPressed: _saveDoctor, child: const Text('Save')),
//                         const SizedBox(width: 8),
//                         TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),

//             // Doctors table
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text('No doctors found'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
//                   }).toList();

//                   if (filtered.isEmpty) {
//                     return const Center(child: Text('No matching doctors found'));
//                   }

//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: SingleChildScrollView(
//                       child: DataTable(
//                         columns: const [
//                           DataColumn(label: Text('Name')),
//                           DataColumn(label: Text('Specialty')),
//                           DataColumn(label: Text('Gender')),
//                           DataColumn(label: Text('Email')),
//                           DataColumn(label: Text('Phone')),
//                           DataColumn(label: Text('Address')),
//                           DataColumn(label: Text('Status')),
//                           DataColumn(label: Text('Experience')),
//                           DataColumn(label: Text('Registered')),
//                           DataColumn(label: Text('Updated')),
//                           DataColumn(label: Text('Actions')),
//                         ],
//                         rows: filtered.map((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           return DataRow(
//                             cells: [
//                               DataCell(Text(data['fullName'] ?? 'N/A')),
//                               DataCell(Text(data['specialties'] ?? 'N/A')),
//                               DataCell(
//                                 Chip(
//                                   label: Text(
//                                     data['gender']?.toString().toUpperCase() ?? 'N/A',
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                   backgroundColor: data['gender'] == 'male'
//                                       ? Colors.blue[100]
//                                       : Colors.pink[100],
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 ),
//                               ),
//                               DataCell(Text(data['email'] ?? 'N/A')),
//                               DataCell(Text(data['phone'] ?? 'N/A')),
//                               DataCell(Text(data['address'] ?? 'N/A')),
//                               DataCell(
//                                 Chip(
//                                   label: Text(
//                                     data['status']?.toString().toUpperCase() ?? 'N/A',
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                   backgroundColor: data['status'] == 'approved'
//                                       ? Colors.green[100]
//                                       : Colors.orange[100],
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 ),
//                               ),
//                               DataCell(Text('${data['experience']?.toString() ?? '0'} yrs')),
//                               DataCell(Text(_formatDate(data['createdAt'] as Timestamp?))),
//                               DataCell(Text(_formatDate(data['updatedAt'] as Timestamp?))),
//                               DataCell(
//                                 Row(
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.edit, size: 20),
//                                       onPressed: () => _startEditing(data, doc.id),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                                       onPressed: () => _deleteDoctor(doc.id),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         }).toList(),
//                       ),
//                       await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//                     ),
//                   );
//                 },
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
// import 'package:intl/intl.dart';

// class DoctorScreen extends StatefulWidget {
//   const DoctorScreen({super.key});

//   @override
//   State<DoctorScreen> createState() => _DoctorScreenState();
// }

// class _DoctorScreenState extends State<DoctorScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

//   final List<String> _genderOptions = ['Male', 'Female'];
//   final List<String> _statusOptions = ['pending', 'approved'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _specialtyController.dispose();
//     _experienceController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingDocId = null;
//       _nameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _specialtyController.clear();
//       _experienceController.clear();
//       _selectedGender = null;
//       _selectedStatus = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> doctorData, String docId) {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = docId;
//       _nameController.text = doctorData['fullName'] ?? '';
//       _emailController.text = doctorData['email'] ?? '';
//       _phoneController.text = doctorData['phone'] ?? '';
//       _addressController.text = doctorData['address'] ?? '';
//       _specialtyController.text = doctorData['specialties'] ?? '';
//       _experienceController.text = doctorData['experience']?.toString() ?? '';
//       _selectedGender = doctorData['gender']?.toLowerCase();
//       _selectedStatus = doctorData['status']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = null;
//     });
//   }

//   Future<void> _saveDoctor() async {
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _specialtyController.text.isEmpty ||
//         _experienceController.text.isEmpty ||
//         _selectedGender == null ||
//         _selectedStatus == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final doctorData = {
//         'fullName': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'specialties': _specialtyController.text,
//         'experience': int.tryParse(_experienceController.text) ?? 0,
//         'gender': _selectedGender,
//         'status': _selectedStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('doctors').add(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('doctors').doc(_editingDocId).update(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteDoctor(String doctorId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this doctor account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting doctor: $e')),
//         );
//       }
//     }
//   }

//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     return DateFormat('MMM d, y').format(timestamp.toDate());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       onChanged: (value) => setState(() => _searchQuery = value),
//                       decoration: const InputDecoration(
//                         hintText: 'Search doctors...',
//                         prefixIcon: Icon(Icons.search),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton.icon(
//                     onPressed: _startAdding,
//                     icon: const Icon(Icons.add),
//                     label: const Text('Add'),
//                   ),
//                 ],
//               ),
//             ),

//             // Editing form
//             if (_editingDocId != null || _isAdding)
//               SingleChildScrollView(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   children: [
//                     TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
//                     TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
//                     TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
//                     TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
//                     TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialties')),
//                     TextField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience (years)'), keyboardType: TextInputType.number),
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: const InputDecoration(labelText: 'Gender'),
//                       items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
//                       onChanged: (val) => setState(() => _selectedGender = val),
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: _selectedStatus,
//                       decoration: const InputDecoration(labelText: 'Status'),
//                       items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
//                       onChanged: (val) => setState(() => _selectedStatus = val),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         ElevatedButton(onPressed: _saveDoctor, child: const Text('Save')),
//                         const SizedBox(width: 8),
//                         TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),

//             // Doctors table
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text('No doctors found'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
//                   }).toList();

//                   if (filtered.isEmpty) {
//                     return const Center(child: Text('No matching doctors found'));
//                   }

//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: SingleChildScrollView(
//                       child: DataTable(
//                         columns: const [
//                           DataColumn(label: Text('Name')),
//                           DataColumn(label: Text('Specialty')),
//                           DataColumn(label: Text('Gender')),
//                           DataColumn(label: Text('Email')),
//                           DataColumn(label: Text('Phone')),
//                           DataColumn(label: Text('Status')),
//                           DataColumn(label: Text('Experience')),
//                           DataColumn(label: Text('Registered')),
//                           DataColumn(label: Text('Updated')),
//                           DataColumn(label: Text('Actions')),
//                         ],
//                         rows: filtered.map((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           return DataRow(
//                             cells: [
//                               DataCell(Text(data['fullName'] ?? 'N/A')),
//                               DataCell(Text(data['specialties'] ?? 'N/A')),
//                               DataCell(
//                                 Chip(
//                                   label: Text(
//                                     data['gender']?.toString().toUpperCase() ?? 'N/A',
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                   backgroundColor: data['gender'] == 'male'
//                                       ? Colors.blue[100]
//                                       : Colors.pink[100],
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 ),
//                               ),
//                               DataCell(Text(data['email'] ?? 'N/A')),
//                               DataCell(Text(data['phone'] ?? 'N/A')),
//                               DataCell(
//                                 Chip(
//                                   label: Text(
//                                     data['status']?.toString().toUpperCase() ?? 'N/A',
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                   backgroundColor: data['status'] == 'approved'
//                                       ? Colors.green[100]
//                                       : Colors.orange[100],
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 ),
//                               ),
//                               DataCell(Text('${data['experience']?.toString() ?? '0'} yrs')),
//                               DataCell(Text(_formatDate(data['createdAt'] as Timestamp?))),
//                               DataCell(Text(_formatDate(data['updatedAt'] as Timestamp?))),
//                               DataCell(
//                                 Row(
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.edit, size: 20),
//                                       onPressed: () => _startEditing(data, doc.id),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                                       onPressed: () => _deleteDoctor(doc.id),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   );
//                 },
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
// import 'package:intl/intl.dart';

// class DoctorScreen extends StatefulWidget {
//   const DoctorScreen({super.key});

//   @override
//   State<DoctorScreen> createState() => _DoctorScreenState();
// }

// class _DoctorScreenState extends State<DoctorScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

//   final List<String> _genderOptions = ['male', 'female'];
//   final List<String> _statusOptions = ['pending', 'approved'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _specialtyController.dispose();
//     _experienceController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingDocId = null;
//       _nameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _specialtyController.clear();
//       _experienceController.clear();
//       _selectedGender = null;
//       _selectedStatus = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> doctorData, String docId) {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = docId;
//       _nameController.text = doctorData['fullName'] ?? '';
//       _emailController.text = doctorData['email'] ?? '';
//       _phoneController.text = doctorData['phone'] ?? '';
//       _addressController.text = doctorData['address'] ?? '';
//       _specialtyController.text = doctorData['specialties'] ?? '';
//       _experienceController.text = doctorData['experience']?.toString() ?? '';
//       _selectedGender = doctorData['gender']?.toLowerCase();
//       _selectedStatus = doctorData['status']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = null;
//     });
//   }

//   Future<void> _saveDoctor() async {
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _specialtyController.text.isEmpty ||
//         _experienceController.text.isEmpty ||
//         _selectedGender == null ||
//         _selectedStatus == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final doctorData = {
//         'fullName': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'specialties': _specialtyController.text,
//         'experience': int.tryParse(_experienceController.text) ?? 0,
//         'gender': _selectedGender,
//         'status': _selectedStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('doctors').add(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('doctors').doc(_editingDocId).update(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteDoctor(String doctorId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this doctor account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting doctor: $e')),
//         );
//       }
//     }
//   }

//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     return DateFormat('MMM d, y').format(timestamp.toDate());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       onChanged: (value) => setState(() => _searchQuery = value),
//                       decoration: const InputDecoration(
//                         hintText: 'Search doctors...',
//                         prefixIcon: Icon(Icons.search),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton.icon(
//                     onPressed: _startAdding,
//                     icon: const Icon(Icons.add),
//                     label: const Text('Add'),
//                   ),
//                 ],
//               ),
//             ),

//             // Editing form
//             if (_editingDocId != null || _isAdding)
//               SingleChildScrollView(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   children: [
//                     TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
//                     TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
//                     TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
//                     TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
//                     TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialties')),
//                     TextField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience (years)'), keyboardType: TextInputType.number),
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: const InputDecoration(labelText: 'Gender'),
//                       items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
//                       onChanged: (val) => setState(() => _selectedGender = val),
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: _selectedStatus,
//                       decoration: const InputDecoration(labelText: 'Status'),
//                       items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
//                       onChanged: (val) => setState(() => _selectedStatus = val),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         ElevatedButton(onPressed: _saveDoctor, child: const Text('Save')),
//                         const SizedBox(width: 8),
//                         TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),

//             // Doctors table
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text('No doctors found'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
//                   }).toList();

//                   if (filtered.isEmpty) {
//                     return const Center(child: Text('No matching doctors found'));
//                   }

//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: SingleChildScrollView(
//                       child: DataTable(
//                         columns: const [
//                           DataColumn(label: Text('Name')),
//                           DataColumn(label: Text('Specialty')),
//                           DataColumn(label: Text('Email')),
//                           DataColumn(label: Text('Phone')),
//                           DataColumn(label: Text('Status')),
//                           DataColumn(label: Text('Experience')),
//                           DataColumn(label: Text('Registered')),
//                           DataColumn(label: Text('Updated')),
//                           DataColumn(label: Text('Actions')),
//                         ],
//                         rows: filtered.map((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           return DataRow(
//                             cells: [
//                               DataCell(Text(data['fullName'] ?? 'N/A')),
//                               DataCell(Text(data['specialties'] ?? 'N/A')),
//                               DataCell(Text(data['email'] ?? 'N/A')),
//                               DataCell(Text(data['phone'] ?? 'N/A')),
//                               DataCell(
//                                 Chip(
//                                   label: Text(
//                                     data['status']?.toString().toUpperCase() ?? 'N/A',
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                   backgroundColor: data['status'] == 'approved'
//                                       ? Colors.green[100]
//                                       : Colors.orange[100],
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 ),
//                               ),
//                               DataCell(Text('${data['experience']?.toString() ?? '0'} yrs')),
//                               DataCell(Text(_formatDate(data['createdAt'] as Timestamp?))),
//                               DataCell(Text(_formatDate(data['updatedAt'] as Timestamp?))),
//                               DataCell(
//                                 Row(
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.edit, size: 20),
//                                       onPressed: () => _startEditing(data, doc.id),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                                       onPressed: () => _deleteDoctor(doc.id),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   );
//                 },
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
// import 'package:intl/intl.dart';

// class DoctorScreen extends StatefulWidget {
//   const DoctorScreen({super.key});

//   @override
//   State<DoctorScreen> createState() => _DoctorScreenState();
// }

// class _DoctorScreenState extends State<DoctorScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

//   final List<String> _genderOptions = ['male', 'female'];
//   final List<String> _statusOptions = ['pending', 'approved'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _specialtyController.dispose();
//     _experienceController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingDocId = null;
//       _nameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _specialtyController.clear();
//       _experienceController.clear();
//       _selectedGender = null;
//       _selectedStatus = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> doctorData, String docId) {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = docId;
//       _nameController.text = doctorData['fullName'] ?? '';
//       _emailController.text = doctorData['email'] ?? '';
//       _phoneController.text = doctorData['phone'] ?? '';
//       _addressController.text = doctorData['address'] ?? '';
//       _specialtyController.text = doctorData['specialties'] ?? '';
//       _experienceController.text = doctorData['experience']?.toString() ?? '';
//       _selectedGender = doctorData['gender']?.toLowerCase();
//       _selectedStatus = doctorData['status']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = null;
//     });
//   }

//   Future<void> _saveDoctor() async {
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _specialtyController.text.isEmpty ||
//         _experienceController.text.isEmpty ||
//         _selectedGender == null ||
//         _selectedStatus == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final doctorData = {
//         'fullName': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'specialties': _specialtyController.text,
//         'experience': int.tryParse(_experienceController.text) ?? 0,
//         'gender': _selectedGender,
//         'status': _selectedStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('doctors').add(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('doctors').doc(_editingDocId).update(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteDoctor(String doctorId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this doctor account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting doctor: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       onChanged: (value) => setState(() => _searchQuery = value),
//                       decoration: const InputDecoration(
//                         hintText: 'Search doctors...',
//                         prefixIcon: Icon(Icons.search),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton.icon(
//                     onPressed: _startAdding,
//                     icon: const Icon(Icons.add),
//                     label: const Text('Add'),
//                   ),
//                 ],
//               ),
//             ),

//             // Editing form
//             if (_editingDocId != null || _isAdding)
//               SingleChildScrollView(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   children: [
//                     TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
//                     TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
//                     TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
//                     TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
//                     TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialties')),
//                     TextField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience (years)'), keyboardType: TextInputType.number),
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: const InputDecoration(labelText: 'Gender'),
//                       items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
//                       onChanged: (val) => setState(() => _selectedGender = val),
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: _selectedStatus,
//                       decoration: const InputDecoration(labelText: 'Status'),
//                       items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
//                       onChanged: (val) => setState(() => _selectedStatus = val),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         ElevatedButton(onPressed: _saveDoctor, child: const Text('Save')),
//                         const SizedBox(width: 8),
//                         TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),

//             // Doctors table
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text('No doctors found'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
//                   }).toList();

//                   if (filtered.isEmpty) {
//                     return const Center(child: Text('No matching doctors found'));
//                   }

//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: SingleChildScrollView(
//                       child: DataTable(
//                         columns: const [
//                           DataColumn(label: Text('Name')),
//                           DataColumn(label: Text('Specialty')),
//                           DataColumn(label: Text('Email')),
//                           DataColumn(label: Text('Phone')),
//                           DataColumn(label: Text('Status')),
//                           DataColumn(label: Text('Experience')),
//                           DataColumn(label: Text('Actions')),
//                         ],
//                         rows: filtered.map((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           return DataRow(
//                             cells: [
//                               DataCell(Text(data['fullName'] ?? 'N/A')),
//                               DataCell(Text(data['specialties'] ?? 'N/A')),
//                               DataCell(Text(data['email'] ?? 'N/A')),
//                               DataCell(Text(data['phone'] ?? 'N/A')),
//                               DataCell(
//                                 Chip(
//                                   label: Text(
//                                     data['status']?.toString().toUpperCase() ?? 'N/A',
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                   backgroundColor: data['status'] == 'approved'
//                                       ? Colors.green[100]
//                                       : Colors.orange[100],
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 ),
//                               ),
//                               DataCell(Text('${data['experience']?.toString() ?? '0'} yrs')),
//                               DataCell(
//                                 Row(
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.edit, size: 20),
//                                       onPressed: () => _startEditing(data, doc.id),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                                       onPressed: () => _deleteDoctor(doc.id),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   );
//                 },
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
// import 'package:intl/intl.dart';

// class DoctorScreen extends StatefulWidget {
//   const DoctorScreen({super.key});

//   @override
//   State<DoctorScreen> createState() => _DoctorScreenState();
// }

// class _DoctorScreenState extends State<DoctorScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

//   final List<String> _genderOptions = ['male', 'female'];
//   final List<String> _statusOptions = ['pending', 'approved'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _specialtyController.dispose();
//     _experienceController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingDocId = null;
//       _nameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _specialtyController.clear();
//       _experienceController.clear();
//       _selectedGender = null;
//       _selectedStatus = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> doctorData, String docId) {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = docId;
//       _nameController.text = doctorData['fullName'] ?? '';
//       _emailController.text = doctorData['email'] ?? '';
//       _phoneController.text = doctorData['phone'] ?? '';
//       _addressController.text = doctorData['address'] ?? '';
//       _specialtyController.text = doctorData['specialties'] ?? '';
//       _experienceController.text = doctorData['experience']?.toString() ?? '';
//       _selectedGender = doctorData['gender']?.toLowerCase();
//       _selectedStatus = doctorData['status']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = null;
//     });
//   }

//   Future<void> _saveDoctor() async {
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _specialtyController.text.isEmpty ||
//         _experienceController.text.isEmpty ||
//         _selectedGender == null ||
//         _selectedStatus == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final doctorData = {
//         'fullName': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'specialties': _specialtyController.text,
//         'experience': int.tryParse(_experienceController.text) ?? 0,
//         'gender': _selectedGender,
//         'status': _selectedStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('doctors').add(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('doctors').doc(_editingDocId).update(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteDoctor(String doctorId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this doctor account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting doctor: $e')),
//         );
//       }
//     }
//   }

//   Widget _buildInfoRow(IconData icon, String? text) {
//     if (text == null || text.isEmpty) return const SizedBox();
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: Colors.grey[700]),
//           const SizedBox(width: 8),
//           Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
//         ],
//       ),
//     );
//   }

//   Widget _buildDoctorRow(Map<String, dynamic> doctor, String docId) {
//     final createdAt = doctor['createdAt']?.toDate();
//     final updatedAt = doctor['updatedAt']?.toDate();

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 24,
//                   backgroundImage: doctor['photoUrl'] != null
//                       ? NetworkImage(doctor['photoUrl'])
//                       : null,
//                   child: doctor['photoUrl'] == null
//                       ? Text(doctor['fullName']?[0] ?? '?')
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     doctor['fullName'] ?? 'No name',
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                 ),
//                 IconButton(icon: const Icon(Icons.edit), onPressed: () => _startEditing(doctor, docId)),
//                 IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDoctor(docId)),
//               ],
//             ),
//             const Divider(),
//             _buildInfoRow(Icons.medical_services, doctor['specialties']),
//             _buildInfoRow(Icons.email, doctor['email']),
//             _buildInfoRow(Icons.phone, doctor['phone']),
//             _buildInfoRow(Icons.location_on, doctor['address']),
//             _buildInfoRow(Icons.work, '${doctor['experience']} years experience'),
//             _buildInfoRow(Icons.person, doctor['gender']),
//             _buildInfoRow(
//               Icons.check_circle,
//               doctor['status'] == 'approved' ? 'Approved' : 'Pending',
//             ),
//             if (createdAt != null)
//               _buildInfoRow(Icons.calendar_today, 'Registered: ${DateFormat('MMM d, y').format(createdAt)}'),
//             if (updatedAt != null)
//               _buildInfoRow(Icons.update, 'Updated: ${DateFormat('MMM d, y').format(updatedAt)}'),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       onChanged: (value) => setState(() => _searchQuery = value),
//                       decoration: const InputDecoration(
//                         hintText: 'Search doctors...',
//                         prefixIcon: Icon(Icons.search),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton.icon(
//                     onPressed: _startAdding,
//                     icon: const Icon(Icons.add),
//                     label: const Text('Add'),
//                   ),
//                 ],
//               ),
//             ),

//             // Editing form
//             if (_editingDocId != null || _isAdding)
//               SingleChildScrollView(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   children: [
//                     TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
//                     TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
//                     TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
//                     TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
//                     TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialties')),
//                     TextField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience (years)'), keyboardType: TextInputType.number),
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: const InputDecoration(labelText: 'Gender'),
//                       items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
//                       onChanged: (val) => setState(() => _selectedGender = val),
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: _selectedStatus,
//                       decoration: const InputDecoration(labelText: 'Status'),
//                       items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
//                       onChanged: (val) => setState(() => _selectedStatus = val),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         ElevatedButton(onPressed: _saveDoctor, child: const Text('Save')),
//                         const SizedBox(width: 8),
//                         TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),

//             // Doctors list
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text('No doctors found'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
//                   }).toList();

//                   if (filtered.isEmpty) {
//                     return const Center(child: Text('No matching doctors found'));
//                   }

//                   return ListView.builder(
//                     itemCount: filtered.length,
//                     itemBuilder: (context, index) {
//                       final doc = filtered[index];
//                       return _buildDoctorRow(doc.data()! as Map<String, dynamic>, doc.id);
//                     },
//                   );
//                 },
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
// import 'package:intl/intl.dart';

// class DoctorScreen extends StatefulWidget {
//   const DoctorScreen({super.key});

//   @override
//   State<DoctorScreen> createState() => _DoctorScreenState();
// }

// class _DoctorScreenState extends State<DoctorScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

//   final List<String> _genderOptions = ['male', 'female'];
//   final List<String> _statusOptions = ['pending', 'approved'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _specialtyController.dispose();
//     _experienceController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingDocId = null;
//       _nameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _specialtyController.clear();
//       _experienceController.clear();
//       _selectedGender = null;
//       _selectedStatus = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> doctorData, String docId) {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = docId;
//       _nameController.text = doctorData['fullName'] ?? '';
//       _emailController.text = doctorData['email'] ?? '';
//       _phoneController.text = doctorData['phone'] ?? '';
//       _addressController.text = doctorData['address'] ?? '';
//       _specialtyController.text = doctorData['specialties'] ?? '';
//       _experienceController.text = doctorData['experience']?.toString() ?? '';
//       _selectedGender = doctorData['gender']?.toLowerCase();
//       _selectedStatus = doctorData['status']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingDocId = null;
//     });
//   }

//   Future<void> _saveDoctor() async {
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _specialtyController.text.isEmpty ||
//         _experienceController.text.isEmpty ||
//         _selectedGender == null ||
//         _selectedStatus == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final doctorData = {
//         'fullName': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'specialties': _specialtyController.text,
//         'experience': int.tryParse(_experienceController.text) ?? 0,
//         'gender': _selectedGender,
//         'status': _selectedStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('doctors').add(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('doctors').doc(_editingDocId).update(doctorData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteDoctor(String doctorId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this doctor account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Doctor deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting doctor: $e')),
//         );
//       }
//     }
//   }

//   Widget _buildInfoRow(IconData icon, String? text) {
//     if (text == null || text.isEmpty) return const SizedBox();
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: Colors.grey[700]),
//           const SizedBox(width: 8),
//           Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
//         ],
//       ),
//     );
//   }

//   Widget _buildDoctorRow(Map<String, dynamic> doctor, String docId) {
//     final createdAt = doctor['createdAt']?.toDate();
//     final updatedAt = doctor['updatedAt']?.toDate();

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 24,
//                   backgroundImage: doctor['photoUrl'] != null
//                       ? NetworkImage(doctor['photoUrl'])
//                       : null,
//                   child: doctor['photoUrl'] == null
//                       ? Text(doctor['fullName']?[0] ?? '?')
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     doctor['fullName'] ?? 'No name',
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                 ),
//                 IconButton(icon: const Icon(Icons.edit), onPressed: () => _startEditing(doctor, docId)),
//                 IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDoctor(docId)),
//               ],
//             ),
//             const Divider(),
//             _buildInfoRow(Icons.medical_services, doctor['specialties']),
//             _buildInfoRow(Icons.email, doctor['email']),
//             _buildInfoRow(Icons.phone, doctor['phone']),
//             _buildInfoRow(Icons.location_on, doctor['address']),
//             _buildInfoRow(Icons.work, '${doctor['experience']} years experience'),
//             _buildInfoRow(Icons.person, doctor['gender']),
//             _buildInfoRow(
//               Icons.check_circle,
//               doctor['status'] == 'approved' ? 'Approved' : 'Pending',
//             ),
//             if (createdAt != null)
//               _buildInfoRow(Icons.calendar_today, 'Registered: ${DateFormat('MMM d, y').format(createdAt)}'),
//             if (updatedAt != null)
//               _buildInfoRow(Icons.update, 'Updated: ${DateFormat('MMM d, y').format(updatedAt)}'),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Column(
//         children: [
//           // Top bar
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: (value) => setState(() => _searchQuery = value),
//                     decoration: const InputDecoration(
//                       hintText: 'Search doctors...',
//                       prefixIcon: Icon(Icons.search),
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton.icon(
//                   onPressed: _startAdding,
//                   icon: const Icon(Icons.add),
//                   label: const Text('Add'),
//                 ),
//               ],
//             ),
//           ),

//           // Main content
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

//                 final docs = snapshot.data!.docs;
//                 final filtered = docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   return data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
//                 }).toList();

//                 return SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       if (_editingDocId != null || _isAdding)
//                         Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Column(
//                             children: [
//                               TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
//                               TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
//                               TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
//                               TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
//                               TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialties')),
//                               TextField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience (years)'), keyboardType: TextInputType.number),
//                               DropdownButtonFormField<String>(
//                                 value: _selectedGender,
//                                 decoration: const InputDecoration(labelText: 'Gender'),
//                                 items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
//                                 onChanged: (val) => setState(() => _selectedGender = val),
//                               ),
//                               DropdownButtonFormField<String>(
//                                 value: _selectedStatus,
//                                 decoration: const InputDecoration(labelText: 'Status'),
//                                 items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
//                                 onChanged: (val) => setState(() => _selectedStatus = val),
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   ElevatedButton(onPressed: _saveDoctor, child: const Text('Save')),
//                                   const SizedBox(width: 8),
//                                   TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
//                                 ],
//                               )
//                             ],
//                           ),
//                         ),
//                       ...filtered.map((doc) => _buildDoctorRow(doc.data()! as Map<String, dynamic>, doc.id)).toList(),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
