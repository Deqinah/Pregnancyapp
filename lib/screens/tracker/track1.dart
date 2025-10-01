import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class TrackerDetailScreen extends StatefulWidget {
  final int pregnancyWeek;
  final DateTime lastPeriodDate;

  const TrackerDetailScreen({
    super.key,
    required this.pregnancyWeek,
    required this.lastPeriodDate,
  });

  @override
  State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
}

class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
  late int _currentWeek;
  late DateTime _lastPeriodDate;
  Timer? _weekUpdateTimer;
  bool _isEditingWeek = false;
  final TextEditingController _weekController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _editWeekDate;
  DateTime? _weekSelectedDate;

  // Colors
  final Color primaryColor = const Color(0xFF344CB7); // Deep Indigo
  final Color accentColor = const Color(0xFF3DDAD7); // Mint Green
  final Color bgColor = Colors.white; // Clean White
  final Color darkText = const Color(0xFF2E2E2E); // Charcoal

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.pregnancyWeek;
    _lastPeriodDate = widget.lastPeriodDate;
    _weekSelectedDate = _calculateWeekStartDate(_currentWeek);
    _loadWeekSelectionDate();
    _startWeekUpdateChecker();
  }

  Future<void> _loadWeekSelectionDate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final trackerDoc = await _getUserTrackerDoc(user.uid);
      if (trackerDoc == null) return;

      final data = trackerDoc.data() as Map<String, dynamic>;
      if (data['weekSelectedDate'] != null) {
        setState(() {
          _weekSelectedDate = data['weekSelectedDate'].toDate();
        });
      }
    } catch (e) {
      debugPrint('Error loading week selection date: $e');
    }
  }

  void _startWeekUpdateChecker() {
    _checkForWeekUpdate();
    _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkForWeekUpdate();
    });
  }

 Future<void> _checkForWeekUpdate() async {
  if (!mounted) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final trackerDoc = await _getUserTrackerDoc(user.uid);
    if (trackerDoc == null) return;

    final data = trackerDoc.data() as Map<String, dynamic>;
    final lastUpdate = data['weekSelectedDate']?.toDate();
    final lastPeriodDate = data['lastPeriodDate']?.toDate();

    if (lastUpdate != null && lastPeriodDate != null) {
      final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
      final calculatedWeek = _calculateCurrentWeek(lastPeriodDate);

      if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
        final weekStartDate = _calculateWeekStartDate(calculatedWeek);
        await _updateWeekInFirestore(trackerDoc.reference, calculatedWeek, weekStartDate);
        
        if (mounted) {
          setState(() {
            _currentWeek = calculatedWeek;
            _weekSelectedDate = weekStartDate;
          });
          _showSuccessMessage('🎉 Congratulations! You are now in week $calculatedWeek');
        }
      }
    }
  } catch (e) {
    debugPrint('Week update error: $e');
    if (mounted) {
      _showErrorMessage('Failed to check for week updates');
    }
  }
}

  Future<DocumentSnapshot?> _getUserTrackerDoc(String userId) async {
    final trackerQuery = await FirebaseFirestore.instance
        .collection('trackingweeks')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return trackerQuery.docs.isEmpty ? null : trackerQuery.docs.first;
  }

  int _calculateCurrentWeek(DateTime lastPeriodDate) {
    return (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);
  }

  Future<void> _updateWeekInFirestore(
  DocumentReference docRef, 
  int newWeek,
  DateTime weekStartDate,
) async {
  await docRef.update({
    'currentWeek': newWeek,
    'weekSelectedDate': Timestamp.fromDate(weekStartDate),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

  void _toggleEditWeek() {
    setState(() {
      _isEditingWeek = !_isEditingWeek;
      if (_isEditingWeek) {
        _weekController.text = _currentWeek.toString();
        _editWeekDate = _weekSelectedDate;
      }
    });
  }

  DateTime _calculateWeekStartDate(int week) {
    return _lastPeriodDate.add(Duration(days: (week + 1) * 7));
  }

  int _getCurrentDayInWeek() {
    if (_weekSelectedDate == null) return 1;
    return DateTime.now().difference(_weekSelectedDate!).inDays.clamp(0, 6) + 1;
  }

  Future<void> _saveEditedWeek() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newWeek = int.tryParse(_weekController.text) ?? _currentWeek;
    if (newWeek < 1 || newWeek > 40) {
      _showErrorMessage('Please enter a week between 1 and 40');
      return;
    }

    try {
      final trackerDoc = await _getUserTrackerDoc(user.uid);
      if (trackerDoc == null) return;

      final weekStartDate = _editWeekDate ?? _calculateWeekStartDate(newWeek);
      
      await _updateWeekInFirestore(trackerDoc.reference, newWeek, weekStartDate);

      setState(() {
        _currentWeek = newWeek;
        _weekSelectedDate = weekStartDate;
        _isEditingWeek = false;
      });

      _showSuccessMessage('Week updated successfully!');
    } catch (e) {
      _showErrorMessage('Failed to update week: ${e.toString()}');
    }
  }

  Future<void> _selectWeekDate(BuildContext context) async {
    final initialDate = _editWeekDate ?? _calculateWeekStartDate(_currentWeek);
    final firstDate = _lastPeriodDate;
    final lastDate = _lastPeriodDate.add(const Duration(days: 40 * 7));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: bgColor,
              onSurface: darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _editWeekDate = pickedDate;
        // Calculate the week based on the selected date
        final daysDifference = pickedDate.difference(_lastPeriodDate).inDays;
        _currentWeek = (daysDifference / 7).floor() + 1;
        _weekController.text = _currentWeek.toString();
      });
    }
  }

  // Modern Card with new colors
  Widget _modernCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, accentColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }

Widget _buildWeekInfoCard() {
    return _modernCard(
      child: Column(
        children: [
          if (_isEditingWeek) ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _weekController,
                    keyboardType: TextInputType.number,
                    readOnly: true,  // This makes the field read-only
                    decoration: InputDecoration(
                      labelText: 'Current Week',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.calendar_today, color: accentColor),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a week number';
                      }
                      final week = int.tryParse(value);
                      if (week == null || week < 1 || week > 40) {
                        return 'Enter a week between 1-40';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectWeekDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: accentColor),
                          const SizedBox(width: 10),
                          Text(
                            _editWeekDate != null
                                ? DateFormat('MMM d, y').format(_editWeekDate!)
                                : 'Select week start date',
                            style: TextStyle(color: darkText),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                        ),
                        onPressed: _toggleEditWeek,
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        onPressed: _saveEditedWeek,
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Week $_currentWeek',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Day ${_getCurrentDayInWeek()} of week $_currentWeek',
              style: TextStyle(
                fontSize: 16,
                color: darkText.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You are in the ${_getTrimester()}',
              style: TextStyle(
                fontSize: 16,
                color: darkText.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _currentWeek / 40,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${((_currentWeek / 40) * 100).toStringAsFixed(1)}% completed',
              style: TextStyle(
                fontSize: 14,
                color: darkText.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
  String _getTrimester() {
    if (_currentWeek <= 12) return '1st Trimester';
    if (_currentWeek <= 27) return '2nd Trimester';
    return '3rd Trimester';
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
       leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      title: const Text(
        'Pregnancy Tracker',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: primaryColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(_isEditingWeek ? Icons.close : Icons.edit, color: Colors.white),
          onPressed: _toggleEditWeek,
        ),
      ],
    );
  }

  Widget _buildDevItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$title: $value',
                style: TextStyle(fontSize: 15, color: darkText)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, color: darkText)),
          ),
        ],
      ),
    );
  }

  String _getFruitSize() {
    const fruits = [
      'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry',
      'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon',
      'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
    ];
    return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
  }

  String _getBabyLength() {
    if (_currentWeek < 5) return 'Not measurable yet';
    const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
    return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
  }

  String _getBabyWeight() {
    if (_currentWeek < 6) return 'Not measurable yet';
    const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
    return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekInfoCard(),
            const SizedBox(height: 20),
            _modernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Baby Development',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 12),
                  _buildDevItem(Icons.straighten, 'Size', 'About the size of a ${_getFruitSize()}'),
                  _buildDevItem(Icons.height, 'Length', _getBabyLength()),
                  _buildDevItem(Icons.monitor_weight, 'Weight', _getBabyWeight()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _modernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Helpful Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 12),
                  _buildTipItem(Icons.medical_services, 'Take prenatal vitamins daily'),
                  _buildTipItem(Icons.local_drink, 'Stay hydrated (8-12 glasses/day)'),
                  _buildTipItem(Icons.directions_walk, '30 minutes of gentle exercise'),
                ],
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:async';
// import 'package:intl/intl.dart';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;
//   bool _isEditingWeek = false;
//   final TextEditingController _weekController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   DateTime? _editWeekDate;
//   DateTime? _weekSelectedDate;

//   // Colors
//   final Color primaryColor = const Color(0xFF344CB7); // Deep Indigo
//   final Color accentColor = const Color(0xFF3DDAD7); // Mint Green
//   final Color bgColor = Colors.white; // Clean White
//   final Color darkText = const Color(0xFF2E2E2E); // Charcoal

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _weekSelectedDate = _calculateWeekStartDate(_currentWeek);
//     _loadWeekSelectionDate();
//     _startWeekUpdateChecker();
//   }

//   Future<void> _loadWeekSelectionDate() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       final data = trackerDoc.data() as Map<String, dynamic>;
//       if (data['weekSelectedDate'] != null) {
//         setState(() {
//           _weekSelectedDate = data['weekSelectedDate'].toDate();
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading week selection date: $e');
//     }
//   }

//   void _startWeekUpdateChecker() {
//     _checkForWeekUpdate();
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//  Future<void> _checkForWeekUpdate() async {
//   if (!mounted) return;

//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) return;

//   try {
//     final trackerDoc = await _getUserTrackerDoc(user.uid);
//     if (trackerDoc == null) return;

//     final data = trackerDoc.data() as Map<String, dynamic>;
//     final lastUpdate = data['weekSelectedDate']?.toDate();
//     final lastPeriodDate = data['lastPeriodDate']?.toDate();

//     if (lastUpdate != null && lastPeriodDate != null) {
//       final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//       final calculatedWeek = _calculateCurrentWeek(lastPeriodDate);

//       if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//         final weekStartDate = _calculateWeekStartDate(calculatedWeek);
//         await _updateWeekInFirestore(trackerDoc.reference, calculatedWeek, weekStartDate);
        
//         if (mounted) {
//           setState(() {
//             _currentWeek = calculatedWeek;
//             _weekSelectedDate = weekStartDate;
//           });
//           _showSuccessMessage('🎉 Congratulations! You are now in week $calculatedWeek');
//         }
//       }
//     }
//   } catch (e) {
//     debugPrint('Week update error: $e');
//     if (mounted) {
//       _showErrorMessage('Failed to check for week updates');
//     }
//   }
// }

//   Future<DocumentSnapshot?> _getUserTrackerDoc(String userId) async {
//     final trackerQuery = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: userId)
//         .limit(1)
//         .get();
//     return trackerQuery.docs.isEmpty ? null : trackerQuery.docs.first;
//   }

//   int _calculateCurrentWeek(DateTime lastPeriodDate) {
//     return (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);
//   }

//   Future<void> _updateWeekInFirestore(
//   DocumentReference docRef, 
//   int newWeek,
//   DateTime weekStartDate,
// ) async {
//   await docRef.update({
//     'weekSelectedDate': Timestamp.fromDate(weekStartDate),
//     'updatedAt': FieldValue.serverTimestamp(),
//   });
// }

//   void _toggleEditWeek() {
//     setState(() {
//       _isEditingWeek = !_isEditingWeek;
//       if (_isEditingWeek) {
//         _weekController.text = _currentWeek.toString();
//         _editWeekDate = _weekSelectedDate;
//       }
//     });
//   }

//   int _getCurrentDayInWeek() {
//   if (_weekSelectedDate == null) return 1;
//   final daysDiff = DateTime.now().difference(_weekSelectedDate!).inDays;
//   // Haddii maalinta ka baxdo 6, waxaa lagu celinayaa 1 ilaa 7
//   return (daysDiff % 7) + 1;
// }

// DateTime _calculateWeekStartDate(int week) {
//   // Week 1 wuxuu bilaabmaa isla maalinta lastPeriodDate
//   return _lastPeriodDate.add(Duration(days: (week - 1) * 7));
// }

//   Future<void> _saveEditedWeek() async {
//     if (!_formKey.currentState!.validate()) return;

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final newWeek = int.tryParse(_weekController.text) ?? _currentWeek;
//     if (newWeek < 1 || newWeek > 40) {
//       _showErrorMessage('Please enter a week between 1 and 40');
//       return;
//     }

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       final weekStartDate = _editWeekDate ?? _calculateWeekStartDate(newWeek);
      
//       await _updateWeekInFirestore(trackerDoc.reference, newWeek, weekStartDate);

//       setState(() {
//         _currentWeek = newWeek;
//         _weekSelectedDate = weekStartDate;
//         _isEditingWeek = false;
//       });

//       _showSuccessMessage('Week updated successfully!');
//     } catch (e) {
//       _showErrorMessage('Failed to update week: ${e.toString()}');
//     }
//   }

//   Future<void> _selectWeekDate(BuildContext context) async {
//     final initialDate = _editWeekDate ?? _calculateWeekStartDate(_currentWeek);
//     final firstDate = _lastPeriodDate;
//     final lastDate = _lastPeriodDate.add(const Duration(days: 40 * 7));

//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: firstDate,
//       lastDate: lastDate,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: primaryColor,
//               onPrimary: Colors.white,
//               surface: bgColor,
//               onSurface: darkText,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (pickedDate != null) {
//       setState(() {
//         _editWeekDate = pickedDate;
//         // Calculate the week based on the selected date
//         final daysDifference = pickedDate.difference(_lastPeriodDate).inDays;
//         _currentWeek = (daysDifference / 7).floor() + 1;
//         _weekController.text = _currentWeek.toString();
//       });
//     }
//   }

//   // Modern Card with new colors
//   Widget _modernCard({required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.white, accentColor.withOpacity(0.05)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(18),
//       child: child,
//     );
//   }

// Widget _buildWeekInfoCard() {
//     return _modernCard(
//       child: Column(
//         children: [
//           if (_isEditingWeek) ...[
//             Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   TextFormField(
//                     controller: _weekController,
//                     keyboardType: TextInputType.number,
//                     readOnly: true,  // This makes the field read-only
//                     decoration: InputDecoration(
//                       labelText: 'Current Week',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       prefixIcon: Icon(Icons.calendar_today, color: accentColor),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a week number';
//                       }
//                       final week = int.tryParse(value);
//                       if (week == null || week < 1 || week > 40) {
//                         return 'Enter a week between 1-40';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   InkWell(
//                     onTap: () => _selectWeekDate(context),
//                     child: Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.calendar_today, color: accentColor),
//                           const SizedBox(width: 10),
//                           Text(
//                             _editWeekDate != null
//                                 ? DateFormat('MMM d, y').format(_editWeekDate!)
//                                 : 'Select week start date',
//                             style: TextStyle(color: darkText),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey[300],
//                         ),
//                         onPressed: _toggleEditWeek,
//                         child: const Text('Cancel'),
//                       ),
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryColor,
//                         ),
//                         onPressed: _saveEditedWeek,
//                         child: const Text('Save', style: TextStyle(color: Colors.white)),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ] else ...[
//             Text(
//               'Week $_currentWeek',
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//                 color: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'Day ${_getCurrentDayInWeek()} of week $_currentWeek',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: darkText.withOpacity(0.7),
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'You are in the ${_getTrimester()}',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: darkText.withOpacity(0.7),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: LinearProgressIndicator(
//                 value: _currentWeek / 40,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: AlwaysStoppedAnimation<Color>(accentColor),
//                 minHeight: 10,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '${((_currentWeek / 40) * 100).toStringAsFixed(1)}% completed',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: darkText.withOpacity(0.6),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//        leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//       title: const Text(
//         'Pregnancy Tracker',
//         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//       ),
//       backgroundColor: primaryColor,
//       elevation: 0,
//       actions: [
//         IconButton(
//           icon: Icon(_isEditingWeek ? Icons.close : Icons.edit, color: Colors.white),
//           onPressed: _toggleEditWeek,
//         ),
//       ],
//     );
//   }

//   Widget _buildDevItem(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, color: accentColor),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text('$title: $value',
//                 style: TextStyle(fontSize: 15, color: darkText)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, color: accentColor),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(text, style: TextStyle(fontSize: 15, color: darkText)),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry',
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon',
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return 'Not measurable yet';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return 'Not measurable yet';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: _buildAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWeekInfoCard(),
//             const SizedBox(height: 20),
//             _modernCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Baby Development',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       )),
//                   const SizedBox(height: 12),
//                   _buildDevItem(Icons.straighten, 'Size', 'About the size of a ${_getFruitSize()}'),
//                   _buildDevItem(Icons.height, 'Length', _getBabyLength()),
//                   _buildDevItem(Icons.monitor_weight, 'Weight', _getBabyWeight()),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             _modernCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Helpful Tips',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       )),
//                   const SizedBox(height: 12),
//                   _buildTipItem(Icons.medical_services, 'Take prenatal vitamins daily'),
//                   _buildTipItem(Icons.local_drink, 'Stay hydrated (8-12 glasses/day)'),
//                   _buildTipItem(Icons.directions_walk, '30 minutes of gentle exercise'),
//                 ],
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
// import 'dart:async';
// import 'package:intl/intl.dart';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;
//   bool _isEditingWeek = false;
//   final TextEditingController _weekController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   DateTime? _editWeekDate;

//   // 🎨 New Professional Colors
//   final Color primaryColor = const Color(0xFF344CB7); // Deep Indigo
//   final Color accentColor = const Color(0xFF3DDAD7); // Mint Green
//   final Color bgColor = Colors.white; // Clean White
//   final Color darkText = const Color(0xFF2E2E2E); // Charcoal

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     _weekController.dispose();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
//     _checkForWeekUpdate();
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//   Future<void> _checkForWeekUpdate() async {
//     if (!mounted) return;

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       final data = trackerDoc.data() as Map<String, dynamic>;
//       final lastUpdate = data['weekSelectedDate']?.toDate();
//       final lastPeriodDate = data['lastPeriodDate']?.toDate();

//       if (lastUpdate != null && lastPeriodDate != null) {
//         final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//         final calculatedWeek = _calculateCurrentWeek(lastPeriodDate);

//         if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//           await _updateWeekInFirestore(trackerDoc.reference, calculatedWeek);
//           if (mounted) {
//             setState(() => _currentWeek = calculatedWeek);
//             _showSuccessMessage('🎉 Congratulations! You are now in week $calculatedWeek');
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//       if (mounted) {
//         _showErrorMessage('Failed to check for week updates');
//       }
//     }
//   }

//   Future<DocumentSnapshot?> _getUserTrackerDoc(String userId) async {
//     final trackerQuery = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: userId)
//         .limit(1)
//         .get();
//     return trackerQuery.docs.isEmpty ? null : trackerQuery.docs.first;
//   }

//   int _calculateCurrentWeek(DateTime lastPeriodDate) {
//     return (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);
//   }

//   Future<void> _updateWeekInFirestore(DocumentReference docRef, int newWeek) async {
//     await docRef.update({
//       'currentWeek': newWeek,
//       'weekSelectedDate': Timestamp.now(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }

//   void _toggleEditWeek() {
//     setState(() {
//       _isEditingWeek = !_isEditingWeek;
//       if (_isEditingWeek) {
//         _weekController.text = _currentWeek.toString();
//         _editWeekDate = _calculateWeekStartDate(_currentWeek);
//       }
//     });
//   }

//   DateTime _calculateWeekStartDate(int week) {
//     return _lastPeriodDate.add(Duration(days: (week - 1) * 7));
//   }

//   int _getCurrentDayInWeek() {
//     final weekStartDate = _calculateWeekStartDate(_currentWeek);
//     return DateTime.now().difference(weekStartDate).inDays.clamp(0, 6) + 1;
//   }

//   // Modern Card with new colors
//   Widget _modernCard({required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.white, accentColor.withOpacity(0.05)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(18),
//       child: child,
//     );
//   }

//   Widget _buildWeekInfoCard() {
//     return _modernCard(
//       child: Column(
//         children: [
//           Text(
//             'Week $_currentWeek',
//             style: TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: primaryColor,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'You are in the ${_getTrimester()}',
//             style: TextStyle(
//               fontSize: 16,
//               color: darkText.withOpacity(0.7),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: LinearProgressIndicator(
//               value: _currentWeek / 40,
//               backgroundColor: Colors.grey[200],
//               valueColor: AlwaysStoppedAnimation<Color>(accentColor),
//               minHeight: 10,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '${((_currentWeek / 40) * 100).toStringAsFixed(1)}% completed',
//             style: TextStyle(
//               fontSize: 14,
//               color: darkText.withOpacity(0.6),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: const Text(
//         'Pregnancy Tracker',
//         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//       ),
//       backgroundColor: primaryColor,
//       elevation: 0,
//       actions: [
//         IconButton(
//           icon: Icon(_isEditingWeek ? Icons.close : Icons.edit, color: Colors.white),
//           onPressed: _toggleEditWeek,
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: _buildAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWeekInfoCard(),
//             const SizedBox(height: 20),
//             _modernCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Baby Development',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       )),
//                   const SizedBox(height: 12),
//                   _buildDevItem(Icons.straighten, 'Size', 'About the size of a ${_getFruitSize()}'),
//                   _buildDevItem(Icons.height, 'Length', _getBabyLength()),
//                   _buildDevItem(Icons.monitor_weight, 'Weight', _getBabyWeight()),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             _modernCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Helpful Tips',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       )),
//                   const SizedBox(height: 12),
//                   _buildTipItem(Icons.medical_services, 'Take prenatal vitamins daily'),
//                   _buildTipItem(Icons.local_drink, 'Stay hydrated (8-12 glasses/day)'),
//                   _buildTipItem(Icons.directions_walk, '30 minutes of gentle exercise'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevItem(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, color: accentColor),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text('$title: $value',
//                 style: TextStyle(fontSize: 15, color: darkText)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, color: accentColor),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(text, style: TextStyle(fontSize: 15, color: darkText)),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry',
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon',
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return 'Not measurable yet';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return 'Not measurable yet';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }
// }

















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:async';
// import 'package:intl/intl.dart';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;
//   bool _isEditingWeek = false;
//   final TextEditingController _weekController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   DateTime? _editWeekDate;

//   final Color primaryColor = const Color(0xFF3A8D99);
//   final Color accentColor = const Color(0xFFFF8A65);
//   final Color bgColor = const Color(0xFFFAFAFA);
//   final Color darkText = const Color(0xFF1B2B34);

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     _weekController.dispose();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
//     _checkForWeekUpdate();
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//   Future<void> _checkForWeekUpdate() async {
//     if (!mounted) return;

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       final data = trackerDoc.data() as Map<String, dynamic>;
//       final lastUpdate = data['weekSelectedDate']?.toDate();
//       final lastPeriodDate = data['lastPeriodDate']?.toDate();

//       if (lastUpdate != null && lastPeriodDate != null) {
//         final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//         final calculatedWeek = _calculateCurrentWeek(lastPeriodDate);

//         if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//           await _updateWeekInFirestore(trackerDoc.reference, calculatedWeek);
//           if (mounted) {
//             setState(() => _currentWeek = calculatedWeek);
//             _showSuccessMessage('🎉 Congratulations! You are now in week $calculatedWeek');
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//       if (mounted) {
//         _showErrorMessage('Failed to check for week updates');
//       }
//     }
//   }

//   Future<DocumentSnapshot?> _getUserTrackerDoc(String userId) async {
//     final trackerQuery = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: userId)
//         .limit(1)
//         .get();
//     return trackerQuery.docs.isEmpty ? null : trackerQuery.docs.first;
//   }

//   int _calculateCurrentWeek(DateTime lastPeriodDate) {
//     return (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);
//   }

//   Future<void> _updateWeekInFirestore(DocumentReference docRef, int newWeek) async {
//     await docRef.update({
//       'currentWeek': newWeek,
//       'weekSelectedDate': Timestamp.now(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }

//   void _toggleEditWeek() {
//     setState(() {
//       _isEditingWeek = !_isEditingWeek;
//       if (_isEditingWeek) {
//         _weekController.text = _currentWeek.toString();
//         _editWeekDate = _calculateWeekStartDate(_currentWeek);
//       }
//     });
//   }

//   DateTime _calculateWeekStartDate(int week) {
//     return _lastPeriodDate.add(Duration(days: (week - 1) * 7));
//   }

//   int _getCurrentDayInWeek() {
//     final weekStartDate = _calculateWeekStartDate(_currentWeek);
//     return DateTime.now().difference(weekStartDate).inDays.clamp(0, 6) + 1;
//   }

//   // Modern Card Builder
//   Widget _modernCard({required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.white, primaryColor.withOpacity(0.05)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.08),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(18),
//       child: child,
//     );
//   }

//   Widget _buildWeekInfoCard() {
//     return _modernCard(
//       child: Column(
//         children: [
//           Text(
//             'Week $_currentWeek',
//             style: TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: primaryColor,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'You are in the ${_getTrimester()}',
//             style: TextStyle(
//               fontSize: 16,
//               color: darkText.withOpacity(0.7),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: LinearProgressIndicator(
//               value: _currentWeek / 40,
//               backgroundColor: Colors.grey[200],
//               valueColor: AlwaysStoppedAnimation<Color>(accentColor),
//               minHeight: 10,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '${((_currentWeek / 40) * 100).toStringAsFixed(1)}% completed',
//             style: TextStyle(
//               fontSize: 14,
//               color: darkText.withOpacity(0.6),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: const Text(
//         'Pregnancy Tracker',
//         style: TextStyle(fontWeight: FontWeight.bold),
//       ),
//       backgroundColor: primaryColor,
//       elevation: 0,
//       actions: [
//         IconButton(
//           icon: Icon(_isEditingWeek ? Icons.close : Icons.edit, color: Colors.white),
//           onPressed: _toggleEditWeek,
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: _buildAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWeekInfoCard(),
//             const SizedBox(height: 20),
//             _modernCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Baby Development',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       )),
//                   const SizedBox(height: 12),
//                   _buildDevItem(Icons.straighten, 'Size', 'About the size of a ${_getFruitSize()}'),
//                   _buildDevItem(Icons.height, 'Length', _getBabyLength()),
//                   _buildDevItem(Icons.monitor_weight, 'Weight', _getBabyWeight()),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             _modernCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Helpful Tips',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       )),
//                   const SizedBox(height: 12),
//                   _buildTipItem(Icons.medical_services, 'Take prenatal vitamins daily'),
//                   _buildTipItem(Icons.local_drink, 'Stay hydrated (8-12 glasses/day)'),
//                   _buildTipItem(Icons.directions_walk, '30 minutes of gentle exercise'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevItem(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, color: accentColor),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text('$title: $value',
//                 style: TextStyle(fontSize: 15, color: darkText)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, color: accentColor),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(text, style: TextStyle(fontSize: 15, color: darkText)),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry',
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon',
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return 'Not measurable yet';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return 'Not measurable yet';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:async';
// import 'package:intl/intl.dart';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;
//   bool _isEditingWeek = false;
//   final TextEditingController _weekController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   DateTime? _editWeekDate;

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     _weekController.dispose();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
//     _checkForWeekUpdate();
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//   Future<void> _checkForWeekUpdate() async {
//     if (!mounted) return;

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       final data = trackerDoc.data() as Map<String, dynamic>;
//       final lastUpdate = data['weekSelectedDate']?.toDate();
//       final lastPeriodDate = data['lastPeriodDate']?.toDate();

//       if (lastUpdate != null && lastPeriodDate != null) {
//         final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//         final calculatedWeek = _calculateCurrentWeek(lastPeriodDate);

//         if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//           await _updateWeekInFirestore(trackerDoc.reference, calculatedWeek);
//           if (mounted) {
//             setState(() => _currentWeek = calculatedWeek);
//             _showSuccessMessage('🎉 Congratulations! You are now in week $calculatedWeek');
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//       if (mounted) {
//         _showErrorMessage('Failed to check for week updates');
//       }
//     }
//   }

//   Future<DocumentSnapshot?> _getUserTrackerDoc(String userId) async {
//     final trackerQuery = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: userId)
//         .limit(1)
//         .get();
//     return trackerQuery.docs.isEmpty ? null : trackerQuery.docs.first;
//   }

//   int _calculateCurrentWeek(DateTime lastPeriodDate) {
//     return (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);
//   }

//   Future<void> _updateWeekInFirestore(DocumentReference docRef, int newWeek) async {
//     await docRef.update({
//       'currentWeek': newWeek,
//       'weekSelectedDate': Timestamp.now(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }

//   void _toggleEditWeek() {
//     setState(() {
//       _isEditingWeek = !_isEditingWeek;
//       if (_isEditingWeek) {
//         _weekController.text = _currentWeek.toString();
//         _editWeekDate = _calculateWeekStartDate(_currentWeek);
//       }
//     });
//   }

//   DateTime _calculateWeekStartDate(int week) {
//     return _lastPeriodDate.add(Duration(days: (week - 1) * 7));
//   }

//   int _getCurrentDayInWeek() {
//     final weekStartDate = _calculateWeekStartDate(_currentWeek);
//     return DateTime.now().difference(weekStartDate).inDays.clamp(0, 6) + 1;
//   }

//   // Modern Card Builder
//   Widget _modernCard({required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.white, const Color(0xFFEAF0FB)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.12),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(18),
//       child: child,
//     );
//   }

//   // Week Info Card
//   Widget _buildWeekInfoCard() {
//     return _modernCard(
//       child: Column(
//         children: [
//           Text(
//             'Week $_currentWeek',
//             style: const TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF2E4B7B),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'You are in the ${_getTrimester()}',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 16),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: LinearProgressIndicator(
//               value: _currentWeek / 40,
//               backgroundColor: Colors.grey[200],
//               valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A8FC7)),
//               minHeight: 10,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '${((_currentWeek / 40) * 100).toStringAsFixed(1)}% completed',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: Text(
//         'Pregnancy Tracker',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: const Color(0xFF6A8FC7),
//       elevation: 0,
//       actions: [
//         IconButton(
//           icon: Icon(_isEditingWeek ? Icons.close : Icons.edit),
//           onPressed: _toggleEditWeek,
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F9FC),
//       appBar: _buildAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWeekInfoCard(),
//             const SizedBox(height: 20),
//             _modernCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Baby Development',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF2E4B7B),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildDevItem(Icons.straighten, 'Size', 'About the size of a ${_getFruitSize()}'),
//                   _buildDevItem(Icons.height, 'Length', _getBabyLength()),
//                   _buildDevItem(Icons.monitor_weight, 'Weight', _getBabyWeight()),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             _modernCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Helpful Tips',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF2E4B7B),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildTipItem(Icons.medical_services, 'Take prenatal vitamins daily'),
//                   _buildTipItem(Icons.local_drink, 'Stay hydrated (8-12 glasses/day)'),
//                   _buildTipItem(Icons.directions_walk, '30 minutes of gentle exercise'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevItem(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF6A8FC7)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text('$title: $value',
//                 style: const TextStyle(fontSize: 15)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF6A8FC7)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(text, style: const TextStyle(fontSize: 15)),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry',
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon',
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return 'Not measurable yet';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return 'Not measurable yet';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:async';
// import 'package:intl/intl.dart';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;
//   bool _isEditingWeek = false;
//   final TextEditingController _weekController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   DateTime? _editWeekDate;

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     _weekController.dispose();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
//     _checkForWeekUpdate();
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//   Future<void> _checkForWeekUpdate() async {
//     if (!mounted) return;
    
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       final data = trackerDoc.data() as Map<String, dynamic>;
//       final lastUpdate = data['weekSelectedDate']?.toDate(); 
//       final lastPeriodDate = data['lastPeriodDate']?.toDate();

//       if (lastUpdate != null && lastPeriodDate != null) {
//         final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//         final calculatedWeek = _calculateCurrentWeek(lastPeriodDate);

//         if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//           await _updateWeekInFirestore(trackerDoc.reference, calculatedWeek);
//           if (mounted) {
//             setState(() => _currentWeek = calculatedWeek);
//             _showSuccessMessage('🎉 Congratulations! You are now in week $calculatedWeek');
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//       if (mounted) {
//         _showErrorMessage('Failed to check for week updates');
//       }
//     }
//   }

//   Future<DocumentSnapshot?> _getUserTrackerDoc(String userId) async {
//     final trackerQuery = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: userId)
//         .limit(1)
//         .get();
//     return trackerQuery.docs.isEmpty ? null : trackerQuery.docs.first;
//   }

//   int _calculateCurrentWeek(DateTime lastPeriodDate) {
//     return (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);
//   }

//   Future<void> _updateWeekInFirestore(DocumentReference docRef, int newWeek) async {
//     await docRef.update({
//       'currentWeek': newWeek,
//       'weekSelectedDate': Timestamp.now(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }

//   void _toggleEditWeek() {
//     setState(() {
//       _isEditingWeek = !_isEditingWeek;
//       if (_isEditingWeek) {
//         _weekController.text = _currentWeek.toString();
//         _editWeekDate = _calculateWeekStartDate(_currentWeek);
//       }
//     });
//   }

//   DateTime _calculateWeekStartDate(int week) {
//     return _lastPeriodDate.add(Duration(days: (week - 1) * 7));
//   }

//   int _getCurrentDayInWeek() {
//     final weekStartDate = _calculateWeekStartDate(_currentWeek);
//     return DateTime.now().difference(weekStartDate).inDays.clamp(0, 6) + 1;
//   }

//   Future<void> _saveWeekUpdate() async {
//     if (!_formKey.currentState!.validate()) return;

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final newWeek = int.tryParse(_weekController.text) ?? _currentWeek;
    
//     if (newWeek < _currentWeek) {
//       if (mounted) {
//         _showErrorMessage('You cannot go back to a previous week');
//       }
//       return;
//     }

//     if (newWeek == 40 && _currentWeek != 40) {
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Congratulations!'),
//           content: const Text('Have you completed your pregnancy journey?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Yes'),
//             ),
//           ],
//         ),
//       );

//       if (confirmed != true) {
//         return;
//       }

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => BabyBornScreen(
//               lastPeriodDate: _lastPeriodDate,
//             ),
//           ),
//         );
//         return;
//       }
//     }

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       await _updateWeekInFirestore(trackerDoc.reference, newWeek);

//       if (mounted) {
//         setState(() {
//           _currentWeek = newWeek;
//           _isEditingWeek = false;
//         });
//         _showSuccessMessage('Successfully updated to week $newWeek');
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorMessage('Error updating week: ${e.toString()}');
//       }
//     }
//   }

//   Widget _buildWeekCounter() {
//     final currentDay = _getCurrentDayInWeek();
//     final progress = currentDay / 7;

//     return Container(
//       margin: const EdgeInsets.only(top: 16),
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF6A8FC7).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF6A8FC7).withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Week Progress',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                 ),
//               ),
//               Text(
//                 'Day $currentDay of 7',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF2E4B7B),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(
//             value: progress,
//             backgroundColor: Colors.grey[200],
//             valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A8FC7)),
//             minHeight: 8,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Week $_currentWeek started',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey,
//                 ),
//               ),
//               Text(
//                 '${(progress * 100).toStringAsFixed(0)}%',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeekEditField() {
//   return Form(
//     key: _formKey,
//     child: Column(
//       children: [
//         TextFormField(
//           controller: _weekController,
//           keyboardType: TextInputType.number,
//           decoration: InputDecoration(
//             labelText: 'Current Pregnancy Week',
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.grey),
//             ),
//             filled: true,
//             fillColor: Colors.grey[50],
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//             suffixIcon: const Icon(Icons.pregnant_woman_rounded),
//           ),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Please enter a week number';
//             }
//             final week = int.tryParse(value);
//             if (week == null || week < 1 || week > 40) {
//               return 'Enter a valid week (1-40)';
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 12),
//         GestureDetector(
//           onTap: () async {
//             final picked = await showDatePicker(
//               context: context,
//               initialDate: _editWeekDate ?? DateTime.now(),
//               firstDate: _lastPeriodDate,
//               lastDate: _lastPeriodDate.add(const Duration(days: 280)),
//               builder: (context, child) {
//                 return Theme(
//                   data: Theme.of(context).copyWith(
//                     colorScheme: const ColorScheme.light(
//                       primary: Color(0xFF6A8FC7),
//                       onPrimary: Colors.white,
//                       surface: Colors.white,
//                       onSurface: Colors.black,
//                     ),
//                     dialogBackgroundColor: Colors.white,
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Week counter header
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         color: const Color(0xFF6A8FC7),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               'Week ${_calculateWeekFromDate(_editWeekDate ?? DateTime.now())}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       // Actual date picker
//                       ConstrainedBox(
//                         constraints: const BoxConstraints(
//                           maxHeight: 400,
//                         ),
//                         child: child!,
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
            
//             if (picked != null) {
//               setState(() {
//                 _editWeekDate = picked;
//                 final calculatedWeek = _calculateWeekFromDate(picked);
//                 _weekController.text = calculatedWeek.toString();
//               });
//             }
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             decoration: BoxDecoration(
//               border: Border.all(color: const Color(0xFF6A8FC7)),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.calendar_today, size: 20, color: Color(0xFF6A8FC7)),
//                 const SizedBox(width: 8),
//                 Text(
//                   _editWeekDate != null 
//                     ? 'Week ${_calculateWeekFromDate(_editWeekDate!)} - ${DateFormat('MMM d, y').format(_editWeekDate!)}'
//                     : 'Select date to calculate week',
//                   style: const TextStyle(color: Color(0xFF6A8FC7)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _saveWeekUpdate,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF6A8FC7),
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 0,
//             ),
//             child: const Text(
//               'SAVE CHANGES',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// // Add this helper method to your state class
// int _calculateWeekFromDate(DateTime date) {
//   final daysDiff = date.difference(_lastPeriodDate).inDays;
//   return (daysDiff / 7).floor().clamp(1, 40);
// }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: Text(
//         'Week $_currentWeek',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 20,
//         ),
//       ),
//       backgroundColor: const Color(0xFF6A8FC7),
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_rounded, size: 28),
//         onPressed: () => Navigator.pushNamed(context, '/home'),
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(
//             _isEditingWeek ? Icons.close_rounded : Icons.edit_rounded,
//             size: 24,
//           ),
//           onPressed: _toggleEditWeek,
//         ),
//       ],
//     );
//   }

//   Widget _buildWeekInfoCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             if (_isEditingWeek)
//               _buildWeekEditField()
//             else
//               Column(
//                 children: [
//                   Text(
//                     'Week $_currentWeek',
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF2E4B7B),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'You are in the ${_getTrimester()}',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   LinearProgressIndicator(
//                     value: _currentWeek / 40,
//                     backgroundColor: Colors.grey[200],
//                     valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A8FC7)),
//                     minHeight: 8,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     '${((_currentWeek / 40) * 100).toStringAsFixed(1)}% completed',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF2E4B7B),
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildDevelopmentItem(
//               Icons.straighten_rounded,
//               'Size',
//               'About the size of a ${_getFruitSize()}',
//             ),
//             const Divider(height: 24, thickness: 1),
//             _buildDevelopmentItem(
//               Icons.height_rounded,
//               'Length',
//               _getBabyLength(),
//             ),
//             const Divider(height: 24, thickness: 1),
//             _buildDevelopmentItem(
//               Icons.monitor_weight_rounded,
//               'Weight',
//               _getBabyWeight(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentItem(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF6A8FC7), size: 24),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipsCard() {
//     final tips = [
//       _buildTipItem(Icons.medical_services_rounded, 'Take prenatal vitamins daily'),
//       _buildTipItem(Icons.local_drink_rounded, 'Stay hydrated (8-12 glasses/day)'),
//       _buildTipItem(Icons.directions_walk_rounded, '30 minutes of gentle exercise'),
//       if (_currentWeek > 12)
//         _buildTipItem(Icons.fastfood_rounded, 'Increase protein intake'),
//       if (_currentWeek > 20)
//         _buildTipItem(Icons.nightlight_round, 'Sleep on your left side'),
//       if (_currentWeek > 28)
//         _buildTipItem(Icons.self_improvement_rounded, 'Practice breathing exercises'),
//     ];

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: List.generate(
//             tips.length * 2 - 1,
//             (index) => index.isOdd
//                 ? const Divider(height: 24, thickness: 1)
//                 : tips[index ~/ 2],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: const Color(0xFF6A8FC7).withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: const Color(0xFF6A8FC7), size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return 'Not measurable yet';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return 'Not measurable yet';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: _buildAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWeekInfoCard(),
//             if (!_isEditingWeek) _buildWeekCounter(),
//             const SizedBox(height: 24),
//             _buildSectionTitle('BABY DEVELOPMENT'),
//             const SizedBox(height: 8),
//             _buildDevelopmentCard(),
//             const SizedBox(height: 24),
//             _buildSectionTitle('HELPFUL TIPS'),
//             const SizedBox(height: 8),
//             _buildTipsCard(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class BabyBornScreen extends StatelessWidget {
//   final DateTime lastPeriodDate;

//   const BabyBornScreen({super.key, required this.lastPeriodDate});

//   @override
//   Widget build(BuildContext context) {
//     final estimatedBirthDate = lastPeriodDate.add(const Duration(days: 280));
//     final formattedDate = DateFormat('MMMM d, y').format(estimatedBirthDate);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Congratulations!'),
//         leading: Container(),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.celebration,
//               size: 100,
//               color: Colors.pink,
//             ),
//             const SizedBox(height: 30),
//             const Text(
//               '🎉 Congratulations! 🎉',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Your baby has arrived!',
//               style: TextStyle(fontSize: 18),
//             ),
//             const SizedBox(height: 30),
//             Text(
//               'Based on your last period date, your estimated delivery date was:',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//             Text(
//               formattedDate,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pushNamedAndRemoveUntil(
//                   context,
//                   '/home',
//                   (route) => false,
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6A8FC7),
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Text(
//                 'Return to Home',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Visit us again in 2 months for postpartum tracking',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//                 fontStyle: FontStyle.italic,
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
// import 'dart:async';
// import 'package:intl/intl.dart';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;
//   bool _isEditingWeek = false;
//   final TextEditingController _weekController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     _weekController.dispose();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
//     _checkForWeekUpdate();
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//   Future<void> _checkForWeekUpdate() async {
//     if (!mounted) return;
    
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       final data = trackerDoc.data() as Map<String, dynamic>;
//       final lastUpdate = data['weekSelectedDate']?.toDate(); 
//       final lastPeriodDate = data['lastPeriodDate']?.toDate();

//       if (lastUpdate != null && lastPeriodDate != null) {
//         final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//         final calculatedWeek = _calculateCurrentWeek(lastPeriodDate);

//         if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//           await _updateWeekInFirestore(trackerDoc.reference, calculatedWeek);
//           if (mounted) {
//             setState(() => _currentWeek = calculatedWeek);
//             _showSuccessMessage('🎉 Congratulations! You are now in week $calculatedWeek');
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//       if (mounted) {
//         _showErrorMessage('Failed to check for week updates');
//       }
//     }
//   }

//   Future<DocumentSnapshot?> _getUserTrackerDoc(String userId) async {
//     final trackerQuery = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: userId)
//         .limit(1)
//         .get();
//     return trackerQuery.docs.isEmpty ? null : trackerQuery.docs.first;
//   }

//   int _calculateCurrentWeek(DateTime lastPeriodDate) {
//     return (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);
//   }

//   Future<void> _updateWeekInFirestore(DocumentReference docRef, int newWeek) async {
//     await docRef.update({
//       'currentWeek': newWeek,
//       'weekSelectedDate': Timestamp.now(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }

//   void _toggleEditWeek() {
//     setState(() {
//       _isEditingWeek = !_isEditingWeek;
//       if (_isEditingWeek) {
//         _weekController.text = _currentWeek.toString();
//       }
//     });
//   }

//   Future<void> _saveWeekUpdate() async {
//     if (!_formKey.currentState!.validate()) return;

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final newWeek = int.tryParse(_weekController.text) ?? _currentWeek;
    
//     // Prevent selecting a previous week
//     if (newWeek < _currentWeek) {
//       if (mounted) {
//         _showErrorMessage('You cannot go back to a previous week');
//       }
//       return;
//     }

//     // Special handling for week 40 (completed pregnancy)
//     if (newWeek == 40 && _currentWeek != 40) {
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Congratulations!'),
//           content: const Text('Have you completed your pregnancy journey?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Yes'),
//             ),
//           ],
//         ),
//       );

//       if (confirmed != true) {
//         return;
//       }

//       // Show baby born screen
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => BabyBornScreen(
//               lastPeriodDate: _lastPeriodDate,
//             ),
//           ),
//         );
//         return;
//       }
//     }

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       await _updateWeekInFirestore(trackerDoc.reference, newWeek);

//       if (mounted) {
//         setState(() {
//           _currentWeek = newWeek;
//           _isEditingWeek = false; when edit use date time piker
//           TextButton(
//                     onPressed: () async {
//                       final picked = await showDatePicker(
//                         context: context,
//                         initialDate: _editweek ?? DateTime.now(),
//                         : DateTime.now().subtract(const Duration(days: 280)),
//                         : DateTime.now(),
//                       );
//                       if (picked != null) {
//                         setState(() => _editweek = picked);
//                       }
//         });
//         _showSuccessMessage('Successfully updated to week $newWeek');
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorMessage('Error updating week: ${e.toString()}');
//       }
//     }
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: Text(
//         'Week $_currentWeek',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 20,
//         ),
//       ),
//       backgroundColor: const Color(0xFF6A8FC7),
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_rounded, size: 28),
//         onPressed: () => Navigator.pushNamed(context, '/home'),
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(
//             _isEditingWeek ? Icons.close_rounded : Icons.edit_rounded,
//             size: 24,
//           ),
//           onPressed: _toggleEditWeek,
//         ),
//       ],
//     );
//   }

//   Widget _buildWeekEditField() {
//     return Form(
//       key: _formKey,
//       child: Column(
//         children: [
//           TextFormField(
//             controller: _weekController,
//             keyboardType: TextInputType.number,
//             decoration: InputDecoration(
//               labelText: 'Current Pregnancy Week',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(color: Colors.grey),
//               ),
//               filled: true,
//               fillColor: Colors.grey[50],
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 14,
//               ),
//               suffixIcon: const Icon(Icons.pregnant_woman_rounded),
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter a week number';
//               }
//               final week = int.tryParse(value);
//               if (week == null || week < 1 || week > 40) {
//                 return 'Enter a valid week (1-40)';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _saveWeekUpdate,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6A8FC7),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//               ),
//               child: const Text(
//                 'SAVE CHANGES',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeekInfoCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             if (_isEditingWeek)
//               _buildWeekEditField()
//             else
//               Column(
//                 children: [
//                   Text(
//                     'Week $_currentWeek',
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF2E4B7B),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'You are in the ${_getTrimester()}',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   LinearProgressIndicator(
//                     value: _currentWeek / 40,
//                     backgroundColor: Colors.grey[200],
//                     valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A8FC7)),
//                     minHeight: 8,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     '${((_currentWeek / 40) * 100).toStringAsFixed(1)}% completed',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF2E4B7B),
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildDevelopmentItem(
//               Icons.straighten_rounded,
//               'Size',
//               'About the size of a ${_getFruitSize()}',
//             ),
//             const Divider(height: 24, thickness: 1),
//             _buildDevelopmentItem(
//               Icons.height_rounded,
//               'Length',
//               _getBabyLength(),
//             ),
//             const Divider(height: 24, thickness: 1),
//             _buildDevelopmentItem(
//               Icons.monitor_weight_rounded,
//               'Weight',
//               _getBabyWeight(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentItem(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF6A8FC7), size: 24),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipsCard() {
//     final tips = [
//       _buildTipItem(Icons.medical_services_rounded, 'Take prenatal vitamins daily'),
//       _buildTipItem(Icons.local_drink_rounded, 'Stay hydrated (8-12 glasses/day)'),
//       _buildTipItem(Icons.directions_walk_rounded, '30 minutes of gentle exercise'),
//       if (_currentWeek > 12)
//         _buildTipItem(Icons.fastfood_rounded, 'Increase protein intake'),
//       if (_currentWeek > 20)
//         _buildTipItem(Icons.nightlight_round, 'Sleep on your left side'),
//       if (_currentWeek > 28)
//         _buildTipItem(Icons.self_improvement_rounded, 'Practice breathing exercises'),
//     ];

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: List.generate(
//             tips.length * 2 - 1,
//             (index) => index.isOdd
//                 ? const Divider(height: 24, thickness: 1)
//                 : tips[index ~/ 2],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: const Color(0xFF6A8FC7).withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: const Color(0xFF6A8FC7), size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: _buildAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWeekInfoCard(),
//             const SizedBox(height: 24),
//             _buildSectionTitle('BABY DEVELOPMENT'),
//             const SizedBox(height: 8),
//             _buildDevelopmentCard(),
//             const SizedBox(height: 24),
//             _buildSectionTitle('HELPFUL TIPS'),
//             const SizedBox(height: 8),
//             _buildTipsCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return 'Not measurable yet';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return 'Not measurable yet';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }
// }

// class BabyBornScreen extends StatelessWidget {
//   final DateTime lastPeriodDate;

//   const BabyBornScreen({super.key, required this.lastPeriodDate});

//   @override
//   Widget build(BuildContext context) {
//     final estimatedBirthDate = lastPeriodDate.add(const Duration(days: 280));
//     final formattedDate = DateFormat('MMMM d, y').format(estimatedBirthDate);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Congratulations!'),
//         leading: Container(),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.celebration,
//               size: 100,
//               color: Colors.pink,
//             ),
//             const SizedBox(height: 30),
//             const Text(
//               '🎉 Congratulations! 🎉',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Your baby has arrived!',
//               style: TextStyle(fontSize: 18),
//             ),
//             const SizedBox(height: 30),
//             Text(
//               'Based on your last period date, your estimated delivery date was:',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//             Text(
//               formattedDate,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pushNamedAndRemoveUntil(
//                   context,
//                   '/home',
//                   (route) => false,
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6A8FC7),
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Text(
//                 'Return to Home',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Visit us again in 2 months for postpartum tracking',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//                 fontStyle: FontStyle.italic,
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
// import 'dart:async';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;
//   bool _isEditingWeek = false;
//   final TextEditingController _weekController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     _weekController.dispose();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
//     _checkForWeekUpdate();
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//   Future<void> _checkForWeekUpdate() async {
//     if (!mounted) return;
    
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       final data = trackerDoc.data() as Map<String, dynamic>;
//       final lastUpdate = data['weekSelectedDate']?.toDate();
//       final lastPeriodDate = data['lastPeriodDate']?.toDate();

//       if (lastUpdate != null && lastPeriodDate != null) {
//         final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//         final calculatedWeek = _calculateCurrentWeek(lastPeriodDate);

//         if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//           await _updateWeekInFirestore(trackerDoc.reference, calculatedWeek);
//           if (mounted) {
//             setState(() => _currentWeek = calculatedWeek);
//             _showSuccessMessage('🎉 Congratulations! You are now in week $calculatedWeek');
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//       if (mounted) {
//         _showErrorMessage('Failed to check for week updates');
//       }
//     }
//   }

//   Future<DocumentSnapshot?> _getUserTrackerDoc(String userId) async {
//     final trackerQuery = await FirebaseFirestore.instance
//         .collection('trackingweeks')
//         .where('userId', isEqualTo: userId)
//         .limit(1)
//         .get();
//     return trackerQuery.docs.isEmpty ? null : trackerQuery.docs.first;
//   }

//   int _calculateCurrentWeek(DateTime lastPeriodDate) {
//     return (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);
//   }

//   Future<void> _updateWeekInFirestore(DocumentReference docRef, int newWeek) async {
//     await docRef.update({
//       'currentWeek': newWeek,
//       'weekSelectedDate': Timestamp.now(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }

//   void _toggleEditWeek() {
//     setState(() {
//       _isEditingWeek = !_isEditingWeek;
//       if (_isEditingWeek) {
//         _weekController.text = _currentWeek.toString();
//       }
//     });
//   }

//   Future<void> _saveWeekUpdate() async {
//     if (!_formKey.currentState!.validate()) return;

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final newWeek = int.tryParse(_weekController.text) ?? _currentWeek;
//     if (newWeek == _currentWeek) {
//       setState(() => _isEditingWeek = false);
//       return;
//     }

//     try {
//       final trackerDoc = await _getUserTrackerDoc(user.uid);
//       if (trackerDoc == null) return;

//       await _updateWeekInFirestore(trackerDoc.reference, newWeek);

//       if (mounted) {
//         setState(() {
//           _currentWeek = newWeek;
//           _isEditingWeek = false;
//         });
//         _showSuccessMessage('Successfully updated to week $newWeek');
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorMessage('Error updating week: ${e.toString()}');
//       }
//     }
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: Text(
//         'Week $_currentWeek',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 20,
//         ),
//       ),
//       backgroundColor: const Color(0xFF6A8FC7),
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_rounded, size: 28),
//         onPressed: () => Navigator.pushNamed(context, '/home'),
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(
//             _isEditingWeek ? Icons.close_rounded : Icons.edit_rounded,
//             size: 24,
//           ),
//           onPressed: _toggleEditWeek,
//         ),
//       ],
//     );
//   }

//   Widget _buildWeekEditField() {
//     return Form(
//       key: _formKey,
//       child: Column(
//         children: [
//           TextFormField(
//             controller: _weekController,
//             keyboardType: TextInputType.number,
//             decoration: InputDecoration(
//               labelText: 'Current Pregnancy Week',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(color: Colors.grey),
//               ),
//               filled: true,
//               fillColor: Colors.grey[50],
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 14,
//               ),
//               suffixIcon: const Icon(Icons.pregnant_woman_rounded),
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter a week number';
//               }
//               final week = int.tryParse(value);
//               if (week == null || week < 1 || week > 40) {
//                 return 'Enter a valid week (1-40)';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _saveWeekUpdate,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6A8FC7),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//               ),
//               child: const Text(
//                 'SAVE CHANGES',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeekInfoCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             if (_isEditingWeek)
//               _buildWeekEditField()
//             else
//               Column(
//                 children: [
//                   Text(
//                     'Week $_currentWeek',
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF2E4B7B),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'You are in the ${_getTrimester()}',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   LinearProgressIndicator(
//                     value: _currentWeek / 40,
//                     backgroundColor: Colors.grey[200],
//                     valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A8FC7)),
//                     minHeight: 8,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     '${((_currentWeek / 40) * 100).toStringAsFixed(1)}% completed',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF2E4B7B),
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildDevelopmentItem(
//               Icons.straighten_rounded,
//               'Size',
//               'About the size of a ${_getFruitSize()}',
//             ),
//             const Divider(height: 24, thickness: 1),
//             _buildDevelopmentItem(
//               Icons.height_rounded,
//               'Length',
//               _getBabyLength(),
//             ),
//             const Divider(height: 24, thickness: 1),
//             _buildDevelopmentItem(
//               Icons.monitor_weight_rounded,
//               'Weight',
//               _getBabyWeight(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentItem(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF6A8FC7), size: 24),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipsCard() {
//     final tips = [
//       _buildTipItem(Icons.medical_services_rounded, 'Take prenatal vitamins daily'),
//       _buildTipItem(Icons.local_drink_rounded, 'Stay hydrated (8-12 glasses/day)'),
//       _buildTipItem(Icons.directions_walk_rounded, '30 minutes of gentle exercise'),
//       if (_currentWeek > 12)
//         _buildTipItem(Icons.fastfood_rounded, 'Increase protein intake'),
//       if (_currentWeek > 20)
//         _buildTipItem(Icons.nightlight_round, 'Sleep on your left side'),
//       if (_currentWeek > 28)
//         _buildTipItem(Icons.self_improvement_rounded, 'Practice breathing exercises'),
//     ];

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: List.generate(
//             tips.length * 2 - 1,
//             (index) => index.isOdd
//                 ? const Divider(height: 24, thickness: 1)
//                 : tips[index ~/ 2],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: const Color(0xFF6A8FC7).withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: const Color(0xFF6A8FC7), size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: _buildAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWeekInfoCard(),
//             const SizedBox(height: 24),
//             _buildSectionTitle('BABY DEVELOPMENT'),
//             const SizedBox(height: 8),
//             _buildDevelopmentCard(),
//             const SizedBox(height: 24),
//             _buildSectionTitle('HELPFUL TIPS'),
//             const SizedBox(height: 8),
//             _buildTipsCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return 'Not measurable yet';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return 'Not measurable yet';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:async';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;
//   bool _isEditingWeek = false;
//   final TextEditingController _weekController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     _weekController.dispose();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
//     // Check immediately on load
//     _checkForWeekUpdate();
//     // Then check every hour
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//   Future<void> _checkForWeekUpdate() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerQuery = await FirebaseFirestore.instance
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: user.uid)
//           .limit(1)
//           .get();

//       if (trackerQuery.docs.isNotEmpty) {
//         final trackerDoc = trackerQuery.docs.first;
//         final data = trackerDoc.data();
//         final lastUpdate = data['weekSelectedDate']?.toDate();
//         final lastPeriodDate = data['lastPeriodDate']?.toDate();

//         if (lastUpdate != null && lastPeriodDate != null) {
//           final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//           final calculatedWeek = (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);

//           if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//             // Update in Firestore
//             await trackerDoc.reference.update({
//               'currentWeek': calculatedWeek,
//               'weekSelectedDate': Timestamp.now(),
//               'updatedAt': FieldValue.serverTimestamp(),
//             });

//             if (mounted) {
//               setState(() => _currentWeek = calculatedWeek);
//               _showWeekUpdateMessage(calculatedWeek);
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//     }
//   }

//   void _showWeekUpdateMessage(int newWeek) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('🎉 Congratulations! You are now in week $newWeek'),
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   void _toggleEditWeek() {
//     setState(() {
//       _isEditingWeek = !_isEditingWeek;
//       if (_isEditingWeek) {
//         _weekController.text = _currentWeek.toString();
//       }
//     });
//   }

//   Future<void> _saveWeekUpdate() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final newWeek = int.tryParse(_weekController.text) ?? _currentWeek;
//     if (newWeek < 1 || newWeek > 40) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter a valid week between 1 and 40'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       return;
//     }

//     try {
//       final trackerQuery = await FirebaseFirestore.instance
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: user.uid)
//           .limit(1)
//           .get();

//       if (trackerQuery.docs.isNotEmpty) {
//         await trackerQuery.docs.first.reference.update({
//           'currentWeek': newWeek,
//           'weekSelectedDate': Timestamp.now(),
//           'updatedAt': FieldValue.serverTimestamp(),
//         });

//         setState(() {
//           _currentWeek = newWeek;
//           _isEditingWeek = false;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Successfully updated to week $newWeek'),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating week: ${e.toString()}'),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   Widget _buildWeekEditField() {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: _weekController,
//             keyboardType: TextInputType.number,
//             decoration: const InputDecoration(
//               labelText: 'Current Pregnancy Week',
//               border: OutlineInputBorder(),
//               contentPadding: EdgeInsets.symmetric(horizontal: 12),
//             ),
//           ),
//         ),
//         const SizedBox(width: 8),
//         ElevatedButton(
//           onPressed: _saveWeekUpdate,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF4A6FA5),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//           child: const Text('Save', style: TextStyle(color: Colors.white)),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Week $_currentWeek'),
//         backgroundColor: const Color(0xFF4A6FA5),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(_isEditingWeek ? Icons.close : Icons.edit),
//             onPressed: _toggleEditWeek,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Week information
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     if (_isEditingWeek)
//                       _buildWeekEditField()
//                     else
//                       Text(
//                         'You are in week $_currentWeek of your pregnancy',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'Trimester: ${_getTrimester()}',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
//             const Text(
//               'BABY DEVELOPMENT',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _buildDevelopmentCard(),

//             const SizedBox(height: 20),
//             const Text(
//               'HELPFUL TIPS',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _buildTipsCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentCard() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildDevelopmentItem('Size', 'About the size of a ${_getFruitSize()}'),
//             const Divider(),
//             _buildDevelopmentItem('Length', _getBabyLength()),
//             const Divider(),
//             _buildDevelopmentItem('Weight', _getBabyWeight()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipsCard() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildTipItem(Icons.favorite, 'Take your prenatal vitamins'),
//             const Divider(),
//             _buildTipItem(Icons.water, 'Stay hydrated'),
//             const Divider(),
//             _buildTipItem(Icons.directions_walk, 'Gentle exercise daily'),
//             if (_currentWeek > 28) ...[
//               const Divider(),
//               _buildTipItem(Icons.access_time, 'Practice breathing exercises'),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentItem(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           Text(value),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blue),
//           const SizedBox(width: 10),
//           Text(text),
//         ],
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return '----';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return '----';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:async';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
    
//     // Then check every hour
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//      _checkForWeekUpdate();
//   }

//   Future<void> _checkForWeekUpdate() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerQuery = await FirebaseFirestore.instance
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: user.uid)
//           .limit(1)
//           .get();

//       if (trackerQuery.docs.isNotEmpty) {
//         final trackerDoc = trackerQuery.docs.first;
//         final data = trackerDoc.data();
//         final lastUpdate = data['weekSelectedDate']?.toDate();
//         final lastPeriodDate = data['lastPeriodDate']?.toDate();

//         if (lastUpdate != null && lastPeriodDate != null) {
//           final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//           final calculatedWeek = (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);

//           if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//             // Update in Firestore
//             await trackerDoc.reference.update({
//               'currentWeek': calculatedWeek,
//               'weekSelectedDate': Timestamp.now(),
//               'updatedAt': FieldValue.serverTimestamp(),
//             });

//             if (mounted) {
//               setState(() => _currentWeek = calculatedWeek);
//               _showWeekUpdateMessage(calculatedWeek);
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//     }
//   }

//   void _showWeekUpdateMessage(int newWeek) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('🎉 Congratulations! You are now in week $newWeek'),
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Week $_currentWeek'),
//         backgroundColor: const Color(0xFF4A6FA5),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Week information
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Text(
//                       'You are in week $_currentWeek of your pregnancy',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'Trimester: ${_getTrimester()}',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
//             const Text(
//               'BABY DEVELOPMENT',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _buildDevelopmentCard(),

//             const SizedBox(height: 20),
//             const Text(
//               'HELPFUL TIPS',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _buildTipsCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentCard() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildDevelopmentItem('Size', 'About the size of a ${_getFruitSize()}'),
//             const Divider(),
//             _buildDevelopmentItem('Length', _getBabyLength()),
//             const Divider(),
//             _buildDevelopmentItem('Weight', _getBabyWeight()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipsCard() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildTipItem(Icons.favorite, 'Take your prenatal vitamins'),
//             const Divider(),
//             _buildTipItem(Icons.water, 'Stay hydrated'),
//             const Divider(),
//             _buildTipItem(Icons.directions_walk, 'Gentle exercise daily'),
//             if (_currentWeek > 28) ...[
//               const Divider(),
//               _buildTipItem(Icons.access_time, 'Practice breathing exercises'),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentItem(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           Text(value),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blue),
//           const SizedBox(width: 10),
//           Text(text),
//         ],
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return '----';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return '----';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class TrackerDetailScreen extends StatefulWidget {
//   final int pregnancyWeek;
//   final DateTime lastPeriodDate;

//   const TrackerDetailScreen({
//     super.key,
//     required this.pregnancyWeek,
//     required this.lastPeriodDate,
//   });

//   @override
//   State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
// }

// class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
//   late int _currentWeek;
//   late DateTime _lastPeriodDate;
//   Timer? _weekUpdateTimer;

//   @override
//   void initState() {
//     super.initState();
//     _currentWeek = widget.pregnancyWeek;
//     _lastPeriodDate = widget.lastPeriodDate;
//     _startWeekUpdateChecker();
//   }

//   @override
//   void dispose() {
//     _weekUpdateTimer?.cancel();
//     super.dispose();
//   }

//   void _startWeekUpdateChecker() {
//     // Check immediately
//     _checkForWeekUpdate();
    
//     // Then check every hour
//     _weekUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
//       _checkForWeekUpdate();
//     });
//   }

//   Future<void> _checkForWeekUpdate() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final trackerQuery = await FirebaseFirestore.instance
//           .collection('trackingweeks')
//           .where('userId', isEqualTo: user.uid)
//           .limit(1)
//           .get();

//       if (trackerQuery.docs.isNotEmpty) {
//         final trackerDoc = trackerQuery.docs.first;
//         final data = trackerDoc.data();
//         final lastUpdate = data['weekSelectedDate']?.toDate();
//         final lastPeriodDate = data['lastPeriodDate']?.toDate();

//         if (lastUpdate != null && lastPeriodDate != null) {
//           final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
//           final calculatedWeek = (DateTime.now().difference(lastPeriodDate).inDays / 7).floor().clamp(1, 40);

//           if (daysSinceUpdate >= 7 && calculatedWeek > _currentWeek) {
//             // Update in Firestore
//             await trackerDoc.reference.update({
//               'currentWeek': calculatedWeek,
//               'weekSelectedDate': Timestamp.now(),
//               'updatedAt': FieldValue.serverTimestamp(),
//             });

//             if (mounted) {
//               setState(() => _currentWeek = calculatedWeek);
//               _showWeekUpdateMessage(calculatedWeek);
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Week update error: $e');
//     }
//   }

//   void _showWeekUpdateMessage(int newWeek) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('🎉 Congratulations! You are now in week $newWeek'),
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }

//   String _getTrimester() {
//     if (_currentWeek <= 12) return '1st Trimester';
//     if (_currentWeek <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Week $_currentWeek'),
//         backgroundColor: const Color(0xFF4A6FA5),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Week information
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Text(
//                       'You are in week $_currentWeek of your pregnancy',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'Trimester: ${_getTrimester()}',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
//             const Text(
//               'BABY DEVELOPMENT',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _buildDevelopmentCard(),

//             const SizedBox(height: 20),
//             const Text(
//               'HELPFUL TIPS',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _buildTipsCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentCard() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildDevelopmentItem('Size', 'About the size of a ${_getFruitSize()}'),
//             const Divider(),
//             _buildDevelopmentItem('Length', _getBabyLength()),
//             const Divider(),
//             _buildDevelopmentItem('Weight', _getBabyWeight()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipsCard() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildTipItem(Icons.favorite, 'Take your prenatal vitamins'),
//             const Divider(),
//             _buildTipItem(Icons.water, 'Stay hydrated'),
//             const Divider(),
//             _buildTipItem(Icons.directions_walk, 'Gentle exercise daily'),
//             if (_currentWeek > 28) ...[
//               const Divider(),
//               _buildTipItem(Icons.access_time, 'Practice breathing exercises'),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDevelopmentItem(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           Text(value),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blue),
//           const SizedBox(width: 10),
//           Text(text),
//         ],
//       ),
//     );
//   }

//   String _getFruitSize() {
//     const fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 
//       'Grape', 'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 
//       'Apple', 'Avocado', 'Onion', 'Sweet Potato', 'Mango', 'Banana'
//     ];
//     return fruits[(_currentWeek - 1).clamp(0, fruits.length - 1)];
//   }

//   String _getBabyLength() {
//     if (_currentWeek < 5) return '----';
//     const lengths = [3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116];
//     return '${lengths[(_currentWeek - 5).clamp(0, lengths.length - 1)]} mm';
//   }

//   String _getBabyWeight() {
//     if (_currentWeek < 6) return '----';
//     const weights = [0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100];
//     return '${weights[(_currentWeek - 6).clamp(0, weights.length - 1)]} grams';
//   }
// }







// import 'package:flutter/material.dart';

// class TrackerDetailScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackerDetailScreen({super.key, required this.pregnancyWeek});

//   String getTrimester(int week) {
//     if (week <= 12) return '1st Trimester';
//     if (week <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   Color getTrimesterColor(String trimester) {
//     switch (trimester) {
//       case '1st Trimester':
//         return const Color(0xFFFF9AA2);
//       case '2nd Trimester':
//         return const Color(0xFFFFB7B2);
//       case '3rd Trimester':
//         return const Color(0xFFB5EAD7);
//       default:
//         return Colors.grey;
//     }
//   }

//   String getFruitName(int week) {
//     final fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 'Grape',
//       'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 'Apple', 'Avocado',
//       'Onion', 'Sweet Potato', 'Mango', 'Banana', 'Pomegranate', 'Papaya',
//       'Grapefruit', 'Coconut', 'Pineapple', 'Cantaloupe', 'Cauliflower', 'Lettuce',
//       'Watermelon', 'Pumpkin', 'Jackfruit', 'Leek', 'Swiss Chard', 'Butternut Squash',
//       'Honeydew', 'Cabbage', 'Celery', 'Eggplant', 'Zucchini', 'Durian', 'Coconut',
//       'Pumpkin'
//     ];
//     return fruits[(week - 1).clamp(0, fruits.length - 1)];
//   }

//   String getLength(int week) {
//     if (week < 5) return '----';
//     final lengths = [
//       3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116, 130, 142, 153, 
//       165, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 
//       300, 310, 320, 330, 340, 350, 360, 370
//     ];
//     final index = (week - 5).clamp(0, lengths.length - 1);
//     return '${(lengths[index] / 10).toStringAsFixed(1)} cm';
//   }

//   String getWeight(int week) {
//     if (week < 6) return '----';
//     final weights = [
//       0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100, 140, 190, 240, 
//       300, 360, 430, 500, 600, 700, 800, 900, 1000, 1150, 1300, 
//       1500, 1700, 1900, 2100, 2400, 2600, 2800, 3000, 3200, 3400
//     ];
//     final index = (week - 5).clamp(0, weights.length - 1);
//     return '${(weights[index] / 1000).toStringAsFixed(3)} kg';
//   }

//   Map<String, String> getFoodSuggestion(int week) {
//     final foods = {
//       1: {
//         'food': 'Folic Acid-rich Foods',
//         'image': 'assets/images/f1.jpg',
//         'description': 'Leafy greens, citrus fruits, and fortified cereals for early development'
//       },
//       5: {
//         'food': 'Spinach & Lentils',
//         'image': 'assets/images/f2.jpg',
//         'description': 'Iron-rich foods to support increased blood volume'
//       },
//       10: {
//         'food': 'Sweet Potatoes',
//         'image': 'assets/images/f3.jpg',
//         'description': 'Beta-carotene for baby\'s cell and tissue development'
//       },
//       15: {
//         'food': 'Iron-rich Foods',
//         'image': 'assets/images/f4.jpg',
//         'description': 'Lean meats, beans, and iron-fortified cereals'
//       },
//       20: {
//         'food': 'Bananas & Yogurt',
//         'image': 'assets/images/f5.jpg',
//         'description': 'Calcium and potassium for bone and muscle development'
//       },
//       25: {
//         'food': 'Salmon & Broccoli',
//         'image': 'assets/images/f6.jpg',
//         'description': 'Omega-3s for brain development and calcium for bones'
//       },
//       30: {
//         'food': 'Oats & Berries',
//         'image': 'assets/images/f7.jpg',
//         'description': 'Fiber to prevent constipation and antioxidants'
//       },
//       35: {
//         'food': 'Eggs & Avocados',
//         'image': 'assets/images/f8.jpg',
//         'description': 'Protein and healthy fats for final growth spurt'
//       },
//       40: {
//         'food': 'Dates & Hydration',
//         'image': 'assets/images/f9.jpg',
//         'description': 'Natural sugars for energy and plenty of fluids'
//       },
//     };
    
//     int key = foods.keys.lastWhere((k) => k <= week, orElse: () => 1);
//     return foods[key]!;
//   }

//   Widget _buildStatTile(String title, String value, IconData icon, Color iconColor) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: iconColor.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: iconColor, size: 24),
//             ),
//             const SizedBox(width: 16),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTrimesterChart(String currentTrimester) {
//     final trimesters = ['1st Trimester', '2nd Trimester', '3rd Trimester'];
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: trimesters.map((trimester) {
//           final isActive = trimester == currentTrimester;
//           final color = isActive ? getTrimesterColor(trimester) : Colors.grey.shade200;

//           return Expanded(
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               child: Center(
//                 child: Text(
//                   trimester,
//                   style: TextStyle(
//                     color: isActive ? Colors.white : Colors.grey.shade600,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final length = getLength(pregnancyWeek);
//     final weight = getWeight(pregnancyWeek);
//     final trimester = getTrimester(pregnancyWeek);
//     final trimesterColor = getTrimesterColor(trimester);
//     final foodInfo = getFoodSuggestion(pregnancyWeek);
//     final fruit = getFruitName(pregnancyWeek);
    
// return Scaffold(
//   appBar: AppBar(
//     backgroundColor: const Color(0xFF4A6FA5),
//     elevation: 0,
//     title: Text(
//       'Week $pregnancyWeek',
//       style: const TextStyle(
//         fontWeight: FontWeight.bold,
//         fontSize: 20,
//       ),
//     ),
//     centerTitle: true,
//     iconTheme: const IconThemeData(color: Colors.white),
//     leading: IconButton(
//       icon: const Icon(Icons.arrow_back),
//       onPressed: () {
//         Navigator.pushNamed(context, '/home');
//       },
//     ),
//     actions: [
//       IconButton(
//         icon: const Icon(Icons.info_outline),
//         onPressed: () {
//           showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Text('Pregnancy Tracker'),
//               content: const Text(
//                 'This screen shows detailed information about your baby\'s development, nutrition recommendations, and helpful tips for each week of pregnancy.',
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('OK'),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     ],
//   ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Food Recommendation Card
//             Card(
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(16),
//                     ),
//                     child: Container(
//                       height: 160,
//                       color: Colors.grey.shade100,
//                       alignment: Alignment.center,
//                       child: const Icon(Icons.restaurant_menu, 
//                           size: 60, color: Colors.grey),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'NUTRITION RECOMMENDATION',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue.shade700,
//                             letterSpacing: 1,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           foodInfo['food']!,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           foodInfo['description']!,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                             height: 1.5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Trimester Information
//             _buildTrimesterChart(trimester),
//             const SizedBox(height: 24),

//             // Baby Development Section
//             const Text(
//               'BABY DEVELOPMENT',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildStatTile(
//               'Length',
//               length,
//               Icons.straighten,
//               const Color(0xFF4A6FA5),
//             ),
//             _buildStatTile(
//               'Weight',
//               weight,
//               Icons.monitor_weight,
//               const Color(0xFF6A8CBB),
//             ),
//             _buildStatTile(
//               'Size Comparison',
//               'Size of a $fruit',
//               Icons.eco,
//               const Color(0xFF88B04B),
//             ),

//             // Additional Tips Section
//             const SizedBox(height: 32),
//             const Text(
//               'HELPFUL TIPS',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Card(
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     _buildTipItem(
//                       Icons.favorite,
//                       const Color(0xFFFF6B6B),
//                       'Schedule your prenatal checkup',
//                     ),
//                     _buildTipItem(
//                       Icons.water,
//                       const Color(0xFF4CC9F0),
//                       'Drink at least 8 glasses of water daily',
//                     ),
//                     _buildTipItem(
//                       Icons.directions_walk,
//                       const Color(0xFF72D99F),
//                       '30 minutes of gentle exercise daily',
//                     ),
//                     if (pregnancyWeek > 28)
//                       _buildTipItem(
//                         Icons.access_time,
//                         const Color(0xFFF8961E),
//                         'Practice breathing techniques for labor',
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, Color color, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 20),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 14,
//                 height: 1.5,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }






































// import 'package:flutter/material.dart';

// class TrackerDetailScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackerDetailScreen({super.key, required this.pregnancyWeek});

//   String getTrimester(int week) {
//     if (week <= 12) return '1st Trimester';
//     if (week <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   Color getTrimesterColor(String trimester) {
//     switch (trimester) {
//       case '1st Trimester':
//         return const Color(0xFFFF9AA2); // Soft pink
//       case '2nd Trimester':
//         return const Color(0xFFFFB7B2); // Coral
//       case '3rd Trimester':
//         return const Color(0xFFB5EAD7); // Mint green
//       default:
//         return Colors.grey;
//     }
//   }

//   String getFruitName(int week) {
//     final fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 'Grape',
//       'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 'Apple', 'Avocado',
//       'Onion', 'Sweet Potato', 'Mango', 'Banana', 'Pomegranate', 'Papaya',
//       'Grapefruit', 'Coconut', 'Pineapple', 'Cantaloupe', 'Cauliflower', 'Lettuce',
//       'Watermelon', 'Pumpkin', 'Jackfruit', 'Leek', 'Swiss Chard', 'Butternut Squash',
//       'Honeydew', 'Cabbage', 'Celery', 'Eggplant', 'Zucchini', 'Durian', 'Coconut',
//       'Pumpkin'
//     ];
//     return fruits[(week - 1).clamp(0, fruits.length - 1)];
//   }

//   String getLength(int week) {
//     if (week < 5) return '----';
//     final lengths = [
//       3, 5, 10, 16, 23, 31, 41, 55, 75, 87, 103, 116, 130, 142, 153, 
//       165, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 
//       300, 310, 320, 330, 340, 350, 360, 370
//     ];
//     final index = (week - 5).clamp(0, lengths.length - 1);
//     return '${(lengths[index] / 10).toStringAsFixed(1)} cm';
//   }

//   String getWeight(int week) {
//     if (week < 6) return '----';
//     final weights = [
//       0, 1, 1.5, 2, 3, 5, 8, 14, 23, 43, 70, 100, 140, 190, 240, 
//       300, 360, 430, 500, 600, 700, 800, 900, 1000, 1150, 1300, 
//       1500, 1700, 1900, 2100, 2400, 2600, 2800, 3000, 3200, 3400
//     ];
//     final index = (week - 5).clamp(0, weights.length - 1);
//     return '${(weights[index] / 1000).toStringAsFixed(3)} kg';
//   }

//   Map<String, String> getFoodSuggestion(int week) {
//     final foods = {
//       1: {
//         'food': 'Folic Acid-rich Foods',
//         'image': 'assets/images/f1.jpg',
//         'description': 'Leafy greens, citrus fruits, and fortified cereals for early development'
//       },
//       5: {
//         'food': 'Spinach & Lentils',
//         'image': 'assets/images/f2.jpg',
//         'description': 'Iron-rich foods to support increased blood volume'
//       },
//       10: {
//         'food': 'Sweet Potatoes',
//         'image': 'assets/images/f3.jpg',
//         'description': 'Beta-carotene for baby\'s cell and tissue development'
//       },
//       15: {
//         'food': 'Iron-rich Foods',
//         'image': 'assets/images/f4.jpg',
//         'description': 'Lean meats, beans, and iron-fortified cereals'
//       },
//       20: {
//         'food': 'Bananas & Yogurt',
//         'image': 'assets/images/f5.jpg',
//         'description': 'Calcium and potassium for bone and muscle development'
//       },
//       25: {
//         'food': 'Salmon & Broccoli',
//         'image': 'assets/images/f6.jpg',
//         'description': 'Omega-3s for brain development and calcium for bones'
//       },
//       30: {
//         'food': 'Oats & Berries',
//         'image': 'assets/images/f7.jpg',
//         'description': 'Fiber to prevent constipation and antioxidants'
//       },
//       35: {
//         'food': 'Eggs & Avocados',
//         'image': 'assets/images/f8.jpg',
//         'description': 'Protein and healthy fats for final growth spurt'
//       },
//       40: {
//         'food': 'Dates & Hydration',
//         'image': 'assets/images/f9.jpg',
//         'description': 'Natural sugars for energy and plenty of fluids'
//       },
//     };
    
//     int key = foods.keys.lastWhere((k) => k <= week, orElse: () => 1);
//     return foods[key]!;
//   }

//   Widget _buildStatTile(String title, String value, IconData icon, Color iconColor) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: iconColor.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: iconColor, size: 24),
//             ),
//             const SizedBox(width: 16),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTrimesterChart(String currentTrimester) {
//     final trimesters = ['1st Trimester', '2nd Trimester', '3rd Trimester'];
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: trimesters.map((trimester) {
//           final isActive = trimester == currentTrimester;
//           final color = isActive ? getTrimesterColor(trimester) : Colors.grey.shade200;

//           return Expanded(
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               child: Center(
//                 child: Text(
//                   trimester,
//                   style: TextStyle(
//                     color: isActive ? Colors.white : Colors.grey.shade600,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final length = getLength(pregnancyWeek);
//     final weight = getWeight(pregnancyWeek);
//     final trimester = getTrimester(pregnancyWeek);
//     final trimesterColor = getTrimesterColor(trimester);
//     final foodInfo = getFoodSuggestion(pregnancyWeek);
//     final fruit = getFruitName(pregnancyWeek);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F9F9),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF4A6FA5),
//         elevation: 0,
//         title: Text(
//           'Week $pregnancyWeek',
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline),
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text('Pregnancy Tracker'),
//                   content: const Text(
//                     'This screen shows detailed information about your baby\'s development, nutrition recommendations, and helpful tips for each week of pregnancy.',
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('OK'),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Food Recommendation Card
//             Card(
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(16),
//                     ),
//                     child: Container(
//                       height: 160,
//                       color: Colors.grey.shade100,
//                       alignment: Alignment.center,
//                       child: const Icon(Icons.restaurant_menu, 
//                           size: 60, color: Colors.grey),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'NUTRITION RECOMMENDATION',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue.shade700,
//                             letterSpacing: 1,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           foodInfo['food']!,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           foodInfo['description']!,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                             height: 1.5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Trimester Information
//             _buildTrimesterChart(trimester),
//             const SizedBox(height: 24),

//             // Baby Development Section
//             const Text(
//               'BABY DEVELOPMENT',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildStatTile(
//               'Length',
//               length,
//               Icons.straighten,
//               const Color(0xFF4A6FA5),
//             ),
//             _buildStatTile(
//               'Weight',
//               weight,
//               Icons.monitor_weight,
//               const Color(0xFF6A8CBB),
//             ),
//             _buildStatTile(
//               'Size Comparison',
//               'Size of a $fruit',
//               Icons.eco,
//               const Color(0xFF88B04B),
//             ),

//             // Additional Tips Section
//             const SizedBox(height: 32),
//             const Text(
//               'HELPFUL TIPS',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Card(
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     _buildTipItem(
//                       Icons.favorite,
//                       const Color(0xFFFF6B6B),
//                       'Schedule your prenatal checkup',
//                     ),
//                     _buildTipItem(
//                       Icons.water,
//                       const Color(0xFF4CC9F0),
//                       'Drink at least 8 glasses of water daily',
//                     ),
//                     _buildTipItem(
//                       Icons.directions_walk,
//                       const Color(0xFF72D99F),
//                       '30 minutes of gentle exercise daily',
//                     ),
//                     if (pregnancyWeek > 28)
//                       _buildTipItem(
//                         Icons.access_time,
//                         const Color(0xFFF8961E),
//                         'Practice breathing techniques for labor',
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, Color color, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 20),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 14,
//                 height: 1.5,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



































// import 'package:flutter/material.dart';

// class TrackerDetailScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackerDetailScreen({super.key, required this.pregnancyWeek});

//   String getTrimester(int week) {
//     if (week <= 12) return '1st Trimester';
//     if (week <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   Color getTrimesterColor(String trimester) {
//     switch (trimester) {
//       case '1st Trimester':
//         return Colors.pinkAccent;
//       case '2nd Trimester':
//         return Colors.deepOrangeAccent;
//       case '3rd Trimester':
//         return Colors.lightGreen;
//       default:
//         return Colors.grey;
//     }
//   }

//   String getFruitName(int week) {
//     final fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 'Grape',
//       'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 'Apple', 'Avocado',
//       'Onion', 'Sweet Potato', 'Mango', 'Banana', 'Pomegranate', 'Papaya',
//       'Grapefruit', 'Coconut', 'Pineapple', 'Cantaloupe', 'Cauliflower', 'Lettuce',
//       'Watermelon', 'Pumpkin', 'Jackfruit', 'Leek', 'Swiss Chard', 'Butternut Squash',
//       'Honeydew', 'Cabbage', 'Celery', 'Eggplant', 'Zucchini', 'Durian', 'Coconut',
//       'Pumpkin'
//     ];
//     return fruits[(week - 1).clamp(0, fruits.length - 1)];
//   }

//  String getLength(int week) {
//   if (week < 5) return '----';
//   final lengths = [ /* same array as above */ ];
//   final index = (week - 5).clamp(0, lengths.length - 1);
//   return '${(lengths[index] / 10).toStringAsFixed(1)} cm'; // mm to cm
// }

// String getWeight(int week) {
//   if (week < 6) return '----';
//   final weights = [ /* same array as above */ ];
//   final index = (week - 5).clamp(0, weights.length - 1);
//   return '${(weights[index] / 1000).toStringAsFixed(3)} kg'; // g to kg
// }

 


   

//   Widget _buildStatTile(String title, String value, IconData icon, Color iconColor) {
//     return Card(
//       elevation: 3,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: Icon(icon, color: iconColor, size: 30),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(value, style: const TextStyle(color: Colors.black87)),
//       ),
//     );
//   }

//   Widget _buildTrimesterChart(String currentTrimester) {
//     final trimesters = ['1st Trimester', '2nd Trimester', '3rd Trimester'];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: trimesters.map((trimester) {
//         final isActive = trimester == currentTrimester;
//         final color = isActive ? getTrimesterColor(trimester) : Colors.grey.shade300;

//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.8),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Text(
//             trimester,
//             style: TextStyle(
//               color: isActive ? Colors.white : Colors.black45,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final length = getLength(pregnancyWeek);
//     final weight = getWeight(pregnancyWeek);
//     final trimester = getTrimester(pregnancyWeek);
//     final trimesterColor = getTrimesterColor(trimester);
//     final foodInfo = getFoodSuggestion(pregnancyWeek);
//     final fruit = getFruitName(pregnancyWeek);

//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: Colors.blueAccent,
//         title: Text('Week $pregnancyWeek Tracker'),
//         iconTheme: const IconThemeData(color: Colors.white),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline),
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text('Pregnancy Tracker'),
//                   content: const Text(
//                     'This screen shows your current pregnancy week details including baby development and nutrition recommendations.',
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('OK'),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Food Recommendation Card
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(12),
//                     ),
                    
//                         color: Colors.grey.shade200,
//                         child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Nutrition Recommendation',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue.shade800,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
                       
//                         const SizedBox(height: 8),
//                         Text(
//                           foodInfo['description']!,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade700,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Trimester Information
//             Text(
//               'Trimester: $trimester',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: trimesterColor,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _buildTrimesterChart(trimester),
//             const SizedBox(height: 24),

//             // Baby Development Section
//             const Text(
//               'Baby\'s Development This Week:',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             _buildStatTile(
//               'Length',
//               length,
//               Icons.straighten,
//               Colors.blueAccent,
//             ),
//             _buildStatTile(
//               'Weight',
//               weight,
//               Icons.monitor_weight_outlined,
//               Colors.deepOrange,
//             ),
//             _buildStatTile(
//               'Size Comparison',
//               'About the size of a $fruit',
//               Icons.eco,
//               Colors.green,
//             ),

//             // Additional Tips Section
//             const SizedBox(height: 24),
//             const Text(
//               'Tips for This Week:',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   children: [
//                     _buildTipItem(
//                       Icons.favorite,
//                       Colors.red,
//                       'Get regular prenatal checkups',
//                     ),
//                     _buildTipItem(
//                       Icons.water_drop,
//                       Colors.blue,
//                       'Stay hydrated - drink at least 8 glasses of water daily',
//                     ),
//                     _buildTipItem(
//                       Icons.directions_walk,
//                       Colors.green,
//                       'Gentle exercise like walking or prenatal yoga',
//                     ),
//                     if (pregnancyWeek > 28)
//                       _buildTipItem(
//                         Icons.timer,
//                         Colors.orange,
//                         'Start preparing for labor and delivery',
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(IconData icon, Color color, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';

// class TrackerDetailScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackerDetailScreen({super.key, required this.pregnancyWeek});

//   String getTrimester(int week) {
//     if (week <= 12) return '1st Trimester';
//     if (week <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   Color getTrimesterColor(String trimester) {
//     switch (trimester) {
//       case '1st Trimester':
//         return Colors.pinkAccent;
//       case '2nd Trimester':
//         return Colors.deepOrangeAccent;
//       case '3rd Trimester':
//         return Colors.lightGreen;
//       default:
//         return Colors.grey;
//     }
//   }

//   String getFruitName(int week) {
//     final fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 'Grape',
//       'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 'Apple', 'Avocado',
//       'Onion', 'Sweet Potato', 'Mango', 'Banana', 'Pomegranate', 'Papaya',
//       'Grapefruit', 'Coconut', 'Pineapple', 'Cantaloupe', 'Cauliflower', 'Lettuce',
//       'Watermelon', 'Pumpkin', 'Jackfruit', 'Leek', 'Swiss Chard', 'Butternut Squash',
//       'Honeydew', 'Cabbage', 'Celery', 'Eggplant', 'Zucchini', 'Durian', 'Coconut',
//       'Pumpkin'
//     ];
//     return fruits[(week - 1).clamp(0, fruits.length - 1)];
//   }

//   String getLength(int week) {
//     if (week < 5) return '----';
//     if (week == 5) return '0.3 cm';
//     if (week <= 12) return '${(week * 0.5 + 1.5).toStringAsFixed(1)} cm';
//     if (week <= 27) return '${(week * 1.1).toStringAsFixed(1)} cm';
//     return '${(week * 1.5).toStringAsFixed(1)} cm';
//   }

//   String getWeight(int week) {
//     if (week < 6) return '----';
//     if (week <= 12) return '${(week * 0.05 + 0.05).toStringAsFixed(2)} kg';
//     if (week <= 27) return '${(week * 0.1 + 0.1).toStringAsFixed(2)} kg';
//     return '${(week * 0.2 + 0.2).toStringAsFixed(2)} kg';
//   }

//   Map<String, String> getFoodSuggestion(int week) {
//     final foods = {
//       1: ['Folic Acid-rich Foods', 'assets/images/f1.jpg'],
//       5: ['Spinach & Lentils', 'assets/images/f2.jpg'],
//       10: ['Sweet Potatoes', 'assets/images/f3.jpg'],
//       15: ['Iron-rich Foods', 'assets/images/f4.jpg'],
//       20: ['Bananas & Yogurt', 'assets/images/f5.jpg'],
//       25: ['Salmon & Broccoli', 'assets/images/f6.jpg'],
//       30: ['Oats & Berries', 'assets/images/f7.jpg'],
//       35: ['Eggs & Avocados', 'assets/images/f8.jpg'],
//       40: ['Dates & Hydration', 'assets/images/f9.jpg'],
//     };
//     int key = foods.keys.lastWhere((k) => k <= week, orElse: () => 1);
//     return {
//       'food': foods[key]![0],
     
//     };
//   }

//   Widget _buildStatTile(String title, String value, IconData icon, Color iconColor) {
//     return Card(
//       elevation: 3,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: Icon(icon, color: iconColor, size: 30),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(value, style: const TextStyle(color: Colors.black87)),
//       ),
//     );
//   }

//   Widget _buildTrimesterChart(String currentTrimester) {
//     final trimesters = ['1st Trimester', '2nd Trimester', '3rd Trimester'];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: trimesters.map((trimester) {
//         final isActive = trimester == currentTrimester;
//         final color = isActive ? getTrimesterColor(trimester) : Colors.grey.shade300;

//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.8),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Text(
//             trimester,
//             style: TextStyle(
//               color: isActive ? Colors.white : Colors.black45,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final length = getLength(pregnancyWeek);
//     final weight = getWeight(pregnancyWeek);
//     final trimester = getTrimester(pregnancyWeek);
//     final trimesterColor = getTrimesterColor(trimester);
//     final foodInfo = getFoodSuggestion(pregnancyWeek);
//     final fruit = getFruitName(pregnancyWeek);

//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: Colors.blueAccent,
//         title: Text('Week $pregnancyWeek Tracker'),
//         iconTheme: const IconThemeData(color: Colors.white),
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.asset(
//                 foodInfo['image']!,
//                 height: 180,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text('Trimester: $trimester',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: trimesterColor,
//                 )),
//             const SizedBox(height: 10),
//             _buildTrimesterChart(trimester),
//             const SizedBox(height: 24),

//             const Text('Baby\'s Growth This Week:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//            _buildStatTile('Length', length, Icons.straighten, Colors.blueAccent),

//             _buildStatTile('Weight', weight, Icons.monitor_weight_outlined, Colors.deepOrange),
//             _buildStatTile('Size of', 'About the size of a $fruit', Icons.eco, Colors.green),

           
//             const SizedBox(height: 12),
//             Card(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               elevation: 3,
              
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Text(
//                       foodInfo['food']!,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


















// import 'package:flutter/material.dart';

// class TrackerDetailScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackerDetailScreen({super.key, required this.pregnancyWeek});

//   String getTrimester(int week) {
//     if (week <= 12) return '1st Trimester';
//     if (week <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   Color getTrimesterColor(String trimester) {
//     switch (trimester) {
//       case '1st Trimester':
//         return Colors.pink;
//       case '2nd Trimester':
//         return Colors.orange;
//       case '3rd Trimester':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   String getFruitName(int week) {
//     final fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 'Grape',
//       'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 'Apple', 'Avocado',
//       'Onion', 'Sweet Potato', 'Mango', 'Banana', 'Pomegranate', 'Papaya',
//       'Grapefruit', 'Coconut', 'Pineapple', 'Cantaloupe', 'Cauliflower', 'Lettuce',
//       'Watermelon', 'Pumpkin', 'Jackfruit', 'Leek', 'Swiss Chard', 'Butternut Squash',
//       'Honeydew', 'Cabbage', 'Celery', 'Eggplant', 'Zucchini', 'Durian', 'Coconut',
//       'Pumpkin'
//     ];
//     return fruits[(week - 1).clamp(0, fruits.length - 1)];
//   }

//   String getLength(int week) {
//     if (week < 5) return '----';
//     if (week == 5) return '0.3 cm';
//     if (week <= 12) return '${(week * 0.5 + 1.5).toStringAsFixed(1)} cm';
//     if (week <= 27) return '${(week * 1.1).toStringAsFixed(1)} cm';
//     return '${(week * 1.5).toStringAsFixed(1)} cm';
//   }

//   String getWeight(int week) {
//     if (week < 6) return '----';
//     if (week <= 12) return '${(week * 0.05 + 0.05).toStringAsFixed(2)} kg';
//     if (week <= 27) return '${(week * 0.1 + 0.1).toStringAsFixed(2)} kg';
//     return '${(week * 0.2 + 0.2).toStringAsFixed(2)} kg';
//   }

//   Map<String, String> getFoodSuggestion(int week) {
//     final foods = {
//       1: ['Folic Acid-rich Foods', 'assets/images/f1.jpg'],
//       5: ['Spinach & Lentils', 'assets/images/f2.jpg'],
//       10: ['Sweet Potatoes', 'assets/images/f3.jpg'],
//       15: ['Iron-rich Foods', 'assets/images/f4.jpg'],
//       20: ['Bananas & Yogurt', 'assets/images/f5.jpg'],
//       25: ['Salmon & Broccoli', 'assets/images/f6.jpg'],
//       30: ['Oats & Berries', 'assets/images/f7.jpg'],
//       35: ['Eggs & Avocados', 'assets/images/f8.jpg'],
//       40: ['Dates & Hydration', 'assets/images/f9.jpg'],
//     };

//     int key = foods.keys.lastWhere((k) => k <= week, orElse: () => 1);
//     return {
//       'food': foods[key]![0],
//       'image': foods[key]![1], // Fixed here!
//     };
//   }

//   Widget _buildStatTile(String title, String value, IconData icon, Color iconColor) {
//     return Card(
//       color: Colors.white.withOpacity(0.1),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: Icon(icon, color: iconColor),
//         title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         subtitle: Text(value, style: const TextStyle(color: Colors.white70)),
//       ),
//     );
//   }

//   Widget _buildTrimesterChart(String currentTrimester) {
//     final trimesters = ['1st Trimester', '2nd Trimester', '3rd Trimester'];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: trimesters.map((trimester) {
//         final isActive = trimester == currentTrimester;
//         final color = isActive ? getTrimesterColor(trimester) : Colors.white24;

//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.4),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Text(
//             trimester,
//             style: TextStyle(
//               color: isActive ? Colors.white : Colors.white70,
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final length = getLength(pregnancyWeek);
//     final weight = getWeight(pregnancyWeek);
//     final trimester = getTrimester(pregnancyWeek);
//     final trimesterColor = getTrimesterColor(trimester);
//     final foodInfo = getFoodSuggestion(pregnancyWeek);
//     final fruit = getFruitName(pregnancyWeek);

//     return Scaffold(
//       backgroundColor: Colors.blue[900],
//       appBar: AppBar(
//         backgroundColor: Colors.blue[800],
//         title: Text(
//           'Week $pregnancyWeek Tracker',
//           style: const TextStyle(color: Colors.white),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Column(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: Image.asset(
//                       foodInfo['image']!,
//                       height: 160,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Trimester: $trimester',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: trimesterColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   _buildTrimesterChart(trimester),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             const Text('Baby\'s Growth This Week:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
//             const SizedBox(height: 12),
//             _buildStatTile('Length', length, Icons.height, Colors.tealAccent),
//             _buildStatTile('Weight', weight, Icons.monitor_weight, Colors.orangeAccent),
//             _buildStatTile('Size of', 'About the size of a $fruit', Icons.spa, Colors.greenAccent),
//             const SizedBox(height: 24),

//             const Text('Weekly Food Suggestion:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
//             const SizedBox(height: 12),
//             Card(
//               color: Colors.white.withOpacity(0.1),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.asset(
//                       foodInfo['image']!,
//                       height: 150,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Text(
//                       foodInfo['food']!,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.white,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }























// import 'package:flutter/material.dart';

// class TrackerDetailScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackerDetailScreen({super.key, required this.pregnancyWeek});

//   String getTrimester(int week) {
//     if (week <= 12) return '1st Trimester';
//     if (week <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   Color getTrimesterColor(String trimester) {
//     switch (trimester) {
//       case '1st Trimester':
//         return Colors.pink;
//       case '2nd Trimester':
//         return Colors.orange;
//       case '3rd Trimester':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   String getFruitName(int week) {
//     final fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 'Grape',
//       'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 'Apple', 'Avocado',
//       'Onion', 'Sweet Potato', 'Mango', 'Banana', 'Pomegranate', 'Papaya',
//       'Grapefruit', 'Coconut', 'Pineapple', 'Cantaloupe', 'Cauliflower', 'Lettuce',
//       'Watermelon', 'Pumpkin', 'Jackfruit', 'Leek', 'Swiss Chard', 'Butternut Squash',
//       'Honeydew', 'Cabbage', 'Celery', 'Eggplant', 'Zucchini', 'Durian', 'Coconut',
//       'Pumpkin'
//     ];
//     return fruits[(week - 1).clamp(0, fruits.length - 1)];
//   }

//   String getLength(int week) {
//     if (week < 5) return '----';
//     if (week == 5) return '0.3 cm';
//     if (week <= 12) return '${(week * 0.5 + 1.5).toStringAsFixed(1)} cm';
//     if (week <= 27) return '${(week * 1.1).toStringAsFixed(1)} cm';
//     return '${(week * 1.5).toStringAsFixed(1)} cm';
//   }

//   String getWeight(int week) {
//     if (week < 6) return '----';
//     if (week <= 12) return '${(week * 0.05 + 0.05).toStringAsFixed(2)} kg';
//     if (week <= 27) return '${(week * 0.1 + 0.1).toStringAsFixed(2)} kg';
//     return '${(week * 0.2 + 0.2).toStringAsFixed(2)} kg';
//   }

//   Map<String, String> getFoodSuggestion(int week) {
//     final foods = {
//       1: ['Folic Acid-rich Foods', 'assets/images/f1.jpg'],
//       5: ['Spinach & Lentils', 'assets/images/f2.jpg'],
//       10: ['Sweet Potatoes', 'assets/images/f3.jpg'],
//       15: ['Iron-rich Foods', 'assets/images/f4.jpg'],
//       20: ['Bananas & Yogurt', 'assets/images/f5.jpg'],
//       25: ['Salmon & Broccoli', 'assets/images/f6.jpg'],
//       30: ['Oats & Berries', 'assets/images/f7.jpg'],
//       35: ['Eggs & Avocados', 'assets/images/f8.jpg'],
//       40: ['Dates & Hydration', 'assets/images/f9.jpg'],
//     };

//     int key = foods.keys.lastWhere((k) => k <= week, orElse: () => 1);
//     return {
//       'food': foods[key]![0],
//       'image': foods[key]![1],
//     };
//   }

//   Widget _buildStatTile(String title, String value, IconData icon, Color color) {
//     return Card(
//       color: Colors.blue[900],
//       elevation: 3,
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white, size: 28),
//         title: Text(title,
//             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         subtitle: Text(value,
//             style: const TextStyle(color: Colors.white70, fontSize: 16)),
//       ),
//     );
//   }

//   Widget _buildTrimesterChart(String currentTrimester) {
//     final trimesters = ['1st Trimester', '2nd Trimester', '3rd Trimester'];

//     return Table(
//       children: [
//         TableRow(
//           children: trimesters.map((trimester) {
//             bool isActive = trimester == currentTrimester;
//             Color color = isActive ? getTrimesterColor(trimester) : Colors.blue[900]!;

//             return Container(
//               margin: const EdgeInsets.all(8),
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Center(
//                 child: Text(
//                   trimester,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: color,
//                     fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         )
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final length = getLength(pregnancyWeek);
//     final weight = getWeight(pregnancyWeek);
//     final trimester = getTrimester(pregnancyWeek);
//     final trimesterColor = getTrimesterColor(trimester);
//     final foodInfo = getFoodSuggestion(pregnancyWeek);
//     final fruit = getFruitName(pregnancyWeek);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Week $pregnancyWeek Tracker'),
//         backgroundColor: trimesterColor,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Fruit Image and Trimester info
//             Center(
//               child: Column(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: Image.asset(
//                       foodInfo['image']!,
//                       height: 150,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Trimester: $trimester',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: trimesterColor,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _buildTrimesterChart(trimester),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             const Text('Baby\'s Growth This Week:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             _buildStatTile('Length', length, Icons.height, Colors.blue),
//             _buildStatTile('Weight', weight, Icons.monitor_weight, Colors.orange),
//             _buildStatTile(
//                 'Size of', 'About the size of a $fruit', Icons.spa, Colors.green),

//             const SizedBox(height: 24),

//             const Text('Weekly Food Suggestion:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.asset(
//                       foodInfo['image']!,
//                       height: 150,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Text(foodInfo['food']!,
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';

// class TrackerDetailScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackerDetailScreen({super.key, required this.pregnancyWeek});

//   // Xisaabi trimester-ka iyadoo laga duulayo week
//   String getTrimester(int week) {
//     if (week <= 12) return '1st ';
//     if (week <= 27) return '2nd ';
//     return '3rd ';
//   }

//   // Midabka trimester
//   Color getTrimesterColor(String trimester) {
//     switch (trimester) {
//       case '1st Trimester':
//         return Colors.pink;
//       case '2nd Trimester':
//         return Colors.orange;
//       case '3rd Trimester':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   // Magaca miro ku salaysan week
//   String getFruitName(int week) {
//     final fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 'Grape',
//       'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 'Apple', 'Avocado',
//       'Onion', 'Sweet Potato', 'Mango', 'Banana', 'Pomegranate', 'Papaya',
//       'Grapefruit', 'Coconut', 'Pineapple', 'Cantaloupe', 'Cauliflower', 'Lettuce',
//       'Watermelon', 'Pumpkin', 'Jackfruit', 'Leek', 'Swiss Chard', 'Butternut Squash',
//       'Honeydew', 'Cabbage', 'Celery', 'Eggplant', 'Zucchini', 'Durian', 'Coconut',
//       'Pumpkin'
//     ];
//     return fruits[(week - 1).clamp(0, fruits.length - 1)];
//   }

//   // Dhererka ilmaha
//   String getLength(int week) {
//     if (week < 5) return '----';
//     if (week == 5) return '0.3 cm';
//     if (week <= 12) return '${(week * 0.5 + 1.5).toStringAsFixed(1)} cm';
//     if (week <= 27) return '${(week * 1.1).toStringAsFixed(1)} cm';
//     return '${(week * 1.5).toStringAsFixed(1)} cm';
//   }

//   // Miisaanka ilmaha
//   String getWeight(int week) {
//     if (week < 6) return '----';
//     if (week <= 12) return '${(week * 0.05 + 0.05).toStringAsFixed(2)} kg';
//     if (week <= 27) return '${(week * 0.1 + 0.1).toStringAsFixed(2)} kg';
//     return '${(week * 0.2 + 0.2).toStringAsFixed(2)} kg';
//   }

//   // Talooyin cunto oo ku salaysan week
//   Map<String, String> getFoodSuggestion(int week) {
//     final foods = {
//       1: ['Folic Acid-rich Foods', 'assets/images/f1.jpg'],
//       5: ['Spinach & Lentils', 'assets/images/f2.jpg'],
//       10: ['Sweet Potatoes', 'assets/images/f3.jpg'],
//       15: ['Iron-rich Foods', 'assets/images/f4.jpg'],
//       20: ['Bananas & Yogurt', 'assets/images/f5.jpg'],
//       25: ['Salmon & Broccoli', 'assets/images/f6.jpg'],
//       30: ['Oats & Berries', 'assets/images/f7.jpg'],
//       35: ['Eggs & Avocados', 'assets/images/f8.jpg'],
//       40: ['Dates & Hydration', 'assets/images/f9.jpg'],
//     };

//     int key = foods.keys.lastWhere((k) => k <= week, orElse: () => 1);
//     return {
//       'food': foods[key]![0],
//       'image': foods[key]![0],
//     };
//   }

//   Widget _buildStatTile(String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 3,
//       child: ListTile(
//         leading: Icon(icon, color: color, size: 28),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(value, style: const TextStyle(fontSize: 16)),
//       ),
//     );
//   }

//   // Jadwalka Trimester-ka oo leh midabyo kala duwan (Table)
//   Widget _buildTrimesterChart(String currentTrimester) {
//     final trimesters = ['1st ', '2nd', '3rd ' /2....];

//     return Table(
//       children: [
//         TableRow(
//           children: trimesters.map((trimester) {
//             bool isActive = trimester == currentTrimester;
//             Color color = isActive ? getTrimesterColor(trimester) : Colors.blue[900];

//             return Container(
//               margin: const EdgeInsets.all(8),
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Column(
//                 children: [
//                  1st/2.... or 2st/26.../or 3st/26.../o
//                   const SizedBox(height: 6),
//                   Text(
//                     trimester,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: color,
//                       fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         )
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final length = getLength(pregnancyWeek);
//     final weight = getWeight(pregnancyWeek);
//     final trimester = getTrimester(pregnancyWeek);
//     final trimesterColor = getTrimesterColor(trimester);
//     final foodInfo = getFoodSuggestion(pregnancyWeek);
//     final fruit = getFruitName(pregnancyWeek);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Week $pregnancyWeek Tracker'),
//         backgroundColor: trimesterColor,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Fruit Image and Trimester info
//             Center(
//               child: Column(
//                 children: [
//                   Image.asset(
//                      foodInfo['image']!,
//                       height: 150,
//                       fit: BoxFit.cover, atomatic ha iskubed bedelo
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Trimester: $trimester',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: trimesterColor,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _buildTrimesterChart(trimester),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Baby size stats
//             const Text('Baby\'s Growth This Week:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             if (length.isNotEmpty)
//               _buildStatTile('Length', length, Icons.height, Colors.blue),
//             if (weight.isNotEmpty)
//               _buildStatTile('Weight', weight, Icons.monitor_weight, Colors.deepOrange),
//             _buildStatTile(
//                 'Size of', 'About the size of a $fruit', Icons.spa, Colors.green),

//             const SizedBox(height: 24),

//             // Food suggestion
//             const Text('Weekly Food Suggestion:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.asset(
//                       foodInfo['image']!,
//                       height: 150,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Text(foodInfo['food']!,
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';

// class TrackerDetailScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackerDetailScreen({super.key, required this.pregnancyWeek});

//   // Trimester logic
//   String getTrimester(int week) {
//     if (week <= 12) return '1st Trimester';
//     if (week <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }


//   String getFruitName(int week) {
//     final fruits = [
//       'Poppy Seed', 'Sesame Seed', 'Lentil', 'Blueberry', 'Raspberry', 'Grape',
//       'Kumquat', 'Fig', 'Lime', 'Plum', 'Peach', 'Lemon', 'Apple', 'Avocado',
//       'Onion', 'Sweet Potato', 'Mango', 'Banana', 'Pomegranate', 'Papaya',
//       'Grapefruit', 'Coconut', 'Pineapple', 'Cantaloupe', 'Cauliflower', 'Lettuce',
//       'Watermelon', 'Pumpkin', 'Jackfruit', 'Leek', 'Swiss Chard', 'Butternut Squash',
//       'Honeydew', 'Cabbage', 'Celery', 'Eggplant', 'Zucchini', 'Durian', 'Coconut',
//       'Pumpkin'
//     ];
//     return fruits[(week - 1).clamp(0, fruits.length - 1)];
//   }

//   String getLength(int week) {
//     if (week < 5) return '----'; sas dhex haduuba waxba lahayn hana qarin soo bixi
//     if (week == 5) return '0.3 cm';
//     if (week <= 12) return '${(week * 0.5 + 1.5).toStringAsFixed(1)} cm';
//     if (week <= 27) return '${(week * 1.1).toStringAsFixed(1)} cm';
//     return '${(week * 1.5).toStringAsFixed(1)} cm';
//   }

//   String getWeight(int week) {
//     if (week < 6) return '----'; sas dhex haduuba waxba lahayn hana qarin soo bixi
//     if (week <= 12) return '${(week * 0.05 + 0.05).toStringAsFixed(2)} kg';
//     if (week <= 27) return '${(week * 0.1 + 0.1).toStringAsFixed(2)} kg';
//     return '${(week * 0.2 + 0.2).toStringAsFixed(2)} kg';
//   }

//   Map<String, String> getFoodSuggestion(int week) {
//     final foods = {
//       1: ['Folic Acid-rich Foods', ' assets/images/f1.jpg'],
//       5: ['Spinach & Lentils', ' assets/images/f2.jpg'],
//       10: ['Sweet Potatoes', 'assets/images/f3.jpg'],
//       15: ['Iron-rich Foods', 'assets/images/f4.jpg'],
//       20: ['Bananas & Yogurt', 'assets/images/f5.jpg'],
//       25: ['Salmon & Broccoli', 'assets/images/f6.jpg'],
//       30: ['Oats & Berries', 'assets/images/f7.jpg'],
//       35: ['Eggs & Avocados', 'assets/images/f8.jpg'],
//       40: ['Dates & Hydration', 'assets/images/f9.jpg'],
//     };

//     int key = foods.keys.lastWhere((k) => k <= week, orElse: () => 1);
//     return {
//       'food': foods[key]![0],
//       'image': foods[key]![1],
//     };
//   }

//   Widget _buildStatTile(String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 3,
//       child: ListTile(
//         leading: Icon(icon, color: color, size: 28),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(value, style: const TextStyle(fontSize: 16)),
//       ),
//     );
//   }

//   Widget _buildTrimesterChart(String currentTrimester) {
//     final trimesters = ['1st day', '2st days', '3st days'/279 oo ah ina ka dhiman dhalmada adiga xisibi oo sax hadan tiradan 279 qaldane sax];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: trimesters.map((t) {
//         bool active = t == currentTrimester;
//         return Column(
//           children: [
//             Icon(Icons.circle,
//                 color: active ? getTrimesterColor(t) : Colors.grey, size: 16),
//             const SizedBox(height: 4),
//             Text(
//               t,
//               style: TextStyle(
//                   color: active ? getTrimesterColor(t) : Colors.grey,
//                   fontWeight: active ? FontWeight.bold : FontWeight.normal),
//                   trimest oo chart like table midabo coloreysan oo kala duwan inta soo dhig calenderkaas ha ii sheego malinta dhali rabo isagoo ka soo aqrisanaya due date
//             ),
//           ],
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final length = getLength(pregnancyWeek);
//     final weight = getWeight(pregnancyWeek);
//     final trimester = getTrimester(pregnancyWeek);
//     final trimesterColor = getTrimesterColor(trimester);
//     final foodInfo = getFoodSuggestion(pregnancyWeek);
//     final fruit = getFruitName(pregnancyWeek);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Week $pregnancyWeek Tracker'),
//         backgroundColor: trimesterColor,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Fruit Image and Trimester info
//             Center(
//               child: Column(
//                 children: [
//                   Image.network(
//                     'https://example.com/fruit/$fruit.jpg',
//                     height: 120,
//                     errorBuilder: (context, error, stackTrace) =>
//                         const Icon(Icons.image, size: 100),
//                   ),
//                   const SizedBox(height: 8),
//                   Text('Trimester: $trimester',
//                       style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: trimesterColor)),
//                   const SizedBox(height: 8),
//                   _buildTrimesterChart(trimester),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Baby size stats
//             const Text('Baby\'s Growth This Week:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             if (length.isNotEmpty)
//               _buildStatTile('Length', length, Icons.height, Colors.blue),
//             if (weight.isNotEmpty)
//               _buildStatTile('Weight', weight, Icons.monitor_weight, Colors.deepOrange),
//             _buildStatTile(
//                 'Size of', 'About the size of a $fruit 🍓', Icons.spa, Colors.green),

//             const SizedBox(height: 24),

//             // Food suggestion
//             const Text('Weekly Food Suggestion:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   ClipRRect(
//                     borderRadius:
//                         const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.network(
//                       foodInfo['image']!,
//                       height: 150,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) =>
//                           const Icon(Icons.food_bank, size: 100),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Text(foodInfo['food']!,
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


























// import 'package:flutter/material.dart';

// class TrackingScreen extends StatelessWidget {
//   final int pregnancyWeek;

//   const TrackingScreen({super.key, required this.pregnancyWeek});

//   // Trimester logic
//   String getTrimester(int week) {
//     if (week <= 12) return '1st Trimester';
//     if (week <= 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   // More realistic baby growth curve
//   String getLength(int week) {
//     if (week < 5) return 'Too small to measure';
//     if (week <= 12) return '${(week * 0.5 + 1.5).toStringAsFixed(1)} cm'; // early
//     if (week <= 27) return '${(week * 1.1).toStringAsFixed(1)} cm'; // mid
//     return '${(week * 1.5).toStringAsFixed(1)} cm'; // late
//   }

//   String getWeight(int week) {
//     if (week < 5) return 'Too small to weigh';
//     if (week <= 12) return '${(week * 0.05 + 0.05).toStringAsFixed(2)} kg'; // early
//     if (week <= 27) return '${(week * 0.1 + 0.1).toStringAsFixed(2)} kg'; // mid
//     return '${(week * 0.2 + 0.2).toStringAsFixed(2)} kg'; // late
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String trimester = getTrimester(pregnancyWeek);
//     final String length = getLength(pregnancyWeek);
//     final String weight = getWeight(pregnancyWeek);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Weekly Baby Tracker"),
//         backgroundColor: Colors.blue[900],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Trimester Indicator
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.calendar_today, color: Colors.blue),
//                   const SizedBox(width: 12),
//                   Text(
//                     '$trimester - Week $pregnancyWeek',
//                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Baby growth stats
//             Text(
//               'Baby\'s Growth This Week:',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900]),
//             ),
//             const SizedBox(height: 12),
//             _buildStatTile('Length', length, Icons.height),
//             _buildStatTile('Weight', weight, Icons.monitor_weight),
//             _buildStatTile('Size', 'About the size of a ${getFruitName(pregnancyWeek)} 🍓', Icons.spa),

//             const SizedBox(height: 30),

//             // Recommended Food
//             Text(
//               'Recommended Food This Week',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900]),
//             ),
//             const SizedBox(height: 12),
//             _buildFoodCard(
//               name: getFoodName(pregnancyWeek),
//               imageUrl: getFoodImage(pregnancyWeek),
//               benefit: getFoodBenefit(pregnancyWeek),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatTile(String label, String value, IconData icon) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.green),
//         title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         subtitle: Text(value, style: const TextStyle(fontSize: 16)),
//       ),
//     );
//   }

//   Widget _buildFoodCard({required String name, required String imageUrl, required String benefit}) {
//     return Card(
//       elevation: 3,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 6),
//                 Text(benefit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   // Simulated data for fruit comparison (Week-wise)
//   String getFruitName(int week) {
//     const fruits = [
//       'poppy seed', 'blueberry', 'grape', 'kiwi', 'plum',
//       'apple', 'avocado', 'onion', 'mango', 'banana', 'papaya',
//       'coconut', 'pineapple', 'watermelon'
//     ];
//     return fruits[week % fruits.length];
//   }

//   // Simulated data for food recommendations
//   String getFoodName(int week) {
//     const foods = [
//       'Spinach', 'Greek Yogurt', 'Salmon', 'Avocado', 'Boiled Eggs',
//       'Sweet Potato', 'Lentils', 'Almonds', 'Oats', 'Orange'
//     ];
//     return foods[week % foods.length];
//   }

//   String getFoodImage(int week) {
//     const images = [
//       'https://www.healthifyme.com/blog/wp-content/uploads/2021/06/Spinach.jpg',
//       'https://hips.hearstapps.com/hmg-prod/images/greek-yogurt-1524771847.jpg',
//       'https://cdn.britannica.com/99/170199-050-9D2B8E7B/Salmon.jpg',
//       'https://www.thespruceeats.com/thmb/QOIBPLcLCnxR5s0EZzCwKogR_yE=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/avocado-5225415-hero-01-9b2de0ad8db84e7b8a7281d29e69499a.jpg',
//       'https://post.medicalnewstoday.com/wp-content/uploads/sites/3/2020/02/264900_2200-732x549.jpg',
//     ];
//     return images[week % images.length];
//   }

//   String getFoodBenefit(int week) {
//     const benefits = [
//       'Rich in iron and folate for early development.',
//       'High in calcium and probiotics for bone growth.',
//       'Provides omega-3 for brain development.',
//       'Full of healthy fats for baby’s cell growth.',
//       'Protein-rich for baby’s muscles.',
//       'Beta carotene helps baby’s skin and eyes.',
//       'Rich in fiber and iron for blood health.',
//       'Contains vitamin E and healthy fats.',
//       'Energy-boosting complex carbs.',
//       'Packed with vitamin C for immunity.',
//     ];
//     return benefits[week % benefits.length];
//   }
// }















// import 'package:flutter/material.dart';

// class TrackingScreen extends StatelessWidget {
//   final int weeks;

//   const TrackingScreen({super.key, required this.weeks});

//   String getTrimester(int weeks) {
//     if (weeks < 13) return '1st Trimester';
//     if (weeks < 27) return '2nd Trimester';
//     return '3rd Trimester';
//   }

//   String getBabySize(int weeks) {
//     if (weeks < 5) return 'Poppy Seed';
//     if (weeks < 8) return 'Raspberry';
//     if (weeks < 13) return 'Lemon';
//     if (weeks < 20) return 'Mango';
//     if (weeks < 27) return 'Eggplant';
//     if (weeks < 34) return 'Cabbage';
//     return 'Watermelon';
//   }

//   String getLength(int weeks) {
//     return '${(weeks * 0.5).toStringAsFixed(1)} cm';
//   }

//   String getWeight(int weeks) {
//     return '${(weeks * 0.1).toStringAsFixed(2)} kg';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String trimester = getTrimester(weeks);
//     final String length = getLength(weeks);
//     final String weight = getWeight(weeks);
//     final String size = getBabySize(weeks);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         title: const Text("Your Pregnancy Tracker"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _infoRow("Pregnancy Week", "$weeks weeks"),
//             _infoRow("Trimester", trimester),
//             const SizedBox(height: 20),
//             const Text(
//               "Baby's Development:",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
//             ),
//             const SizedBox(height: 10),
//             _infoRow("Length", length),
//             _infoRow("Weight", weight),
//             _infoRow("Size", size),
//             const Spacer(),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[900],
//                   padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text("Go Back", style: TextStyle(fontSize: 16, color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _infoRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               "$title:",
//               style: const TextStyle(fontSize: 16, color: Colors.black87),
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
//           ),
//         ],
//       ),
//     );
//   }
// }

