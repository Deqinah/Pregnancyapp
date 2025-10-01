import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedDoctorId;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String? _selectedDay;
  bool _isSubmitting = false;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
        if (_selectedEndTime != null && 
            _isEndTimeBeforeStartTime(picked, _selectedEndTime!)) {
          _selectedEndTime = null;
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final initialTime = _selectedStartTime != null 
        ? TimeOfDay(hour: _selectedStartTime!.hour + 1, minute: _selectedStartTime!.minute)
        : TimeOfDay.now();
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedEndTime) {
      if (_selectedStartTime != null && _isEndTimeBeforeStartTime(_selectedStartTime!, picked)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }
      
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  bool _isEndTimeBeforeStartTime(TimeOfDay start, TimeOfDay end) {
    if (end.hour < start.hour) return true;
    if (end.hour == start.hour && end.minute <= start.minute) return true;
    return false;
  }

  Future<bool> _checkExistingSchedule(String day) async {
    if (_selectedDoctorId == null) return false;
    
    final schedules = await _firestore
        .collection('doctors')
        .doc(_selectedDoctorId)
        .collection('schedules')
        .where('day', isEqualTo: day)
        .get();

    return schedules.docs.isNotEmpty;
  }

  Future<void> _addSchedule() async {
    if (_selectedDoctorId == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null ||
        _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final doctorDoc = await _firestore.collection('doctors').doc(_selectedDoctorId).get();
    if (!doctorDoc.exists || doctorDoc['status'] != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected doctor is not approved')),
      );
      return;
    }

    final hasSchedule = await _checkExistingSchedule(_selectedDay!);
    if (hasSchedule) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This doctor already has a schedule for $_selectedDay')),
      );
      return;
    }

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    if (endDateTime.difference(startDateTime).inMinutes < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum appointment duration is 30 minutes')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestore.collection('doctors').doc(_selectedDoctorId)
          .collection('schedules').add({
        'day': _selectedDay,
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule added successfully')),
      );

      setState(() {
        _selectedStartTime = null;
        _selectedEndTime = null;
        _selectedDay = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding schedule: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildDayChip(String day) {
    final isSelected = _selectedDay == day;
    return ChoiceChip(
      label: Text(day),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDay = selected ? day : null;
        });
      },
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildTimeSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SCHEDULE DETAILS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Day Selection
            Text(
              'Select Day',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek.map((day) => _buildDayChip(day)).toList(),
            ),
            const SizedBox(height: 16),
            
            // Selected Day Display
            if (_selectedDay != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Selected: $_selectedDay',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Time Selection
            Text(
              'Select Time Slot',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    context: context,
                    label: 'Start Time',
                    time: _selectedStartTime,
                    onPressed: () => _selectStartTime(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeButton(
                    context: context,
                    label: 'End Time',
                    time: _selectedEndTime,
                    onPressed: _selectedStartTime == null 
                        ? null 
                        : () => _selectEndTime(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton({
    required BuildContext context,
    required String label,
    required TimeOfDay? time,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: onPressed == null ? Colors.grey[300]! : Colors.grey[400]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 18,
            color: time != null ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            time != null ? time.format(context) : label,
            style: TextStyle(
              color: time != null ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedules'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Doctor Selection Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT DOCTOR',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final doctors = snapshot.data!.docs;

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            hint: const Text('Choose a doctor'),
                          ),
                          value: _selectedDoctorId,
                          items: doctors.map((doctor) {
                            return DropdownMenuItem<String>(
                              value: doctor.id,
                              child: Text(
                                doctor['fullName'] ?? 'Unnamed Doctor',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDoctorId = newValue;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Schedule Details Card
            _buildTimeSelectionCard(),

            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _addSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ADD SCHEDULE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Existing Schedules Section
            if (_selectedDoctorId != null) ...[
              Text(
                'EXISTING SCHEDULES',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: _buildScheduleList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('doctors')
          .doc(_selectedDoctorId)
          .collection('schedules')
          .orderBy('startTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final schedules = snapshot.data!.docs;

        if (schedules.isEmpty) {
          return Center(
            child: Text(
              'No schedules found for this doctor',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: schedules.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            final startTime = (schedule['startTime'] as Timestamp).toDate();
            final endTime = (schedule['endTime'] as Timestamp).toDate();
            final day = schedule['day'] as String;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                day,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  try {
                    await _firestore
                        .collection('doctors')
                        .doc(_selectedDoctorId)
                        .collection('schedules')
                        .doc(schedule.id)
                        .delete();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: ${e.toString()}')),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}



















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ScheduleScreen extends StatefulWidget {
//   const ScheduleScreen({super.key});

//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }

// class _ScheduleScreenState extends State<ScheduleScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _selectedDoctorId;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   String? _selectedDay;
//   bool _isSubmitting = false;

//   final List<String> _daysOfWeek = [
//     'Monday',
//     'Tuesday',
//     'Wednesday',
//     'Thursday',
//     'Friday',
//     'Saturday',
//     'Sunday'
//   ];

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedStartTime ?? TimeOfDay.now(),
//     );
//     if (picked != null && picked != _selectedStartTime) {
//       setState(() {
//         _selectedStartTime = picked;
//         if (_selectedEndTime != null && 
//             _isEndTimeBeforeStartTime(picked, _selectedEndTime!)) {
//           _selectedEndTime = null;
//         }
//       });
//     }
//   }

//   Future<void> _selectEndTime(BuildContext context) async {
//     final initialTime = _selectedStartTime != null 
//         ? TimeOfDay(hour: _selectedStartTime!.hour + 1, minute: _selectedStartTime!.minute)
//         : TimeOfDay.now();
    
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedEndTime ?? initialTime,
//     );
    
//     if (picked != null && picked != _selectedEndTime) {
//       if (_selectedStartTime != null && _isEndTimeBeforeStartTime(_selectedStartTime!, picked)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('End time must be after start time')),
//         );
//         return;
//       }
      
//       setState(() {
//         _selectedEndTime = picked;
//       });
//     }
//   }

//   bool _isEndTimeBeforeStartTime(TimeOfDay start, TimeOfDay end) {
//     if (end.hour < start.hour) return true;
//     if (end.hour == start.hour && end.minute <= start.minute) return true;
//     return false;
//   }

//   Future<bool> _checkExistingSchedule(String day, TimeOfDay startTime, TimeOfDay endTime) async {
//     if (_selectedDoctorId == null) return false;
    
//     final schedules = await _firestore
//         .collection('doctors')
//         .doc(_selectedDoctorId)
//         .collection('schedules')
//         .where('day', isEqualTo: day)
//         .get();

//     final newStart = startTime.hour * 60 + startTime.minute;
//     final newEnd = endTime.hour * 60 + endTime.minute;

//     for (final schedule in schedules.docs) {
//       final existingStartTime = (schedule['startTime'] as Timestamp).toDate();
//       final existingEndTime = (schedule['endTime'] as Timestamp).toDate();
      
//       final existingStart = existingStartTime.hour * 60 + existingStartTime.minute;
//       final existingEnd = existingEndTime.hour * 60 + existingEndTime.minute;

//       if ((newStart >= existingStart && newStart < existingEnd) ||
//           (newEnd > existingStart && newEnd <= existingEnd) ||
//           (newStart <= existingStart && newEnd >= existingEnd)) {
//         return true;
//       }
//     }
//     return false;
//   }

//   Future<void> _addSchedule() async {
//     if (_selectedDoctorId == null ||
//         _selectedStartTime == null ||
//         _selectedEndTime == null ||
//         _selectedDay == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     // Check if doctor is approved
//     final doctorDoc = await _firestore.collection('doctors').doc(_selectedDoctorId).get();
//     if (!doctorDoc.exists || doctorDoc['status'] != 'approved') {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Selected doctor is not approved')),
//       );
//       return;
//     }

//     // Check for existing schedule on the same day
//     final hasConflict = await _checkExistingSchedule(
//       _selectedDay!, 
//       _selectedStartTime!, 
//       _selectedEndTime!
//     );

//     if (hasConflict) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('This doctor already has a schedule for the selected day')),
//       );
//       return;
//     }

//     final now = DateTime.now();
//     final startDateTime = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       _selectedStartTime!.hour,
//       _selectedStartTime!.minute,
//     );

//     final endDateTime = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       _selectedEndTime!.hour,
//       _selectedEndTime!.minute,
//     );

//     if (endDateTime.isBefore(startDateTime)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
//       );
//       return;
//     }

//     if (endDateTime.difference(startDateTime).inMinutes < 30) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Minimum appointment duration is 30 minutes')),
//       );
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       await _firestore.collection('doctors').doc(_selectedDoctorId)
//           .collection('schedules').add({
//         'day': _selectedDay,
//         'startTime': Timestamp.fromDate(startDateTime),
//         'endTime': Timestamp.fromDate(endDateTime),
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Schedule added successfully')),
//       );

//       setState(() {
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//         _selectedDay = null;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding schedule: ${e.toString()}')),
//       );
//     } finally {
//       setState(() {
//         _isSubmitting = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Schedules'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Select Doctor',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(child: CircularProgressIndicator());
//                         }

//                         final doctors = snapshot.data!.docs;

//                         return DropdownButtonFormField<String>(
//                           decoration: const InputDecoration(
//                             border: OutlineInputBorder(),
//                             contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                           ),
//                           value: _selectedDoctorId,
//                           hint: const Text('Choose a doctor'),
//                           items: doctors.map((doctor) {
//                             return DropdownMenuItem<String>(
//                               value: doctor.id,
//                               child: Text(doctor['fullName'] ?? 'Unnamed Doctor'),
//                             );
//                           }).toList(),
//                           onChanged: (String? newValue) {
//                             setState(() {
//                               _selectedDoctorId = newValue;
//                             });
//                           },
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Schedule Details',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Day selection
//                     DropdownButtonFormField<String>(
//                       decoration: const InputDecoration(
//                         labelText: 'Select Day',
//                         border: OutlineInputBorder(),
//                       ),
//                       value: _selectedDay,
//                       items: _daysOfWeek.map((day) {
//                         return DropdownMenuItem<String>(
//                           value: day,
//                           child: Text(day),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           _selectedDay = newValue;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Time selection
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,
//                       children: [
//                         _buildStartTimeButton(context),
//                         _buildEndTimeButton(context),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
            
//             ElevatedButton(
//               onPressed: _isSubmitting ? null : _addSchedule,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: _isSubmitting
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text('Add Schedule'),
//             ),

//             const SizedBox(height: 20),
//             const Divider(),
//             const SizedBox(height: 20),

//             if (_selectedDoctorId != null) ...[
//               const Text(
//                 'Existing Schedules:',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.4,
//                 child: _buildScheduleList(),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStartTimeButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: () => _selectStartTime(context),
//       icon: const Icon(Icons.access_time, size: 18),
//       label: Text(
//         _selectedStartTime == null
//             ? 'Start Time'
//             : _selectedStartTime!.format(context),
//       ),
//     );
//   }

//   Widget _buildEndTimeButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: _selectedStartTime == null 
//           ? null 
//           : () => _selectEndTime(context),
//       icon: const Icon(Icons.access_time, size: 18),
//       label: Text(
//         _selectedEndTime == null
//             ? 'End Time'
//             : _selectedEndTime!.format(context),
//       ),
//     );
//   }

//   Widget _buildScheduleList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('doctors')
//           .doc(_selectedDoctorId)
//           .collection('schedules')
//           // .orderBy('day')
//           // .orderBy('startTime')
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         final schedules = snapshot.data!.docs;

//         if (schedules.isEmpty) {
//           return const Center(
//             child: Text('No schedules found for this doctor'),
//           );
//         }

//         return ListView.builder(
//           itemCount: schedules.length,
//           itemBuilder: (context, index) {
//             final schedule = schedules[index];
//             final startTime = (schedule['startTime'] as Timestamp).toDate();
//             final endTime = (schedule['endTime'] as Timestamp).toDate();
//             final day = schedule['day'] as String;

//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 4),
//               child: ListTile(
//                 title: Text(
//                   day,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(
//                   '${DateFormat('hh:mm a').format(startTime)} - '
//                   '${DateFormat('hh:mm a').format(endTime)}',
//                 ),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () async {
//                     try {
//                       await _firestore
//                           .collection('doctors')
//                           .doc(_selectedDoctorId)
//                           .collection('schedules')
//                           .doc(schedule.id)
//                           .delete();
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to delete: ${e.toString()}')),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ScheduleScreen extends StatefulWidget {
//   const ScheduleScreen({super.key});

//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }

// class _ScheduleScreenState extends State<ScheduleScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _selectedDoctorId;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   String? _selectedDay;
//   bool _isSubmitting = false;
//   bool _isWeekly = false;

//   final List<String> _daysOfWeek = [
//     'Monday',
//     'Tuesday',
//     'Wednesday',
//     'Thursday',
//     'Friday',
//     'Saturday',
//     'Sunday'
//   ];

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedStartTime ?? TimeOfDay.now(),
//     );
//     if (picked != null && picked != _selectedStartTime) {
//       setState(() {
//         _selectedStartTime = picked;
//         if (_selectedEndTime != null && 
//             _isEndTimeBeforeStartTime(picked, _selectedEndTime!)) {
//           _selectedEndTime = null;
//         }
//       });
//     }
//   }

//   Future<void> _selectEndTime(BuildContext context) async {
//     final initialTime = _selectedStartTime != null 
//         ? TimeOfDay(hour: _selectedStartTime!.hour + 1, minute: _selectedStartTime!.minute)
//         : TimeOfDay.now();
    
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedEndTime ?? initialTime,
//     );
    
//     if (picked != null && picked != _selectedEndTime) {
//       if (_selectedStartTime != null && _isEndTimeBeforeStartTime(_selectedStartTime!, picked)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('End time must be after start time')),
//         );
//         return;
//       }
      
//       setState(() {
//         _selectedEndTime = picked;
//       });
//     }
//   }

//   bool _isEndTimeBeforeStartTime(TimeOfDay start, TimeOfDay end) {
//     if (end.hour < start.hour) return true;
//     if (end.hour == start.hour && end.minute <= start.minute) return true;
//     return false;
//   }

//   Future<void> _addSchedule() async {
//     if (_selectedDoctorId == null ||
//         _selectedStartTime == null ||
//         _selectedEndTime == null ||
//         _selectedDay == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     final now = DateTime.now();
//     final startDateTime = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       _selectedStartTime!.hour,
//       _selectedStartTime!.minute,
//     );

//     final endDateTime = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       _selectedEndTime!.hour,
//       _selectedEndTime!.minute,
//     );

//     if (endDateTime.isBefore(startDateTime)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
//       );
//       return;
//     }

//     if (endDateTime.difference(startDateTime).inMinutes < 30) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Minimum appointment duration is 30 minutes')),
//       );
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       // Check if doctor is approved
//       final doctorDoc = await _firestore.collection('doctors').doc(_selectedDoctorId).get();
//       if (!doctorDoc.exists || doctorDoc['status'] != 'approved') {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Selected doctor is not approved')),
//         );
//         return;
//       }

//       // Add schedule for selected day or all week days
//       final daysToAdd = _isWeekly ? _daysOfWeek : [_selectedDay!];
      
//       for (final day in daysToAdd) {
//         await _firestore.collection('doctors').doc(_selectedDoctorId)
//             .collection('schedules').add({
//           'day': day,
//           'startTime': Timestamp.fromDate(startDateTime),
//           'endTime': Timestamp.fromDate(endDateTime),
//           'isWeekly': _isWeekly,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Schedule added successfully')),
//       );

//       setState(() {
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//         _selectedDay = null;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding schedule: ${e.toString()}')),
//       );
//     } finally {
//       setState(() {
//         _isSubmitting = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Schedules'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Select Doctor',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(child: CircularProgressIndicator());
//                         }

//                         final doctors = snapshot.data!.docs;

//                         return DropdownButtonFormField<String>(
//                           decoration: const InputDecoration(
//                             border: OutlineInputBorder(),
//                             contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                           ),
//                           value: _selectedDoctorId,
//                           hint: const Text('Choose a doctor'),
//                           items: doctors.map((doctor) {
//                             return DropdownMenuItem<String>(
//                               value: doctor.id,
//                               child: Text(doctor['fullName'] ?? 'Unnamed Doctor'),
//                             );
//                           }).toList(),
//                           onChanged: (String? newValue) {
//                             setState(() {
//                               _selectedDoctorId = newValue;
//                             });
//                           },
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Schedule Details',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Day/Week Selection
//                     Row(
//                       children: [
//                         const Text('Repeat:'),
//                         const SizedBox(width: 10),
//                         ChoiceChip(
//                           label: const Text('Single Day'),
//                           selected: !_isWeekly,
//                           onSelected: (selected) {
//                             setState(() {
//                               _isWeekly = !selected;
//                               if (_isWeekly) _selectedDay = null;
//                             });
//                           },
//                         ),
//                         const SizedBox(width: 10),
//                         ChoiceChip(
//                           label: const Text('Entire Week'),
//                           selected: _isWeekly,
//                           onSelected: (selected) {
//                             setState(() {
//                               _isWeekly = selected;
//                               if (_isWeekly) _selectedDay = null;
//                             });
//                           },
//                         ),
//                       ],
//                     ),
                    
//                     const SizedBox(height: 16),
                    
//                     // Day selection (only if not weekly)
//                     if (!_isWeekly) ...[
//                       DropdownButtonFormField<String>(
//                         decoration: const InputDecoration(
//                           labelText: 'Select Day',
//                           border: OutlineInputBorder(),
//                         ),
//                         value: _selectedDay,
//                         items: _daysOfWeek.map((day) {
//                           return DropdownMenuItem<String>(
//                             value: day,
//                             child: Text(day),
//                           );
//                         }).toList(),
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             _selectedDay = newValue;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                     ],
                    
//                     // Time selection
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,
//                       children: [
//                         _buildStartTimeButton(context),
//                         _buildEndTimeButton(context),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
            
//             ElevatedButton(
//               onPressed: _isSubmitting ? null : _addSchedule,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: _isSubmitting
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text('Add Schedule'),
//             ),

//             const SizedBox(height: 20),
//             const Divider(),
//             const SizedBox(height: 20),

//             if (_selectedDoctorId != null) ...[
//               const Text(
//                 'Existing Schedules:',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.4,
//                 child: _buildScheduleList(),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStartTimeButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: () => _selectStartTime(context),
//       icon: const Icon(Icons.access_time, size: 18),
//       label: Text(
//         _selectedStartTime == null
//             ? 'Start Time'
//             : _selectedStartTime!.format(context),
//       ),
//     );
//   }

//   Widget _buildEndTimeButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: _selectedStartTime == null 
//           ? null 
//           : () => _selectEndTime(context),
//       icon: const Icon(Icons.access_time, size: 18),
//       label: Text(
//         _selectedEndTime == null
//             ? 'End Time'
//             : _selectedEndTime!.format(context),
//       ),
//     );
//   }

//   Widget _buildScheduleList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('doctors')
//           .doc(_selectedDoctorId)
//           .collection('schedules')
//           // .orderBy('day')
//           // .orderBy('startTime')
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         final schedules = snapshot.data!.docs;

//         if (schedules.isEmpty) {
//           return const Center(
//             child: Text('No schedules found for this doctor'),
//           );
//         }

//         return ListView.builder(
//           itemCount: schedules.length,
//           itemBuilder: (context, index) {
//             final schedule = schedules[index];
//             final startTime = (schedule['startTime'] as Timestamp).toDate();
//             final endTime = (schedule['endTime'] as Timestamp).toDate();
//             final day = schedule['day'] as String;
//             final isWeekly = schedule['isWeekly'] as bool? ?? false;

//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 4),
//               child: ListTile(
//                 title: Text(
//                   day,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(
//                   '${DateFormat('hh:mm a').format(startTime)} - '
//                   '${DateFormat('hh:mm a').format(endTime)}'
//                   '${isWeekly ? ' (Weekly)' : ''}',
//                 ),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () async {
//                     try {
//                       await _firestore
//                           .collection('doctors')
//                           .doc(_selectedDoctorId)
//                           .collection('schedules')
//                           .doc(schedule.id)
//                           .delete();
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to delete: ${e.toString()}')),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ScheduleScreen extends StatefulWidget {
//   const ScheduleScreen({super.key});

//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }

// class _ScheduleScreenState extends State<ScheduleScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _selectedDoctorId;
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   bool _isSubmitting = false;

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//       });
//     }
//   }

//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedStartTime ?? TimeOfDay.now(),
//     );
//     if (picked != null && picked != _selectedStartTime) {
//       setState(() {
//         _selectedStartTime = picked;
//         if (_selectedEndTime != null && 
//             _isEndTimeBeforeStartTime(picked, _selectedEndTime!)) {
//           _selectedEndTime = null;
//         }
//       });
//     }
//   }

//   Future<void> _selectEndTime(BuildContext context) async {
//     final initialTime = _selectedStartTime != null 
//         ? TimeOfDay(hour: _selectedStartTime!.hour + 1, minute: _selectedStartTime!.minute)
//         : TimeOfDay.now();
    
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedEndTime ?? initialTime,
//     );
    
//     if (picked != null && picked != _selectedEndTime) {
//       if (_selectedStartTime != null && _isEndTimeBeforeStartTime(_selectedStartTime!, picked)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('End time must be after start time')),
//         );
//         return;
//       }
      
//       setState(() {
//         _selectedEndTime = picked;
//       });
//     }
//   }

//   bool _isEndTimeBeforeStartTime(TimeOfDay start, TimeOfDay end) {
//     if (end.hour < start.hour) return true;
//     if (end.hour == start.hour && end.minute <= start.minute) return true;
//     return false;
//   }

//   Future<void> _addSchedule() async {
//     if (_selectedDoctorId == null ||
//         _selectedDate == null ||
//         _selectedStartTime == null ||
//         _selectedEndTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     final startDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedStartTime!.hour,
//       _selectedStartTime!.minute,
//     );

//     final endDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedEndTime!.hour,
//       _selectedEndTime!.minute,
//     );

//     if (endDateTime.isBefore(startDateTime)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
//       );
//       return;
//     }

//     if (endDateTime.difference(startDateTime).inMinutes < 30) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Minimum appointment duration is 30 minutes')),
//       );
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       await _firestore.collection('doctors').doc(_selectedDoctorId)
//        stream: _firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots(),
//         builder: (context, doctorsSnapshot) {
//           if (doctorsSnapshot.hasError) {
//             return Center(child: Text('Error loading doctors: ${doctorsSnapshot.error}'));
//           }

//           if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!doctorsSnapshot.hasData || doctorsSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No approved doctors available'));
//           }

//       .collection('schedules').add({
//         'startTime': Timestamp.fromDate(startDateTime),
//         'endTime': Timestamp.fromDate(endDateTime),
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Schedule added successfully')),
//       );

//       setState(() {
//         _selectedDate = null;
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding schedule: ${e.toString()}')),
//       );
//     } finally {
//       setState(() {
//         _isSubmitting = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Schedules'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Select Doctor',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: _firestore.collection('doctors').snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(child: CircularProgressIndicator());
//                         }

//                         final doctors = snapshot.data!.docs;

//                         return DropdownButtonFormField<String>(
//                           decoration: const InputDecoration(
//                             border: OutlineInputBorder(),
//                             contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                           ),
//                           value: _selectedDoctorId,
//                           hint: const Text('Choose a doctor'),
//                           items: doctors.map((doctor) {
//                             return DropdownMenuItem<String>(
//                               value: doctor.id,
//                               child: Text(doctor['fullName'] ?? 'Unnamed Doctor'),
//                             );
//                           }).toList(),
//                           onChanged: (String? newValue) {
//                             setState(() {
//                               _selectedDoctorId = newValue;
//                             });
//                           },
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Schedule Details',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,
//                       children: [
//                         _buildDateButton(context),
//                         _buildStartTimeButton(context),
//                         _buildEndTimeButton(context),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
            
//             ElevatedButton(
//               onPressed: _isSubmitting ? null : _addSchedule,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: _isSubmitting
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text('Add Schedule'),
//             ),

//             const SizedBox(height: 20),
//             const Divider(),
//             const SizedBox(height: 20),

//             if (_selectedDoctorId != null) ...[
//               const Text(
//                 'Existing Schedules:',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.4,
//                 child: _buildScheduleList(),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: () => _selectDate(context),
//       icon: const Icon(Icons.calendar_today, size: 18),
//       label: Text(
//         _selectedDate == null
//             ? 'Select Date'
//             : DateFormat('MMM dd, yyyy').format(_selectedDate!),
//       ),
//     );
//   }

//   Widget _buildStartTimeButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: _selectedDate == null 
//           ? null 
//           : () => _selectStartTime(context),
//       icon: const Icon(Icons.access_time, size: 18),
//       label: Text(
//         _selectedStartTime == null
//             ? 'Start Time'
//             : _selectedStartTime!.format(context),
//       ),
//     );
//   }

//   Widget _buildEndTimeButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: _selectedStartTime == null 
//           ? null 
//           : () => _selectEndTime(context),
//       icon: const Icon(Icons.access_time, size: 18),
//       label: Text(
//         _selectedEndTime == null
//             ? 'End Time'
//             : _selectedEndTime!.format(context),
//       ),
//     );
//   }

//   Widget _buildScheduleList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('doctors')
//           .doc(_selectedDoctorId)
//           .collection('schedules')
       
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         final schedules = snapshot.data!.docs;

//         if (schedules.isEmpty) {
//           return const Center(
//             child: Text('No schedules found for this doctor'),
//           );
//         }

//         return ListView.builder(
//           itemCount: schedules.length,
//           itemBuilder: (context, index) {
//             final schedule = schedules[index];
//             final startTime = (schedule['startTime'] as Timestamp).toDate();
//             final endTime = (schedule['endTime'] as Timestamp).toDate();

//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 4),
//               child: ListTile(
//                 title: Text(
//                   DateFormat('MMM dd, yyyy').format(startTime),
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(
//                   '${DateFormat('hh:mm a').format(startTime)} - '
//                   '${DateFormat('hh:mm a').format(endTime)}',
//                 ),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () async {
//                     try {
//                       await _firestore
//                           .collection('doctors')
//                           .doc(_selectedDoctorId)
//                           .collection('schedules')
//                           .doc(schedule.id)
//                           .delete();
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to delete: ${e.toString()}')),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ScheduleScreen extends StatefulWidget {
//   const ScheduleScreen({super.key});

//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }

// class _ScheduleScreenState extends State<ScheduleScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _selectedDoctorId;
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   bool _isSubmitting = false;

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         // Reset times when date changes
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//       });
//     }
//   }

//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedStartTime ?? TimeOfDay.now(),
//     );
//     if (picked != null && picked != _selectedStartTime) {
//       setState(() {
//         _selectedStartTime = picked;
//         // Reset end time if it's now before start time
//         if (_selectedEndTime != null && 
//             _isEndTimeBeforeStartTime(picked, _selectedEndTime!)) {
//           _selectedEndTime = null;
//         }
//       });
//     }
//   }

//   Future<void> _selectEndTime(BuildContext context) async {
//     final initialTime = _selectedStartTime != null 
//         ? TimeOfDay(hour: _selectedStartTime!.hour + 1, minute: _selectedStartTime!.minute)
//         : TimeOfDay.now();
    
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedEndTime ?? initialTime,
//     );
    
//     if (picked != null && picked != _selectedEndTime) {
//       if (_selectedStartTime != null && _isEndTimeBeforeStartTime(_selectedStartTime!, picked)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('End time must be after start time')),
//         );
//         return;
//       }
      
//       setState(() {
//         _selectedEndTime = picked;
//       });
//     }
//   }

//   bool _isEndTimeBeforeStartTime(TimeOfDay start, TimeOfDay end) {
//     if (end.hour < start.hour) return true;
//     if (end.hour == start.hour && end.minute <= start.minute) return true;
//     return false;
//   }

//   Future<void> _addSchedule() async {
//     if (_selectedDoctorId == null ||
//         _selectedDate == null ||
//         _selectedStartTime == null ||
//         _selectedEndTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     final startDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedStartTime!.hour,
//       _selectedStartTime!.minute,
//     );

//     final endDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedEndTime!.hour,
//       _selectedEndTime!.minute,
//     );

//     if (endDateTime.isBefore(startDateTime)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
//       );
//       return;
//     }

//     if (endDateTime.difference(startDateTime).inMinutes < 50) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Minimum appointment duration is 50 minutes')),
//       );
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       await _firestore.collection('doctors').doc(_selectedDoctorId).collection('schedules').add({
//         'date': Timestamp.fromDate(_selectedDate!),
//         'startTime': Timestamp.fromDate(startDateTime),
//         'endTime': Timestamp.fromDate(endDateTime),
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Schedule added successfully')),
//       );

//       // Clear form
//       setState(() {
//         _selectedDate = null;
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context
//         SnackBar(content: Text('Error adding schedule: ${e.toString()}')),
//       );
//     } finally {
//       setState(() {
//         _isSubmitting = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Schedules'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Doctor selection dropdown
//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Select Doctor',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: _firestore.collection('doctors').snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(child: CircularProgressIndicator());
//                         }

//                         final doctors = snapshot.data!.docs;

//                         return DropdownButtonFormField<String>(
//                           decoration: const InputDecoration(
//                             border: OutlineInputBorder(),
//                             contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                           ),
//                           value: _selectedDoctorId,
//                           hint: const Text('Choose a doctor'),
//                           items: doctors.map((doctor) {
//                             return DropdownMenuItem<String>(
//                               value: doctor.id,
//                               child: Text(doctor['fullName'] ?? 'Unnamed Doctor'),
//                             );
//                           }).toList(),
//                           onChanged: (String? newValue) {
//                             setState(() {
//                               _selectedDoctorId = newValue;
//                             });
//                           },
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Date and time selection
//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Schedule Details',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,
//                       children: [
//                         _buildDateButton(context),
//                         _buildStartTimeButton(context),
//                         _buildEndTimeButton(context),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
            
//             // Add schedule button
//             ElevatedButton(
//               onPressed: _isSubmitting ? null : _addSchedule,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: _isSubmitting
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text('Add Schedule'),
//             ),

//             const SizedBox(height: 20),
//             const Divider(),
//             const SizedBox(height: 20),

//             // Display existing schedules
//             if (_selectedDoctorId != null) ...[
//               const Text(
//                 'Existing Schedules:',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.4,
//                 child: _buildScheduleList(),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: () => _selectDate(context),
//       icon: const Icon(Icons.calendar_today, size: 18),
//       label: Text(
//         _selectedDate == null
//             ? 'Select Date'
//             : DateFormat('MMM dd, yyyy').format(_selectedDate!),
//       ),
//     );
//   }

//   Widget _buildStartTimeButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: _selectedDate == null 
//           ? null 
//           : () => _selectStartTime(context),
//       icon: const Icon(Icons.access_time, size: 18),
//       label: Text(
//         _selectedStartTime == null
//             ? 'Start Time'
//             : _selectedStartTime!.format(context),
//       ),
//     );
//   }

//   Widget _buildEndTimeButton(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: _selectedStartTime == null 
//           ? null 
//           : () => _selectEndTime(context),
//       icon: const Icon(Icons.access_time, size: 18),
//       label: Text(
//         _selectedEndTime == null
//             ? 'End Time'
//             : _selectedEndTime!.format(context),
//       ),
//     );
//   }

//   Widget _buildScheduleList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('doctors')
//           .doc(_selectedDoctorId)
//           .collection('schedules')
//           .orderBy('startTime', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         final schedules = snapshot.data!.docs;

//         if (schedules.isEmpty) {
//           return const Center(
//             child: Text('No schedules found for this doctor'),
//           );
//         }

//         return ListView.builder(
//           itemCount: schedules.length,
//           itemBuilder: (context, index) {
//             final schedule = schedules[index];
//             final startTime = (schedule['startTime'] as Timestamp).toDate();
//             final endTime = (schedule['endTime'] as Timestamp).toDate();

//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 4),
//               child: ListTile(
//                 title: Text(
//                   DateFormat('MMM dd, yyyy').format(startTime),
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '${DateFormat('hh:mm a').format(startTime)} - '
//                       '${DateFormat('hh:mm a').format(endTime)}',
//                     ),
//                   ],
//                 ),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () async {
//                     try {
//                       await _firestore
//                           .collection('doctors')
//                           .doc(_selectedDoctorId)
//                           .collection('schedules')
//                           .doc(schedule.id)
//                           .delete();
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to delete: ${e.toString()}')),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ScheduleScreen extends StatefulWidget {
//   const ScheduleScreen({super.key});

//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }

// class _ScheduleScreenState extends State<ScheduleScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _selectedDoctorId;
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   final TextEditingController _notesController = TextEditingController();

//   @override
//   void dispose() {
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null && picked != _selectedStartTime) {
//       setState(() {
//         _selectedStartTime = picked;
//       });
//     }
//   }

//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null && picked != _selectedEndTime) {
//       setState(() {
//         _selectedEndTime = picked;
//       });
//     }
//   }

//   Future<void> _addSchedule() async {
//     if (_selectedDoctorId == null ||
//         _selectedDate == null ||
//         _selectedStartTime == null ||
//         _selectedEndTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all fields')),
//       );
//       return;
//     }

//     final startDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedStartTime!.hour,
//       _selectedStartTime!.minute,
//     );

//     final endDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedEndTime!.hour,
//       _selectedEndTime!.minute,
//     );

//     if (endDateTime.isBefore(startDateTime)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
//       );
//       return;
//     }

//     try {
//       await _firestore.collection('doctors').doc(_selectedDoctorId).collection('schedules').add({
//         'date': _selectedDate,
//         'startTime': startDateTime,
//         'endTime': endDateTime,
//         // 'notes': _notesController.text,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Schedule added successfully')),
//       );

//       // Clear form
//       setState(() {
//         _selectedDate = null;
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//         _notesController.clear();
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding schedule: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Doctor selection dropdown
//             Material(
//               elevation: 2,
//               borderRadius: BorderRadius.circular(4),
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _firestore.collection('doctors').snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Padding(
//                       padding: EdgeInsets.all(16.0),
//                       child: CircularProgressIndicator(),
//                     );
//                   }

//                   final doctors = snapshot.data!.docs;

//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                     child: DropdownButtonFormField<String>(
//                       decoration: const InputDecoration(
//                         labelText: 'Select Doctor',
//                         border: InputBorder.none,
//                       ),
//                       value: _selectedDoctorId,
//                       items: doctors.map((doctor) {
//                         return DropdownMenuItem<String>(
//                           value: doctor.id,
//                           child: Text(doctor['fullName'] ?? 'Unnamed Doctor'),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           _selectedDoctorId = newValue;
//                         });
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Date and time selection
//             Material(
//               elevation: 2,
//               borderRadius: BorderRadius.circular(4),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () => _selectDate(context),
//                         child: Text(
//                           _selectedDate == null
//                               ? 'Select Date'
//                               : DateFormat('MMM dd, yyyy').format(_selectedDate!),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () => _selectStartTime(context),
//                         child: Text(
//                           _selectedStartTime == null
//                               ? 'Start Time'
//                               : _selectedStartTime!.format(context),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () => _selectEndTime(context),
//                         child: Text(
//                           _selectedEndTime == null
//                               ? 'End Time'
//                               : _selectedEndTime!.format(context),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
//             // Add schedule button
//             ElevatedButton(
//               onPressed: _addSchedule,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: const Text('Add Schedule'),
//             ),

//             const SizedBox(height: 20),
//             const Divider(),
//             const SizedBox(height: 20),

//             // Display existing schedules
//             if (_selectedDoctorId != null) ...[
//               const Text(
//                 'Existing Schedules:',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.4, // Fixed height
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: _firestore
//                       .collection('doctors')
//                       .doc(_selectedDoctorId)
//                       .collection('schedules')
//                       .orderBy('startTime')
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     final schedules = snapshot.data!.docs;

//                     if (schedules.isEmpty) {
//                       return const Center(
//                         child: Text('No schedules found for this doctor'),
//                       );
//                     }

//                     return ListView.builder(
//                       shrinkWrap: true,
//                       physics: const AlwaysScrollableScrollPhysics(),
//                       itemCount: schedules.length,
//                       itemBuilder: (context, index) {
//                         final schedule = schedules[index];
//                         final startTime = (schedule['startTime'] as Timestamp).toDate();
//                         final endTime = (schedule['endTime'] as Timestamp).toDate();
//                         // final notes = schedule['notes'] as String?;

//                         return Card(
//                           margin: const EdgeInsets.symmetric(vertical: 4),
//                           child: ListTile(
//                             title: Text(
//                               '${DateFormat('MMM dd, yyyy').format(startTime)} • '
//                               '${DateFormat('hh:mm a').format(startTime)} - '
//                               '${DateFormat('hh:mm a').format(endTime)}',
//                             ),
//                             // subtitle: notes?.isNotEmpty == true ? Text(notes!) : null,
//                             trailing: IconButton(
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                               onPressed: () async {
//                                 await _firestore
//                                     .collection('doctors')
//                                     .doc(_selectedDoctorId)
//                                     .collection('schedules')
//                                     .doc(schedule.id)
//                                     .delete();
//                               },
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ScheduleScreen extends StatefulWidget {
//   const ScheduleScreen({super.key});

//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }

// class _ScheduleScreenState extends State<ScheduleScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _selectedDoctorId;
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   final TextEditingController _notesController = TextEditingController();

//   @override
//   void dispose() {
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null && picked != _selectedStartTime) {
//       setState(() {
//         _selectedStartTime = picked;
//       });
//     }
//   }

//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null && picked != _selectedEndTime) {
//       setState(() {
//         _selectedEndTime = picked;
//       });
//     }
//   }

//   Future<void> _addSchedule() async {
//     if (_selectedDoctorId == null ||
//         _selectedDate == null ||
//         _selectedStartTime == null ||
//         _selectedEndTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all fields')),
//       );
//       return;
//     }

//     final startDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedStartTime!.hour,
//       _selectedStartTime!.minute,
//     );

//     final endDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedEndTime!.hour,
//       _selectedEndTime!.minute,
//     );

//     if (endDateTime.isBefore(startDateTime)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
//       );
//       return;
//     }

//     try {
//       await _firestore.collection('doctors').doc(_selectedDoctorId).collection('schedules').add({
//         'date': _selectedDate,
//         'startTime': startDateTime,
//         'endTime': endDateTime,
//         'notes': _notesController.text,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Schedule added successfully')),
//       );

//       // Clear form
//       setState(() {
//         _selectedDate = null;
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//         _notesController.clear();
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding schedule: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Doctor selection dropdown
//           StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection('doctors').snapshots(),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) {
//                 return const CircularProgressIndicator();
//               }

//               final doctors = snapshot.data!.docs;

//               return DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(
//                   labelText: 'Select Doctor',
//                   border: OutlineInputBorder(),
//                 ),
//                 value: _selectedDoctorId,
//                 items: doctors.map((doctor) {
//                   return DropdownMenuItem<String>(
//                     value: doctor.id,
//                     child: Text(doctor['fullName'] ?? 'Unnamed Doctor'),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedDoctorId = newValue;
//                   });
//                 },
//               );
//             },
//           ),

//           const SizedBox(height: 20),

//           // Date and time selection
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => _selectDate(context),
//                   child: Text(
//                     _selectedDate == null
//                         ? 'Select Date'
//                         : DateFormat('MMM dd, yyyy').format(_selectedDate!),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => _selectStartTime(context),
//                   child: Text(
//                     _selectedStartTime == null
//                         ? 'Start Time'
//                         : _selectedStartTime!.format(context),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => _selectEndTime(context),
//                   child: Text(
//                     _selectedEndTime == null
//                         ? 'End Time'
//                         : _selectedEndTime!.format(context),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           // Add schedule button
//           ElevatedButton(
//             onPressed: _addSchedule,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//             ),
//             child: const Text('Add Schedule'),
//           ),

//           const SizedBox(height: 20),
//           const Divider(),
//           const SizedBox(height: 20),

//           // Display existing schedules
//           if (_selectedDoctorId != null) ...[
//             const Text(
//               'Existing Schedules:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _selectedDoctorId == null
//                     ? null
//                     : _firestore
//                         .collection('doctors')
//                         .doc(_selectedDoctorId)
//                         .collection('schedules')
//                         .orderBy('startTime')
//                         .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   final schedules = snapshot.data!.docs;

//                   if (schedules.isEmpty) {
//                     return const Center(
//                       child: Text('No schedules found for this doctor'),
//                     );
//                   }

//                   return ListView.builder(
//                     itemCount: schedules.length,
//                     itemBuilder: (context, index) {
//                       final schedule = schedules[index];
//                       final startTime = (schedule['startTime'] as Timestamp).toDate();
//                       final endTime = (schedule['endTime'] as Timestamp).toDate();
//                       final notes = schedule['notes'] as String?;

//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 4),
//                         child: ListTile(
//                           title: Text(
//                             '${DateFormat('MMM dd, yyyy').format(startTime)} • '
//                             '${DateFormat('hh:mm a').format(startTime)} - '
//                             '${DateFormat('hh:mm a').format(endTime)}',
//                           ),
//                           subtitle: notes?.isNotEmpty == true ? Text(notes!) : null,
//                           trailing: IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () async {
//                               await _firestore
//                                   .collection('doctors')
//                                   .doc(_selectedDoctorId)
//                                   .collection('schedules')
//                                   .doc(schedule.id)
//                                   .delete();
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ), 
//           ],
//         ],
//       ),
//     );
//   }
// }

// class ScheduleScreen extends StatelessWidget {
//     const ScheduleScreen ({Key? key}) : super(key: key);

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold(
//             appBar: AppBar(
//                 title: const Text('Feedback'),
//             ),
//             body: const Center(
//                 child: Text('FeedbackScreen'),
//             ),
//         );
//     }
// }