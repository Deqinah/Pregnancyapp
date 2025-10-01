import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _editingUserId;
  bool _isAdding = false;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();



  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    // Get all patients data
    final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    final patients = querySnapshot.docs;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Patients Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Name', 'Email', 'Phone', 'Address', 'DOB', 'Registered'],
                data: patients.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // Format date of birth
                  String formattedDob = data['dateOfBirth'] ?? '';
                  if (formattedDob.isEmpty && data['dateOfBirth'] != null) {
                    if (data['dateOfBirth'] is int) {
                      final date = DateTime.fromMillisecondsSinceEpoch(data['dateOfBirth']);
                      formattedDob = DateFormat('yyyy-MM-dd').format(date);
                    } else if (data['dateOfBirth'] is Timestamp) {
                      final date = (data['dateOfBirth'] as Timestamp).toDate();
                      formattedDob = DateFormat('yyyy-MM-dd').format(date);
                    }
                  }

                  return [
                    data['fullName'] ?? 'N/A',
                    data['email'] ?? 'N/A',
                    data['phone'] ?? 'N/A',
                    data['address'] ?? 'N/A',
                    formattedDob,
                    _formatTimestamp(data['createdAt'] as Timestamp?),
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
  void dispose() {
    _searchController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _startAdding() {
    setState(() {
      _isAdding = true;
      _editingUserId = null;
      _fullNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _dateOfBirthController.clear();
    });
  }

  void _startEditing(Map<String, dynamic> userData, String userId) {
    setState(() {
      _isAdding = false;
      _editingUserId = userId;
      _fullNameController.text = userData['fullName'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
      
      if (userData['dateOfBirth'] != null) {
        if (userData['dateOfBirth'] is String) {
          _dateOfBirthController.text = userData['dateOfBirth'];
        } else if (userData['dateOfBirth'] is int) {
          final date = DateTime.fromMillisecondsSinceEpoch(userData['dateOfBirth']);
          _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
        } else if (userData['dateOfBirth'] is Timestamp) {
          final date = (userData['dateOfBirth'] as Timestamp).toDate();
          _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
        }
      } else {
        _dateOfBirthController.clear();
      }
     
    });
  }

  void _cancelEditing() {
    setState(() {
      _isAdding = false;
      _editingUserId = null;
    });
  }

  Future<void> _saveUser() async {
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _dateOfBirthController.text.isEmpty ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final dateOfBirth = DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text);
      
      final userData = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'dateOfBirth': _dateOfBirthController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
      };

      if (_isAdding) {
        await FirebaseFirestore.instance.collection('users').add(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully')),
        );
      } else {
        await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      }

      _cancelEditing();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
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
                        hintText: 'Search patients...',
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data!.docs;
                  final filtered = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['fullName']
                            ?.toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ??
                        false;
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Address')),
                        DataColumn(label: Text('DOB')),
                        DataColumn(label: Text('Registered')),
                        DataColumn(label: Text('Last Updated')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: [
                        if (_isAdding || _editingUserId != null)
                          DataRow(
                            cells: [
                              DataCell(TextField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(hintText: 'Full Name'),
                              )),
                              DataCell(TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(hintText: 'Email'),
                              )),
                              DataCell(TextField(
                                controller: _phoneController,
                                decoration: const InputDecoration(hintText: 'Phone'),
                              )),
                              DataCell(TextField(
                                controller: _addressController,
                                decoration: const InputDecoration(hintText: 'Address'),
                              )),
                              DataCell(
                                TextField(
                                  controller: _dateOfBirthController,
                                  decoration: const InputDecoration(
                                    hintText: 'DOB',
                                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _dateOfBirthController.text = 
                                          DateFormat('yyyy-MM-dd').format(picked);
                                      });
                                    }
                                  },
                                ),
                              ),
                              
                              DataCell(const Text('Now')),
                              DataCell(const Text('Now')),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: _saveUser,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: _cancelEditing,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ...filtered.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final isEditing = _editingUserId == doc.id;
                          
                          // Format date of birth
                          String formattedDob = data['dateOfBirth'] ?? '';
                          if (formattedDob.isEmpty && data['dateOfBirth'] != null) {
                            if (data['dateOfBirth'] is int) {
                              final date = DateTime.fromMillisecondsSinceEpoch(data['dateOfBirth']);
                              formattedDob = DateFormat('yyyy-MM-dd').format(date);
                            } else if (data['dateOfBirth'] is Timestamp) {
                              final date = (data['dateOfBirth'] as Timestamp).toDate();
                              formattedDob = DateFormat('yyyy-MM-dd').format(date);
                            }
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                isEditing
                                    ? TextField(
                                        controller: _fullNameController,
                                        decoration: const InputDecoration(hintText: 'Full Name'),
                                      )
                                    : Text(data['fullName'] ?? ''),
                              ),
                              DataCell(
                                isEditing
                                    ? TextField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(hintText: 'Email'),
                                      )
                                    : Text(data['email'] ?? ''),
                              ),
                              DataCell(
                                isEditing
                                    ? TextField(
                                        controller: _phoneController,
                                        decoration: const InputDecoration(hintText: 'Phone'),
                                      )
                                    : Text(data['phone'] ?? ''),
                              ),
                              DataCell(
                                isEditing
                                    ? TextField(
                                        controller: _addressController,
                                        decoration: const InputDecoration(hintText: 'Address'),
                                      )
                                    : Text(data['address'] ?? ''),
                              ),
                              DataCell(
                                isEditing
                                    ? TextField(
                                        controller: _dateOfBirthController,
                                        decoration: const InputDecoration(hintText: 'DOB'),
                                        readOnly: true,
                                        onTap: () async {
                                          final DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _dateOfBirthController.text = 
                                                DateFormat('yyyy-MM-dd').format(picked);
                                            });
                                          }
                                        },
                                      )
                                    : Text(formattedDob),
                              ),
                            
                              DataCell(Text(_formatTimestamp(data['createdAt'] as Timestamp?))),
                              DataCell(Text(_formatTimestamp(data['updatedAt'] as Timestamp?))),
                              DataCell(
                                isEditing
                                    ? Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check, color: Colors.green),
                                            onPressed: _saveUser,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: _cancelEditing,
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18),
                                            onPressed: () => _startEditing(data, doc.id),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                            onPressed: () => _deleteUser(doc.id),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
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

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['Male', 'Female'];

//   String _formatTimestamp(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
      
//       if (userData['dateOfBirth'] != null) {
//         if (userData['dateOfBirth'] is String) {
//           _dateOfBirthController.text = userData['dateOfBirth'];
//         } else if (userData['dateOfBirth'] is int) {
//           final date = DateTime.fromMillisecondsSinceEpoch(userData['dateOfBirth']);
//           _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
//         } else if (userData['dateOfBirth'] is Timestamp) {
//           final date = (userData['dateOfBirth'] as Timestamp).toDate();
//           _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
//         }
//       } else {
//         _dateOfBirthController.clear();
//       }
      
//       _selectedGender = userData['gender'];
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final dateOfBirth = DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text);
      
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': _dateOfBirthController.text,
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
     
//       body: Column(
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: _startAdding,
//             tooltip: 'Add Patient',
//           ),
//            actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _generatePdfReport,
//             tooltip: 'Generate PDF Report',
//           ),
//         ],
//         ],
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               onChanged: (value) => setState(() => _searchQuery = value),
//               decoration: const InputDecoration(
//                 hintText: 'Search patients...',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance.collection('users').snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 final docs = snapshot.data!.docs;
//                 final filtered = docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   return data['fullName']
//                           ?.toString()
//                           .toLowerCase()
//                           .contains(_searchQuery.toLowerCase()) ??
//                       false;
//                 }).toList();

//                 return SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: DataTable(
//                     columns: const [
//                       DataColumn(label: Text('Name')),
//                       DataColumn(label: Text('Email')),
//                       DataColumn(label: Text('Phone')),
//                       DataColumn(label: Text('Address')),
//                       DataColumn(label: Text('DOB')),
//                       DataColumn(label: Text('Gender')),
//                       DataColumn(label: Text('Registered')),
//                       DataColumn(label: Text('Last Updated')),
//                       DataColumn(label: Text('Actions')),
//                     ],
//                     rows: [
//                       if (_isAdding || _editingUserId != null)
//                         DataRow(
//                           cells: [
//                             DataCell(TextField(
//                               controller: _fullNameController,
//                               decoration: const InputDecoration(hintText: 'Full Name'),
//                             )),
//                             DataCell(TextField(
//                               controller: _emailController,
//                               decoration: const InputDecoration(hintText: 'Email'),
//                             )),
//                             DataCell(TextField(
//                               controller: _phoneController,
//                               decoration: const InputDecoration(hintText: 'Phone'),
//                             )),
//                             DataCell(TextField(
//                               controller: _addressController,
//                               decoration: const InputDecoration(hintText: 'Address'),
//                             )),
//                             DataCell(
//                               TextField(
//                                 controller: _dateOfBirthController,
//                                 decoration: const InputDecoration(
//                                   hintText: 'DOB',
//                                   suffixIcon: Icon(Icons.calendar_today, size: 18),
//                                 ),
//                                 readOnly: true,
//                                 onTap: () async {
//                                   final DateTime? picked = await showDatePicker(
//                                     context: context,
//                                     initialDate: DateTime.now(),
//                                     firstDate: DateTime(1900),
//                                     lastDate: DateTime.now(),
//                                   );
//                                   if (picked != null) {
//                                     setState(() {
//                                       _dateOfBirthController.text = 
//                                         DateFormat('yyyy-MM-dd').format(picked);
//                                     });
//                                   }
//                                 },
//                               ),
//                             ),
//                             DataCell(
//                               DropdownButton<String>(
//                                 value: _selectedGender,
//                                 items: _genderOptions
//                                     .map((gender) => DropdownMenuItem(
//                                           value: gender,
//                                           child: Text(gender),
//                                         ))
//                                     .toList(),
//                                 onChanged: (val) => setState(() => _selectedGender = val),
//                                 hint: const Text('Select'),
//                                 isExpanded: true,
//                                 underline: const SizedBox(),
//                               ),
//                             ),
//                             DataCell(const Text('Now')),
//                             DataCell(const Text('Now')),
//                             DataCell(
//                               Row(
//                                 children: [
//                                   IconButton(
//                                     icon: const Icon(Icons.check, color: Colors.green),
//                                     onPressed: _saveUser,
//                                   ),
//                                   IconButton(
//                                     icon: const Icon(Icons.close, color: Colors.red),
//                                     onPressed: _cancelEditing,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ...filtered.map((doc) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         final isEditing = _editingUserId == doc.id;
                        
//                         // Format date of birth
//                         String formattedDob = data['dateOfBirth'] ?? '';
//                         if (formattedDob.isEmpty && data['dateOfBirth'] != null) {
//                           if (data['dateOfBirth'] is int) {
//                             final date = DateTime.fromMillisecondsSinceEpoch(data['dateOfBirth']);
//                             formattedDob = DateFormat('yyyy-MM-dd').format(date);
//                           } else if (data['dateOfBirth'] is Timestamp) {
//                             final date = (data['dateOfBirth'] as Timestamp).toDate();
//                             formattedDob = DateFormat('yyyy-MM-dd').format(date);
//                           }
//                         }

//                         return DataRow(
//                           cells: [
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _fullNameController,
//                                       decoration: const InputDecoration(hintText: 'Full Name'),
//                                     )
//                                   : Text(data['fullName'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _emailController,
//                                       decoration: const InputDecoration(hintText: 'Email'),
//                                     )
//                                   : Text(data['email'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _phoneController,
//                                       decoration: const InputDecoration(hintText: 'Phone'),
//                                     )
//                                   : Text(data['phone'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _addressController,
//                                       decoration: const InputDecoration(hintText: 'Address'),
//                                     )
//                                   : Text(data['address'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _dateOfBirthController,
//                                       decoration: const InputDecoration(hintText: 'DOB'),
//                                       readOnly: true,
//                                       onTap: () async {
//                                         final DateTime? picked = await showDatePicker(
//                                           context: context,
//                                           initialDate: DateTime.now(),
//                                           firstDate: DateTime(1900),
//                                           lastDate: DateTime.now(),
//                                         );
//                                         if (picked != null) {
//                                           setState(() {
//                                             _dateOfBirthController.text = 
//                                               DateFormat('yyyy-MM-dd').format(picked);
//                                           });
//                                         }
//                                       },
//                                     )
//                                   : Text(formattedDob),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? DropdownButton<String>(
//                                       value: _selectedGender,
//                                       items: _genderOptions
//                                           .map((gender) => DropdownMenuItem(
//                                                 value: gender,
//                                                 child: Text(gender),
//                                               ))
//                                           .toList(),
//                                       onChanged: (val) => setState(() => _selectedGender = val),
//                                       hint: const Text('Select'),
//                                       isExpanded: true,
//                                       underline: const SizedBox(),
//                                     )
//                                   : Text(data['gender'] ?? ''),
//                             ),
//                             DataCell(Text(_formatTimestamp(data['createdAt'] as Timestamp?))),
//                             DataCell(Text(_formatTimestamp(data['updatedAt'] as Timestamp?))),
//                             DataCell(
//                               isEditing
//                                   ? Row(
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(Icons.check, color: Colors.green),
//                                           onPressed: _saveUser,
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.close, color: Colors.red),
//                                           onPressed: _cancelEditing,
//                                         ),
//                                       ],
//                                     )
//                                   : Row(
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(Icons.edit, size: 18),
//                                           onPressed: () => _startEditing(data, doc.id),
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.delete, size: 18, color: Colors.red),
//                                           onPressed: () => _deleteUser(doc.id),
//                                         ),
//                                       ],
//                                     ),
//                             ),
//                           ],
//                         );
//                       }).toList(),
//                     ],
//                   ),
//                    await Printing.layoutPdf(
//     onLayout: (PdfPageFormat format) async => pdf.save(),
//   );
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
// import 'package:intl/intl.dart';

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['Male', 'Female'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
      
//       if (userData['dateOfBirth'] != null) {
//         if (userData['dateOfBirth'] is String) {
//           _dateOfBirthController.text = userData['dateOfBirth'];
//         } else if (userData['dateOfBirth'] is int) {
//           final date = DateTime.fromMillisecondsSinceEpoch(userData['dateOfBirth']);
//           _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
//         } else if (userData['dateOfBirth'] is Timestamp) {
//           final date = (userData['dateOfBirth'] as Timestamp).toDate();
//           _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
//         }
//       } else {
//         _dateOfBirthController.clear();
//       }
      
//       _selectedGender = userData['gender'];
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final dateOfBirth = DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text);
      
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': _dateOfBirthController.text,
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patients'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: _startAdding,
//             tooltip: 'Add Patient',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               onChanged: (value) => setState(() => _searchQuery = value),
//               decoration: const InputDecoration(
//                 hintText: 'Search patients...',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance.collection('users').snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 final docs = snapshot.data!.docs;
//                 final filtered = docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   return data['fullName']
//                           ?.toString()
//                           .toLowerCase()
//                           .contains(_searchQuery.toLowerCase()) ??
//                       false;
//                 }).toList();

//                 return SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: DataTable(
//                     columns: const [
//                       DataColumn(label: Text('Name')),
//                       DataColumn(label: Text('Email')),
//                       DataColumn(label: Text('Phone')),
//                       DataColumn(label: Text('Address')),
//                       DataColumn(label: Text('DOB')),
//                       DataColumn(label: Text('Gender')),
//                       DataColumn(label: Text('Actions')),
//                     ],
//                     rows: [
//                       if (_isAdding || _editingUserId != null)
//                         DataRow(
//                           cells: [
//                             DataCell(TextField(
//                               controller: _fullNameController,
//                               decoration: const InputDecoration(hintText: 'Full Name'),
//                             )),
//                             DataCell(TextField(
//                               controller: _emailController,
//                               decoration: const InputDecoration(hintText: 'Email'),
//                             )),
//                             DataCell(TextField(
//                               controller: _phoneController,
//                               decoration: const InputDecoration(hintText: 'Phone'),
//                             )),
//                             DataCell(TextField(
//                               controller: _addressController,
//                               decoration: const InputDecoration(hintText: 'Address'),
//                             )),
//                             DataCell(
//                               TextField(
//                                 controller: _dateOfBirthController,
//                                 decoration: const InputDecoration(
//                                   hintText: 'DOB',
//                                   suffixIcon: Icon(Icons.calendar_today, size: 18),
//                                 ),
//                                 readOnly: true,
//                                 onTap: () async {
//                                   final DateTime? picked = await showDatePicker(
//                                     context: context,
//                                     initialDate: DateTime.now(),
//                                     firstDate: DateTime(1900),
//                                     lastDate: DateTime.now(),
//                                   );
//                                   if (picked != null) {
//                                     setState(() {
//                                       _dateOfBirthController.text = 
//                                         DateFormat('yyyy-MM-dd').format(picked);
//                                     });
//                                   }
//                                 },
//                               ),
//                             ),
//                             DataCell(
//                               DropdownButton<String>(
//                                 value: _selectedGender,
//                                 items: _genderOptions
//                                     .map((gender) => DropdownMenuItem(
//                                           value: gender,
//                                           child: Text(gender),
//                                         ))
//                                     .toList(),
//                                 onChanged: (val) => setState(() => _selectedGender = val),
//                                 hint: const Text('Select'),
//                                 isExpanded: true,
//                                 underline: const SizedBox(),
//                               ),
//                             ),
//                             DataCell(
//                               Row(
//                                 children: [
//                                   IconButton(
//                                     icon: const Icon(Icons.check, color: Colors.green),
//                                     onPressed: _saveUser,
//                                   ),
//                                   IconButton(
//                                     icon: const Icon(Icons.close, color: Colors.red),
//                                     onPressed: _cancelEditing,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ...filtered.map((doc) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         final isEditing = _editingUserId == doc.id;
                        
//                         // Format date of birth
//                         String formattedDob = data['dateOfBirth'] ?? '';
//                         if (formattedDob.isEmpty && data['dateOfBirth'] != null) {
//                           if (data['dateOfBirth'] is int) {
//                             final date = DateTime.fromMillisecondsSinceEpoch(data['dateOfBirth']);
//                             formattedDob = DateFormat('yyyy-MM-dd').format(date);
//                           } else if (data['dateOfBirth'] is Timestamp) {
//                             final date = (data['dateOfBirth'] as Timestamp).toDate();
//                             formattedDob = DateFormat('yyyy-MM-dd').format(date);
//                           }
//                         }

//                         return DataRow(
//                           cells: [
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _fullNameController,
//                                       decoration: const InputDecoration(hintText: 'Full Name'),
//                                     )
//                                   : Text(data['fullName'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _emailController,
//                                       decoration: const InputDecoration(hintText: 'Email'),
//                                     )
//                                   : Text(data['email'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _phoneController,
//                                       decoration: const InputDecoration(hintText: 'Phone'),
//                                     )
//                                   : Text(data['phone'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _addressController,
//                                       decoration: const InputDecoration(hintText: 'Address'),
//                                     )
//                                   : Text(data['address'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? TextField(
//                                       controller: _dateOfBirthController,
//                                       decoration: const InputDecoration(hintText: 'DOB'),
//                                       readOnly: true,
//                                       onTap: () async {
//                                         final DateTime? picked = await showDatePicker(
//                                           context: context,
//                                           initialDate: DateTime.now(),
//                                           firstDate: DateTime(1900),
//                                           lastDate: DateTime.now(),
//                                         );
//                                         if (picked != null) {
//                                           setState(() {
//                                             _dateOfBirthController.text = 
//                                               DateFormat('yyyy-MM-dd').format(picked);
//                                           });
//                                         }
//                                       },
//                                     )
//                                   : Text(formattedDob),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? DropdownButton<String>(
//                                       value: _selectedGender,
//                                       items: _genderOptions
//                                           .map((gender) => DropdownMenuItem(
//                                                 value: gender,
//                                                 child: Text(gender),
//                                               ))
//                                           .toList(),
//                                       onChanged: (val) => setState(() => _selectedGender = val),
//                                       hint: const Text('Select'),
//                                       isExpanded: true,
//                                       underline: const SizedBox(),
//                                     )
//                                   : Text(data['gender'] ?? ''),
//                             ),
//                             DataCell(
//                               isEditing
//                                   ? Row(
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(Icons.check, color: Colors.green),
//                                           onPressed: _saveUser,
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.close, color: Colors.red),
//                                           onPressed: _cancelEditing,
//                                         ),
//                                       ],
//                                     )
//                                   : Row(
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(Icons.edit, size: 18),
//                                           onPressed: () => _startEditing(data, doc.id),
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.delete, size: 18, color: Colors.red),
//                                           onPressed: () => _deleteUser(doc.id),
//                                         ),
//                                       ],
//                                     ),
//                             ),
//                           ],
//                         );
//                       }).toList(),
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




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['Male', 'Female'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
      
//       // Handle date of birth - could be string or timestamp
//       if (userData['dateOfBirth'] != null) {
//         if (userData['dateOfBirth'] is String) {
//           // If stored as string (e.g., "2004-08-15")
//           _dateOfBirthController.text = userData['dateOfBirth'];
//         } else if (userData['dateOfBirth'] is int) {
//           // If stored as timestamp
//           final date = DateTime.fromMillisecondsSinceEpoch(userData['dateOfBirth']);
//           _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
//         } else if (userData['dateOfBirth'] is Timestamp) {
//           // If stored as Firestore Timestamp
//           final date = (userData['dateOfBirth'] as Timestamp).toDate();
//           _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
//         }
//       } else {
//         _dateOfBirthController.clear();
//       }
      
//       _selectedGender = userData['gender'];
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       // Parse the date string to DateTime
//       final dateOfBirth = DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text);
      
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': _dateOfBirthController.text, // Store as string "yyyy-MM-dd"
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
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
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserCard(Map<String, dynamic> user, String userId) {
//     final createdAt = user['createdAt']?.toDate();
//     final updatedAt = user['updatedAt']?.toDate();
    
//     // Format date of birth for display
//     String? formattedDateOfBirth = user['dateOfBirth'];
//     if (formattedDateOfBirth == null && user['dateOfBirth'] != null) {
//       if (user['dateOfBirth'] is int) {
//         final date = DateTime.fromMillisecondsSinceEpoch(user['dateOfBirth']);
//         formattedDateOfBirth = DateFormat('yyyy-MM-dd').format(date);
//       } else if (user['dateOfBirth'] is Timestamp) {
//         final date = (user['dateOfBirth'] as Timestamp).toDate();
//         formattedDateOfBirth = DateFormat('yyyy-MM-dd').format(date);
//       }
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       child: InkWell(
//         onTap: () => _startEditing(user, userId),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 24,
//                     backgroundImage: user['photoUrl'] != null
//                         ? NetworkImage(user['photoUrl'])
//                         : null,
//                     child: user['photoUrl'] == null
//                         ? Text(user['fullName']?[0] ?? '?')
//                         : null,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       user['fullName'] ?? 'No name',
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   if (MediaQuery.of(context).size.width > 600)
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.edit),
//                           onPressed: () => _startEditing(user, userId),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () => _deleteUser(userId),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//               if (MediaQuery.of(context).size.width <= 600)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton.icon(
//                         icon: const Icon(Icons.edit, size: 16),
//                         label: const Text('Edit'),
//                         onPressed: () => _startEditing(user, userId),
//                       ),
//                       const SizedBox(width: 8),
//                       TextButton.icon(
//                         icon: const Icon(Icons.delete, size: 16, color: Colors.red),
//                         label: const Text('Delete', style: TextStyle(color: Colors.red)),
//                         onPressed: () => _deleteUser(userId),
//                       ),
//                     ],
//                   ),
//                 ),
//               const Divider(),
//               Wrap(
//                 spacing: 16,
//                 runSpacing: 8,
//                 children: [
//                   if (user['email'] != null && user['email'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.email, size: 16),
//                       label: Text(user['email']),
//                     ),
//                   if (user['phone'] != null && user['phone'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.phone, size: 16),
//                       label: Text(user['phone']),
//                     ),
//                   if (user['address'] != null && user['address'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.location_on, size: 16),
//                       label: Text(user['address']),
//                     ),
//                   if (formattedDateOfBirth != null)
//                     Chip(
//                       avatar: const Icon(Icons.cake, size: 16),
//                       label: Text(formattedDateOfBirth),
//                     ),
//                   if (user['gender'] != null)
//                     Chip(
//                       avatar: const Icon(Icons.person, size: 16),
//                       label: Text(user['gender']),
//                     ),
//                 ],
//               ),
//               if (createdAt != null || updatedAt != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Wrap(
//                     spacing: 8,
//                     runSpacing: 4,
//                     children: [
//                       if (createdAt != null)
//                         Text(
//                           'Registered: ${DateFormat('MMM d, y').format(createdAt)}',
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                       if (updatedAt != null)
//                         Text(
//                           'Updated: ${DateFormat('MMM d, y').format(updatedAt)}',
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
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
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   if (constraints.maxWidth > 600) {
//                     return Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _searchController,
//                             onChanged: (value) => setState(() => _searchQuery = value),
//                             decoration: const InputDecoration(
//                               hintText: 'Search user...',
//                               prefixIcon: Icon(Icons.search),
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         ElevatedButton.icon(
//                           onPressed: _startAdding,
//                           icon: const Icon(Icons.add),
//                           label: const Text('Add User'),
//                         ),
//                       ],
//                     );
//                   } else {
//                     return Column(
//                       children: [
//                         TextField(
//                           controller: _searchController,
//                           onChanged: (value) => setState(() => _searchQuery = value),
//                           decoration: const InputDecoration(
//                             hintText: 'Search user...',
//                             prefixIcon: Icon(Icons.search),
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton.icon(
//                             onPressed: _startAdding,
//                             icon: const Icon(Icons.add),
//                             label: const Text('Add User'),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//                 },
//               ),
//             ),

//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']
//                             ?.toString()
//                             .toLowerCase()
//                             .contains(_searchQuery.toLowerCase()) ??
//                         false;
//                   }).toList();

//                   return ListView.builder(
//                     itemCount: (_editingUserId != null || _isAdding) ? filtered.length + 1 : filtered.length,
//                     itemBuilder: (context, index) {
//                       if (index == 0 && (_editingUserId != null || _isAdding)) {
//                         return Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Column(
//                                 children: [
//                                   TextField(
//                                     controller: _fullNameController,
//                                     decoration: const InputDecoration(labelText: 'Full Name*'),
//                                   ),
//                                   TextField(
//                                     controller: _emailController,
//                                     decoration: const InputDecoration(labelText: 'Email*'),
//                                     keyboardType: TextInputType.emailAddress,
//                                   ),
//                                   TextField(
//                                     controller: _phoneController,
//                                     decoration: const InputDecoration(labelText: 'Phone*'),
//                                     keyboardType: TextInputType.phone,
//                                   ),
//                                   TextField(
//                                     controller: _addressController,
//                                     decoration: const InputDecoration(labelText: 'Address*'),
//                                   ),
//                                   TextFormField(
//                                     controller: _dateOfBirthController,
//                                     decoration: const InputDecoration(
//                                       labelText: 'Date of Birth*',
//                                       suffixIcon: Icon(Icons.calendar_today),
//                                     ),
//                                     readOnly: true,
//                                     onTap: () async {
//                                       FocusScope.of(context).requestFocus(FocusNode());
//                                       final DateTime? picked = await showDatePicker(
//                                         context: context,
//                                         initialDate: DateTime.now(),
//                                         firstDate: DateTime(1900),
//                                         lastDate: DateTime.now(),
//                                         initialEntryMode: DatePickerEntryMode.calendarOnly,
//                                         initialDatePickerMode: DatePickerMode.year,
//                                         builder: (context, child) {
//                                           return Theme(
//                                             data: Theme.of(context).copyWith(
//                                               colorScheme: ColorScheme.light(
//                                                 primary: Colors.blue,
//                                                 onPrimary: Colors.white,
//                                                 onSurface: Colors.black,
//                                               ),
//                                               textButtonTheme: TextButtonThemeData(
//                                                 style: TextButton.styleFrom(
//                                                   foregroundColor: Colors.blue,
//                                                 ),
//                                               ),
//                                             ),
//                                             child: child!,
//                                           );
//                                         },
//                                       );
                                      
//                                       if (picked != null) {
//                                         setState(() {
//                                           _dateOfBirthController.text = 
//                                             DateFormat('yyyy-MM-dd').format(picked);
//                                         });
//                                       }
//                                     },
//                                   ),
//                                   DropdownButtonFormField<String>(
//                                     value: _selectedGender,
//                                     decoration: const InputDecoration(labelText: 'Gender*'),
//                                     items: _genderOptions
//                                         .map((gender) => DropdownMenuItem(
//                                               value: gender,
//                                               child: Text(gender),
//                                             ))
//                                         .toList(),
//                                     onChanged: (val) => setState(() => _selectedGender = val),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       TextButton(
//                                         onPressed: _cancelEditing,
//                                         child: const Text('Cancel'),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       ElevatedButton(
//                                         onPressed: _saveUser,
//                                         child: const Text('Save'),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }

//                       final docIndex = (_editingUserId != null || _isAdding) ? index - 1 : index;
//                       final doc = filtered[docIndex];
//                       return _buildUserCard(doc.data() as Map<String, dynamic>, doc.id);
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

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['Male', 'Female'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
      
//       // Handle date of birth - assuming it's stored as a timestamp in Firestore
//       if (userData['dateOfBirth'] != null) {
//         final date = DateTime.fromMillisecondsSinceEpoch(userData['dateOfBirth']);
//         _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
//       } else {
//         _dateOfBirthController.clear();
//       }
      
//       _selectedGender = userData['gender'];
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       // Parse the date string to DateTime
//       final dateOfBirth = DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text);
      
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': dateOfBirth.millisecondsSinceEpoch, // Store as timestamp
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
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
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserCard(Map<String, dynamic> user, String userId) {
//     final createdAt = user['createdAt']?.toDate();
//     final updatedAt = user['updatedAt']?.toDate();
    
//     // Format date of birth for display
//     String? formattedDateOfBirth;
//     if (user['dateOfBirth'] != null) {
//       final date = DateTime.fromMillisecondsSinceEpoch(user['dateOfBirth']);
//       formattedDateOfBirth = DateFormat('yyyy-MM-dd').format(date);
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       child: InkWell(
//         onTap: () => _startEditing(user, userId),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 24,
//                     backgroundImage: user['photoUrl'] != null
//                         ? NetworkImage(user['photoUrl'])
//                         : null,
//                     child: user['photoUrl'] == null
//                         ? Text(user['fullName']?[0] ?? '?')
//                         : null,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       user['fullName'] ?? 'No name',
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   if (MediaQuery.of(context).size.width > 600)
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.edit),
//                           onPressed: () => _startEditing(user, userId),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () => _deleteUser(userId),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//               if (MediaQuery.of(context).size.width <= 600)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton.icon(
//                         icon: const Icon(Icons.edit, size: 16),
//                         label: const Text('Edit'),
//                         onPressed: () => _startEditing(user, userId),
//                       ),
//                       const SizedBox(width: 8),
//                       TextButton.icon(
//                         icon: const Icon(Icons.delete, size: 16, color: Colors.red),
//                         label: const Text('Delete', style: TextStyle(color: Colors.red)),
//                         onPressed: () => _deleteUser(userId),
//                       ),
//                     ],
//                   ),
//                 ),
//               const Divider(),
//               Wrap(
//                 spacing: 16,
//                 runSpacing: 8,
//                 children: [
//                   if (user['email'] != null && user['email'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.email, size: 16),
//                       label: Text(user['email']),
//                     ),
//                   if (user['phone'] != null && user['phone'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.phone, size: 16),
//                       label: Text(user['phone']),
//                     ),
//                   if (user['address'] != null && user['address'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.location_on, size: 16),
//                       label: Text(user['address']),
//                     ),
//                   if (formattedDateOfBirth != null)
//                     Chip(
//                       avatar: const Icon(Icons.cake, size: 16),
//                       label: Text(formattedDateOfBirth),
//                     ),
//                   if (user['gender'] != null)
//                     Chip(
//                       avatar: const Icon(Icons.person, size: 16),
//                       label: Text(user['gender']),
//                     ),
//                 ],
//               ),
//               if (createdAt != null || updatedAt != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Wrap(
//                     spacing: 8,
//                     runSpacing: 4,
//                     children: [
//                       if (createdAt != null)
//                         Text(
//                           'Registered: ${DateFormat('MMM d, y').format(createdAt)}',
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                       if (updatedAt != null)
//                         Text(
//                           'Updated: ${DateFormat('MMM d, y').format(updatedAt)}',
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
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
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   if (constraints.maxWidth > 600) {
//                     return Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _searchController,
//                             onChanged: (value) => setState(() => _searchQuery = value),
//                             decoration: const InputDecoration(
//                               hintText: 'Search user...',
//                               prefixIcon: Icon(Icons.search),
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         ElevatedButton.icon(
//                           onPressed: _startAdding,
//                           icon: const Icon(Icons.add),
//                           label: const Text('Add User'),
//                         ),
//                       ],
//                     );
//                   } else {
//                     return Column(
//                       children: [
//                         TextField(
//                           controller: _searchController,
//                           onChanged: (value) => setState(() => _searchQuery = value),
//                           decoration: const InputDecoration(
//                             hintText: 'Search user...',
//                             prefixIcon: Icon(Icons.search),
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton.icon(
//                             onPressed: _startAdding,
//                             icon: const Icon(Icons.add),
//                             label: const Text('Add User'),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//                 },
//               ),
//             ),

//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']
//                             ?.toString()
//                             .toLowerCase()
//                             .contains(_searchQuery.toLowerCase()) ??
//                         false;
//                   }).toList();

//                   return ListView.builder(
//                     itemCount: (_editingUserId != null || _isAdding) ? filtered.length + 1 : filtered.length,
//                     itemBuilder: (context, index) {
//                       if (index == 0 && (_editingUserId != null || _isAdding)) {
//                         return Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Column(
//                                 children: [
//                                   TextField(
//                                     controller: _fullNameController,
//                                     decoration: const InputDecoration(labelText: 'Full Name*'),
//                                   ),
//                                   TextField(
//                                     controller: _emailController,
//                                     decoration: const InputDecoration(labelText: 'Email*'),
//                                     keyboardType: TextInputType.emailAddress,
//                                   ),
//                                   TextField(
//                                     controller: _phoneController,
//                                     decoration: const InputDecoration(labelText: 'Phone*'),
//                                     keyboardType: TextInputType.phone,
//                                   ),
//                                   TextField(
//                                     controller: _addressController,
//                                     decoration: const InputDecoration(labelText: 'Address*'),
//                                   ),
//                                   TextFormField(
//                                     controller: _dateOfBirthController,
//                                     decoration: const InputDecoration(
//                                       labelText: 'Date of Birth*',
//                                       suffixIcon: Icon(Icons.calendar_today),
//                                     ),
//                                     readOnly: true,
//                                     onTap: () async {
//                                       FocusScope.of(context).requestFocus(FocusNode());
//                                       final DateTime? picked = await showDatePicker(
//                                         context: context,
//                                         initialDate: DateTime.now(),
//                                         firstDate: DateTime(1900),
//                                         lastDate: DateTime.now(),
//                                         initialEntryMode: DatePickerEntryMode.calendarOnly,
//                                         initialDatePickerMode: DatePickerMode.year,
//                                         builder: (context, child) {
//                                           return Theme(
//                                             data: Theme.of(context).copyWith(
//                                               colorScheme: ColorScheme.light(
//                                                 primary: Colors.blue,
//                                                 onPrimary: Colors.white,
//                                                 onSurface: Colors.black,
//                                               ),
//                                               textButtonTheme: TextButtonThemeData(
//                                                 style: TextButton.styleFrom(
//                                                   foregroundColor: Colors.blue,
//                                                 ),
//                                               ),
//                                             ),
//                                             child: child!,
//                                           );
//                                         },
//                                       );
                                      
//                                       if (picked != null) {
//                                         setState(() {
//                                           _dateOfBirthController.text = 
//                                             DateFormat('yyyy-MM-dd').format(picked);
//                                         });
//                                       }
//                                     },
//                                   ),
//                                   DropdownButtonFormField<String>(
//                                     value: _selectedGender,
//                                     decoration: const InputDecoration(labelText: 'Gender*'),
//                                     items: _genderOptions
//                                         .map((gender) => DropdownMenuItem(
//                                               value: gender,
//                                               child: Text(gender),
//                                             ))
//                                         .toList(),
//                                     onChanged: (val) => setState(() => _selectedGender = val),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       TextButton(
//                                         onPressed: _cancelEditing,
//                                         child: const Text('Cancel'),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       ElevatedButton(
//                                         onPressed: _saveUser,
//                                         child: const Text('Save'),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }

//                       final docIndex = (_editingUserId != null || _isAdding) ? index - 1 : index;
//                       final doc = filtered[docIndex];
//                       return _buildUserCard(doc.data() as Map<String, dynamic>, doc.id);
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

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['Male', 'Female'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
//       _dateOfBirthController.text = userData['dateOfBirth'].toString() ?? '';
//       _selectedGender = userData['gender']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': int.tryParse(_dateOfBirthController.text) ?? 0,
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
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
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserCard(Map<String, dynamic> user, String userId) {
//     final createdAt = user['createdAt']?.toDate();
//     final updatedAt = user['updatedAt']?.toDate();

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       child: InkWell(
//         onTap: () => _startEditing(user, userId),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 24,
//                     backgroundImage: user['photoUrl'] != null
//                         ? NetworkImage(user['photoUrl'])
//                         : null,
//                     child: user['photoUrl'] == null
//                         ? Text(user['fullName']?[0] ?? '?')
//                         : null,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       user['fullName'] ?? 'No name',
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   if (MediaQuery.of(context).size.width > 600) // Show buttons directly on larger screens
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.edit),
//                           onPressed: () => _startEditing(user, userId),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () => _deleteUser(userId),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//               if (MediaQuery.of(context).size.width <= 600) // Show buttons in a row on small screens
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton.icon(
//                         icon: const Icon(Icons.edit, size: 16),
//                         label: const Text('Edit'),
//                         onPressed: () => _startEditing(user, userId),
//                       ),
//                       const SizedBox(width: 8),
//                       TextButton.icon(
//                         icon: const Icon(Icons.delete, size: 16, color: Colors.red),
//                         label: const Text('Delete', style: TextStyle(color: Colors.red)),
//                         onPressed: () => _deleteUser(userId),
//                       ),
//                     ],
//                   ),
//                 ),
//               const Divider(),
//               Wrap(
//                 spacing: 16,
//                 runSpacing: 8,
//                 children: [
//                   if (user['email'] != null && user['email'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.email, size: 16),
//                       label: Text(user['email']),
//                     ),
//                   if (user['phone'] != null && user['phone'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.phone, size: 16),
//                       label: Text(user['phone']),
//                     ),
//                   if (user['address'] != null && user['address'].isNotEmpty)
//                     Chip(
//                       avatar: const Icon(Icons.location_on, size: 16),
//                       label: Text(user['address']),
//                     ),
//                   if (user['dateOfBirth'] != null)
//                     Chip(
//                       avatar: const Icon(Icons.cake, size: 16),
//                       label: Text(user['dateOfBirth'].toString()),
//                     ),
//                   if (user['gender'] != null)
//                     Chip(
//                       avatar: const Icon(Icons.person, size: 16),
//                       label: Text(user['gender']),
//                     ),
//                 ],
//               ),
//               if (createdAt != null || updatedAt != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Wrap(
//                     spacing: 8,
//                     runSpacing: 4,
//                     children: [
//                       if (createdAt != null)
//                         Text(
//                           'Registered: ${DateFormat('MMM d, y').format(createdAt)}',
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                       if (updatedAt != null)
//                         Text(
//                           'Updated: ${DateFormat('MMM d, y').format(updatedAt)}',
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
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
//             // Responsive top bar
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   if (constraints.maxWidth > 600) {
//                     // Wide layout
//                     return Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _searchController,
//                             onChanged: (value) => setState(() => _searchQuery = value),
//                             decoration: const InputDecoration(
//                               hintText: 'Search user...',
//                               prefixIcon: Icon(Icons.search),
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         ElevatedButton.icon(
//                           onPressed: _startAdding,
//                           icon: const Icon(Icons.add),
//                           label: const Text('Add User'),
//                         ),
//                       ],
//                     );
//                   } else {
//                     // Narrow layout
//                     return Column(
//                       children: [
//                         TextField(
//                           controller: _searchController,
//                           onChanged: (value) => setState(() => _searchQuery = value),
//                           decoration: const InputDecoration(
//                             hintText: 'Search user...',
//                             prefixIcon: Icon(Icons.search),
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton.icon(
//                             onPressed: _startAdding,
//                             icon: const Icon(Icons.add),
//                             label: const Text('Add User'),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//                 },
//               ),
//             ),

//             // Main content
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']
//                             ?.toString()
//                             .toLowerCase()
//                             .contains(_searchQuery.toLowerCase()) ??
//                         false;
//                   }).toList();

//                   return ListView.builder(
//                     itemCount: (_editingUserId != null || _isAdding) ? filtered.length + 1 : filtered.length,
//                     itemBuilder: (context, index) {
//                       if (index == 0 && (_editingUserId != null || _isAdding)) {
//                         return Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Column(
//                                 children: [
//                                   TextField(
//                                     controller: _fullNameController,
//                                     decoration: const InputDecoration(labelText: 'Full Name*'),
//                                   ),
//                                   TextField(
//                                     controller: _emailController,
//                                     decoration: const InputDecoration(labelText: 'Email*'),
//                                     keyboardType: TextInputType.emailAddress,
//                                   ),
//                                   TextField(
//                                     controller: _phoneController,
//                                     decoration: const InputDecoration(labelText: 'Phone*'),
//                                     keyboardType: TextInputType.phone,
//                                   ),
//                                   TextField(
//                                     controller: _addressController,
//                                     decoration: const InputDecoration(labelText: 'Address*'),
//                                   ),
//                                         TextFormField(
//                 controller: datebirthController,
//                 decoration: _inputDecoration("Date of Birth", Icons.calendar_today),
//                 readOnly: true,
//                 onTap: () async {
//                 FocusScope.of(context).requestFocus(FocusNode());


//                final DateTime? picked = await showDatePicker(
//                 context: context,
//                initialDate: DateTime.now(),
//                 firstDate: DateTime(1900),
//                lastDate: DateTime.now(),
//                initialEntryMode: DatePickerEntryMode.calendarOnly, // Opens calendar view first
//               initialDatePickerMode: DatePickerMode.year, // Starts with year selection
//               builder: (context, child) {
//               return Theme(
//              data: Theme.of(context).copyWith(
//               colorScheme: ColorScheme.light(
//               primary: Colors.blue,
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.blue,
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
    
//     if (picked != null) {
//       String formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
//       datebirthController.text = formattedDate;
//     }
//   },
//   validator: (value) {
//     if (value == null || value.trim().isEmpty) {
//       return "Please enter your date of birth";
//     }
//     if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
//       return "Enter a valid date (YYYY-MM-DD)";
//     }
//     return null;
//   },
// ),
//                                   DropdownButtonFormField<String>(
//                                     value: _selectedGender,
//                                     decoration: const InputDecoration(labelText: 'Gender*'),
//                                     items: _genderOptions
//                                         .map((gender) => DropdownMenuItem(
//                                               value: gender,
//                                               child: Text(gender[0].toUpperCase() + gender.substring(1)),
//                                             ))
//                                             Female or Male
//                                         .toList(),
//                                     onChanged: (val) => setState(() => _selectedGender = val),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       TextButton(
//                                         onPressed: _cancelEditing,
//                                         child: const Text('Cancel'),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       ElevatedButton(
//                                         onPressed: _saveUser,
//                                         child: const Text('Save'),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }

//                       final docIndex = (_editingUserId != null || _isAdding) ? index - 1 : index;
//                       final doc = filtered[docIndex];
//                       return _buildUserCard(doc.data() as Map<String, dynamic>, doc.id);
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

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['male', 'female'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
//       _dateOfBirthController.text = userData['dateOfBirth'].toString() ?? '';
//       _selectedGender = userData['gender']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': int.tryParse(_dateOfBirthController.text) ?? 0,
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
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
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserCard(Map<String, dynamic> user, String userId) {
//     final createdAt = user['createdAt']?.toDate();
//     final updatedAt = user['updatedAt']?.toDate();

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
//                   backgroundImage: user['photoUrl'] != null
//                       ? NetworkImage(user['photoUrl'])
//                       : null,
//                   child: user['photoUrl'] == null
//                       ? Text(user['fullName']?[0] ?? '?')
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     user['fullName'] ?? 'No name',
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () => _startEditing(user, userId),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () => _deleteUser(userId),
//                 ),
//               ],
//             ),
//             const Divider(),
//             _buildInfoRow(Icons.email, user['email']),
//             _buildInfoRow(Icons.phone, user['phone']),
//             _buildInfoRow(Icons.location_on, user['address']),
//             _buildInfoRow(Icons.cake, user['dateOfBirth']?.toString()),
//             _buildInfoRow(Icons.person, user['gender']),
//             if (createdAt != null)
//               _buildInfoRow(
//                 Icons.calendar_today,
//                 'Registered: ${DateFormat('MMM d, y').format(createdAt)}',
//               ),
//             if (updatedAt != null)
//               _buildInfoRow(
//                 Icons.update,
//                 'Updated: ${DateFormat('MMM d, y').format(updatedAt)}',
//               ),
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
//                         hintText: 'Search user...',
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

//             // Main content
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']
//                             ?.toString()
//                             .toLowerCase()
//                             .contains(_searchQuery.toLowerCase()) ??
//                         false;
//                   }).toList();

//                   return ListView.builder(
//                     itemCount: (_editingUserId != null || _isAdding) ? filtered.length + 1 : filtered.length,
//                     itemBuilder: (context, index) {
//                       if (index == 0 && (_editingUserId != null || _isAdding)) {
//                         return Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Column(
//                                 children: [
//                                   TextField(
//                                     controller: _fullNameController,
//                                     decoration: const InputDecoration(labelText: 'Full Name'),
//                                   ),
//                                   TextField(
//                                     controller: _emailController,
//                                     decoration: const InputDecoration(labelText: 'Email'),
//                                   ),
//                                   TextField(
//                                     controller: _phoneController,
//                                     decoration: const InputDecoration(labelText: 'Phone'),
//                                   ),
//                                   TextField(
//                                     controller: _addressController,
//                                     decoration: const InputDecoration(labelText: 'Address'),
//                                   ),
//                                   TextField(
//                                     controller: _dateOfBirthController,
//                                     decoration: const InputDecoration(labelText: 'Date of Birth'),
//                                     keyboardType: TextInputType.number,
//                                   ),
//                                   DropdownButtonFormField<String>(
//                                     value: _selectedGender,
//                                     decoration: const InputDecoration(labelText: 'Gender'),
//                                     items: _genderOptions
//                                         .map((gender) => DropdownMenuItem(
//                                               value: gender,
//                                               child: Text(gender),
//                                             ))
//                                         .toList(),
//                                     onChanged: (val) => setState(() => _selectedGender = val),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       TextButton(
//                                         onPressed: _cancelEditing,
//                                         child: const Text('Cancel'),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       ElevatedButton(
//                                         onPressed: _saveUser,
//                                         child: const Text('Save'),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }

//                       final docIndex = (_editingUserId != null || _isAdding) ? index - 1 : index;
//                       final doc = filtered[docIndex];
//                       return _buildUserCard(doc.data() as Map<String, dynamic>, doc.id);
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

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['Male', 'Female'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
      
//       if (userData['dateOfBirth'] != null) {
//         if (userData['dateOfBirth'] is Timestamp) {
//           _dateOfBirthController.text = DateFormat('yyyy-MM-dd')
//               .format(userData['dateOfBirth'].toDate());
//         } else if (userData['dateOfBirth'] is String) {
//           _dateOfBirthController.text = userData['dateOfBirth'];
//         }
//       } else {
//         _dateOfBirthController.clear();
//       }
      
//       _selectedGender = userData['gender'];
//     });
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
//       });
//     }
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': _dateOfBirthController.text,
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Patient added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Patient updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this patient?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Patient deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting patient: $e')),
//         );
//       }
//     }
//   }

//   Widget _buildEditForm() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _isAdding ? 'Add New Patient' : 'Edit Patient',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _fullNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Full Name',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.person),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.email),
//               ),
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _phoneController,
//               decoration: const InputDecoration(
//                 labelText: 'Phone Number',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.phone),
//               ),
//               keyboardType: TextInputType.phone,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _addressController,
//               decoration: const InputDecoration(
//                 labelText: 'Address',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.location_on),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _dateOfBirthController,
//               decoration: const InputDecoration(
//                 labelText: 'Date of Birth',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.calendar_today),
//               ),
//               onTap: () => _selectDate(context),
//               readOnly: true,
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: _selectedGender,
//               decoration: const InputDecoration(
//                 labelText: 'Gender',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.person_outline),
//               ),
//               items: _genderOptions
//                   .map((gender) => DropdownMenuItem(
//                         value: gender,
//                         child: Text(gender),
//                       ))
//                   .toList(),
//               onChanged: (val) => setState(() => _selectedGender = val),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 OutlinedButton(
//                   onPressed: _cancelEditing,
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                   ),
//                   child: const Text('Cancel'),
//                 ),
//                 const SizedBox(width: 16),
//                 ElevatedButton(
//                   onPressed: _saveUser,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                   ),
//                   child: const Text('Save'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   DataRow _buildDataRow(Map<String, dynamic> user, String userId) {
//     return DataRow(
//       cells: [
//         DataCell(Text(user['fullName'] ?? 'N/A')),
//         DataCell(Text(user['email'] ?? 'N/A')),
//         DataCell(Text(user['phone'] ?? 'N/A')),
//         DataCell(
//           Chip(
//             label: Text(
//               user['gender']?.toString().toUpperCase() ?? 'N/A',
//               style: const TextStyle(fontSize: 12, color: Colors.white),
//             ),
//             backgroundColor: user['gender']?.toString().toLowerCase() == 'male' 
//                 ? Colors.blue 
//                 : Colors.pink,
//           ),
//         ),
//         DataCell(Text(user['dateOfBirth']?.toString() ?? 'N/A')),
//         DataCell(
//           Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.edit, color: Colors.blue),
//                 onPressed: () => _startEditing(user, userId),
//                 tooltip: 'Edit',
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red),
//                 onPressed: () => _deleteUser(userId),
//                 tooltip: 'Delete',
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient Management'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: _startAdding,
//             tooltip: 'Add New Patient',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//             child: TextField(
//               controller: _searchController,
//               onChanged: (value) => setState(() => _searchQuery = value),
//               decoration: InputDecoration(
//                 hintText: 'Search patients...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
          
//           if (_editingUserId != null || _isAdding) 
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: _buildEditForm(),
//             ),
          
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return _searchQuery.isEmpty ||
//                         data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
//                         data['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
//                         data['phone']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true;
//                   }).toList();

//                   if (filtered.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.search_off, size: 48, color: Colors.grey),
//                           const SizedBox(height: 16),
//                           Text(
//                             _searchQuery.isEmpty 
//                                 ? 'No patients found' 
//                                 : 'No matching patients found',
//                             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return Card(
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: DataTable(
//                           headingRowColor: MaterialStateProperty.resolveWith<Color>(
//                             (states) => Theme.of(context).primaryColor.withOpacity(0.1),
//                           ),
//                           columns: const [
//                             DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Date of Birth', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
//                           ],
//                           rows: filtered.map((doc) => _buildDataRow(
//                             doc.data() as Map<String, dynamic>, 
//                             doc.id,
//                           )).toList(),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['Male', 'Female'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
      
//       if (userData['dateOfBirth'] != null) {
//         if (userData['dateOfBirth'] is Timestamp) {
//           _dateOfBirthController.text = DateFormat('yyyy-MM-dd')
//               .format(userData['dateOfBirth'].toDate());
//         } else if (userData['dateOfBirth'] is String) {
//           _dateOfBirthController.text = userData['dateOfBirth'];
//         }
//       } else {
//         _dateOfBirthController.clear();
//       }
      
//       _selectedGender = userData['gender'];
//     });
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
//       });
//     }
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': _dateOfBirthController.text,
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
//         );
//       }
//     }
//   }

//   Widget _buildEditForm() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _isAdding ? 'Add New Patient' : 'Edit Patient',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _fullNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Full Name',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.person),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.email),
//               ),
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _phoneController,
//               decoration: const InputDecoration(
//                 labelText: 'Phone Number',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.phone),
//               ),
//               keyboardType: TextInputType.phone,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _addressController,
//               decoration: const InputDecoration(
//                 labelText: 'Address',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.location_on),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _dateOfBirthController,
//               decoration: const InputDecoration(
//                 labelText: 'Date of Birth',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.calendar_today),
//               ),
//               onTap: () => _selectDate(context),
//               readOnly: true,
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: _selectedGender,
//               decoration: const InputDecoration(
//                 labelText: 'Gender',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.person_outline),
//               ),
//               items: _genderOptions
//                   .map((gender) => DropdownMenuItem(
//                         value: gender,
//                         child: Text(gender),
//                       ))
//                   .toList(),
//               onChanged: (val) => setState(() => _selectedGender = val),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 OutlinedButton(
//                   onPressed: _cancelEditing,
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                   ),
//                   child: const Text('Cancel'),
//                 ),
//                 const SizedBox(width: 16),
//                 ElevatedButton(
//                   onPressed: _saveUser,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                   ),
//                   child: const Text('Save'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUserTableRow(Map<String, dynamic> user, String userId) {
//     return DataRow(
//       onSelectChanged: (selected) => _startEditing(user, userId),
//       cells: [
//         DataCell(
//           Text(
//             user['fullName'] ?? 'N/A',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//         ),
//         DataCell(Text(user['email'] ?? 'N/A')),
//         DataCell(Text(user['phone'] ?? 'N/A')),
//         DataCell(
//           Chip(
//             label: Text(
//               user['gender']?.toString().toUpperCase() ?? 'N/A',
//               style: const TextStyle(fontSize: 12, color: Colors.white),
//             ),
//             backgroundColor: user['gender']?.toString().toLowerCase() == 'male' 
//                 ? Colors.blue 
//                 : Colors.pink,
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           ),
//         ),
//         DataCell(Text(user['dateOfBirth']?.toString() ?? 'N/A')),
//         DataCell(
//           Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.edit, color: Colors.blue),
//                 onPressed: () => _startEditing(user, userId),
//                 tooltip: 'Edit',
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red),
//                 onPressed: () => _deleteUser(userId),
//                 tooltip: 'Delete',
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient Management'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: _startAdding,
//             tooltip: 'Add New Patient',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//             child: TextField(
//               controller: _searchController,
//               onChanged: (value) => setState(() => _searchQuery = value),
//               decoration: InputDecoration(
//                 hintText: 'Search patients...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
          
//           if (_editingUserId != null || _isAdding) 
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: _buildEditForm(),
//             ),
          
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return _searchQuery.isEmpty ||
//                         data['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
//                         data['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
//                         data['phone']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true;
//                   }).toList();

//                   if (filtered.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.search_off, size: 48, color: Colors.grey),
//                           const SizedBox(height: 16),
//                           Text(
//                             _searchQuery.isEmpty 
//                                 ? 'No patients found' 
//                                 : 'No matching patients found',
//                             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return Card(
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: DataTable(
//                           headingRowColor: MaterialStateProperty.resolveWith<Color>(
//                             (states) => Theme.of(context).primaryColor.withOpacity(0.1),
//                           ),
//                           columns: const [
//                             DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Date of Birth', style: TextStyle(fontWeight: FontWeight.bold))),
//                             DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
//                           ],
//                           rows: filtered.map((doc) => _buildUserTableRow(
//                             doc.data() as Map<String, dynamic>, 
//                             doc.id,
//                           )).toList(),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genderOptions = ['male', 'female'];

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
//       _dateOfBirthController.text = userData['dateOfBirth'].toString() ?? '';
//       _selectedGender = userData['gender']?.toLowerCase();
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': int.tryParse(_dateOfBirthController.text) ?? 0,
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
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
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserCard(Map<String, dynamic> user, String userId) {
//     final createdAt = user['createdAt']?.toDate();
//     final updatedAt = user['updatedAt']?.toDate();

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
//                   backgroundImage: user['photoUrl'] != null
//                       ? NetworkImage(user['photoUrl'])
//                       : null,
//                   child: user['photoUrl'] == null
//                       ? Text(user['fullName']?[0] ?? '?')
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     user['fullName'] ?? 'No name',
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () => _startEditing(user, userId),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () => _deleteUser(userId),
//                 ),
//               ],
//             ),
//             const Divider(),
//             _buildInfoRow(Icons.email, user['email']),
//             _buildInfoRow(Icons.phone, user['phone']),
//             _buildInfoRow(Icons.location_on, user['address']),
//             _buildInfoRow(Icons.cake, user['dateOfBirth']?.toString()),
//             _buildInfoRow(Icons.person, user['gender']),
//             if (createdAt != null)
//               _buildInfoRow(
//                 Icons.calendar_today,
//                 'Registered: ${DateFormat('MMM d, y').format(createdAt)}',
//               ),
//             if (updatedAt != null)
//               _buildInfoRow(
//                 Icons.update,
//                 'Updated: ${DateFormat('MMM d, y').format(updatedAt)}',
//               ),
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
//                         hintText: 'Search user...',
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

//             // Main content
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }

//                   final docs = snapshot.data!.docs;
//                   final filtered = docs.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return data['fullName']
//                             ?.toString()
//                             .toLowerCase()
//                             .contains(_searchQuery.toLowerCase()) ??
//                         false;
//                   }).toList();

//                   return ListView.builder(
//                     itemCount: (_editingUserId != null || _isAdding) ? filtered.length + 1 : filtered.length,
//                     itemBuilder: (context, index) {
//                       if (index == 0 && (_editingUserId != null || _isAdding)) {
//                         return Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Column(
//                                 children: [
//                                   TextField(
//                                     controller: _fullNameController,
//                                     decoration: const InputDecoration(labelText: 'Full Name'),
//                                   ),
//                                   TextField(
//                                     controller: _emailController,
//                                     decoration: const InputDecoration(labelText: 'Email'),
//                                   ),
//                                   TextField(
//                                     controller: _phoneController,
//                                     decoration: const InputDecoration(labelText: 'Phone'),
//                                   ),
//                                   TextField(
//                                     controller: _addressController,
//                                     decoration: const InputDecoration(labelText: 'Address'),
//                                   ),
//                                   TextField(
//                                     controller: _dateOfBirthController,
//                                     decoration: const InputDecoration(labelText: 'Date of Birth'),
//                                     keyboardType: TextInputType.number,
//                                   ),
//                                   DropdownButtonFormField<String>(
//                                     value: _selectedGender,
//                                     decoration: const InputDecoration(labelText: 'Gender'),
//                                     items: _genderOptions
//                                         .map((gender) => DropdownMenuItem(
//                                               value: gender,
//                                               child: Text(gender),
//                                             ))
//                                         .toList(),
//                                     onChanged: (val) => setState(() => _selectedGender = val),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       TextButton(
//                                         onPressed: _cancelEditing,
//                                         child: const Text('Cancel'),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       ElevatedButton(
//                                         onPressed: _saveUser,
//                                         child: const Text('Save'),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }

//                       final docIndex = (_editingUserId != null || _isAdding) ? index - 1 : index;
//                       final doc = filtered[docIndex];
//                       return _buildUserCard(doc.data() as Map<String, dynamic>, doc.id);
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

// class PatientScreen extends StatefulWidget {
//   const PatientScreen({super.key});

//   @override
//   State<PatientScreen> createState() => _PatientScreenState();
// }

// class _PatientScreenState extends State<PatientScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingUserId;
//   bool _isAdding = false;

//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _dateOfBirthController = TextEditingController();
//   String? _selectedGender;
 

//   final List<String> _genderOptions = ['male', 'female'];
 

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _dateOfBirthController.dispose();
//     super.dispose();
//   }

//   void _startAdding() {
//     setState(() {
//       _isAdding = true;
//       _editingUserId = null;
//       _fullNameController.clear();
//       _emailController.clear();
//       _phoneController.clear();
//       _addressController.clear();
//       _dateOfBirthController.clear();
//       _selectedGender = null;
//     });
//   }

//   void _startEditing(Map<String, dynamic> userData, String userId) {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = userId;
//       _fullNameController.text = userData['fullName'] ?? '';
//       _emailController.text = userData['email'] ?? '';
//       _phoneController.text = userData['phone'] ?? '';
//       _addressController.text = userData['address'] ?? '';
//       _dateOfBirthController.text = userData['dateOfBirth'].toString() ?? '';
//       _selectedGender = userData['gender']?.toLowerCase();
    
//     });
//   }

//   void _cancelEditing() {
//     setState(() {
//       _isAdding = false;
//       _editingUserId = null;
//     });
//   }

//   Future<void> _saveUser() async {
//     if (_fullNameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _dateOfBirthController.text.isEmpty ||
//         _selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     try {
//       final userData = {
//         'fullName': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'address': _addressController.text,
//         'dateOfBirth': int.tryParse(_dateOfBirthController.text) ?? 0,
//         'gender': _selectedGender,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (_isAdding) 'createdAt': FieldValue.serverTimestamp(),
//       };

//       if (_isAdding) {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('user added successfully')),
//         );
//       } else {
//         await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('user updated successfully')),
//         );
//       }

//       _cancelEditing();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _deleteUser(String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this user account?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(userId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User deleted successfully')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
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

//   Widget _buildDoctorRow(Map<String, dynamic> user, String userId) {
//     final createdAt = user['createdAt']?.toDate();
//     final updatedAt = user['updatedAt']?.toDate();

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
//                   backgroundImage: user['photoUrl'] != null
//                       ? NetworkImage(user['photoUrl'])
//                       : null,
//                   child: user['photoUrl'] == null
//                       ? Text(user['fullName']?[0] ?? '?')
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     user['fullName'] ?? 'No name',
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                 ),
//                 IconButton(icon: const Icon(Icons.edit), onPressed: () => _startEditing(user, userId)),
//                 IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(userId)),
//               ],
//             ),
//             const Divider(),
//             _buildInfoRow(Icons.medical_services, user['specialties']),
//             _buildInfoRow(Icons.email, user['email']),
//             _buildInfoRow(Icons.phone, user['phone']),
//             _buildInfoRow(Icons.location_on, user['address']),
//             _buildInfoRow(Icons.work,'${user['dateOfBirth']}'),
//             _buildInfoRow(Icons.person, user['gender']),
           
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
//                       hintText: 'Search user...',
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
//               stream: FirebaseFirestore.instance.collection('users').snapshots(),
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
//                       if (_editingUserId != null || _isAdding)
//                         Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Column(
//                             children: [
//                               TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name')),
//                               TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
//                               TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
//                               TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
//                               TextField(controller: _dateOfBirthController, decoration: const InputDecoration(labelText: 'dateOfBirth'), keyboardType: TextInputType.number),
//                               DropdownButtonFormField<String>(
//                                 value: _selectedGender,
//                                 decoration: const InputDecoration(labelText: 'Gender'),
//                                 items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
//                                 onChanged: (val) => setState(() => _selectedGender = val),
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   ElevatedButton(onPressed: _saveUser, child: const Text('Save')),
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
