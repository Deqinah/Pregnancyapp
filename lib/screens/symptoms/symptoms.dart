import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Symptoms extends StatefulWidget {
  const Symptoms({Key? key}) : super(key: key);

  @override
  _SymptomsState createState() => _SymptomsState();
}

class _SymptomsState extends State<Symptoms> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weekController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;
  List<DocumentSnapshot> _trackingWeeks = [];
  List<DocumentSnapshot> _savedSymptoms = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _approvedDoctors = [];
  String? _selectedDoctorId;
  List<String> selectedSymptoms = [];

  final Map<String, String> symptomMap = {
    'Madax Xanuun (Headache)': 'Madax Xanuun (Headache)',
    'Matag & Lalabo (Nausea & Vomiting)': 'Matag & Lalabo (Nausea & Vomiting)',
    'Calool Istaag (Constipation)': 'Calool Istaag (Constipation)',
    'Dhiig Bax (Vaginal bleeding)': 'Dhiig Bax (Vaginal bleeding)',
    'Cadaadis Dhiig Sare (Pre-eclampsia / Hypertension)': 'Cadaadis Dhiig Sare (Pre-eclampsia / Hypertension)',
    'Dhiig Yari (Anemia)': 'Dhiig Yari (Anemia)',
    'Luga Barar (Swelling / Edema)': 'Luga Barar (Swelling / Edema)',
    'Dhiig Fara Badan (Gestational Diabetes)': 'Dhiig Fara Badan (Gestational Diabetes)',
  };

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    if (_userId != null) {
      _fetchData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    try {
      final futures = <Future>[
        _fetchTrackingWeeks(),
        // _fetchApprovedDoctors(),
         _fetchUserDoctors(),
        _fetchSavedSymptoms(),
      ];
      await Future.wait(futures);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTrackingWeeks() async {
    try {
      final querySnapshot = await _firestore
          .collection('trackingweeks')
          .where('userId', isEqualTo: _userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final latestWeek = querySnapshot.docs.first;
        if (mounted) {
          setState(() {
            _trackingWeeks = querySnapshot.docs;
            _fullNameController.text = latestWeek.get('fullName') ?? '';
            _ageController.text = latestWeek.get('age')?.toString() ?? '';
            _weekController.text = latestWeek.get('currentWeek')?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tracking weeks: ${e.toString()}')),
        );
      }
    }
  }

  // Future<void> _fetchApprovedDoctors() async {
  //   try {
  //     final querySnapshot = await _firestore
  //         .collection('doctors')
  //         .where('status', isEqualTo: 'approved')
  //         .get();

  //     if (mounted) {
  //       setState(() {
  //         _approvedDoctors = querySnapshot.docs.map((doc) {
  //           return {
  //             'id': doc.id,
  //             'fullName': doc.get('fullName') ?? 'Unknown Doctor',
  //           };
  //         }).toList();
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error fetching doctors: ${e.toString()}')),
  //       );
  //     }
  //   }
  // }
  Future<void> _fetchUserDoctors() async {
  try {
    final user = _auth.currentUser;
    if (user == null) return;

    // Hel balamaha user-ka
    final appointmentsSnapshot = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .get();

    // Soo saar dhakhaatiirta ku jira balamaha
    final doctorIds = appointmentsSnapshot.docs
        .map((doc) => doc.get('doctorId') as String?)
        .where((id) => id != null)
        .toSet();

    if (doctorIds.isEmpty) {
      if (mounted) {
        setState(() {
          _approvedDoctors = [];
        });
      }
      return;
    }

    // Ka soo aqri xogta dhakhaatiirta
    final doctorsSnapshot = await _firestore
        .collection('doctors')
        .where(FieldPath.documentId, whereIn: doctorIds.toList())
        .get();

    if (mounted) {
      setState(() {
        _approvedDoctors = doctorsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'fullName': doc.get('fullName') ?? 'Unknown Doctor',
          };
        }).toList();
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user doctors: ${e.toString()}')),
      );
    }
  }
}


  Future<void> _fetchSavedSymptoms() async {
    try {
      final querySnapshot = await _firestore
          .collection('symptoms')
          .where('userId', isEqualTo: _userId)
          .get();

      if (mounted) {
        setState(() {
          _savedSymptoms = querySnapshot.docs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching symptoms: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure you want to send these symptoms to the doctor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      readOnly: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please complete your profile tracking first';
        }
        return null;
      },
    );
  }

  Widget _buildDoctorDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select Doctor',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: const Icon(Icons.medical_services),
      ),
      value: _selectedDoctorId,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select a doctor'),
        ),
        ..._approvedDoctors.map((doctor) {
          return DropdownMenuItem<String>(
            value: doctor['id'],
            child: Text(doctor['fullName']),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDoctorId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a doctor';
        }
        return null;
      },
    );
  }

 Widget _buildXanuunCheckboxList() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Select symptoms (max 4):',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Text(
        'Selected: ${selectedSymptoms.length}/4',
        style: TextStyle(
          color: selectedSymptoms.length >= 4 ? Colors.red : null,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 10),
      ...symptomMap.keys.map((symptom) {
        final isSelected = selectedSymptoms.contains(symptom);
        final canSelectMore = selectedSymptoms.length < 4;

        return CheckboxListTile(
          title: Text(
            symptom,
            style: TextStyle(
              color: !isSelected && !canSelectMore ? Colors.grey : null,
            ),
          ),
          value: isSelected,
          onChanged: (!isSelected && !canSelectMore)
              ? null // Disable if already 4 selected and this one is not selected
              : (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedSymptoms.add(symptom);
                    } else {
                      selectedSymptoms.remove(symptom);
                    }
                  });
                },
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    ],
  );
}


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
   
    if (_selectedDoctorId == null) {
      _showAlert('Error', 'Please select a doctor');
      return;
    }

    if (selectedSymptoms.isEmpty && _symptomsController.text.isEmpty) {
      _showAlert('Error', 'Please select symptoms or describe them');
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      String doctorName = 'Not selected';
      if (_selectedDoctorId != null) {
        final selectedDoc = _approvedDoctors.firstWhere(
          (doc) => doc['id'] == _selectedDoctorId,
          orElse: () => {'fullName': 'Unknown'},
        );
        doctorName = selectedDoc['fullName'];
      }

      await _firestore.collection('symptoms').add({
        'userId': _userId,
        'fullName': _fullNameController.text,
        'age': _ageController.text,
        'week': _weekController.text,
        'doctorName': doctorName,
        'selectedSymptoms': selectedSymptoms.map((s) => symptomMap[s]).toList(),
        'customSymptoms': _symptomsController.text.isEmpty ? null : _symptomsController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'assignedDoctorId': _selectedDoctorId,
      });

      // Clear form after submission
      _symptomsController.clear();
      setState(() {
        selectedSymptoms.clear();
      });
      
      await _fetchSavedSymptoms();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptoms saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving symptoms: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error saving symptoms: $e\n$stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
           leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
        title: const Text('Pregnancy Symptoms'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Track Pregnancy Symptoms',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
                    const SizedBox(height: 20),
                    _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
                    const SizedBox(height: 20),
                    _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
                    const SizedBox(height: 20),
                    _buildDoctorDropdown(),
                    const SizedBox(height: 20),
                    _buildXanuunCheckboxList(),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _symptomsController,
                      decoration: InputDecoration(
                        labelText: 'Other Symptoms (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.health_and_safety),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (selectedSymptoms.isEmpty && (value == null || value.isEmpty)) {
                          return 'Please either select symptoms above or describe them here';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Submit Symptoms',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _weekController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }
}

























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _approvedDoctors = [];
//   String? _selectedDoctorId;
//   List<String> selectedSymptoms = [];

//   final Map<String, String> symptomMap = {
//     'Madax Xanuun (Headache)': 'Madax Xanuun (Headache)',
//     'Matag & Lalabo (Nausea & Vomiting)': 'Matag & Lalabo (Nausea & Vomiting)',
//     'Calool Istaag (Constipation)': 'Calool Istaag (Constipation)',
//     'Dhiig Bax (Vaginal bleeding)': 'Dhiig Bax (Vaginal bleeding)',
//     'Cadaadis Dhiig Sare (Pre-eclampsia / Hypertension)': 'Cadaadis Dhiig Sare (Pre-eclampsia / Hypertension)',
//     'Dhiig Yari (Anemia)': 'Dhiig Yari (Anemia)',
//     'Luga Barar (Swelling / Edema)': 'Luga Barar (Swelling / Edema)',
//     'Dhiig Fara Badan (Gestational Diabetes)': 'Dhiig Fara Badan (Gestational Diabetes)',
//   };

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       final futures = <Future>[
//         _fetchTrackingWeeks(),
//         _fetchApprovedDoctors(),
//         _fetchSavedSymptoms(),
//       ];
//       await Future.wait(futures);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching data: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: _userId)
//           .limit(1)
//           .get();

//       if (querySnapshot.docs.isNotEmpty) {
//         final latestWeek = querySnapshot.docs.first;
//         if (mounted) {
//           setState(() {
//             _trackingWeeks = querySnapshot.docs;
//             _fullNameController.text = latestWeek.get('fullName') ?? '';
//             _ageController.text = latestWeek.get('age')?.toString() ?? '';
//             _weekController.text = latestWeek.get('currentWeek')?.toString() ?? '';
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching tracking weeks: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchApprovedDoctors() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('doctors')
//           .where('status', isEqualTo: 'approved')
//           .get();

//       if (mounted) {
//         setState(() {
//           _approvedDoctors = querySnapshot.docs.map((doc) {
//             return {
//               'id': doc.id,
//               'fullName': doc.get('fullName') ?? 'Unknown Doctor',
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching doctors: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('symptoms')
//           .where('userId', isEqualTo: _userId)
//           .get();

//       if (mounted) {
//         setState(() {
//           _savedSymptoms = querySnapshot.docs;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching symptoms: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<bool> _checkDoctorAvailability(String doctorId) async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: doctorId)
//           .where('status', whereIn: ['pending', 'confirmed'])
//           .limit(1)
//           .get();

//       return querySnapshot.docs.isEmpty;
//     } catch (e) {
//       debugPrint('Error checking doctor availability: $e');
//       return false;
//     }
//   }

//   Future<bool> _showConfirmationDialog() async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Submission'),
//         content: const Text('Are you sure you want to send these symptoms to the doctor?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     ) ?? false;
//   }

//   void _showAlert(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please complete your profile tracking first';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildDoctorDropdown() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore.collection('appointments')
//           .where('status', whereIn: ['pending', 'confirmed', 'cancelled'])
//           .snapshots(),
//       builder: (context, appointmentsSnapshot) {
//         if (appointmentsSnapshot.hasError) {
//           return Center(child: Text('Error loading appointments: ${appointmentsSnapshot.error}'));
//         }

//         // Get list of doctor IDs with pending/confirmed appointments
//         final busyDoctorIds = appointmentsSnapshot.hasData
//             ? appointmentsSnapshot.data!.docs
//                 .map((doc) => doc['doctorId'] as String?)
//                 .where((id) => id != null)
//                 .toSet()
//             : <String>{};

//         // Filter current user to exclude those with pending/confirmed appointments
//         final availableDoctors = _approvedDoctors
//             .where((doctor) => !busyDoctorIds.contains(doctor['id']))
//             .toList();

//         return DropdownButtonFormField<String>(
//           decoration: InputDecoration(
//             labelText: 'Select Doctor',
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             prefixIcon: const Icon(Icons.medical_services),
//           ),
//           value: _selectedDoctorId,
//           items: [
//             const DropdownMenuItem<String>(
//               value: null,
//               child: Text('Select a doctor'),
//             ),
//             ...availableDoctors.map((doctor) {
//               return DropdownMenuItem<String>(
//                 value: doctor['id'],
//                 child: Text(doctor['fullName']),
//               );
//             }),
//           ],
//           onChanged: (value) {
//             setState(() {
//               _selectedDoctorId = value;
//             });
//           },
//           validator: (value) {
//             if (value == null) {
//               return 'Please select a doctor';
//             }
//             return null;
//           },
//         );
//       },
//     );
//   }

//   Widget _buildXanuunCheckboxList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Select symptoms (max 3):',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           'Selected: ${selectedSymptoms.length}/3',
//           style: TextStyle(
//             color: selectedSymptoms.length >= 3 ? Colors.red : null,
//             fontStyle: FontStyle.italic,
//           ),
//         ),
//         const SizedBox(height: 10),
//         ...symptomMap.keys.map((symptom) {
//           return CheckboxListTile(
//             title: Text(symptom),
//             value: selectedSymptoms.contains(symptom),
//             onChanged: (bool? value) {
//               setState(() {
//                 if (value == true) {
//                   if (selectedSymptoms.length < 3) {
//                     selectedSymptoms.add(symptom);
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("You can select maximum 3 symptoms"),
//                         duration: Duration(seconds: 2),
//                       ),
//                     );
//                   }
//                 } else {
//                   selectedSymptoms.remove(symptom);
//                 }
//               });
//             },
//           );
//         }).toList(),
//       ],
//     );
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
   
//     if (_selectedDoctorId == null) {
//       _showAlert('Error', 'Please select a doctor');
//       return;
//     }

//     if (selectedSymptoms.isEmpty && _symptomsController.text.isEmpty) {
//       _showAlert('Error', 'Please select symptoms or describe them');
//       return;
//     }

//     // Check if doctor is available
//     final isAvailable = await _checkDoctorAvailability(_selectedDoctorId!);
//     if (!isAvailable) {
//       if (mounted) {
//         await showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Doctor Not Available'),
//             content: const Text('The selected doctor already has an appointment. Please select another doctor.'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   Navigator.of(context).pop(); // Navigate back
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         );
//       }
//       return;
//     }

//     final confirmed = await _showConfirmationDialog();
//     if (!confirmed) {
//       return;
//     }

//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       String doctorName = 'Not selected';
//       if (_selectedDoctorId != null) {
//         final selectedDoc = _approvedDoctors.firstWhere(
//           (doc) => doc['id'] == _selectedDoctorId,
//           orElse: () => {'fullName': 'Unknown'},
//         );
//         doctorName = selectedDoc['fullName'];
//       }

//       await _firestore.collection('symptoms').add({
//         'userId': _userId,
//         'fullName': _fullNameController.text,
//         'age': _ageController.text,
//         'week': _weekController.text,
//         'doctorName': doctorName,
//         'selectedSymptoms': selectedSymptoms.map((s) => symptomMap[s]).toList(),
//         'customSymptoms': _symptomsController.text.isEmpty ? null : _symptomsController.text,
//         'createdAt': FieldValue.serverTimestamp(),
//         'status': 'pending',
//         'assignedDoctorId': _selectedDoctorId,
//       });

//       // Clear form after submission
//       _symptomsController.clear();
//       setState(() {
//         selectedSymptoms.clear();
//       });
      
//       await _fetchSavedSymptoms();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Symptoms saved successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error saving symptoms: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       debugPrint('Error saving symptoms: $e\n$stackTrace');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Symptoms'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const SizedBox(height: 20),
//                     const Text(
//                       'Track Pregnancy Symptoms',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 30),
//                     _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                     const SizedBox(height: 20),
//                     _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                     const SizedBox(height: 20),
//                     _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                     const SizedBox(height: 20),
//                     _buildDoctorDropdown(),
//                     const SizedBox(height: 20),
//                     _buildXanuunCheckboxList(),
//                     const SizedBox(height: 20),
//                     TextFormField(
//                       controller: _symptomsController,
//                       decoration: InputDecoration(
//                         labelText: 'Other Symptoms (optional)',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         prefixIcon: const Icon(Icons.health_and_safety),
//                       ),
//                       maxLines: 3,
//                       validator: (value) {
//                         if (selectedSymptoms.isEmpty && (value == null || value.isEmpty)) {
//                           return 'Please either select symptoms above or describe them here';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 30),
//                     ElevatedButton(
//                       onPressed: _submitForm,
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Submit Symptoms',
//                         style: TextStyle(fontSize: 18),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _ageController.dispose();
//     _weekController.dispose();
//     _symptomsController.dispose();
//     super.dispose();
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _approvedDoctors = [];
//   String? _selectedDoctorId;
//   List<String> selectedSymptoms = [];

//   final Map<String, String> symptomMap = {
//     'Madax Xanuun (Headache)': 'Madax Xanuun (Headache)',
//     'Matag & Lalabo (Nausea & Vomiting)': 'Matag & Lalabo (Nausea & Vomiting)',
//     'Calool Istaag (Constipation)': 'Calool Istaag (Constipation)',
//     'Dhiig Bax (Vaginal bleeding)': 'Dhiig Bax (Vaginal bleeding)',
//     'Cadaadis Dhiig Sare (Pre-eclampsia / Hypertension)': 'Cadaadis Dhiig Sare (Pre-eclampsia / Hypertension)',
//     'Dhiig Yari (Anemia)': 'Dhiig Yari (Anemia)',
//     'Luga Barar (Swelling / Edema)': 'Luga Barar (Swelling / Edema)',
//     'Dhiig Fara Badan (Gestational Diabetes)': 'Dhiig Fara Badan (Gestational Diabetes)',
//   };

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       final futures = <Future>[
//         _fetchTrackingWeeks(),
//         _fetchApprovedDoctors(),
//         _fetchSavedSymptoms(),
//       ];
//       await Future.wait(futures);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching data: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: _userId)
//           .limit(1)
//           .get();

//       if (querySnapshot.docs.isNotEmpty) {
//         final latestWeek = querySnapshot.docs.first;
//         if (mounted) {
//           setState(() {
//             _trackingWeeks = querySnapshot.docs;
//             _fullNameController.text = latestWeek.get('fullName') ?? '';
//             _ageController.text = latestWeek.get('age')?.toString() ?? '';
//             _weekController.text = latestWeek.get('currentWeek')?.toString() ?? '';
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching tracking weeks: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchApprovedDoctors() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('doctors')
//           .where('status', isEqualTo: 'approved')
//           .get();

//       if (mounted) {
//         setState(() {
//           _approvedDoctors = querySnapshot.docs.map((doc) {
//             return {
//               'id': doc.id,
//               'fullName': doc.get('fullName') ?? 'Unknown Doctor',
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching doctors: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('symptoms')
//           .where('userId', isEqualTo: _userId)
//           .get();

//       if (mounted) {
//         setState(() {
//           _savedSymptoms = querySnapshot.docs;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching symptoms: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<bool> _showConfirmationDialog() async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Submission'),
//         content: const Text('Are you sure you want to send these symptoms to the doctor?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     ) ?? false;
//   }

//   void _showAlert(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please complete your profile tracking first';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildDoctorDropdown() {
//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: 'Select Doctor',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.medical_services),
//       ),
//       value: _selectedDoctorId,
//       items: [
//         const DropdownMenuItem<String>(
//           value: null,
//           child: Text('Select a doctor'),
//         ),
//         ..._approvedDoctors.map((doctor) {
//           return DropdownMenuItem<String>(
//             value: doctor['id'],
//             child: Text(doctor['fullName']),
//           );
//         }),
//       ],
//       onChanged: (value) {
//         setState(() {
//           _selectedDoctorId = value;
//         });
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a doctor';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildXanuunCheckboxList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Select symptoms (max 3):',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           'Selected: ${selectedSymptoms.length}/3',
//           style: TextStyle(
//             color: selectedSymptoms.length >= 3 ? Colors.red : null,
//             fontStyle: FontStyle.italic,
//           ),
//         ),
//         const SizedBox(height: 10),
//         ...symptomMap.keys.map((symptom) {
//           return CheckboxListTile(
//             title: Text(symptom),
//             value: selectedSymptoms.contains(symptom),
//             onChanged: (bool? value) {
//               setState(() {
//                 if (value == true) {
//                   if (selectedSymptoms.length < 3) {
//                     selectedSymptoms.add(symptom);
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("You can select maximum 3 symptoms"),
//                         duration: Duration(seconds: 2),
//                       ),
//                     );
//                   }
//                 } else {
//                   selectedSymptoms.remove(symptom);
//                 }
//               });
//             },
//           );
//         }).toList(),
//       ],
//     );
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
   
//     if (_selectedDoctorId == null) {
//       _showAlert('Error', 'Please select a doctor');
//       return;
//     }

//     if (selectedSymptoms.isEmpty && _symptomsController.text.isEmpty) {
//       _showAlert('Error', 'Please select symptoms or describe them');
//       return;
//     }

//     final confirmed = await _showConfirmationDialog();
//     if (!confirmed) {
//       return;
//     }

//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       String doctorName = 'Not selected';
//       if (_selectedDoctorId != null) {
//         final selectedDoc = _approvedDoctors.firstWhere(
//           (doc) => doc['id'] == _selectedDoctorId,
//           orElse: () => {'fullName': 'Unknown'},
//         );
//         doctorName = selectedDoc['fullName'];
//       }

//       await _firestore.collection('symptoms').add({
//         'userId': _userId,
//         'fullName': _fullNameController.text,
//         'age': _ageController.text,
//         'week': _weekController.text,
//         'doctorName': doctorName,
//         'selectedSymptoms': selectedSymptoms.map((s) => symptomMap[s]).toList(),
//         'customSymptoms': _symptomsController.text.isEmpty ? null : _symptomsController.text,
//         'createdAt': FieldValue.serverTimestamp(),
//         'status': 'pending',
//         'assignedDoctorId': _selectedDoctorId,
//       });

//       // Clear form after submission
//       _symptomsController.clear();
//       setState(() {
//         selectedSymptoms.clear();
//       });
      
//       await _fetchSavedSymptoms();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Symptoms saved successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error saving symptoms: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       debugPrint('Error saving symptoms: $e\n$stackTrace');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Symptoms'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const SizedBox(height: 20),
//                     const Text(
//                       'Track Pregnancy Symptoms',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 30),
//                     _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                     const SizedBox(height: 20),
//                     _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                     const SizedBox(height: 20),
//                     _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                     const SizedBox(height: 20),
//                     _buildDoctorDropdown(),
//                     const SizedBox(height: 20),
//                     _buildXanuunCheckboxList(),
//                     const SizedBox(height: 20),
//                     TextFormField(
//                       controller: _symptomsController,
//                       decoration: InputDecoration(
//                         labelText: 'Other Symptoms (optional)',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         prefixIcon: const Icon(Icons.health_and_safety),
//                       ),
//                       maxLines: 3,
//                       validator: (value) {
//                         if (selectedSymptoms.isEmpty && (value == null || value.isEmpty)) {
//                           return 'Please either select symptoms above or describe them here';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 30),
//                     ElevatedButton(
//                       onPressed: _submitForm,
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Submit Symptoms',
//                         style: TextStyle(fontSize: 18),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _ageController.dispose();
//     _weekController.dispose();
//     _symptomsController.dispose();
//     super.dispose();
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _selctedsymptomsController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();


//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _approvedDoctors = [];
//   String? _selectedDoctorId;
//   String? selectedSymptom;

//   final Map<String, String> selctedsymptomsController = {
//     'Madax Xanuun (Headache)': 'Headache',
//     'Matag & Lalabo (Nausea & Vomiting)': 'Nausea & Vomiting',
//     'Calool Istaag (Constipation)': 'Constipation',
//     'Dhiig Bax (Vaginal bleeding)': 'Vaginal bleeding',
//     'Cadaadis Dhiig Sare (Pre-eclampsia / Hypertension)': 'Pre-eclampsia / Hypertension',
//     'Dhiig Yari (Anemia)': 'Anemia',
//     'Luga Barar (Swelling / Edema)': 'Swelling / Edema',
//     'Dhiig Fara Badan (Gestational Diabetes)': 'Gestational Diabetes',
//   };

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       await Future.wait([
//         _fetchTrackingWeeks(),
//         _fetchApprovedDoctors(),
//         _fetchSavedSymptoms(),
//       ]);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching data: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: _userId)
//           .limit(1)
//           .get();

//       if (querySnapshot.docs.isNotEmpty) {
//         final latestWeek = querySnapshot.docs.first;
//         if (mounted) {
//           setState(() {
//             _trackingWeeks = querySnapshot.docs;
//             _fullNameController.text = latestWeek.get('fullName') ?? '';
//             _ageController.text = latestWeek.get('age')?.toString() ?? '';
//             _weekController.text = latestWeek.get('currentWeek')?.toString() ?? '';
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching tracking weeks: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchApprovedDoctors() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('doctors')
//           .where('status', isEqualTo: 'approved')
//           .get();

//       if (mounted) {
//         setState(() {
//           _approvedDoctors = querySnapshot.docs.map((doc) {
//             return {
//               'id': doc.id,
//               'fullName': doc.get('fullName') ?? 'Unknown Doctor',
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching doctors: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('symptoms')
//           .where('userId', isEqualTo: _userId)
//           .get();

//       if (mounted) {
//         setState(() {
//           _savedSymptoms = querySnapshot.docs;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching symptoms: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showDaawoDialog() {
//     if (selectedSymptom == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Fadlan dooro Calaamadaha aad dareymeyso')),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(selectedSymptom!),
//         content: Text(symptomMap[selectedSymptom] ?? 'No information available'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
   
//     if (_selectedDoctorId == null) {
//       _showAlert('Error', 'Please select a doctor');
//       return;
//     }

//     final confirmed = await _showConfirmationDialog();
//     if (!confirmed) {
//       return;
//     }

//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       String doctorName = 'Not selected';
//       if (_selectedDoctorId != null) {
//         final selectedDoc = _approvedDoctors.firstWhere(
//           (doc) => doc['id'] == _selectedDoctorId,
//           orElse: () => {'fullName': 'Unknown'},
//         );
//         doctorName = selectedDoc['fullName'];
//       }

//       await _firestore.collection('symptoms').add({
//         'userId': _userId,
//         'fullName': _fullNameController.text,
//         'age': _ageController.text,
//         'week': _weekController.text,
//         'doctorName': doctorName,
//         'xanuun': selectedSymptom,
//         'symptoms': _symptomsController.text,
//         'createdAt': FieldValue.serverTimestamp(),
//         'status': 'pending',
//         'assignedDoctorId': _selectedDoctorId,
//       });

//       _symptomsController.clear();
//       setState(() {
//         selectedSymptom = null;
//       });
//       await _fetchSavedSymptoms();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Symptoms saved successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error saving symptoms: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       debugPrint('Error saving symptoms: $e\n$stackTrace');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<bool> _showConfirmationDialog() async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Submission'),
//         content: const Text('Are you sure you want to send these symptoms to the doctor?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     ) ?? false;
//   }

//   void _showAlert(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Symptoms'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Track Pregnancy Symptoms',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 30),
//                         _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                         const SizedBox(height: 20),
//                         _buildDoctorDropdown(),
//                         const SizedBox(height: 20),
//                        _buildXanuunCheckboxList(),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _symptomsController,
//                           decoration: InputDecoration(
//                             labelText: 'Current Symptoms ',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.health_and_safety),
//                           ),
//                           maxLines: 2,
//                           enabled: selectedSymptom == null, // Disable if symptom is selected
//                           validator: (value) {
//                             if (selectedSymptom == null && (value == null || value.isEmpty)) {
//                               return 'Please either select a symptom above or describe your symptoms here';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _submitForm,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             'Save Symptoms',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//  List<String> selectedSymptoms = [];

// Widget _buildXanuunCheckboxList() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const Text(
//         'Select  symptoms:',
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 10),
//       ...selctedsymptomsController.keys.map((symptom) {
//         return CheckboxListTile(
//           title: Text(symptom),
//           value: selectedSymptoms.contains(symptom),
//           onChanged: (bool? value) {
//             setState(() {
//               if (value == true) {
//                 if (selectedSymptoms.length < 3) {
//                   selectedSymptoms.add(symptom);
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("You can select up to 3 symptoms only")),
//                   );
//                 }
//               } else {
//                 selectedSymptoms.remove(symptom);
//               }
//             });
//           },
//         );
//       }).toList(),
//     ],
//   );
// }

//   Widget _buildDoctorDropdown() {
//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: 'Select Doctor',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.medical_services),
//       ),
//       value: _selectedDoctorId,
//       items: [
//         const DropdownMenuItem<String>(
//           value: null,
//           child: Text('Select a doctor'),
//         ),
//         ..._approvedDoctors.map((doctor) {
//           return DropdownMenuItem<String>(
//             value: doctor['id'],
//             child: Text(doctor['fullName']),
//           );
//         }),
//       ],
//       onChanged: (value) {
//         setState(() {
//           _selectedDoctorId = value;
//         });
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a doctor';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please complete your profile tracking first';
//         }
//         return null;
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _ageController.dispose();
//     _weekController.dispose();
//     _selctedsymptomsController.dispose();
//     _symptomsController.dispose();
//     super.dispose();
//   }
// }







/////////////////////////////////////////////////////////////////////


  

    
 
 



//////////////////////////////////////////////////////////////////

















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _approvedDoctors = [];
//   String? _selectedDoctorId;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       _isLoading = false;
//     }
//   } 
  

//   Future<void> _fetchData() async {
//     try {
//       await Future.wait([
//         _fetchTrackingWeeks(),
//         _fetchApprovedDoctors(),
//       ]);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     final querySnapshot = await _firestore
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: _userId)
//         .get();

//     if (mounted) {
//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });
//     }

//     if (_trackingWeeks.isNotEmpty) {
//       final latestWeek = _trackingWeeks.first;
//       _fullNameController.text = latestWeek['fullName'] ?? '';
//       _ageController.text = latestWeek['age']?.toString() ?? '';
//       _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//     }
//   }

//   Future<void> _fetchApprovedDoctors() async {
//     final querySnapshot = await _firestore
//         .collection('doctors')
//         .where('status', isEqualTo: 'approved')
//         .get();

//     if (mounted) {
//       setState(() {
//         _approvedDoctors = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             'name': doc['fullName'] ?? 'Unknown Doctor',
//           };
//         }).toList();
//       });
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     final querySnapshot = await _firestore
//         .collection('symptoms')
//         .where('userId', isEqualTo: _userId)
//         .get();

//     if (mounted) {
//       setState(() {
//         _savedSymptoms = querySnapshot.docs;
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     if (_symptomsController.text.isEmpty) {
//       _showAlert('Error', 'Please enter your symptoms first');
//       return;
//     }

//     if (_selectedDoctorId == null) {
//       _showAlert('Error', 'Please select a doctor');
//       return;
//     }

//     final confirmed = await _showConfirmationDialog();
//     if (!confirmed) {
//       return;
//     }

//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       String doctorName = 'Not selected';
//       if (_selectedDoctorId != null) {
//         final selectedDoc = _approvedDoctors.firstWhere(
//           (doc) => doc['id'] == _selectedDoctorId,
//           orElse: () => {'name': 'Unknown'},
//         );
//         doctorName = selectedDoc['name'];
//       }

//       await _firestore.collection('symptoms').add({
//         'userId': _userId,
//         'fullName': _fullNameController.text,
//         'age': _ageController.text,
//         'week': _weekController.text,
//         'doctorName': doctorName,
//         'symptoms': _symptomsController.text,
//         'timestamp': FieldValue.serverTimestamp(),
//         'status':'pending',
//         'assignedDoctorId': _selectedDoctorId,
//       });

//       // Clear and refresh only after successful submission
//       _symptomsController.clear();
//       await _fetchSavedSymptoms();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Symptoms saved successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error saving symptoms: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       debugPrint('Error saving symptoms: $e\n$stackTrace');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<bool> _showConfirmationDialog() async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Submission'),
//         content: const Text('Are you sure you want to send these symptoms to the doctor?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     ) ?? false;
//   }

//   void _showAlert(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Track Pregnancy Symptoms',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 30),
//                         _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                         const SizedBox(height: 20),
//                         _buildDoctorDropdown(),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _symptomsController,
//                           decoration: InputDecoration(
//                             labelText: 'Current Symptoms',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.health_and_safety),
//                           ),
//                           maxLines: 2,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please describe your symptoms';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _submitForm,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             'Save Symptoms',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildDoctorDropdown() {
//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: 'Select Doctor',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.medical_services),
//       ),
//       value: _selectedDoctorId,
//       items: [
//         const DropdownMenuItem<String>(
//           value: null,
//           child: Text('Select a doctor'),
//         ),
//         ..._approvedDoctors.map((doctor) {
//           return DropdownMenuItem<String>(
//             value: doctor['id'],
//             child: Text(doctor['name']),
//           );
//         }),
//       ],
//       onChanged: (value) {
//         setState(() {
//           _selectedDoctorId = value;
//         });
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a doctor';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//     );
//   }
// }






































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _approvedDoctors = [];
//   String? _selectedDoctorId;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       _isLoading = false;
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       await Future.wait([
//         _fetchTrackingWeeks(),
//         _fetchApprovedDoctors(),
//       ]);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     final querySnapshot = await _firestore
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: _userId)
//         .get();

//     if (mounted) {
//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });
//     }

//     if (_trackingWeeks.isNotEmpty) {
//       final latestWeek = _trackingWeeks.first;
//       _fullNameController.text = latestWeek['fullName'] ?? '';
//       _ageController.text = latestWeek['age']?.toString() ?? '';
//       _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//     }
//   }

//   Future<void> _fetchApprovedDoctors() async {
//     final querySnapshot = await _firestore
//         .collection('doctors')
//         .where('status', isEqualTo: 'approved')
//         .get();

//     if (mounted) {
//       setState(() {
//         _approvedDoctors = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             'name': doc['fullName'] ?? 'Unknown Doctor',
//           };
//         }).toList();
//       });
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     final querySnapshot = await _firestore
//         .collection('symptoms')
//         .where('userId', isEqualTo: _userId)
//         .orderBy('timestamp', descending: true)
//         .get();

//     if (mounted) {
//       setState(() {
//         _savedSymptoms = querySnapshot.docs;
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//   if (!_formKey.currentState!.validate()) {
//     return;
//   }

//   if (_symptomsController.text.isEmpty) {
//     _showAlert('Error', 'Please enter your symptoms first');
//     return;
//   }

//   if (_selectedDoctorId == null) {
//     _showAlert('Error', 'Please select a doctor');
//     return;
//   }

//   final confirmed = await _showConfirmationDialog();
//  if (confirmed) {
//   _symptomsController.clear();
//   await _fetchSavedSymptoms();
//   if (mounted) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Symptoms saved successfully!'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
// }
//   try {
//     setState(() {
//       _isLoading = true;
//     });

//     String doctorName = 'Not selected';
//     if (_selectedDoctorId != null) {
//       final selectedDoc = _approvedDoctors.firstWhere(
//         (doc) => doc['id'] == _selectedDoctorId,
//         orElse: () => {'name': 'Unknown'},
//       );
//       doctorName = selectedDoc['name'];
//     }

//     await _firestore.collection('symptoms').add({
//       'userId': _userId,
//       'fullName': _fullNameController.text,
//       'age': _ageController.text,
//       'week': _weekController.text,
//       'doctorName': doctorName,
//       'symptoms': _symptomsController.text,
//       'timestamp': FieldValue.serverTimestamp(),
//     });

  
//     }
//   } catch (e, stackTrace) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error saving symptoms: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//     debugPrint('Error saving symptoms: $e\n$stackTrace');
//   } finally {
//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
// }
// Future<bool> _showConfirmationDialog() async {
//   return await showDialog<bool>(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: const Text('Confirm Submission'),
//       content: const Text('Are you sure you want to send these symptoms to the doctor?'),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(false),
//           child: const Text('Cancel'),
//         ),
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(true),
//           child: const Text('OK'),
//         ),
//       ],
//     ),
//   ) ?? false;
// }

//   void _showAlert(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Track Pregnancy Symptoms',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 30),
//                         _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                         const SizedBox(height: 20),
//                         _buildDoctorDropdown(),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _symptomsController,
//                           decoration: InputDecoration(
//                             labelText: 'Current Symptoms',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.health_and_safety),
//                           ),
//                           maxLines: 2,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please describe your symptoms';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _submitForm,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             'Save Symptoms',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildDoctorDropdown() {
//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: 'Select Doctor',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.medical_services),
//       ),
//       value: _selectedDoctorId,
//       items: [
//         const DropdownMenuItem<String>(
//           value: null,
//           child: Text('Select a doctor'),
//         ),
//         ..._approvedDoctors.map((doctor) {
//           return DropdownMenuItem<String>(
//             value: doctor['id'],
//             child: Text(doctor['name']),
//           );
//         }),
//       ],
//       onChanged: (value) {
//         setState(() {
//           _selectedDoctorId = value;
//         });
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a doctor';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//     );
//   }
// }








































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _approvedDoctors = [];
//   String? _selectedDoctorId;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       _isLoading = false;
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       await Future.wait([
//         _fetchTrackingWeeks(),
//         _fetchApprovedDoctors(),
//       ]);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     final querySnapshot = await _firestore
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: _userId)
//         .get();

//     if (mounted) {
//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });
//     }

//     if (_trackingWeeks.isNotEmpty) {
//       final latestWeek = _trackingWeeks.first;
//       _fullNameController.text = latestWeek['fullName'] ?? '';
//       _ageController.text = latestWeek['age']?.toString() ?? '';
//       _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//     }
//   }

//   Future<void> _fetchApprovedDoctors() async {
//     final querySnapshot = await _firestore
//         .collection('doctors')
//         .where('status', isEqualTo: 'approved')
//         .get();

//     if (mounted) {
//       setState(() {
//         _approvedDoctors = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             'name': doc['fullName'] ?? 'Unknown Doctor',
//           };
//         }).toList();
//       });
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     final querySnapshot = await _firestore
//         .collection('symptoms')
//         .where('userId', isEqualTo: _userId)
//         .orderBy('timestamp', descending: true)
//         .get();

//     if (mounted) {
//       setState(() {
//         _savedSymptoms = querySnapshot.docs;
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     // Check if symptoms field is empty
//     if (_symptomsController.text.isEmpty) {
//       _showAlert('Error', 'Please enter your symptoms first');
//       return;
//     }

    
//     if (_selectedDoctorId text.isEmpty) {
//       _showAlert('Error', 'Selected doctor');
      
//         return;
    
//     }

 

//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       // Get selected doctor name
//       String doctorName = 'Not selected';
//       if (_selectedDoctorId != null) {
//         final selectedDoc = _approvedDoctors.firstWhere(
//           (doc) => doc['id'] == _selectedDoctorId,
//           orElse: () => {'name': 'Unknown'},
//         );
//         doctorName = selectedDoc['name'];
//       }

//       await _firestore.collection('symptoms').add({
//         'userId': _userId,
//         'fullName': _fullNameController.text,
//         'age': _ageController.text,
//         'week': _weekController.text,
//         'doctorName': doctorName,
//         'symptoms': _symptomsController.text,
//         'timestamp': FieldValue.serverTimestamp(),
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Symptoms saved successfully!')),
//         );
//       }

//       _symptomsController.clear();
//       await _fetchSavedSymptoms();
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving symptoms: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

  
//   Future<bool> _showConfirmationDialog() async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Submission'),
//         content: const Text('Are you sure you want to send these symptoms to the doctor?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     ) ?? false;
//   }

//   void _showAlert(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Track Pregnancy Symptoms',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 30),
//                         _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                         const SizedBox(height: 20),
//                         _buildDoctorDropdown(),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _symptomsController,
//                           decoration: InputDecoration(
//                             labelText: 'Current Symptoms',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.health_and_safety),
//                           ),
//                           maxLines: 2,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please describe your symptoms';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _submitForm,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             'Save Symptoms',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildDoctorDropdown() {
//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: 'Select Doctor',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.medical_services),
//         error selected doctor
//       ),
//       value: _selectedDoctorId,
//       items: [
//         const DropdownMenuItem<String>(
//           value: null,
//           child: Text('Select a doctor'),
//         ),
//         ..._approvedDoctors.map((doctor) {
//           return DropdownMenuItem<String>(
//             value: doctor['id'],
//             child: Text(doctor['name']),
//           );
//         }),
//       ],
//       onChanged: (value) {
//         setState(() {
//           _selectedDoctorId = value;
//         });
//       },
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//     );
//   }
// }









































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _approvedDoctors = [];
//   String? _selectedDoctorId;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       _isLoading = false;
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       await Future.wait([
//         _fetchTrackingWeeks(),
//         _fetchSavedSymptoms(),
//         _fetchApprovedDoctors(),
//       ]);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     final querySnapshot = await _firestore
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: _userId)
//         .get();

//     if (mounted) {
//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });
//     }

//     if (_trackingWeeks.isNotEmpty) {
//       final latestWeek = _trackingWeeks.first;
//       _fullNameController.text = latestWeek['fullName'] ?? '';
//       _ageController.text = latestWeek['age']?.toString() ?? '';
//       _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//     }
//   }

//   Future<void> _fetchApprovedDoctors() async {
//     final querySnapshot = await _firestore
//         .collection('doctors')
//         .where('status', isEqualTo: 'approved')
//         .get();

//     if (mounted) {
//       setState(() {
//         _approvedDoctors = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             'name': doc['fullName'] ?? 'Unknown Doctor',
//           };
//         }).toList();
//       });
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     final querySnapshot = await _firestore
//         .collection('symptoms')
//         .where('userId', isEqualTo: _userId)
//         .orderBy('timestamp', descending: true)
//         .get();

//     if (mounted) {
//       setState(() {
//         _savedSymptoms = querySnapshot.docs;
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         setState(() {
//           _isLoading = true;
//         });

//         // Get selected doctor name
//         String doctorName = 'Not selected';
//         if (_selectedDoctorId != null) {
//           final selectedDoc = _approvedDoctors.firstWhere(
//             (doc) => doc['id'] == _selectedDoctorId,
//             orElse: () => {'name': 'Unknown'},
//           );
//           doctorName = selectedDoc['name'];
//         }

//         await _firestore.collection('symptoms').add({
//           'userId': _userId,
//           'fullName': _fullNameController.text,
//           'age': _ageController.text,
//           'week': _weekController.text,
//           'doctorName': doctorName,
//           'symptoms': _symptomsController.text,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Symptoms saved successfully!')),
//         );

//         _symptomsController.clear();
//         await _fetchSavedSymptoms();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving symptoms: $e')),
//         );
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Track Pregnancy Symptoms',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 30),
//                         _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                         const SizedBox(height: 20),
//                         _buildDoctorDropdown(),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _symptomsController,
//                           decoration: InputDecoration(
//                             labelText: 'Current Symptoms',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.health_and_safety),
//                           ),
//                           maxLines: 2,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please describe your symptoms';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _submitForm,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             'Save Symptoms',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildDoctorDropdown() {
//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: 'Select Doctor',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.medical_services),
//       ),
//       value: _selectedDoctorId,
//       items: _approvedDoctors.map((doctor) {
//         return DropdownMenuItem<String>(
//           value: doctor['id'],
//           child: Text(doctor['name']),
//         );
//       }).toList(),
//       onChanged: (value) {
//         setState(() {
//           _selectedDoctorId = value;
//         });
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a doctor';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//     );
//   }
// }

























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _approvedDoctors = [];
//   String? _selectedDoctorId;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       _isLoading = false;
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       await Future.wait([
//         _fetchTrackingWeeks(),
//         _fetchSavedSymptoms(),
//         _fetchApprovedDoctors(),
//       ]);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     final querySnapshot = await _firestore
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: _userId)
//         .get();

//     if (mounted) {
//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });
//     }

//     if (_trackingWeeks.isNotEmpty) {
//       final latestWeek = _trackingWeeks.first;
//       _fullNameController.text = latestWeek['fullName'] ?? '';
//       _ageController.text = latestWeek['age']?.toString() ?? '';
//       _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//     }
//   }

//   Future<void> _fetchApprovedDoctors() async {
//     final querySnapshot = await _firestore
//         .collection('doctors')
//         .where('status', isEqualTo: 'approved')
//         .get();

//     if (mounted) {
//       setState(() {
//         _approvedDoctors = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             'name': doc['fullName'] ?? 'Unknown Doctor',
//           };
//         }).toList();
//       });
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     final querySnapshot = await _firestore
//         .collection('symptoms')
//         .where('userId', isEqualTo: _userId)
//         .orderBy('timestamp', descending: true)
//         .get();

//     if (mounted) {
//       setState(() {
//         _savedSymptoms = querySnapshot.docs;
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         setState(() {
//           _isLoading = true;
//         });

//         // Get selected doctor name
//         String doctorName = 'Not selected';
//         if (_selectedDoctorId != null) {
//           final selectedDoc = _approvedDoctors.firstWhere(
//             (doc) => doc['id'] == _selectedDoctorId,
//             orElse: () => {'name': 'Unknown'},
//           );
//           doctorName = selectedDoc['name'];
//         }

//         await _firestore.collection('symptoms').add({
//           'userId': _userId,
//           'fullName': _fullNameController.text,
//           'age': _ageController.text,
//           'week': _weekController.text,
//           'doctorName': doctorName,
//           'symptoms': _symptomsController.text,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Symptoms saved successfully!')),
//         );

//         _symptomsController.clear();
//         await _fetchSavedSymptoms();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving symptoms: $e')),
//         );
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   Future<void> _deleteSymptom(String docId) async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       await _firestore.collection('symptoms').doc(docId).delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Symptom deleted successfully!')),
//       );
//       await _fetchSavedSymptoms();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting symptom: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Track Pregnancy Symptoms',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 30),
//                         _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                         const SizedBox(height: 20),
//                         _buildDoctorDropdown(),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _symptomsController,
//                           decoration: InputDecoration(
//                             labelText: 'Current Symptoms',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.health_and_safety),
//                           ),
//                           maxLines: 2,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please describe your symptoms';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _submitForm,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             'Save ',
//                             'please wait doctorka inuu dawooyinka kaga soo qorayo',
//                             navigated.pop(/home)
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 30),
                 
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildDoctorDropdown() {
//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: 'Select Doctor',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.medical_services),
//       ),
//       value: _selectedDoctorId,
//       items: _approvedDoctors.map((doctor) {
//         return DropdownMenuItem<String>(
//           value: doctor['id'],
//           child: Text(doctor['name']),
//         );
//       }).toList(),
//       onChanged: (value) {
//         setState(() {
//           _selectedDoctorId = value;
//         });
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a doctor';
//         }
//         return null;
//       },
//     );
//   }


//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//     );
//   }
// }































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       _isLoading = false;
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       await Future.wait([
//         _fetchTrackingWeeks(),
//         _fetchSavedSymptoms(),
//       ]);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     final querySnapshot = await _firestore
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: _userId)
//         .get();

//     if (mounted) {
//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });
//     }

//     if (_trackingWeeks.isNotEmpty) {
//       final latestWeek = _trackingWeeks.first;
//       _fullNameController.text = latestWeek['fullName'] ?? '';
//       _ageController.text = latestWeek['age']?.toString() ?? '';
//       _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//     }
//   }
//     final doc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(doctor.uid)
//           .get();
//           only read doctor status"approved"

//   Future<void> _fetchSavedSymptoms() async {
//     final querySnapshot = await _firestore
//         .collection('symptoms')
//         .where('userId', isEqualTo: _userId)
//         .orderBy('timestamp', descending: true)
//         .get();

//     if (mounted) {
//       setState(() {
//         _savedSymptoms = querySnapshot.docs;
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         setState(() {
//           _isLoading = true;
//         });

//         await _firestore.collection('symptoms').add({
//           'userId': _userId,
//           'fullName': _fullNameController.text,
//           'age': _ageController.text,
//           'week': _weekController.text,
//           'doctorName':........
//           'symptoms': _symptomsController.text,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Symptoms saved successfully!')),
//         );

//         _symptomsController.clear();
//         await _fetchSavedSymptoms();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving symptoms: $e')),
//         );
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   Future<void> _deleteSymptom(String docId) async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       await _firestore.collection('symptoms').doc(docId).delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Symptom deleted successfully!')),
//       );
//       await _fetchSavedSymptoms();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting symptom: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Track Pregnancy Symptoms',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 30),
//                         _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                         const SizedBox(height: 20),
//                         dropdown list selected doctor
//                         TextFormField(
//                           controller: _symptomsController,
//                           decoration: InputDecoration(
//                             labelText: 'Current Symptoms',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.health_and_safety),
//                           ),
//                           maxLines: 2,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please describe your symptoms';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _submitForm,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             'Save Current Symptoms',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   const Text(
//                     'Symptoms History',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   _buildSymptomsList(),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildSymptomsList() {
//     if (_savedSymptoms.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Text('No saved symptoms yet'),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: _savedSymptoms.length,
//       itemBuilder: (context, index) {
//         final symptom = _savedSymptoms[index];
//         final data = symptom.data() as Map<String, dynamic>;
//         final timestamp = data['timestamp']?.toDate();
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 8),
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       '${data['fullName'] ?? 'N/A'}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _deleteSymptom(symptom.id),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Text('Age: ${data['age'] ?? 'N/A'}'),
//                     const SizedBox(width: 16),
//                     Text('Week: ${data['week'] ?? 'N/A'}'),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(data['symptoms'] ?? ''),
//                 const SizedBox(height: 8),
//                 Text(
//                   timestamp != null
//                       ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)
//                       : 'No date',
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//     );
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     if (_userId != null) {
//       _fetchData();
//     } else {
//       _isLoading = false;
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       await Future.wait([
//         _fetchTrackingWeeks(),
//         _fetchSavedSymptoms(),
//       ]);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     final querySnapshot = await _firestore
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: _userId)
//         .get();

//     if (mounted) {
//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });
//     }

//     if (_trackingWeeks.isNotEmpty) {
//       final latestWeek = _trackingWeeks.first;
//       _fullNameController.text = latestWeek['fullName'] ?? '';
//       _ageController.text = latestWeek['age']?.toString() ?? '';
//       _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     final querySnapshot = await _firestore
//         .collection('symptoms')
//         .where('userId', isEqualTo: _userId)
//         .orderBy('timestamp', descending: true)
//         .get();

//     if (mounted) {
//       setState(() {
//         _savedSymptoms = querySnapshot.docs;
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         setState(() {
//           _isLoading = true;
//         });

//         await _firestore.collection('symptoms').add({
//           'userId': _userId,
//           'fullName': _fullNameController.text,
//           'age': _ageController.text,
//           'week': _weekController.text,
//           'symptoms': _symptomsController.text,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Symptoms saved successfully!')),
//         );

//         _symptomsController.clear();
//         await _fetchSavedSymptoms();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving symptoms: $e')),
//         );
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   Future<void> _deleteSymptom(String docId) async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       await _firestore.collection('symptoms').doc(docId).delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Symptom deleted successfully!')),
//       );
//       await _fetchSavedSymptoms();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting symptom: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Track Pregnancy Symptoms',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 30),
//                         _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                         const SizedBox(height: 20),
//                         _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _symptomsController,
//                           decoration: InputDecoration(
//                             labelText: 'Current Symptoms',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.health_and_safety),
//                           ),
//                           maxLines: 2,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please describe your symptoms';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _submitForm,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             'Save Current Symptoms',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   const Text(
//                     'Saved Symptoms History',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   _buildSymptomsList(),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildSymptomsList() {
//     if (_savedSymptoms.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Text('No saved symptoms yet'),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
     
//         final doc = _savedSymptoms await FirebaseFirestore.instance{
//           .collection('symptoms')
//           .doc(user.uid)
//           .get();
//         };
//         final data = symptom.data() as Map<String, dynamic>;
//         final timestamp = data['timestamp']?.toDate();
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 8),
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                       Datarow(
//                       'fullNme ${data['FullNme'] ?? 'N/A'}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                      Datarow(
//                       'age ${data['age'] ?? 'N/A'}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     Datarow(
//                       'Week ${data['week'] ?? 'N/A'}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
                    
//                     IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _deleteSymptom(symptom.id),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(data['symptoms'] ?? ''),
//                 const SizedBox(height: 8),
//                 Text(
//                   timestamp != null
//                       ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)
//                       : 'No date',
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//     );
//   }
// }





























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];
//   List<DocumentSnapshot> _savedSymptoms = [];

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     _fetchTrackingWeeks();
//     _fetchSavedSymptoms();
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _ageController.dispose();
//     _weekController.dispose();
//     _symptomsController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     if (_userId == null) return;

//     try {
//       final querySnapshot = await _firestore
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: _userId)
//           .get();

//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });

//       if (_trackingWeeks.isNotEmpty) {
//         final latestWeek = _trackingWeeks.first;
//         _fullNameController.text = latestWeek['fullName'] ?? '';
//         _ageController.text = latestWeek['age']?.toString() ?? '';
//         _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching tracking weeks: $e')),
//       );
//     }
//   }

//   Future<void> _fetchSavedSymptoms() async {
//     if (_userId == null) return;

//     try {
//       final querySnapshot = await _firestore
//           .collection('symptoms')
//           .where('userId', isEqualTo: _userId)
//           .orderBy('timestamp', descending: true)
//           .get();

//       setState(() {
//         _savedSymptoms = querySnapshot.docs;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching symptoms: $e')),
//       );
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         await _firestore.collection('symptoms').add({
//           'userId': _userId,
//           'fullName': _fullNameController.text,
//           'age': _ageController.text,
//           'week': _weekController.text,
//           'symptoms': _symptomsController.text,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Symptoms saved successfully!')),
//         );

//         _symptomsController.clear();
//         _fetchSavedSymptoms();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving symptoms: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _deleteSymptom(String docId) async {
//     try {
//       await _firestore.collection('symptoms').doc(docId).delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Symptom deleted successfully!')),
//       );
//       _fetchSavedSymptoms();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting symptom: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const SizedBox(height: 20),
//                   const Text(
//                     'Track Pregnancy Symptoms',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 30),
//                   // Read-only fields
//                   _buildReadOnlyField('Full Name', _fullNameController, Icons.person),
//                   const SizedBox(height: 20),
//                   _buildReadOnlyField('Age', _ageController, Icons.calendar_today),
//                   const SizedBox(height: 20),
//                   _buildReadOnlyField('Week of Pregnancy', _weekController, Icons.date_range),
//                   const SizedBox(height: 20),
//                   // Symptoms input field
//                   TextFormField(
//                     controller: _symptomsController,
//                     decoration: InputDecoration(
//                       labelText: 'Current Symptoms',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       prefixIcon: const Icon(Icons.health_and_safety),
//                     ),
//                     maxLines: 2,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please describe your symptoms';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: _submitForm,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 15),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     child: const Text(
//                       'Save Current Symptoms',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             const Text(
//               'Saved Symptoms History',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _savedSymptoms.isEmpty
//                 ? const Padding(
//                     padding: EdgeInsets.all(16.0),
//                     child: Text('No saved symptoms yet'),
//                   )
//                 : ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: _savedSymptoms.length,
//                     itemBuilder: (context, index) {
//                       final symptom = _savedSymptoms[index];
//                       final timestamp = symptom['timestamp']?.toDate();
//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         child: Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     'Week ${symptom['week']}',
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                   IconButton(
//                                     icon: const Icon(Icons.delete, color: Colors.red),
//                                     onPressed: () => _deleteSymptom(symptom.id),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Text(symptom['symptoms']),
//                               const SizedBox(height: 8),
//                               Text(
//                                 timestamp != null
//                                     ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)
//                                     : 'No date',
//                                 style: TextStyle(
//                                   color: Colors.grey[600],
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       readOnly: true,
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();
//   final TextEditingController _notesController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _userId;
//   List<DocumentSnapshot> _trackingWeeks = [];

//   @override
//   void initState() {
//     super.initState();
//     _userId = _auth.currentUser?.uid;
//     _fetchTrackingWeeks();
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _ageController.dispose();
//     _weekController.dispose();
//     _symptomsController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchTrackingWeeks() async {
//     if (_userId == null) return;

//     try {
//       final querySnapshot = await _firestore
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: _userId)
//           .get();

//       setState(() {
//         _trackingWeeks = querySnapshot.docs;
//       });

//       // Auto-fill the form if we have tracking weeks data
//       if (_trackingWeeks.isNotEmpty) {
//         final latestWeek = _trackingWeeks.first;
//         _fullNameController.text = latestWeek['fullName'] ?? '';
//         _ageController.text = latestWeek['age']?.toString() ?? '';
//         _weekController.text = latestWeek['currentWeek']?.toString() ?? '';
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching tracking weeks: $e')),
//       );
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         await _firestore.collection('symptoms').add({
//           'userId': _userId,
//           'fullName': _fullNameController.text,
//           'age': _ageController.text,
//           'week': _weekController.text,
//           'symptoms': _symptomsController.text,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Symptoms saved successfully!')),
//         );

//         // Clear the form after submission
//         _formKey.currentState!.reset();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving symptoms: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Track Pregnancy Symptoms',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),
//               TextFormField(
//                 controller: _fullNameController,
//                 decoration: InputDecoration(
//                   labelText: 'Full Name',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.person),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your full name';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _ageController,
//                 decoration: InputDecoration(
//                   labelText: 'Age',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.calendar_today),
//                 ),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your age';
//                   }
//                   if (int.tryParse(value) == null) {
//                     return 'Please enter a valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _weekController,
//                 decoration: InputDecoration(
//                   labelText: 'Week of Pregnancy',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.date_range),
//                 ),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your pregnancy week';
//                   }
//                   if (int.tryParse(value) == null) {
//                     return 'Please enter a valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _symptomsController,
//                 decoration: InputDecoration(
//                   labelText: 'Symptoms Experienced',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.health_and_safety),
//                 ),
//                 maxLines: 2,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please describe your symptoms';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _submitForm,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text(
//                   'Save Symptoms',
//                   style: TextStyle(fontSize: 18),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class Symptoms extends StatefulWidget {
//   const Symptoms({Key? key}) : super(key: key);

//   @override
//   _SymptomsState createState() => _SymptomsState();
// }

// class _SymptomsState extends State<Symptoms> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _symptomsController = TextEditingController();
//   final TextEditingController _notesController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _ageController.dispose();
//     _weekController.dispose();
//     _symptomsController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }
//  Future<List<QueryDocumentSnapshot>> fetchAppointments() async {
//     if (_userId == null) return [];

//     // Soo qaado appointments userka leh oo status-koodu yahay confirmed ama cancelled (lowercase)
//     final querySnapshot = await FirebaseFirestore.instance
//           .collection('trackingweeks')
//            'fullName': _fullName,
//         'age': _age,
//         'currentWeek': pregnancyWeek,
//           .doc(user.uid)
//           .get();

//     return querySnapshot.docs;
//   }
//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         await _firestore.collection('symptoms').add({
//           'fullName': _fullNameController.text,
//           'age': _ageController.text,
//           'week': _weekController.text,
//           'symptoms': _symptomsController.text,
//           'notes': _notesController.text,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Symptoms saved successfully!')),
//         );

//         // Clear the form after submission
//         _formKey.currentState!.reset();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving symptoms: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Symptoms Tracker'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Track Pregnancy Symptoms',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),
//               TextFormField(
//                 controller: _fullNameController,
//                 decoration: InputDecoration(
//                   labelText: 'Full Name',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.person),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your full name';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _ageController,
//                 decoration: InputDecoration(
//                   labelText: 'Age',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.calendar_today),
//                 ),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your age';
//                   }
//                   if (int.tryParse(value) == null) {
//                     return 'Please enter a valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _weekController,
//                 decoration: InputDecoration(
//                   labelText: 'Week of Pregnancy',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.date_range),
//                 ),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your pregnancy week';
//                   }
//                   if (int.tryParse(value) == null) {
//                     return 'Please enter a valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _symptomsController,
//                 decoration: InputDecoration(
//                   labelText: 'Symptoms Experienced',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.health_and_safety),
//                 ),
//                 maxLines: 3,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please describe your symptoms';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _notesController,
//                 decoration: InputDecoration(
//                   labelText: 'Additional Notes',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   prefixIcon: const Icon(Icons.note),
//                 ),
//                 maxLines: 3,
//               ),
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: _submitForm,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text(
//                   'Save Symptoms',
//                   style: TextStyle(fontSize: 18),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }