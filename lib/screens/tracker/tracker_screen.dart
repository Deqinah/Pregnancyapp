import 'dart:async'; // Add this import for Timer
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'track1.dart';

class PregnancyTrackerScreen extends StatefulWidget {
  const PregnancyTrackerScreen({super.key});

  @override
  State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
}

class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
  DateTime? _lastPeriodDate;
  bool _agreed = false;
  String? _fullName;
  int? _age;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _fullName = data['fullName']?.toString();
          final dobString = data['dateOfBirth']?.toString();
          if (dobString != null && dobString.isNotEmpty) {
            try {
              final dob = DateFormat('yyyy-MM-dd').parse(dobString);
              final now = DateTime.now();
              _age = now.year - dob.year;
              if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
                _age = _age! - 1;
              }
            } catch (e) {
              _age = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: ${e.toString()}')),
        );
      }
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  int _calculatePregnancyWeeks() {
    if (_lastPeriodDate == null) return 0;
    final difference = DateTime.now().difference(_lastPeriodDate!);
    return (difference.inDays / 7).floor().clamp(1, 40);
  }

  DateTime get _dueDate => _lastPeriodDate != null 
      ? _lastPeriodDate!.add(const Duration(days: 280)) 
      : DateTime.now();

  Future<void> _createOrUpdateTracker() async {
    if (_lastPeriodDate == null || _fullName == null || _age == null || _age! < 14 || !_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final pregnancyWeek = _calculatePregnancyWeeks();
      final dueDate = _dueDate;

      // Check for existing tracker
      final query = await FirebaseFirestore.instance
          .collection('trackingweeks')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Update existing tracker
        await query.docs.first.reference.update({
          'currentWeek': pregnancyWeek,
          'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
          'dueDate': Timestamp.fromDate(dueDate),
          'updatedAt': FieldValue.serverTimestamp(),
          'weekSelectedDate': Timestamp.now(),
        });
      } else {
        // Create new tracker
        await FirebaseFirestore.instance.collection('trackingweeks').add({
          'userId': user.uid,
          'fullName': _fullName,
          'age': _age,
          'currentWeek': pregnancyWeek,
          'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
          'dueDate': Timestamp.fromDate(dueDate),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'weekSelectedDate': Timestamp.now(),
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrackerDetailScreen(
              pregnancyWeek: pregnancyWeek,
              lastPeriodDate: _lastPeriodDate!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Pregnancy Tracker"),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Welcome to Pregnancy Tracker!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),

              // Last Period Date Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Last period started:'),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _lastPeriodDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 280)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _lastPeriodDate = picked);
                      }
                    },
                    child: Text(
                      _lastPeriodDate == null 
                          ? 'Select date' 
                          : formatDate(_lastPeriodDate),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text('Due date: ${formatDate(_dueDate)}'),

              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _lastPeriodDate == null
                        ? '🎉 Congratulations!'
                        : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Terms Agreement
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (value) => setState(() => _agreed = value ?? false),
                    activeColor: Colors.green,
                  ),
                  const Expanded(
                    child: Text("I agree to terms"),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
                      ? _createOrUpdateTracker
                      : null,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
















// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String? _fullName;
//   int? _age;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<void> _fetchUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('No user logged in during fetch');
//       return;
//     }

//     debugPrint('Fetching user data for UID: ${user.uid}');
    
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
          
//       debugPrint('User document exists: ${doc.exists}');
      
//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           _fullName = data['fullName']?.toString();
          
//           // Calculate age from date of birth
//           final dobString = data['dateOfBirth']?.toString();
//           if (dobString != null && dobString.isNotEmpty) {
//             try {
//               final dob = DateFormat('yyyy-MM-dd').parse(dobString);
//               final now = DateTime.now();
//               _age = now.year - dob.year;
//               if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
//                 _age = _age! - 1;
//               }
//               debugPrint('Calculated age from DOB ($dobString): $_age');
//             } catch (e) {
//               debugPrint('Error parsing date of birth: $e');
//               _age = null;
//             }
//           } else {
//             debugPrint('No date of birth found in user data');
//             _age = null;
//           }
//         });
//         debugPrint('Set user data - fullName: $_fullName, age: $_age');
//       } else {
//         debugPrint('User document does not exist');
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error fetching user data: $e');
//       debugPrint('Stack trace: $stackTrace');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading user data: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     // Validate all required fields
//     if (_lastPeriodDate == null) {
//       debugPrint('Last period date is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select your last period date')),
//         );
//       }
//       return;
//     }

//     if (_fullName == null || _fullName!.isEmpty) {
//       debugPrint('Full name is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Full name is required')),
//         );
//       }
//       return;
//     }

//     if (_age == null || _age! <14) {
//       debugPrint('Valid age is required (minimum 14)');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('You must be at least 14 years old')),
//         );
//       }
//       return;
//     }

//     if (!_agreed) {
//       debugPrint('Must agree to terms');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please agree to the terms and conditions')),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     debugPrint('Attempting to create pregnancy tracker...');
//     debugPrint('User: $_fullName, Age: $_age');
//     debugPrint('Last Period: $_lastPeriodDate');
//     debugPrint('Calculated Week: ${_calculatePregnancyWeeks()}');

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         debugPrint('No authenticated user found');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Authentication required. Please login again')),
//           );
//         }
//         return;
//       }

//       final pregnancyWeek = _calculatePregnancyWeeks();
//       final dueDate = _dueDate;

//       debugPrint('Creating document in trackerweek collection...');
      
//       final docRef = await FirebaseFirestore.instance.collection('trackingweeks').add({
//         'userId': user.uid,
//         'fullName': _fullName,
//         'age': _age,
//         'currentWeek': pregnancyWeek,
//         'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
//         'dueDate': Timestamp.fromDate(dueDate),
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       debugPrint('Successfully created tracker with ID: ${docRef.id}');

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TrackerDetailScreen(pregnancyWeek: pregnancyWeek),
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error creating pregnancy tracker: $e');
//       debugPrint('Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create tracker: ${e.toString()}'),
//             duration: const Duration(seconds: 5),
//           ),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Your Pregnancy Tracker"),
//         backgroundColor: Colors.blue,
//           leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pushNamed(context, '/home');
//           },
//         ),
//       ),
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime.now().subtract(const Duration(days: 280)),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null && picked != _lastPeriodDate) {
//                         setState(() {
//                           _lastPeriodDate = picked;
//                         });
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() {
//                         _agreed = value ?? false;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//                       ? _createTrackerWeek
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _agreed && _lastPeriodDate != null 
//                         ? Colors.blue[900] 
//                         : Colors.grey,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Done',
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }





































// import 'package:flutter/gestures.dart'; // Add this import
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String? _fullName;
//   int? _age;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<void> navigateBasedOnTrackingStatus(BuildContext context) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final hasTracking = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: user.uid)
//         .limit(1)
//         .get()
//         .then((snapshot) => snapshot.docs.isNotEmpty);

//     if (hasTracking) {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: user.uid)
//           .orderBy('createdAt', descending: true)
//           .limit(1)
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         final week = snapshot.docs.first['currentWeek'] as int;
//         if (mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => TrackerDetailScreen(pregnancyWeek: week),
//             ),
//           );
//         }
//       }
//     }
//   }

//   Future<void> _fetchUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
      
//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           _fullName = data['fullName']?.toString();
          
//           // Calculate age from date of birth
//           final dobString = data['dateOfBirth']?.toString();
//           if (dobString != null && dobString.isNotEmpty) {
//             try {
//               final dob = DateFormat('yyyy-MM-dd').parse(dobString);
//               final now = DateTime.now();
//               _age = now.year - dob.year;
//               if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
//                 _age = _age! - 1;
//               }
//             } catch (e) {
//               _age = null;
//             }
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading user data: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return 'Not selected';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     if (_lastPeriodDate == null || _fullName == null || _fullName!.isEmpty || 
//         _age == null || _age! < 16 || !_agreed) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please fill all required fields')),
//         );
//       }
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;

//       final pregnancyWeek = _calculatePregnancyWeeks();
//       final dueDate = _dueDate;

//       await FirebaseFirestore.instance.collection('trackingweeks').add({
//         'userId': user.uid,
//         'fullName': _fullName,
//         'age': _age,
//         'currentWeek': pregnancyWeek,
//         'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
//         'dueDate': Timestamp.fromDate(dueDate),
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TrackerDetailScreen(pregnancyWeek: pregnancyWeek),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to create tracker: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Tracker'),
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.blue,
//       ),
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 10),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               // Last Period Date Picker
//               _buildDatePickerField(),

//               const SizedBox(height: 20),

//               // Due Date (Auto-generated)
//               _buildInfoRow('Estimated due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               // Weeks Pregnant Box
//               _buildPregnancyInfoBox(),

//               const SizedBox(height: 20),

//               // Terms Agreement
//               _buildTermsCheckbox(),

//               const SizedBox(height: 20),

//               // Done Button
//               _buildSubmitButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDatePickerField() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         const Text(
//           'First day of last period:',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         TextButton(
//           onPressed: () async {
//             final DateTime? picked = await showDatePicker(
//               context: context,
//               initialDate: _lastPeriodDate ?? DateTime.now(),
//               firstDate: DateTime.now().subtract(const Duration(days: 280)),
//               lastDate: DateTime.now(),
//             );
//             if (picked != null && picked != _lastPeriodDate) {
//               setState(() => _lastPeriodDate = picked);
//             }
//           },
//           child: Text(
//             formatDate(_lastPeriodDate),
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.blue,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPregnancyInfoBox() {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.blue[50],
//           border: Border.all(color: Colors.green, width: 2),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Text(
//           _lastPeriodDate == null
//               ? '🎉 Select your last period date to begin tracking'
//               : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTermsCheckbox() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Checkbox(
//           value: _agreed,
//           onChanged: (value) {
//             setState(() => _agreed = value ?? false);
//           },
//           activeColor: Colors.green,
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: RichText(
//             text: TextSpan(
//               style: const TextStyle(fontSize: 14, color: Colors.black),
//               children: [
//                 const TextSpan(
//                   text: "I confirm that I'm at least 16 years old and I agree to the ",
//                 ),
//                 TextSpan(
//                   text: "Terms & Conditions",
//                   style: const TextStyle(
//                     color: Colors.blue,
//                     decoration: TextDecoration.underline,
//                   ),
//                   recognizer: TapGestureRecognizer()
//                     ..onTap = () {
//                       // Add terms navigation here
//                     },
//                 ),
//                 const TextSpan(text: " and "),
//                 TextSpan(
//                   text: "Privacy Policy",
//                   style: const TextStyle(
//                     color: Colors.blue,
//                     decoration: TextDecoration.underline,
//                   ),
//                   recognizer: TapGestureRecognizer()
//                     ..onTap = () {
//                       // Add privacy policy navigation here
//                     },
//                 ),
//                 const TextSpan(text: "."),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSubmitButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//             ? _createTrackerWeek
//             : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _agreed && _lastPeriodDate != null 
//               ? Colors.blue[900] 
//               : Colors.grey,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: _isLoading
//             ? const CircularProgressIndicator(color: Colors.white)
//             : const Text(
//                 'Start Tracking',
//                 style: TextStyle(fontSize: 18, color: Colors.white),
//               ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String? _fullName;
//   int? _age;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }
// Future<void> navigateBasedOnTrackingStatus(BuildContext context) async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) {
//     // Handle login flow
//     return;
//   }

//   final hasTracking = await FirebaseFirestore.instance
//       .collection('trackingweeks')
//       .where('userId', isEqualTo: user.uid)
//       .limit(1)
//       .get()
//       .then((snapshot) => snapshot.docs.isNotEmpty);

//   if (hasTracking) {
//     // Get latest tracking data
//     final snapshot = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: user.uid)
//         .orderBy('createdAt', descending: true)
//         .limit(1)
//         .get();

//     if (snapshot.docs.isNotEmpty) {
//       final week = snapshot.docs.first['currentWeek'] as int;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => TrackerDetailScreen(pregnancyWeek: week),
//         ),
//       );
//     }
//   } else {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const PregnancyTrackerScreen()),
//     );
//   }
// }
//   Future<void> _fetchUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
      
//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           _fullName = data['fullName']?.toString();
          
//           // Calculate age from date of birth
//           final dobString = data['dateOfBirth']?.toString();
//           if (dobString != null && dobString.isNotEmpty) {
//             try {
//               final dob = DateFormat('yyyy-MM-dd').parse(dobString);
//               final now = DateTime.now();
//               _age = now.year - dob.year;
//               if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
//                 _age = _age! - 1;
//               }
//             } catch (e) {
//               _age = null;
//             }
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading user data: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     if (_lastPeriodDate == null || _fullName == null || _fullName!.isEmpty || 
//         _age == null || _age! < 16 || !_agreed) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;

//       final pregnancyWeek = _calculatePregnancyWeeks();
//       final dueDate = _dueDate;

//       await FirebaseFirestore.instance.collection('trackingweeks').add({
//         'userId': user.uid,
//         'fullName': _fullName,
//         'age': _age,
//         'currentWeek': pregnancyWeek,
//         'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
//         'dueDate': Timestamp.fromDate(dueDate),
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       // Navigate to TrackerDetailScreen after successful creation
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TrackerDetailScreen(pregnancyWeek: pregnancyWeek),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to create tracker: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime.now().subtract(const Duration(days: 280)),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null && picked != _lastPeriodDate) {
//                         setState(() => _lastPeriodDate = picked);
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() => _agreed = value ?? false);
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//                       ? _createTrackerWeek
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _agreed && _lastPeriodDate != null 
//                         ? Colors.blue[900] 
//                         : Colors.grey,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Done',
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }






































// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String? _fullName;
//   int? _age;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<bool> _hasExistingTracking() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return false;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: user.uid)
//           .limit(1)
//           .get();
      
//       return querySnapshot.docs.isNotEmpty;
//     } catch (e) {
//       debugPrint('Error checking existing tracking: $e');
//       return false;
//     }
//   }

//   Future<void> _fetchUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('No user logged in during fetch');
//       return;
//     }

//     debugPrint('Fetching user data for UID: ${user.uid}');
    
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
          
//       debugPrint('User document exists: ${doc.exists}');
      
//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           _fullName = data['fullName']?.toString();
          
//           // Calculate age from date of birth
//           final dobString = data['dateOfBirth']?.toString();
//           if (dobString != null && dobString.isNotEmpty) {
//             try {
//               final dob = DateFormat('yyyy-MM-dd').parse(dobString);
//               final now = DateTime.now();
//               _age = now.year - dob.year;
//               if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
//                 _age = _age! - 1;
//               }
//               debugPrint('Calculated age from DOB ($dobString): $_age');
//             } catch (e) {
//               debugPrint('Error parsing date of birth: $e');
//               _age = null;
//             }
//           } else {
//             debugPrint('No date of birth found in user data');
//             _age = null;
//           }
//         });
//         debugPrint('Set user data - fullName: $_fullName, age: $_age');
//       } else {
//         debugPrint('User document does not exist');
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error fetching user data: $e');
//       debugPrint('Stack trace: $stackTrace');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading user data: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     // Validate all required fields
//     if (_lastPeriodDate == null) {
//       debugPrint('Last period date is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select your last period date')),
//         );
//       }
//       return;
//     }

//     if (_fullName == null || _fullName!.isEmpty) {
//       debugPrint('Full name is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Full name is required')),
//         );
//       }
//       return;
//     }

//     if (_age == null || _age! < 16) {
//       debugPrint('Valid age is required (minimum 16)');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('You must be at least 16 years old')),
//         );
//       }
//       return;
//     }

//     if (!_agreed) {
//       debugPrint('Must agree to terms');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please agree to the terms and conditions')),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     debugPrint('Attempting to create pregnancy tracker...');
//     debugPrint('User: $_fullName, Age: $_age');
//     debugPrint('Last Period: $_lastPeriodDate');
//     debugPrint('Calculated Week: ${_calculatePregnancyWeeks()}');

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         debugPrint('No authenticated user found');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Authentication required. Please login again')),
//           );
//         }
//         return;
//       }

//       final pregnancyWeek = _calculatePregnancyWeeks();
//       final dueDate = _dueDate;

//       // Check if user has existing tracking data
//       final hasExistingTracking = await _hasExistingTracking();
      
//       debugPrint('Creating document in trackerweek collection...');
      
//       final docRef = await FirebaseFirestore.instance.collection('trackingweeks').add({
//         'userId': user.uid,
//         'fullName': _fullName,
//         'age': _age,
//         'currentWeek': pregnancyWeek,
//         'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
//         'dueDate': Timestamp.fromDate(dueDate),
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       debugPrint('Successfully created tracker with ID: ${docRef.id}');

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => hasExistingTracking
//                 ? TrackerDetailScreen(pregnancyWeek: pregnancyWeek)
//                 : PregnancyTrackerScreen(),
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error creating pregnancy tracker: $e');
//       debugPrint('Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create tracker: ${e.toString()}'),
//             duration: const Duration(seconds: 5),
//           ),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime.now().subtract(const Duration(days: 280)),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null && picked != _lastPeriodDate) {
//                         setState(() {
//                           _lastPeriodDate = picked;
//                         });
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() {
//                         _agreed = value ?? false;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//                       ? _createTrackerWeek
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _agreed && _lastPeriodDate != null 
//                         ? Colors.blue[900] 
//                         : Colors.grey,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Done',
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }


























// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String? _fullName;
//   int? _age;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<void> _fetchUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('No user logged in during fetch');
//       return;
//     }

//     debugPrint('Fetching user data for UID: ${user.uid}');
    
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
          
//       debugPrint('User document exists: ${doc.exists}');
      
//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           _fullName = data['fullName']?.toString();
          
//           // Calculate age from date of birth
//           final dobString = data['dateOfBirth']?.toString();
//           if (dobString != null && dobString.isNotEmpty) {
//             try {
//               final dob = DateFormat('yyyy-MM-dd').parse(dobString);
//               final now = DateTime.now();
//               _age = now.year - dob.year;
//               if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
//                 _age = _age! - 1;
//               }
//               debugPrint('Calculated age from DOB ($dobString): $_age');
//             } catch (e) {
//               debugPrint('Error parsing date of birth: $e');
//               _age = null;
//             }
//           } else {
//             debugPrint('No date of birth found in user data');
//             _age = null;
//           }
//         });
//         debugPrint('Set user data - fullName: $_fullName, age: $_age');
//       } else {
//         debugPrint('User document does not exist');
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error fetching user data: $e');
//       debugPrint('Stack trace: $stackTrace');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading user data: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     // Validate all required fields
//     if (_lastPeriodDate == null) {
//       debugPrint('Last period date is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select your last period date')),
//         );
//       }
//       return;
//     }

//     if (_fullName == null || _fullName!.isEmpty) {
//       debugPrint('Full name is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Full name is required')),
//         );
//       }
//       return;
//     }

//     if (_age == null || _age! < 16) {
//       debugPrint('Valid age is required (minimum 16)');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('You must be at least 16 years old')),
//         );
//       }
//       return;
//     }

//     if (!_agreed) {
//       debugPrint('Must agree to terms');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please agree to the terms and conditions')),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     debugPrint('Attempting to create pregnancy tracker...');
//     debugPrint('User: $_fullName, Age: $_age');
//     debugPrint('Last Period: $_lastPeriodDate');
//     debugPrint('Calculated Week: ${_calculatePregnancyWeeks()}');

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         debugPrint('No authenticated user found');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Authentication required. Please login again')),
//           );
//         }
//         return;
//       }

//       final pregnancyWeek = _calculatePregnancyWeeks();
//       final dueDate = _dueDate;

//       debugPrint('Creating document in trackerweek collection...');
      
//       final docRef = await FirebaseFirestore.instance.collection('trackingweeks').add({
//         'userId': user.uid,
//         'fullName': _fullName,
//         'age': _age,
//         'currentWeek': pregnancyWeek,
//         'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
//         'dueDate': Timestamp.fromDate(dueDate),
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       debugPrint('Successfully created tracker with ID: ${docRef.id}');

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TrackerDetailScreen(pregnancyWeek: pregnancyWeek),
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error creating pregnancy tracker: $e');
//       debugPrint('Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create tracker: ${e.toString()}'),
//             duration: const Duration(seconds: 5),
//           ),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime.now().subtract(const Duration(days: 280)),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null && picked != _lastPeriodDate) {
//                         setState(() {
//                           _lastPeriodDate = picked;
//                         });
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() {
//                         _agreed = value ?? false;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//                       ? _createTrackerWeek
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _agreed && _lastPeriodDate != null 
//                         ? Colors.blue[900] 
//                         : Colors.grey,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Done',
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }































// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String? _fullName;
//   int? _age;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<void> _fetchUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('No user logged in during fetch');
//       return;
//     }

//     debugPrint('Fetching user data for UID: ${user.uid}');
    
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
          
//       debugPrint('User document exists: ${doc.exists}');
      
//       if (doc.exists) {
//         setState(() {
//           _fullName = doc.data()?['fullName']?.toString();
//           final ageData = doc.data()?['age'];
//           _age = ageData is int ? ageData : int.tryParse(ageData?.toString() ?? '');
//         });
//         debugPrint('Set user data - fullName: $_fullName, age: $_age');
//       } else {
//         debugPrint('User document does not exist');
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error fetching user data: $e');
//       debugPrint('Stack trace: $stackTrace');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading user data: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     // Validate all required fields
//     if (_lastPeriodDate == null) {
//       debugPrint('Last period date is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select your last period date')),
//         );
//       }
//       return;
//     }

//     if (_fullName == null || _fullName!.isEmpty) {
//       debugPrint('Full name is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Full name is required')),
//         );
//       }
//       return;
//     }

//     if (_age == null || _age! < 16) {
//       debugPrint('Valid age is required (minimum 16)');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('You must be at least 16 years old')),
//         );
//       }
//       return;
//     }

//     if (!_agreed) {
//       debugPrint('Must agree to terms');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please agree to the terms and conditions')),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     debugPrint('Attempting to create pregnancy tracker...');
//     debugPrint('User: $_fullName, Age: $_age');
//     debugPrint('Last Period: $_lastPeriodDate');
//     debugPrint('Calculated Week: ${_calculatePregnancyWeeks()}');

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         debugPrint('No authenticated user found');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Authentication required. Please login again')),
//           );
//         }
//         return;
//       }

//       final pregnancyWeek = _calculatePregnancyWeeks();
//       final dueDate = _dueDate;

//       debugPrint('Creating document in tracker_week collection...');
      
//       final docRef = await FirebaseFirestore.instance.collection('tracker_week').add({
//         'userId': user.uid,
//         'fullName': _fullName,
//         'age': _age,
//         'currentWeek': pregnancyWeek,
//         'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
//         'dueDate': Timestamp.fromDate(dueDate),
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       debugPrint('Successfully created tracker with ID: ${docRef.id}');

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TrackerDetailScreen(pregnancyWeek: pregnancyWeek),
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error creating pregnancy tracker: $e');
//       debugPrint('Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create tracker: ${e.toString()}'),
//             duration: const Duration(seconds: 5),
//           ),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime.now().subtract(const Duration(days: 280)),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null && picked != _lastPeriodDate) {
//                         setState(() {
//                           _lastPeriodDate = picked;
//                         });
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() {
//                         _agreed = value ?? false;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//                       ? _createTrackerWeek
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _agreed && _lastPeriodDate != null 
//                         ? Colors.blue[900] 
//                         : Colors.grey,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Done',
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String? _fullName;
//   int? _age;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<void> _fetchUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('No user logged in during fetch');
//       return;
//     }

//     debugPrint('Fetching user data for UID: ${user.uid}');
    
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
          
//       debugPrint('User document exists: ${doc.exists}');
      
//       if (doc.exists) {
//         setState(() {
//           _fullName = doc.data()?['fullName']?.toString();
//           _age = doc.data()?['age'] is int ? doc.data()?['age'] : int.tryParse(doc.data()?['age']?.toString() ?? '');
//         });
//         debugPrint('Set user data - fullName: $_fullName, age: $_age');
//       } else {
//         debugPrint('User document does not exist');
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error fetching user data: $e');
//       debugPrint('Stack trace: $stackTrace');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading user data: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     // Validate all required fields
//     if (_lastPeriodDate == null) {
//       debugPrint('Last period date is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select your last period date')),
//         );
//       }
//       return;
//     }

//     if (_fullName == null || _fullName!.isEmpty) {
//       debugPrint('Full name is required');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Full name is required')),
//         );
//       }
//       return;
//     }

//     if (_age == null || _age! < 16) {
//       debugPrint('Valid age is required (minimum 16)');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('You must be at least 16 years old')),
//         );
//       }
//       return;
//     }

//     if (!_agreed) {
//       debugPrint('Must agree to terms');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please agree to the terms and conditions')),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     debugPrint('Attempting to create pregnancy tracker...');
//     debugPrint('User: $_fullName, Age: $_age');
//     debugPrint('Last Period: $_lastPeriodDate');
//     debugPrint('Calculated Week: ${_calculatePregnancyWeeks()}');

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         debugPrint('No authenticated user found');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Authentication required. Please login again')),
//           );
//         }
//         return;
//       }

//       final pregnancyWeek = _calculatePregnancyWeeks();
//       final dueDate = _dueDate;

//       debugPrint('Creating document in tracker_week collection...');
      
//       final docRef = await FirebaseFirestore.instance.collection('tracker_week').add({
//         'userId': user.uid,
//         'fullName': _fullName,
//         'age': _age,
//         'currentWeek': pregnancyWeek,
//         'lastPeriodDate': Timestamp.fromDate(_lastPeriodDate!),
//         'dueDate': Timestamp.fromDate(dueDate),
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       debugPrint('Successfully created tracker with ID: ${docRef.id}');

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TrackerDetailScreen(pregnancyWeek: pregnancyWeek),
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error creating pregnancy tracker: $e');
//       debugPrint('Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create tracker: ${e.toString()}'),
//             duration: const Duration(seconds: 5),
//           ),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime.now().subtract(const Duration(days: 280)),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null && picked != _lastPeriodDate) {
//                         setState(() {
//                           _lastPeriodDate = picked;
//                         });
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() {
//                         _agreed = value ?? false;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//                       ? _createTrackerWeek
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _agreed && _lastPeriodDate != null 
//                         ? Colors.blue[900] 
//                         : Colors.grey,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Done',
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }
































// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String? _fullName;
//   int? _age;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<void> _fetchUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       try {
//         final doc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();
//         if (doc.exists) {
//           setState(() {
//             _fullName = doc.data()?['fullName'];
//             _age = doc.data()?['age'];
//           });
//         }
//       } catch (e) {
//         debugPrint('Error fetching user data: $e');
//       }
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     if (_lastPeriodDate == null || _fullName == null || _age == null) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final pregnancyWeek = _calculatePregnancyWeeks();
//         await FirebaseFirestore.instance.collection('tracker_week').add({
//           'userId': user.uid,
//           'fullName': _fullName,
//           'age': _age,
//           'currentWeek': pregnancyWeek,
//           'lastPeriodDate': _lastPeriodDate,
//           'dueDate': _dueDate,
//           'createdAt': FieldValue.serverTimestamp(),
//         });

//         // Navigate to the next screen after successful creation
//         if (mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => TrackerDetailScreen(pregnancyWeek: pregnancyWeek),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint('Error creating tracker week: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to create tracker. Please try again.')),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime(2020),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null) {
//                         setState(() {
//                           _lastPeriodDate = picked;
//                         });
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() {
//                         _agreed = value ?? false;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//   width: double.infinity,
//   child: ElevatedButton(
//     onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//         ? _createTrackerWeek
//         : null,
//     style: ElevatedButton.styleFrom(
//       backgroundColor: _agreed && _lastPeriodDate != null 
//           ? Colors.blue[900] 
//           : Colors.grey,
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//     ),
//     child: _isLoading
//         ? const CircularProgressIndicator(color: Colors.white)
//         : const Text(
//             'Done',
//             style: TextStyle(fontSize: 18, color: Colors.white),
//           ),
//   ),
// ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;
//   String _fullName = '';
//   int _age = 0;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<void> _fetchUserData() async {
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();
        
//         if (userDoc.exists) {
//           final data = userDoc.data() as Map<String, dynamic>;
//           setState(() {
//             _fullName = data['fullName'] ?? '';
            
//             // Calculate age from DOB
//             if (data['dob'] != null) {
//               final dob = (data['dob'] as Timestamp).toDate();
//               final now = DateTime.now();
//               _age = now.year - dob.year;
//               if (now.month < dob.month || 
//                   (now.month == dob.month && now.day < dob.day)) {
//                 _age--;
//               }
//             }
//           });
//         }
//       }
//     } catch (e) {
//       print('Error fetching user data: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   Future<void> _createTrackerWeek() async {
//     if (_lastPeriodDate == null || _fullName.isEmpty) return;

//     final currentWeek = _calculatePregnancyWeeks();
//     final user = FirebaseAuth.instance.currentUser;
    
//     if (user != null) {
//       try {
//         await FirebaseFirestore.instance
//             .collection('tracker_week')
//             .doc(user.uid)
//             .set({
//               'fullName': _fullName,
//               'age': _age,
//               'currentWeek': currentWeek,
//               'createdAt': FieldValue.serverTimestamp(),
//               'userId': user.uid,
//             });
//       } catch (e) {
//         print('Error creating tracker week: $e');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime(2020),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null) {
//                         setState(() {
//                           _lastPeriodDate = picked;
//                         });
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() {
//                         _agreed = value ?? false;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (_agreed && _lastPeriodDate != null && !_isLoading)
//                       ? () async {
//                           await _createTrackerWeek();
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => TrackerDetailScreen(
//                                 pregnancyWeek: _calculatePregnancyWeeks(),
//                               ),
//                             ),
//                           );
//                         }
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         (_agreed && _lastPeriodDate != null && !_isLoading) 
//                             ? Colors.blue[900] 
//                             : Colors.grey,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Done',
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'track1.dart'; // Ensure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   bool _agreed = false;

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               /// Last Period Date Picker
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Last period started:',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       final DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: _lastPeriodDate ?? DateTime.now(),
//                         firstDate: DateTime(2020),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null) {
//                         setState(() {
//                           _lastPeriodDate = picked;
//                         });
//                       }
//                     },
//                     child: Text(
//                       _lastPeriodDate == null
//                           ? 'Select date'
//                           : formatDate(_lastPeriodDate),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               /// Due Date (Auto-generated)
//               _buildInfoRow('Due date',
//                   _lastPeriodDate == null ? '-----' : formatDate(_dueDate)),

//               const SizedBox(height: 40),

//               /// Weeks Pregnant Box
//               Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     border: Border.all(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _lastPeriodDate == null
//                         ? '🎉 Congratulations!'
//                         : "🤰 You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               /// Terms Agreement
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreed,
//                     onChanged: (value) {
//                       setState(() {
//                         _agreed = value ?? false;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               /// Done Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _agreed && _lastPeriodDate != null
//                       ? () {
//                           // Replace with your actual navigation
//                            Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) =>TrackerDetailScreen(pregnancyWeek: _calculatePregnancyWeeks()),
//   ),
// );

//                         }
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         _agreed && _lastPeriodDate != null ? Colors.blue[900] : Colors.grey,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: const Text(
//                     'Done',
//                     style: TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       ],
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;

//   String formatDate(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   int _calculatePregnancyWeeks() {
//     if (_lastPeriodDate == null) return 0;
//     final difference = DateTime.now().difference(_lastPeriodDate!);
//     return (difference.inDays / 7).floor();
//   }

//   DateTime get _dueDate =>
//       _lastPeriodDate != null ? _lastPeriodDate!.add(const Duration(days: 280)) : DateTime.now();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 40),
//             const Text(
//               'Welcome to Pregnancy Tracker!',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.pink,
//               ),
//             ),
//             const SizedBox(height: 30),

//             /// 👇 Last Period Picker
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Last period started:',
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     final DateTime? picked = await showDatePicker(
//                       context: context,
//                       initialDate: _lastPeriodDate ?? DateTime.now(),
//                       firstDate: DateTime(2020),
//                       lastDate: DateTime.now(),
//                     );
//                     if (picked != null) {
//                       setState(() {
//                         _lastPeriodDate = picked;
//                       });
//                     }
//                   },
//                   child: Text(
//                     _lastPeriodDate == null ? 'Select date' : formatDate(_lastPeriodDate),
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),

//             /// ✅ Auto-calculated Due Date (no selection)
//             _lastPeriodDate == null
//                 ? _buildInfoRow('Due date', '-----' color: Colors.blue)
//                 : _buildInfoRow('Due date', formatDate(_dueDate)),
//                  child: Text(
//                     _lastPeriodDate == null ? '----' : formatDate(_lastPeriodDate),
//                     style: const TextStyle(fontSize: 16),
//                   ),

//             const SizedBox(height: 40),

//             /// Weeks Pregnant (Auto)
//             Center(
//               child: Text(
//                 _lastPeriodDate == null
//                     ? 'Congratulations!',
//                     : "You're ${_calculatePregnancyWeeks()} weeks pregnant",
//                 style: const TextStyle(
//                   fontSize: 22,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),

//             const Spacer(),

//             Row(
//               children: [
//                 Checkbox(value: true, onChanged: (value) {}),
//                 const Expanded(
//                   child: Text(
//                     "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                     style: TextStyle(fontSize: 14),
//                   ),
//                   isagoona tic lasaarin lagama tagi karo
//                 ),
//               ],
//             ),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Done',
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//                 Navigate to next screen   TrackScreen(
//                   onPressed: () {
//                     // Navigate to the next screen
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const TrackingScreen(),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   DateTime? _dueDate;

//   void _pickLastPeriodDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
//     if (picked != null) {
//       setState(() {
//         _lastPeriodDate = picked;
//         _dueDate = picked.add(const Duration(days: 280)); // 40 weeks
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     String formatDate(DateTime? date) {
//       return date != null ? DateFormat('MMM d, yyyy').format(date) : 'Select date';
//     }

//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 40),
//             const Text(
//               'Welcome to Pregnancy Tracker!',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.pink,
//               ),
//             ),
//             const SizedBox(height: 30),

//             GestureDetector(
//               onTap: _pickLastPeriodDate,
//               child: _buildInfoRow(
//                 'Last period started',
//                 formatDate(_lastPeriodDate),
//                 isClickable: true,
//               ),
//             ),

//             const SizedBox(height: 20),
//             _buildInfoRow('Due date', formatDate(_dueDate)),

//             const SizedBox(height: 40),
//             const Center(
//               child: Text(
//                 'Congratulations!',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.pink,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Center(
//               child: Text(
//                 "You're 1 week pregnant",
//                 style: TextStyle(
//                   fontSize: 22,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//             const Spacer(),
//             Row(
//               children: [
//                 Checkbox(value: true, onChanged: (value) {}),
//                 const Expanded(
//                   child: Text(
//                     "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Done',
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value, {bool isClickable = false}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 16,
//             color: Colors.grey,
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: isClickable ? Colors.blue : Colors.black,
//             decoration: isClickable ? TextDecoration.underline : null,
//           ),
//         ),
//       ],
//     );
//   }
// }





// import 'package:flutter/material.dart';

// class PregnancyTrackerScreen extends StatelessWidget {
//   const PregnancyTrackerScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 40),
//             const Text(
//               'Welcome to Pregnancy Tracker!',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.pink,
//               ),
//             ),
//             const SizedBox(height: 30),
//             _buildInfoRow('Last period started', 'May 18, 2025'),
//             const SizedBox(height: 20),
//             _buildInfoRow('Due date', 'Feb 22, 2026'),
//             const SizedBox(height: 40),
//             const Center(
//               child: Text(
//                 'Congratulations!',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.pink,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Center(
//               child: Text(
//                 "You're 1 week pregnant",
//                 style: TextStyle(
//                   fontSize: 22,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//             const Spacer(),
//             Row(
//               children: [
//                 Checkbox(value: true, onChanged: (value) {}),
//                 const Expanded(
//                   child: Text(
//                     "I confirm that I'm at least 16 years old and I have read Terms & Conditions and Privacy Policy.",
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//            SizedBox(
//   height: 20,
//   width: double.infinity, // ✅ sax ah halkan
// ),

//               child: ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'Done',
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 16,
//             color: Colors.grey,
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'track1.dart'; // Make sure this import path is correct

// class PregnancyTrackerScreen extends StatefulWidget {
//   const PregnancyTrackerScreen({Key? key}) : super(key: key);

//   @override
//   State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _selectedDueDate;
//   int _currentWeek = 0;
//   double _progress = 0.0;
//   List<String> _weeklyTips = [];
//   List<bool> _tipsCompleted = [];

//   void _selectDueDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDueDate ?? DateTime.now(),
//       firstDate: DateTime.now().subtract(const Duration(days: 7)),
//       lastDate: DateTime.now().add(const Duration(days: 300)),
//     );
//     if (picked != null && picked != _selectedDueDate) {
//       setState(() {
//         _selectedDueDate = picked;
//         _calculatePregnancyWeek();
//         _generateWeeklyTips();
//       });
//     }
//   }

//   void _calculatePregnancyWeek() {
//     if (_selectedDueDate == null) return;
//     final conceptionDate = _selectedDueDate!.subtract(const Duration(days: 280));
//     final now = DateTime.now();
//     final difference = now.difference(conceptionDate).inDays;
//     final weeks = (difference / 7).floor();
//     setState(() {
//       _currentWeek = weeks.clamp(0, 40);
//       _progress = _currentWeek / 40.0;
//     });
//   }

//   void _generateWeeklyTips() {
//     _weeklyTips = List.generate(
//       40,
//       (index) => "Week ${index + 1}: Stay healthy and hydrated. Take your vitamins!",
//     );
//     _tipsCompleted = List.filled(40, false);
//   }

//   @override
//   void initState() {
//     super.initState();
//     _generateWeeklyTips();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Tracker'),
//         backgroundColor: Colors.blue[900],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Track Your Pregnancy",
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     color: Colors.blue[900],
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => _selectDueDate(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue[900],
//               ),
//               child: const Text("Select Due Date"),
//             ),
//             const SizedBox(height: 8),
//             if (_selectedDueDate != null) ...[
//               Text(
//                 "Due Date: ${DateFormat('MMMM d, yyyy').format(_selectedDueDate!)}",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue[900],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 "Current Week: $_currentWeek / 40",
//                 style: const TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 8),
//               LinearProgressIndicator(
//                 value: _progress,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[900]!),
//                 backgroundColor: Colors.blue[100],
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 _weeklyTips[_currentWeek],
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: Colors.blue[900],
//                     ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Checkbox(
//                     value: _tipsCompleted[_currentWeek],
//                     onChanged: (bool? value) {
//                       setState(() {
//                         _tipsCompleted[_currentWeek] = value ?? false;
//                       });
//                     },
//                     fillColor: MaterialStateProperty.resolveWith<Color>(
//                       (states) => Colors.blue[900]!,
//                     ),
//                   ),
//                   const Text("Done", style: TextStyle(fontSize: 16)),
//                   const SizedBox(width: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const TrackingScreen(),
//                         ),
//                       );
//                     },
//                     child: const Text("View Details"),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }






































// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'track1.dart';
// class WelcomeScreen extends StatefulWidget {
//   const WelcomeScreen({super.key});

//   @override
//   State<WelcomeScreen> createState() => _WelcomeScreenState();
// }

// class _WelcomeScreenState extends State<WelcomeScreen> {
//   DateTime? lastPeriodDate;
//   bool agreed = false;

//   String getPregnancyInfo() {
//     if (lastPeriodDate == null) return "";
//     final weeks = DateTime.now().difference(lastPeriodDate!).inDays ~/ 7;
//     return "Congratulations!\nYou're $weeks week${weeks == 1 ? '' : 's'} pregnant";
//   }

//   DateTime getDueDate() {
//     if (lastPeriodDate == null) return DateTime.now();
//     return lastPeriodDate!.add(const Duration(days: 280));
//   }

//   void saveToFirebaseAndNavigate() async {
//     if (lastPeriodDate == null) return;
//     final weeks = DateTime.now().difference(lastPeriodDate!).inDays ~/ 7;

//     await FirebaseFirestore.instance.collection('pregnancies').add({
//       'lastPeriod': lastPeriodDate!.toIso8601String(),
//       'dueDate': getDueDate().toIso8601String(),
//       'weeksPregnant': weeks,
//       'timestamp': FieldValue.serverTimestamp(),
//     });

//     // Navigate to week tracker screen with current week
//    Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => WeekTrackerScreen(
//       currentWeek: weeks),
//   ),
// );

//   }

//   @override
//   Widget build(BuildContext context) {
//     final dueDate = getDueDate();
//     final dateFormat = DateFormat('MMM dd, yyyy');

//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             Image.asset('assets/baby_mother.jpg'),
//             const SizedBox(height: 10),
//             const Text("Welcome to Pregnancy Tracker!", style: TextStyle(fontSize: 20)),
//             const SizedBox(height: 20),
//             ListTile(
//               title: const Text("Last period started"),
//               trailing: Text(lastPeriodDate != null ? dateFormat.format(lastPeriodDate!) : 'Select'),
//               onTap: () async {
//                 final picked = await showDatePicker(
//                   context: context,
//                   initialDate: DateTime.now(),
//                   firstDate: DateTime(2020),
//                   lastDate: DateTime.now(),
//                 );
//                 if (picked != null) setState(() => lastPeriodDate = picked);
//               },
//             ),
//             if (lastPeriodDate != null)
//               ListTile(
//                 title: const Text("Due date"),
//                 trailing: Text(dateFormat.format(dueDate)),
//               ),
//             if (lastPeriodDate != null)
//               Container(
//                 margin: const EdgeInsets.all(12),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   border: Border.all(color: Colors.green),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(getPregnancyInfo(), textAlign: TextAlign.center),
//               ),
//             Row(
//               children: [
//                 Checkbox(value: agreed, onChanged: (val) => setState(() => agreed = val!)),
//                 const Expanded(
//                   child: Text.rich(TextSpan(children: [
//                     TextSpan(text: "I confirm that I’m at least 16 years old and I have read "),
//                     TextSpan(text: "Terms & Conditions", style: TextStyle(decoration: TextDecoration.underline)),
//                     TextSpan(text: " and "),
//                     TextSpan(text: "Privacy Policy", style: TextStyle(decoration: TextDecoration.underline)),
//                     TextSpan(text: "."),
//                   ])),
//                 )
//               ],
//             ),
//             ElevatedButton(
//   onPressed: (lastPeriodDate != null && agreed)
//       ? () {
//           saveToFirebaseAndNavigate();
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const WeekTrackerScreen(),
//             ),
//           );
//         }
//       : null,
//   style: ElevatedButton.styleFrom(
//     backgroundColor: Colors.green,
//     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//   ),
//   child: const Text("Done"),
// )

//           ],
//         ),
//       ),
//     );
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';

// class TrackerScreen extends StatefulWidget {
//   @override
//   _TrackerScreenState createState() => _TrackerScreenState();
// }

// class _TrackerScreenState extends State<TrackerScreen> {
//   DateTime? _lastPeriodDate;
//   DateTime? _dueDate;
//   int _currentWeek = 0;
//   bool _termsAccepted = false;

//   @override
//   void initState() {
//     super.initState();
//     Firebase.initializeApp(); // initialize Firebase here if not done in main.dart
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );

//     if (picked != null && picked != _lastPeriodDate) {
//       setState(() {
//         _lastPeriodDate = picked;
//         _calculatePregnancyWeek();
//       });
//     }
//   }

//   void _calculatePregnancyWeek() {
//     if (_lastPeriodDate != null) {
//       final today = DateTime.now();
//       final difference = today.difference(_lastPeriodDate!).inDays;
//       _currentWeek = (difference / 7).floor();
//       _dueDate = _lastPeriodDate!.add(const Duration(days: 280));
//     }
//   }

//   Future<void> _saveData() async {
//     if (_lastPeriodDate == null) return;

//     final weekData = {
//       'lastPeriodDate': _lastPeriodDate!.toIso8601String(),
//       'dueDate': _dueDate?.toIso8601String(),
//       'currentWeek': _currentWeek,
//       'savedAt': DateTime.now().toIso8601String(),
//     };

//     try {
//       await FirebaseFirestore.instance
//           .collection('pregnancy_weeks')
//           .add(weekData);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Your pregnancy data has been saved'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Error saving data'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Tracker'),
//         backgroundColor: Colors.pink[200],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Welcome to Pregnancy Tracker!',
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                       color: Colors.pink,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 24),

//               // Last Period Selection
//               GestureDetector(
//                 onTap: () => _selectDate(context),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Last period started'),
//                     const SizedBox(height: 4),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 12, horizontal: 16),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             _lastPeriodDate != null
//                                 ? DateFormat('MMM d, y')
//                                     .format(_lastPeriodDate!)
//                                 : 'Select date',
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                           const Icon(Icons.calendar_today, size: 20),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Due Date Display
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('Estimated due date'),
//                   const SizedBox(height: 4),
//                   Text(
//                     _dueDate != null
//                         ? DateFormat('MMM d, y').format(_dueDate!)
//                         : '--',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.pink,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),

//               // Pregnancy Progress
//               if (_currentWeek > 0) ...[
//                 Center(
//                   child: Column(
//                     children: [
//                       Text(
//                         'Congratulations!',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               color: Colors.blue[900],
//                             ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'You\'re $_currentWeek week${_currentWeek != 1 ? 's' : ''} pregnant',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 LinearProgressIndicator(
//                   value: _currentWeek / 40,
//                   minHeight: 12,
//                   backgroundColor: Colors.grey[200],
//                   valueColor:
//                       const AlwaysStoppedAnimation<Color>(Colors.blue),
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Week $_currentWeek',
//                         style: const TextStyle(color: Colors.blue)),
//                     Text('Week 40', style: TextStyle(color: Colors.grey[600])),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//               ],

//               // Terms Agreement
//               Row(
//                 children: [
//                   Checkbox(
//                     value: _termsAccepted,
//                     onChanged: (value) =>
//                         setState(() => _termsAccepted = value ?? false),
//                     fillColor: MaterialStateProperty.resolveWith<Color>(
//                       (states) => Colors.blue,
//                     ),
//                   ),
//                   const Expanded(
//                     child: Text(
//                       'I confirm that I\'m at least 16 years old and agree to the Terms & Conditions.',
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),

//               // Save Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _termsAccepted && _lastPeriodDate != null
//                       ? _saveData
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[900],
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Done',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
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
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
// import 'dart:convert'; // Added for jsonEncode/jsonDecode
// import '../notifications/notification_screen.dart'; // Adjust the import path as needed

// class PregnancyTrackerScreen extends StatefulWidget {
//   @override
//   _PregnancyTrackerScreenState createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   DateTime? _dueDate;
//   int _currentWeek = 0;
//   bool _termsAccepted = false;
  
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _notificationsPlugin = 
//       FlutterLocalNotificationsPlugin();

//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//     _setupNotificationListeners();
//   }

//   Future<void> _initializeApp() async {
//     tz.initializeTimeZones();
//     await _setupNotifications();
//     await _loadSavedData();
//   }

//   Future<void> _setupNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: androidSettings);
    
//     await _notificationsPlugin.initialize(initializationSettings);
    
//     // Create notification channel for Android 8.0+
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'pregnancy_channel_id',
//       'Pregnancy Updates',
//       description: 'Notifications for pregnancy progress',
//       importance: Importance.high,
//     );
    
//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
    
//     // Request notification permissions
//     await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//   }

//   Future<void> _setupNotificationListeners() async {
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _saveNotification(message);
//     });

//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       _handleNotificationOpen(message);
//     });

//     FirebaseMessaging.instance.getInitialMessage().then((message) {
//       if (message != null) _handleNotificationOpen(message);
//     });
//   }

//   Future<void> _saveNotification(RemoteMessage message) async {
//     final notification = {
//       'title': message.notification?.title ?? 'Pregnancy Update',
//       'body': message.notification?.body ?? 'New update available',
//       'date': DateTime.now().toIso8601String(),
//       'read': false,
//     };

//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList('pregnancy_notifications') ?? [];
//     saved.add(jsonEncode(notification));
//     await prefs.setStringList('pregnancy_notifications', saved);
//   }

//   Future<void> _handleNotificationOpen(RemoteMessage message) async {
//     final notification = {
//       'title': message.notification?.title ?? 'Pregnancy Update',
//       'body': message.notification?.body ?? 'New update available',
//       'date': DateTime.now().toIso8601String(),
//       'read': true,
//     };

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => NotificationDetail(notification: notification),
//       ),
//     );
//   }

//   Future<void> _loadSavedData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _lastPeriodDate = prefs.getString('lastPeriodDate') != null 
//           ? DateTime.parse(prefs.getString('lastPeriodDate')!) 
//           : null;
//       _termsAccepted = prefs.getBool('termsAccepted') ?? false;
      
//       if (_lastPeriodDate != null) {
//         _calculatePregnancy();
//       }
//     });
//   }

//   void _calculatePregnancy() {
//     if (_lastPeriodDate == null) return;
    
//     final now = DateTime.now();
//     final difference = now.difference(_lastPeriodDate!).inDays;
//     final weeks = (difference / 7).floor();
    
//     setState(() {
//       _currentWeek = weeks.clamp(1, 40);
//       _dueDate = _lastPeriodDate!.add(const Duration(days: 280)); // 40 weeks
//     });
    
//     _scheduleWeeklyNotifications();
//   }

//   Future<void> _scheduleWeeklyNotifications() async {
//     if (_lastPeriodDate == null || _currentWeek >= 40) return;
    
//     await _notificationsPlugin.cancelAll();
    
//     for (int week = _currentWeek + 1; week <= 40; week++) {
//       final notificationDate = _lastPeriodDate!.add(Duration(days: week * 7));
      
//       if (notificationDate.isAfter(DateTime.now())) {
//         await _scheduleWeekNotification(week, notificationDate);
//       }
//     }
//   }

//   Future<void> _scheduleWeekNotification(int week, DateTime date) async {
//     final notification = {
//       'id': week,
//       'title': 'Week $week Pregnancy Update',
//       'body': 'You are now $week weeks pregnant. Tap to see what\'s happening with your baby this week!',
//       'date': date.toIso8601String(),
//       'read': false,
//       'week': week,
//     };

//     // Save notification
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList('pregnancy_notifications') ?? [];
//     saved.add(jsonEncode(notification));
//     await prefs.setStringList('pregnancy_notifications', saved);

//     // Schedule notification
//     final androidDetails = AndroidNotificationDetails(
//       'pregnancy_channel',
//       'Pregnancy Updates',
//       importance: Importance.high,
//       priority: Priority.high,
//       enableVibration: true,
//     );

     

// //     await _notificationsPlugin.zonedSchedule(
// //   week,
// //   notification['title'],
// //   notification['body'],
// //   tz.TZDateTime.from(date, tz.local),
// //   NotificationDetails(android: androidDetails),
// //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ REQUIRED in latest versions
// //   payload: jsonEncode(notification),
// // );


//     // await _notificationsPlugin.zonedSchedule(
//     //   week,
//     //   notification['title'],
//     //   notification['body'],
//     //   tz.TZDateTime.from(date, tz.local),
//     //   NotificationDetails(android: androidDetails),
//     //   //androidAllowWhileIdle: true,
//     //   //uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//     //   payload: jsonEncode(notification),
//     // );
//   }

//   Future<void> _saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lastPeriodDate', _lastPeriodDate!.toIso8601String());
//     await prefs.setBool('termsAccepted', _termsAccepted);
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _lastPeriodDate ?? DateTime.now(),
//       firstDate: DateTime.now().subtract(const Duration(days: 90)),
//       lastDate: DateTime.now(),
//     );
    
//     if (picked != null && picked != _lastPeriodDate) {
//       setState(() {
//         _lastPeriodDate = picked;
//         _calculatePregnancy();
//         _saveData();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Tracker'),
//         backgroundColor: Colors.pink[200],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Welcome to Pregnancy Tracker!',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     color: Colors.pink,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 24),
            
//             // Last Period Date Selection
//             GestureDetector(
//               onTap: () => _selectDate(context),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Last period started',
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 12,
//                       horizontal: 16,
//                     ),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           _lastPeriodDate != null
//                               ? DateFormat('MMM d, y').format(_lastPeriodDate!)
//                               : 'Select date',
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                         const Icon(Icons.calendar_today, size: 20),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Due Date Display
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Estimated due date',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _dueDate != null
//                       ? DateFormat('MMM d, y').format(_dueDate!)
//                       : '--',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.pink,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Pregnancy Progress
//             if (_currentWeek > 0) ...[
//               Center(
//                 child: Column(
//                   children: [
//                     Text(
//                       'Congratulations!',
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             color: Colors.pink,
//                           ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'You\'re $_currentWeek week${_currentWeek != 1 ? 's' : ''} pregnant',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               LinearProgressIndicator(
//                 value: _currentWeek / 40,
//                 minHeight: 12,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Week $_currentWeek',
//                     style: const TextStyle(color: Colors.pink),
//                   ),
//                   Text(
//                     'Week 40',
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//             ],
            
//             // Terms Agreement
//             Row(
//               children: [
//                 Checkbox(
//                   value: _termsAccepted,
//                   onChanged: (value) => setState(() => _termsAccepted = value ?? false),
//                   fillColor: MaterialStateProperty.resolveWith<Color>(
//                     (states) => Colors.pink,
//                   ),
//                 ),
//                 const Expanded(
//                   child: Text(
//                     'I confirm that I\'m at least 16 years old and agree to the Terms & Conditions.',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Save Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _termsAccepted && _lastPeriodDate != null
//                     ? () {
//                         _saveData();
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Your pregnancy data has been saved'),
//                             backgroundColor: Colors.pink,
//                           ),
//                         );
//                       }
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'SAVE',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






































// import 'package:flutter/material.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class PregnancyTrackerScreen extends StatefulWidget {
//   @override
//   _PregnancyTrackerScreenState createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? _lastPeriodDate;
//   DateTime? _dueDate;
//   int _currentWeek = 0;
//   bool _termsAccepted = false;
  
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _notificationsPlugin = 
//       FlutterLocalNotificationsPlugin();

//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     tz.initializeTimeZones();
//     await _setupNotifications();
//     await _loadSavedData();
//   }

//   Future<void> _setupNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: androidSettings);
    
//     await _notificationsPlugin.initialize(initializationSettings);
    
//     // Create notification channel for Android 8.0+
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'pregnancy_channel_id',
//       'Pregnancy Updates',
//       description: 'Notifications for pregnancy progress',
//       importance: Importance.high,
//     );
    
//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
    
//     // Request notification permissions
//     await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//   }

//   Future<void> _loadSavedData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _lastPeriodDate = prefs.getString('lastPeriodDate') != null 
//           ? DateTime.parse(prefs.getString('lastPeriodDate')!) 
//           : null;
//       _termsAccepted = prefs.getBool('termsAccepted') ?? false;
      
//       if (_lastPeriodDate != null) {
//         _calculatePregnancy();
//       }
//     });
//   }

//   void _calculatePregnancy() {
//     if (_lastPeriodDate == null) return;
    
//     final now = DateTime.now();
//     final difference = now.difference(_lastPeriodDate!).inDays;
//     final weeks = (difference / 7).floor();
    
//     setState(() {
//       _currentWeek = weeks.clamp(1, 40);
//       _dueDate = _lastPeriodDate!.add(const Duration(days: 280)); // 40 weeks
//     });
    
//     _scheduleWeeklyNotifications();
//   }

//   Future<void> _scheduleWeeklyNotifications() async {
//     if (_lastPeriodDate == null || _currentWeek >= 40) return;
    
//     await _notificationsPlugin.cancelAll();
    
//     for (int week = _currentWeek + 1; week <= 40; week++) {
//       final notificationDate = _lastPeriodDate!.add(Duration(days: week * 7));
      
//       if (notificationDate.isAfter(DateTime.now())) {
//         await _scheduleWeekNotification(week, notificationDate);
//       }
//     }
//   }

//   Future<void> _scheduleWeekNotification(int week, DateTime date) async {
//     final details = NotificationDetails(
//       android: AndroidNotificationDetails(
//         'pregnancy_schedule_channel',
//         'Pregnancy Schedule',
//         channelDescription: 'Weekly pregnancy updates',
//         importance: Importance.high,
//         priority: Priority.high,
//       ),
//     );
    
//     await _notificationsPlugin.zonedSchedule(
//       week, // Unique ID for each notification
//       'Week $week Update',
//       'You are now $week weeks pregnant!',
//       tz.TZDateTime.from(date, tz.local),
//       details,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       //uiLocalNotificationDateInterpretation: 
//         //  UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   Future<void> _saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lastPeriodDate', _lastPeriodDate!.toIso8601String());
//     await prefs.setBool('termsAccepted', _termsAccepted);
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _lastPeriodDate ?? DateTime.now(),
//       firstDate: DateTime.now().subtract(const Duration(days: 90)),
//       lastDate: DateTime.now(),
//     );
    
//     if (picked != null && picked != _lastPeriodDate) {
//       setState(() {
//         _lastPeriodDate = picked;
//         _calculatePregnancy();
//         _saveData();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Tracker'),
//         backgroundColor: Colors.pink[200],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Welcome to Pregnancy Tracker!',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     color: Colors.pink,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 24),
            
//             // Last Period Date Selection
//             GestureDetector(
//               onTap: () => _selectDate(context),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Last period started',
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 12,
//                       horizontal: 16,
//                     ),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           _lastPeriodDate != null
//                               ? DateFormat('MMM d, y').format(_lastPeriodDate!)
//                               : 'Select date',
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                         const Icon(Icons.calendar_today, size: 20),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Due Date Display
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Estimated due date',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _dueDate != null
//                       ? DateFormat('MMM d, y').format(_dueDate!)
//                       : '--',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.pink,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Pregnancy Progress
//             if (_currentWeek > 0) ...[
//               Center(
//                 child: Column(
//                   children: [
//                     Text(
//                       'Congratulations!',
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             color: Colors.pink,
//                           ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'You\'re $_currentWeek week${_currentWeek != 1 ? 's' : ''} pregnant',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               LinearProgressIndicator(
//                 value: _currentWeek / 40,
//                 minHeight: 12,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Week $_currentWeek',
//                     style: const TextStyle(color: Colors.pink),
//                   ),
//                   Text(
//                     'Week 40',
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//             ],
            
//             // Terms Agreement
//             Row(
//               children: [
//                 Checkbox(
//                   value: _termsAccepted,
//                   onChanged: (value) => setState(() => _termsAccepted = value ?? false),
//                   fillColor: MaterialStateProperty.resolveWith<Color>(
//                     (states) => Colors.pink,
//                   ),
//                 ),
//                 const Expanded(
//                   child: Text(
//                     'I confirm that I\'m at least 16 years old and agree to the Terms & Conditions.',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Save Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _termsAccepted && _lastPeriodDate != null
//                     ? () {
//                         _saveData();
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Your pregnancy data has been saved'),
//                             backgroundColor: Colors.pink,
//                           ),
//                         );
//                       }
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Done',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

























// import 'package:flutter/material.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class TrackerScreen extends StatefulWidget {
//   @override
//   _TrackerScreenState createState() => _TrackerScreenState();
// }

// class _TrackerScreenState extends State<TrackerScreen> {
//   DateTime? _lastPeriodDate;
//   DateTime? _dueDate;
//   int _currentWeek = 0;
//   bool _termsAccepted = false;
  
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   @override
//   void initState() {
//     super.initState();
//     tz.initializeTimeZones();
//     _loadSavedData();
//     _initNotifications();
//     _setupFirebase();
//     _createNotificationChannel();
//   }

//   Future<void> _createNotificationChannel() async {
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'pregnancy_channel',
//       'Pregnancy Updates',
//       description: 'Notifications for pregnancy week updates',
//       importance: Importance.max,
//     );
    
//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }

//   Future<void> _loadSavedData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _lastPeriodDate = prefs.getString('lastPeriodDate') != null 
//           ? DateTime.parse(prefs.getString('lastPeriodDate')!) 
//           : null;
//       _dueDate = prefs.getString('dueDate') != null 
//           ? DateTime.parse(prefs.getString('dueDate')!) 
//           : null;
//       _termsAccepted = prefs.getBool('termsAccepted') ?? false;
      
//       if (_lastPeriodDate != null) {
//         _calculatePregnancy();
//       }
//     });
//   }

//   Future<void> _initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
    
//     await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }

//   Future<void> _setupFirebase() async {
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
    
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showNotification(message);
//     });
    
//     String? token = await _firebaseMessaging.getToken();
//     debugPrint("Firebase Messaging Token: $token");
//   }

//   Future<void> _showNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'pregnancy_channel',
//       'Pregnancy Updates',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
    
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
    
//     await _flutterLocalNotificationsPlugin.show(
//       0,
//       message.notification?.title,
//       message.notification?.body,
//       platformChannelSpecifics,
//     );
//   }

//   void _calculatePregnancy() {
//     if (_lastPeriodDate == null) return;
    
//     final now = DateTime.now();
//     final difference = now.difference(_lastPeriodDate!).inDays;
//     final weeks = (difference / 7).floor();
    
//     setState(() {
//       _currentWeek = weeks.clamp(1, 40);
//       _dueDate = _lastPeriodDate!.add(const Duration(days: 280)); // 40 weeks
//     });
    
//     _scheduleWeeklyNotifications();
//   }

//   Future<void> _scheduleWeeklyNotifications() async {
//     if (_lastPeriodDate == null || _currentWeek >= 40) return;
    
//     await _flutterLocalNotificationsPlugin.cancelAll();
    
//     for (int week = _currentWeek + 1; week <= 40; week++) {
//       final notificationDate = _lastPeriodDate!.add(Duration(days: week * 7));
      
//       if (notificationDate.isAfter(DateTime.now())) {
//         await _scheduleNotification(
//           week,
//           'Week $week Update',
//           'You are now $week weeks pregnant!',
//           notificationDate,
//         );
//       }
//     }
//   }

//   Future<void> _scheduleNotification(
//     int id,
//     String title,
//     String body,
//     DateTime scheduledDate,
//   ) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'pregnancy_schedule',
//       'Scheduled Pregnancy Updates',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
    
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
    
//     await _flutterLocalNotificationsPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledDate, tz.local),
//       platformChannelSpecifics,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation: 
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   Future<void> _saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lastPeriodDate', _lastPeriodDate!.toIso8601String());
//     await prefs.setString('dueDate', _dueDate!.toIso8601String());
//     await prefs.setBool('termsAccepted', _termsAccepted);
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _lastPeriodDate ?? DateTime.now(),
//       firstDate: DateTime.now().subtract(const Duration(days: 90)),
//       lastDate: DateTime.now(),
//     );
    
//     if (picked != null && picked != _lastPeriodDate) {
//       setState(() {
//         _lastPeriodDate = picked;
//         _calculatePregnancy();
//         _saveData();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pregnancy Tracker'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             const Text(
//               'Welcome to Pregnancy Tracker!',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 30),
//             GestureDetector(
//               onTap: () => _selectDate(context),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Last period started',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   Text(
//                     _lastPeriodDate != null 
//                         ? DateFormat('MMM d, y').format(_lastPeriodDate!)
//                         : 'Select date',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.pink,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Due date',
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 Text(
//                   _dueDate != null 
//                       ? DateFormat('MMM d, y').format(_dueDate!)
//                       : '--',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.pink,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 30),
//             if (_currentWeek > 0 && _currentWeek <= 40) ...[
//               Center(
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Congratulations!',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.pink,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'You\'re $_currentWeek week${_currentWeek != 1 ? 's' : ''} pregnant',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               LinearProgressIndicator(
//                 value: _currentWeek / 40,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
//               ),
//               const SizedBox(height: 10),
//               Center(
//                 child: Text(
//                   '$_currentWeek of 40 weeks',
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               ),
//             ],
//             const SizedBox(height: 40),
//             Row(
//               children: [
//                 Checkbox(
//                   value: _termsAccepted,
//                   onChanged: (value) {
//                     setState(() {
//                       _termsAccepted = value ?? false;
//                       _saveData();
//                     });
//                   },
//                 ),
//                 const Expanded(
//                   child: Text(
//                     'I confirm that I\'m at least 16 years old and I have read Terms & Conditions and Privacy Policy.',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: ElevatedButton(
//                 onPressed: _termsAccepted && _lastPeriodDate != null
//                     ? () {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(content: Text('Data saved successfully!')),
//                         );
//                       }
//                     : null,
//                 child: const Text('Done'),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

































// import 'package:flutter/material.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class TrackerScreen extends StatefulWidget {
//   @override
//   _TrackerScreenState createState() => _TrackerScreenState();
// }

// class _TrackerScreenState extends State<TrackerScreen> {
//   DateTime? _lastPeriodDate;
//   DateTime? _dueDate;
//   int _currentWeek = 0;
//   bool _termsAccepted = false;
  
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   @override
//   void initState() {
//     super.initState();
//     tz.initializeTimeZones();
//     _loadSavedData();
//     _initNotifications();
//     _setupFirebase();
//   }

//   Future<void> _loadSavedData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _lastPeriodDate = prefs.getString('lastPeriodDate') != null 
//           ? DateTime.parse(prefs.getString('lastPeriodDate')!) 
//           : null;
//       _dueDate = prefs.getString('dueDate') != null 
//           ? DateTime.parse(prefs.getString('dueDate')!) 
//           : null;
//       _termsAccepted = prefs.getBool('termsAccepted') ?? false;
      
//       if (_lastPeriodDate != null) {
//         _calculatePregnancy();
//       }
//     });
//   }

//   Future<void> _initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
    
//     await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }

//   Future<void> _setupFirebase() async {
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
    
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showNotification(message);
//     });
    
//     String? token = await _firebaseMessaging.getToken();
//     debugPrint("Firebase Messaging Token: $token");
//   }

//   Future<void> _showNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'pregnancy_channel',
//       'Pregnancy Updates',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: false,
//     );
    
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
    
//     await _flutterLocalNotificationsPlugin.show(
//       0,
//       message.notification?.title,
//       message.notification?.body,
//       platformChannelSpecifics,
//       payload: 'pregnancy_update',
//     );
//   }

//   void _calculatePregnancy() {
//     if (_lastPeriodDate == null) return;
    
//     final now = DateTime.now();
//     final difference = now.difference(_lastPeriodDate!).inDays;
//     final weeks = (difference / 7).floor();
    
//     setState(() {
//       _currentWeek = weeks.clamp(1, 40);
//       _dueDate = _lastPeriodDate!.add(const Duration(days: 280)); // 40 weeks
//     });
    
//     _scheduleWeeklyNotifications();
//   }

//   Future<void> _scheduleWeeklyNotifications() async {
//     if (_lastPeriodDate == null || _currentWeek >= 40) return;
    
//     await _flutterLocalNotificationsPlugin.cancelAll();
    
//     for (int week = _currentWeek + 1; week <= 40; week++) {
//       final notificationDate = _lastPeriodDate!.add(Duration(days: week * 7));
      
//       if (notificationDate.isAfter(DateTime.now())) {
//         await _scheduleNotification(
//           week,
//           'Week $week Update',
//           'You are now $week weeks pregnant!',
//           notificationDate,
//         );
//       }
//     }
//   }

//   Future<void> _scheduleNotification(
//     int id,
//     String title,
//     String body,
//     DateTime scheduledDate,
//   ) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'pregnancy_schedule',
//       'Scheduled Pregnancy Updates',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
    
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
    
//     await _flutterLocalNotificationsPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledDate, tz.local),
//       platformChannelSpecifics,
//       androidAllowWhileIdle: true,
//      UILocalNotificationDateInterpretation.absoluteTime,
      
//     );
//   }

//   Future<void> _saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lastPeriodDate', _lastPeriodDate!.toIso8601String());
//     await prefs.setString('dueDate', _dueDate!.toIso8601String());
//     await prefs.setBool('termsAccepted', _termsAccepted);
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _lastPeriodDate ?? DateTime.now(),
//       firstDate: DateTime.now().subtract(const Duration(days: 90)),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Colors.pink,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black,
//             ),
//             dialogBackgroundColor: Colors.white,
//           ),
//           child: child!,
//         );
//       },
//     );
    
//     if (picked != null && picked != _lastPeriodDate) {
//       setState(() {
//         _lastPeriodDate = picked;
//         _calculatePregnancy();
//         _saveData();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text('Pregnancy Tracker'),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.pink,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Welcome to Pregnancy Tracker!',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.pink,
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     _buildDateSelector(),
//                     const SizedBox(height: 20),
//                     _buildDueDateDisplay(),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 25),
//             if (_currentWeek > 0 && _currentWeek <= 40) _buildPregnancyProgress(),
//             const SizedBox(height: 30),
//             _buildTermsAgreement(),
//             const SizedBox(height: 20),
//             _buildSaveButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Last period started',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         InkWell(
//           onTap: () => _selectDate(context),
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey[300]!),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   _lastPeriodDate != null 
//                       ? DateFormat('MMM d, y').format(_lastPeriodDate!)
//                       : 'Select date',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const Icon(Icons.calendar_today, size: 20),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDueDateDisplay() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Estimated due date',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           _dueDate != null 
//               ? DateFormat('MMM d, y').format(_dueDate!)
//               : '--',
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.pink,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPregnancyProgress() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             const Text(
//               'Congratulations!',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.pink,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'You\'re $_currentWeek week${_currentWeek != 1 ? 's' : ''} pregnant',
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 20),
//             LinearProgressIndicator(
//               value: _currentWeek / 40,
//               minHeight: 12,
//               backgroundColor: Colors.grey[200],
//               valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Week $_currentWeek',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.pink,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   'Week 40',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTermsAgreement() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(15.0),
//         child: Row(
//           children: [
//             Transform.scale(
//               scale: 1.2,
//               child: Checkbox(
//                 value: _termsAccepted,
//                 onChanged: (value) {
//                   setState(() {
//                     _termsAccepted = value ?? false;
//                     _saveData();
//                   });
//                 },
//                 activeColor: Colors.pink,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: RichText(
//                 text: const TextSpan(
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.black87,
//                     height: 1.4,
//                   ),
//                   children: [
//                     TextSpan(text: 'I confirm that I\'m at least 16 years old and I have read '),
//                     TextSpan(
//                       text: 'Terms & Conditions',
//                       style: TextStyle(
//                         color: Colors.pink,
//                         decoration: TextDecoration.underline,
//                       ),
//                     ),
//                     TextSpan(text: ' and '),
//                     TextSpan(
//                       text: 'Privacy Policy',
//                       style: TextStyle(
//                         color: Colors.pink,
//                         decoration: TextDecoration.underline,
//                       ),
//                     ),
//                     TextSpan(text: '.'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSaveButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _termsAccepted && _lastPeriodDate != null
//             ? () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Data saved successfully!'),
//                     backgroundColor: Colors.pink,
//                   ),
//                 );
//               }
//             : null,
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           backgroundColor: Colors.pink,
//           disabledBackgroundColor: Colors.pink.withOpacity(0.5),
//         ),
//         child: const Text(
//           'DONE',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }

































// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';



// class PregnancyTrackerScreen extends StatefulWidget {
//   @override
//   _PregnancyTrackerScreenState createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   DateTime? lastPeriodDate;
//   DateTime? dueDate;
//   int currentWeek = 0;
//   bool termsAccepted = false;
  
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedData();
//     _initNotifications();
//     _setupFirebase();
//   }

//   Future<void> _loadSavedData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       lastPeriodDate = prefs.getString('lastPeriodDate') != null 
//           ? DateTime.parse(prefs.getString('lastPeriodDate')!) 
//           : null;
//       dueDate = prefs.getString('dueDate') != null 
//           ? DateTime.parse(prefs.getString('dueDate')!) 
//           : null;
//       termsAccepted = prefs.getBool('termsAccepted') ?? false;
      
//       if (lastPeriodDate != null) {
//         _calculatePregnancy();
//       }
//     });
//   }

//   Future<void> _initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
    
//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }

//   Future<void> _setupFirebase() async {
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
    
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showNotification(message);
//     });
    
//     // Get token for sending notifications from server
//     String? token = await _firebaseMessaging.getToken();
//     print("Firebase Messaging Token: $token");
//   }

//   Future<void> _showNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'pregnancy_channel',
//       'Pregnancy Updates',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: false,
//     );
    
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
    
//     await flutterLocalNotificationsPlugin.show(
//       0,
//       message.notification?.title,
//       message.notification?.body,
//       platformChannelSpecifics,
//       payload: 'item x',
//     );
//   }

//   void _calculatePregnancy() {
//     if (lastPeriodDate == null) return;
    
//     final now = DateTime.now();
//     final difference = now.difference(lastPeriodDate!).inDays;
//     final weeks = (difference / 7).floor();
    
//     setState(() {
//       currentWeek = weeks.clamp(1, 40);
//       dueDate = lastPeriodDate!.add(Duration(days: 280)); // 40 weeks
//     });
    
//     // Schedule weekly notifications
//     _scheduleWeeklyNotifications();
//   }

//   Future<void> _scheduleWeeklyNotifications() async {
//     if (lastPeriodDate == null || currentWeek >= 40) return;
    
//     // Cancel all previous notifications
//     await flutterLocalNotificationsPlugin.cancelAll();
    
//     // Schedule notifications for each remaining week
//     for (int week = currentWeek + 1; week <= 40; week++) {
//       final notificationDate = lastPeriodDate!.add(Duration(days: week * 7));
      
//       if (notificationDate.isAfter(DateTime.now())) {
//         await _scheduleNotification(
//           week,
//           'Week $week Update',
//           'You are now $week weeks pregnant!',
//           notificationDate,
//         );
//       }
//     }
//   }

//   Future<void> _scheduleNotification(
//     int id,
//     String title,
//     String body,
//     DateTime scheduledDate,
//   ) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'pregnancy_schedule',
//       'Scheduled Pregnancy Updates',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
    
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
    
//     await flutterLocalNotificationsPlugin.schedule(
//       id,
//       title,
//       body,
//       scheduledDate,
//       platformChannelSpecifics,
//       androidAllowWhileIdle: true,
//     );
//   }

//   Future<void> _saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lastPeriodDate', lastPeriodDate!.toIso8601String());
//     await prefs.setString('dueDate', dueDate!.toIso8601String());
//     await prefs.setBool('termsAccepted', termsAccepted);
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: lastPeriodDate ?? DateTime.now(),
//       firstDate: DateTime.now().subtract(Duration(days: 90)),
//       lastDate: DateTime.now(),
//     );
    
//     if (picked != null && picked != lastPeriodDate) {
//       setState(() {
//         lastPeriodDate = picked;
//         _calculatePregnancy();
//         _saveData();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Pregnancy Tracker'),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Text(
//               'Welcome to Pregnancy Tracker!',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 30),
//             GestureDetector(
//               onTap: () => _selectDate(context),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Last period started',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   Text(
//                     lastPeriodDate != null 
//                         ? DateFormat('MMM d, y').format(lastPeriodDate!)
//                         : 'Select date',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.pink,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Due date',
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 Text(
//                   dueDate != null 
//                       ? DateFormat('MMM d, y').format(dueDate!)
//                       : '--',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.pink,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 30),
//             if (currentWeek > 0 && currentWeek <= 40) ...[
//               Center(
//                 child: Column(
//                   children: [
//                     Text(
//                       'Congratulations!',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.pink,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       'You\'re $currentWeek week${currentWeek != 1 ? 's' : ''} pregnant',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 20),
//               LinearProgressIndicator(
//                 value: currentWeek / 40,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
//               ),
//               SizedBox(height: 10),
//               Center(
//                 child: Text(
//                   '$currentWeek of 40 weeks',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//             ],
//             SizedBox(height: 40),
//             Row(
//               children: [
//                 Checkbox(
//                   value: termsAccepted,
//                   onChanged: (value) {
//                     setState(() {
//                       termsAccepted = value ?? false;
//                       _saveData();
//                     });
//                   },
//                 ),
//                 Expanded(
//                   child: Text(
//                     'I confirm that I\'m at least 16 years old and I have read Terms & Conditions and Privacy Policy.',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//             Center(
//               child: ElevatedButton(
//                 onPressed: termsAccepted && lastPeriodDate != null
//                     ? () {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Data saved successfully!')),
//                         );
//                       }
//                     : null,
//                 child: Text('Done'),
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//                 ),
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
// import 'package:firebase_auth/firebase_auth.dart';

// class PregnancyTrackerScreen extends StatefulWidget {
//   @override
//   _PregnancyTrackerScreenState createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _detailsController = TextEditingController();

//   bool isAllowed = false;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     checkUserPermission();
//   }

//   Future<void> checkUserPermission() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       final doc = await _firestore.collection('users').doc(user.uid).get();
//       if (doc.exists) {
//         final userData = doc.data() as Map<String, dynamic>?;
//         if (userData != null &&
//             userData['gender'] == 'Female' &&
//             userData['title'] == 'User') {
//           setState(() {
//             isAllowed = true;
//           });
//         }
//       }
//     }
//     setState(() {
//       isLoading = false;
//     });
//   }

//   Future<void> _addWeek() async {
//     final weekNumber = _weekController.text;
//     final details = _detailsController.text;

//     if (weekNumber.isEmpty || details.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill in all fields")),
//       );
//       return;
//     }

//     try {
//       await _firestore.collection('pregnancy_weeks').add({
//         'week': int.parse(weekNumber),
//         'details': details,
//         'userId': _auth.currentUser?.uid,
//         'timestamp': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Week added successfully!")),
//       );

//       _weekController.clear();
//       _detailsController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error adding week: ${e.toString()}")),
//       );
//     }
//   }

//   Future<void> _deleteWeek(String id) async {
//     try {
//       await _firestore.collection('pregnancy_weeks').doc(id).delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Week deleted successfully")),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error deleting week: ${e.toString()}")),
//       );
//     }
//   }

//   void _editWeek(String id, int week, String details) {
//     _weekController.text = week.toString();
//     _detailsController.text = details;

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Update Week'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: _weekController,
//               decoration: const InputDecoration(labelText: 'Week Number'),
//               keyboardType: TextInputType.number,
//             ),
//             TextField(
//               controller: _detailsController,
//               decoration: const InputDecoration(labelText: 'Details'),
//               maxLines: 2,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: const Text('Cancel'),
//             onPressed: () => Navigator.pop(context),
//           ),
//           ElevatedButton(
//             child: const Text('Update'),
//             onPressed: () async {
//               try {
//                 await _firestore.collection('pregnancy_weeks').doc(id).update({
//                   'week': int.parse(_weekController.text),
//                   'details': _detailsController.text,
//                   'timestamp': FieldValue.serverTimestamp(),
//                 });
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Week updated successfully!")),
//                 );
//                 _weekController.clear();
//                 _detailsController.clear();
//                 Navigator.pop(context);
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text("Error updating week: ${e.toString()}")),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text("Pregnancy Tracker")),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (!isAllowed) {
//       return Scaffold(
//         appBar: AppBar(title: const Text("Pregnancy Tracker")),
//         body: const Center(
//           child: Text("Access denied. This section is only for female users."),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Pregnancy Tracker')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _weekController,
//                   decoration: const InputDecoration(labelText: 'Week Number'),
//                   keyboardType: TextInputType.number,
//                 ),
//                 TextField(
//                   controller: _detailsController,
//                   decoration: const InputDecoration(labelText: 'Details'),
//                   maxLines: 2,
//                 ),
//                 const SizedBox(height: 8),
//                 ElevatedButton(
//                   onPressed: _addWeek,
//                   child: const Text('Add Week'),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('pregnancy_weeks')
//                   .where('userId', isEqualTo: _auth.currentUser?.uid)
//                   //.orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text('No pregnancy weeks added yet'));
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = snapshot.data!.docs[index];
//                     final data = doc.data() as Map<String, dynamic>;
//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         title: Text('Week ${data['week']}'),
//                         subtitle: Text(data['details']),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.edit, color: Colors.blue),
//                               onPressed: () => _editWeek(
//                                 doc.id, 
//                                 data['week'], 
//                                 data['details']
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                               onPressed: () => _deleteWeek(doc.id),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _weekController.dispose();
//     _detailsController.dispose();
//     super.dispose();
//   }
// }

































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class PregnancyTrackerScreen extends StatefulWidget {
//   @override
//   _PregnancyTrackerScreenState createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _detailsController = TextEditingController();

//   bool isAllowed = false;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     checkUserPermission();
//   }

//   Future<void> checkUserPermission() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       final doc = await _firestore.collection('users').doc(user.uid).get();
//       if (doc.exists) {
//         final userData = doc.data();
//         print("UserData: $userData");
//         if (userData != null &&
//             userData['gender'] == 'Female' &&
//             userData['title'] == 'User') {
//           setState(() {
//             isAllowed = true;
//           });
//         }
//       }
//     }
//     setState(() {
//       isLoading = false;
//     });
//   }

//   void addWeek() async {
//   final weekNumber = _weekNumberController.text;
//   final details = _detailsController.text;

//   if (weekNumber.isEmpty || details.isEmpty) {
//     // Show validation error
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Please fill in all fields")),
//     );
//     return;
//   }

//   await FirebaseFirestore.instance.collection('weeks').add({
//     'weekNumber': int.parse(weekNumber),
//     'details': details,
//     'createdAt': Timestamp.now(),
//     'userId': FirebaseAuth.instance.currentUser?.uid,
//   });

//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text("Week added successfully!")),
//   );

//   _weekNumberController.clear();
//   _detailsController.clear();
// }


//   void _deleteWeek(String id) async {
//     await _firestore.collection('weeks').doc(id).delete();
//   }

//   void _editWeek(String id, String week, String details) {
//     _weekController.text = week;
//     _detailsController.text = details;

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Update Week'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(controller: _weekController, decoration: InputDecoration(labelText: 'Week')),
//             TextField(controller: _detailsController, decoration: InputDecoration(labelText: 'Details')),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: Text('Cancel'),
//             onPressed: () => Navigator.pop(context),
//           ),
//           ElevatedButton(
//             child: Text('Update'),
//             onPressed: () async {
//               await _firestore.collection('weeks').doc(id).update({
//                 'week': _weekController.text,
//                 'details': _detailsController.text,
//               });
//               _weekController.clear();
//               _detailsController.clear();
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: Text("Pregnancy Tracker")),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (!isAllowed) {
//       return Scaffold(
//         appBar: AppBar(title: Text("Pregnancy Tracker")),
//         body: Center(
//           child: Text("Access denied. This section is only for female users."),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text('Pregnancy Tracker')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _weekController,
//                   decoration: InputDecoration(labelText: 'Week Number'),
//                   keyboardType: TextInputType.number,
//                 ),
//                 TextField(
//                   controller: _detailsController,
//                   decoration: InputDecoration(labelText: 'Details'),
//                   maxLines: 2,
//                 ),
//                 SizedBox(height: 8),
//                 ElevatedButton(
//                   onPressed: _addWeek,
//                   child: Text('Add Week'),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('pregnancy_weeks')
//                   .where('userId', isEqualTo: _auth.currentUser?.uid)
//                   .orderBy('timestamp')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
//                 final docs = snapshot.data!.docs;
//                 return ListView.builder(
//                   itemCount: docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = docs[index];
//                     final data = doc.data() as Map<String, dynamic>;
//                     return Card(
//                       margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         title: Text('Week ${data['week']}'),
//                         subtitle: Text(data['details']),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.edit, color: Colors.blue),
//                               onPressed: () => _editWeek(doc.id, data['week'], data['details']),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.delete, color: Colors.red),
//                               onPressed: () => _deleteWeek(doc.id),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
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
// import 'package:firebase_auth/firebase_auth.dart';

// class PregnancyTrackerScreen extends StatefulWidget {
//   @override
//   _PregnancyTrackerScreenState createState() => _PregnancyTrackerScreenState();
// }

// class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   final TextEditingController _weekController = TextEditingController();
//   final TextEditingController _detailsController = TextEditingController();

//   bool isAllowed = false;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     checkUserPermission();
//   }

//   Future<void> checkUserPermission() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       final email = user.email;
//       final query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();

//       if (query.docs.isNotEmpty) {
//         final userData = query.docs.first.data();
//         if (userData['gender'] == 'female') {
//           setState(() {
//             isAllowed = true;
//           });
//         }
//       }
//     }
//     setState(() {
//       isLoading = false;
//     });
//   }

//   void _addWeek() async {
//     if (_weekController.text.isNotEmpty && _detailsController.text.isNotEmpty) {
//       await _firestore.collection('pregnancy_weeks').add({
//         'week': _weekController.text,
//         'details': _detailsController.text,
//         'email': _auth.currentUser?.email,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//       _weekController.clear();
//       _detailsController.clear();
//     }
//   }

//   void _deleteWeek(String id) async {
//     await _firestore.collection('pregnancy_weeks').doc(id).delete();
//   }

//   void _editWeek(String id, String week, String details) {
//     _weekController.text = week;
//     _detailsController.text = details;

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Update Week'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(controller: _weekController, decoration: InputDecoration(labelText: 'Week')),
//             TextField(controller: _detailsController, decoration: InputDecoration(labelText: 'Details')),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: Text('Cancel'),
//             onPressed: () => Navigator.pop(context),
//           ),
//           ElevatedButton(
//             child: Text('Update'),
//             onPressed: () async {
//               await _firestore.collection('pregnancy_weeks').doc(id).update({
//                 'week': _weekController.text,
//                 'details': _detailsController.text,
//               });
//               _weekController.clear();
//               _detailsController.clear();
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: Text("Pregnancy Tracker")),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (!isAllowed) {
//       return Scaffold(
//         appBar: AppBar(title: Text("Pregnancy Tracker")),
//         body: Center(
//           child: Text("Access denied. This section is only for female users."),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text('Pregnancy Tracker')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _weekController,
//                   decoration: InputDecoration(labelText: 'Week Number'),
//                 ),
//                 TextField(
//                   controller: _detailsController,
//                   decoration: InputDecoration(labelText: 'Details'),
//                 ),
//                 SizedBox(height: 8),
//                 ElevatedButton(
//                   onPressed: _addWeek,
//                   child: Text('Add Week'),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('pregnancy_weeks')
//                   .where('email', isEqualTo: _auth.currentUser?.email)
//                   .orderBy('timestamp')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
//                 final docs = snapshot.data!.docs;
//                 return ListView.builder(
//                   itemCount: docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = docs[index];
//                     final data = doc.data() as Map<String, dynamic>;
//                     return Card(
//                       margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         title: Text('Week ${data['week']}'),
//                         subtitle: Text(data['details']),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.edit, color: Colors.blue),
//                               onPressed: () => _editWeek(doc.id, data['week'], data['details']),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.delete, color: Colors.red),
//                               onPressed: () => _deleteWeek(doc.id),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
