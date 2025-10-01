// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';


// class ProfileManagementScreen extends StatelessWidget {
//   const ProfileManagementScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Profile Management', style: TextStyle(color: Colors.white)),
//           centerTitle: true,
//           backgroundColor: Colors.blue[900],
//           bottom: const TabBar(
//             indicatorColor: Colors.white,
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.white70,
//             tabs: [
//               Tab(text: 'Schedule'),
//               Tab(text: 'Doctors'),
//               Tab(text: 'Patients'),
//             ],
//           ),
//         ),
//         body: const TabBarView(
//           children: [
//             ScheduleTab(),
//             DoctorsTab(),
//             PatientsTab(),
//           ],
//         ),
//       ),
//     );
//   }
// }


// class ScheduleTab extends StatelessWidget {
//   const ScheduleTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Schedule management will be implemented here.'),
//     );
//   }
// }

//////////


// class ScheduleTab extends StatefulWidget {
//   const ScheduleTab({super.key});

//   @override
//   State<ScheduleTab> createState() => _ScheduleTabState();
// }

// class _ScheduleTabState extends State<ScheduleTab> {
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

//           // Notes field
//           TextField(
//             controller: _notesController,
//             decoration: const InputDecoration(
//               labelText: 'Notes (optional)',
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 2,
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
////////////////
///////////////

// class DoctorsTab extends StatefulWidget {
//   const DoctorsTab({super.key});

//   @override
//   State<DoctorsTab> createState() => _DoctorsTabState();
// }

// class _DoctorsTabState extends State<DoctorsTab> {
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



///////////////////////////////

// class PatientsTab extends StatefulWidget {
//   const PatientsTab({super.key});

//   @override
//   State<PatientsTab> createState() => _PatientsTabState();
// }

// class _PatientsTabState extends State<PatientsTab> {
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






// class PatientsTab extends StatelessWidget {
//   const PatientsTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance.collection('users').snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final users = snapshot.data!.docs;

//         return ListView.builder(
//           itemCount: users.length,
//           itemBuilder: (context, index) {
//             final user = users[index].data() as Map<String, dynamic>;
//             return ListTile(
//               title: Text(user['fullName'] ?? 'No name'),
//               subtitle: Text(user['email'] ?? 'No email'),
//               // Add more fields as needed
//             );
//           },
//         );
//       },
//     );
//   }
// }



// class DoctorsTab extends StatefulWidget {
//   const DoctorsTab({super.key});

//   @override
//   State<DoctorsTab> createState() => _DoctorsTabState();
// }

// class _DoctorsTabState extends State<DoctorsTab> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   // Controllers for the editable row
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

//   // Dropdown options
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
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
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

//   Widget _buildDoctorRow(Map<String, dynamic> doctor, String docId) {
//     final createdAt = doctor['createdAt']?.toDate();
//     final updatedAt = doctor['updatedAt']?.toDate();

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       child: SingleChildScrollView(
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
//                 IconButton(
//                   icon: const Icon(Icons.edit, size: 20),
//                   onPressed: () => _startEditing(doctor, docId),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                   onPressed: () => _deleteDoctor(docId),
//                 ),
//               ],
//             ),
//             const Divider(height: 16, thickness: 1),
//             _buildInfoRow(Icons.medical_services, doctor['specialties']),
//             _buildInfoRow(Icons.email, doctor['email']),
//             _buildInfoRow(Icons.phone, doctor['phone']),
//             if (doctor['address']?.isNotEmpty ?? false)
//               _buildInfoRow(Icons.location_on, doctor['address']),
//             if (doctor['experience'] != null)
//               _buildInfoRow(Icons.work, '${doctor['experience']} years experience'),
//             if (doctor['gender'] != null)
//               _buildInfoRow(Icons.person_outline, doctor['gender'] == 'male' ? 'Male' : 'Female'),
//             if (doctor['status'] != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.check_circle,
//                       size: 16,
//                       color: doctor['status'] == 'approved' ? Colors.green : Colors.orange,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       doctor['status'] == 'approved' ? 'Approved' : 'Pending',
//                       style: TextStyle(
//                         color: doctor['status'] == 'approved' ? Colors.green : Colors.orange,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             if (createdAt != null)
//               _buildInfoRow(Icons.calendar_today, 'Registered: ${DateFormat('MMM d, y').format(createdAt)}'),
//             if (updatedAt != null)
//               _buildInfoRow(Icons.update, 'Updated: ${DateFormat('MMM d, y').format(updatedAt)}'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String? text) {
//     if (text == null || text.isEmpty) return const SizedBox();
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 16),
//           const SizedBox(width: 8),
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

//   Widget _buildEditableRow() {
//     return Card(
//       margin: const EdgeInsets.all(8),
//       color: Colors.blue[50],
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 _isAdding ? 'Add New Doctor' : 'Edit Doctor',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               _buildTextField(_nameController, 'Full Name', Icons.person, true),
//               _buildTextField(_emailController, 'Email', Icons.email, true),
//               _buildTextField(_phoneController, 'Phone', Icons.phone, true),
//               _buildTextField(_addressController, 'Address', Icons.location_on, false),
//               _buildTextField(_specialtyController, 'Specialty', Icons.medical_services, true),
//               _buildTextField(_experienceController, 'Experience (years)', Icons.work, true),
//               const SizedBox(height: 8),
//               _buildDropdown(
//                 'Gender',
//                 Icons.person_outline,
//                 _selectedGender,
//                 _genderOptions,
//                 (value) => setState(() => _selectedGender = value),
//               ),
//               const SizedBox(height: 8),
//               _buildDropdown(
//                 'Status',
//                 Icons.check_circle,
//                 _selectedStatus,
//                 _statusOptions,
//                 (value) => setState(() => _selectedStatus = value),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: _cancelEditing,
//                     child: const Text('Cancel'),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton(
//                     onPressed: _saveDoctor,
//                     child: const Text('Save'),
//                   ),
//                 ],
//               ),
//               SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool required) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: const OutlineInputBorder(),
//           filled: true,
//           fillColor: Colors.white,
//           contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//           isDense: true,
//           suffixIcon: required
//               ? const Padding(
//                   padding: EdgeInsets.only(right: 8),
//                   child: Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
//                 )
//               : null,
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown(String label, IconData icon, String? value, List<String> items, ValueChanged<String?> onChanged) {
//     // Validate that the current value exists in the items list
//     final String? dropdownValue = items.contains(value) ? value : null;

//     return InputDecorator(
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: const OutlineInputBorder(),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//         isDense: true,
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: dropdownValue,
//           isDense: true,
//           isExpanded: true,
//           hint: const Text('Select...'),
//           items: items.map((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value[0].toUpperCase() + value.substring(1)),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               labelText: 'Search by Fullname...',
//               prefixIcon: const Icon(Icons.search),
//               suffixIcon: IconButton(
//                 icon: const Icon(Icons.clear),
//                 onPressed: () {
//                   _searchController.clear();
//                   setState(() => _searchQuery = '');
//                 },
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//             ),
//             onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
//           ),
//         ),
//         if (_editingDocId == null && !_isAdding)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Align(
//               alignment: Alignment.centerRight,
//               child: FloatingActionButton(
//                 onPressed: _startAdding,
//                 child: const Icon(Icons.add),
//                 mini: true,
//               ),
//             ),
//           ),
//         if (_editingDocId != null || _isAdding) _buildEditableRow(),
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }

//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final doctors = snapshot.data!.docs.where((doc) {
//                 final doctor = doc.data() as Map<String, dynamic>;
//                 final name = doctor['fullName']?.toString().toLowerCase() ?? '';
//                 return name.contains(_searchQuery);
//               }).toList();

//               if (doctors.isEmpty) {
//                 return Center(
//                   child: Text(_searchQuery.isEmpty 
//                     ? 'No doctors found' 
//                     : 'No doctors match your search'),
//                 );
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 itemCount: doctors.length,
//                 itemBuilder: (context, index) {
//                   final doctorDoc = doctors[index];
//                   final doctor = doctorDoc.data() as Map<String, dynamic>;
//                   return _buildDoctorRow(doctor, doctorDoc.id);
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// class DoctorsTab extends StatefulWidget {
//   const DoctorsTab({super.key});

//   @override
//   State<DoctorsTab> createState() => _DoctorsTabState();
// }

// class _DoctorsTabState extends State<DoctorsTab> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   // Controllers for the editable row
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

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
//       _selectedGender = doctorData['gender'];
//       _selectedStatus = doctorData['status'];
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
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
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

//   Widget _buildDoctorRow(Map<String, dynamic> doctor, String docId) {
//     final createdAt = doctor['createdAt']?.toDate();
//     final updatedAt = doctor['updatedAt']?.toDate();

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       child: SingleChildScrollView(
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
//                 IconButton(
//                   icon: const Icon(Icons.edit, size: 20),
//                   onPressed: () => _startEditing(doctor, docId),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                   onPressed: () => _deleteDoctor(docId),
//                 ),
//               ],
//             ),
//             const Divider(height: 16, thickness: 1),
//             _buildInfoRow(Icons.medical_services, doctor['specialties']),
//             _buildInfoRow(Icons.email, doctor['email']),
//             _buildInfoRow(Icons.phone, doctor['phone']),
//             if (doctor['address']?.isNotEmpty ?? false)
//               _buildInfoRow(Icons.location_on, doctor['address']),
//             if (doctor['experience'] != null)
//               _buildInfoRow(Icons.work, '${doctor['experience']} years experience'),
//             if (doctor['gender'] != null)
//               _buildInfoRow(Icons.person_outline, doctor['gender'] == 'male' ? 'Male' : 'Female'),
//             if (doctor['status'] != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.check_circle,
//                       size: 16,
//                       color: doctor['status'] == 'approved' ? Colors.green : Colors.orange,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       doctor['status'] == 'approved' ? 'Approved' : 'Pending',
//                       style: TextStyle(
//                         color: doctor['status'] == 'approved' ? Colors.green : Colors.orange,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             if (createdAt != null)
//               _buildInfoRow(Icons.calendar_today, 'Registered: ${DateFormat('MMM d, y').format(createdAt)}'),
//             if (updatedAt != null)
//               _buildInfoRow(Icons.update, 'Updated: ${DateFormat('MMM d, y').format(updatedAt)}'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String? text) {
//     if (text == null || text.isEmpty) return const SizedBox();
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 16),
//           const SizedBox(width: 8),
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

// Widget _buildEditableRow() {
//   return Card(
//     margin: const EdgeInsets.all(8),
//     color: Colors.blue[50],
//     child: ConstrainedBox(
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height to 80% of screen
//       ),
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           mainAxisSize: MainAxisSize.min, // Important for scrollable columns
//           children: [
//             Text(
//               _isAdding ? 'Add New Doctor' : 'Edit Doctor',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(_nameController, 'Full Name', Icons.person, true),
//             _buildTextField(_emailController, 'Email', Icons.email, true),
//             _buildTextField(_phoneController, 'Phone', Icons.phone, true),
//             _buildTextField(_addressController, 'Address', Icons.location_on, false),
//             _buildTextField(_specialtyController, 'Specialty', Icons.medical_services, true),
//             _buildTextField(_experienceController, 'Experience (years)', Icons.work, true),
//             const SizedBox(height: 8),
//             _buildDropdown(
//               'Gender',
//               Icons.person_outline,
//               _selectedGender,
//               ['male', 'female'],
//               (value) => setState(() => _selectedGender = value),
//             ),
//             const SizedBox(height: 8),
//             _buildDropdown(
//               'Status',
//               Icons.check_circle,
//               _selectedStatus,
//               ['pending', 'approved'],
//               (value) => setState(() => _selectedStatus = value),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: _cancelEditing,
//                   child: const Text('Cancel'),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _saveDoctor,
//                   child: const Text('Save'),
//                 ),
//               ],
//             ),
//             // Add extra space when keyboard is visible
//             SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
//           ],
//         ),
//       ),
//     ),
//   );
// }

//   Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool required) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: const OutlineInputBorder(),
//           filled: true,
//           fillColor: Colors.white,
//           contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//           isDense: true,
//           suffixIcon: required
//               ? const Padding(
//                   padding: EdgeInsets.only(right: 8),
//                   child: Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
//                 )
//               : null,
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown(String label, IconData icon, String? value, List<String> items, ValueChanged<String?> onChanged) {
//     return InputDecorator(
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: const OutlineInputBorder(),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//         isDense: true,
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: value,
//           isDense: true,
//           isExpanded: true,
//           items: items.map((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value[0].toUpperCase() + value.substring(1)),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               labelText: 'Search by Fullname...',
//               prefixIcon: const Icon(Icons.search),
//               suffixIcon: IconButton(
//                 icon: const Icon(Icons.clear),
//                 onPressed: () {
//                   _searchController.clear();
//                   setState(() => _searchQuery = '');
//                 },
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//             ),
//             onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
//           ),
//         ),
//         if (_editingDocId == null && !_isAdding)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Align(
//               alignment: Alignment.centerRight,
//               child: FloatingActionButton(
//                 onPressed: _startAdding,
//                 child: const Icon(Icons.add),
//                 mini: true,
//               ),
//             ),
//           ),
//         if (_editingDocId != null || _isAdding) _buildEditableRow(),
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }

//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final doctors = snapshot.data!.docs.where((doc) {
//                 final doctor = doc.data() as Map<String, dynamic>;
//                 final name = doctor['fullName']?.toString().toLowerCase() ?? '';
//                 return name.contains(_searchQuery);
//               }).toList();

//               if (doctors.isEmpty) {
//                 return Center(
//                   child: Text(_searchQuery.isEmpty 
//                     ? 'No doctors found' 
//                     : 'No doctors match your search'),
//                 );
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 itemCount: doctors.length,
//                 itemBuilder: (context, index) {
//                   final doctorDoc = doctors[index];
//                   final doctor = doctorDoc.data() as Map<String, dynamic>;
//                   return _buildDoctorRow(doctor, doctorDoc.id);
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }



























// class DoctorsTab extends StatefulWidget {
//   const DoctorsTab({super.key});

//   @override
//   State<DoctorsTab> createState() => _DoctorsTabState();
// }

// class _DoctorsTabState extends State<DoctorsTab> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _editingDocId;
//   bool _isAdding = false;

//   // Controllers for the editable row
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//   String? _selectedGender;
//   String? _selectedStatus;

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
//       _selectedGender = doctorData['gender'];
//       _selectedStatus = doctorData['status'];
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
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
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

//   Widget _buildDoctorRow(Map<String, dynamic> doctor, String docId) {
//     final createdAt = doctor['createdAt']?.toDate();
//     final updatedAt = doctor['updatedAt']?.toDate();

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
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
//                 IconButton(
//                   icon: const Icon(Icons.edit, size: 20),
//                   onPressed: () => _startEditing(doctor, docId),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                   onPressed: () => _deleteDoctor(docId),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             _buildInfoRow(Icons.medical_services, doctor['specialties']),
//             _buildInfoRow(Icons.email, doctor['email']),
//             _buildInfoRow(Icons.phone, doctor['phone']),
//             _buildInfoRow(Icons.location_on, doctor['address']),
//             if (doctor['experience'] != null)
//               _buildInfoRow(Icons.work, '${doctor['experience']} years experience'),
//             if (doctor['gender'] != null)
//               _buildInfoRow(Icons.person_outline, doctor['gender'] == 'male' ? 'Male' : 'Female'),
//             if (doctor['status'] != null)
//               Row(
//                 children: [
//                   Icon(
//                     Icons.check_circle,
//                     size: 16,
//                     color: doctor['status'] == 'approved' ? Colors.green : Colors.orange,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     doctor['status'] == 'approved' ? 'Approved' : 'Pending',
//                     style: TextStyle(
//                       color: doctor['status'] == 'approved' ? Colors.green : Colors.orange,
//                     ),
//                   ),
//                 ],
//               ),
//             if (createdAt != null)
//               _buildInfoRow(Icons.calendar_today, 'Registered: ${DateFormat('MMM d, y').format(createdAt)}'),
//             if (updatedAt != null)
//               _buildInfoRow(Icons.update, 'Updated: ${DateFormat('MMM d, y').format(updatedAt)}'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String? text) {
//     if (text == null || text.isEmpty) return const SizedBox();
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2.0),
//       child: Row(
//         children: [
//           Icon(icon, size: 16),
//           const SizedBox(width: 8),
//           Flexible(child: Text(text)),
//         ],
//       ),
//     );
//   }

//   Widget _buildEditableRow() {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       color: Colors.blue[50],
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             Text(
//               _isAdding ? 'Add New Doctor' : 'Edit Doctor',
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(_nameController, 'Full Name', Icons.person, true),
//             _buildTextField(_emailController, 'Email', Icons.email, true),
//             _buildTextField(_phoneController, 'Phone', Icons.phone, true),
//             _buildTextField(_addressController, 'Address', Icons.location_on, false),
//             _buildTextField(_specialtyController, 'Specialty', Icons.medical_services, true),
//             _buildTextField(_experienceController, 'Experience (years)', Icons.work, true),
//             const SizedBox(height: 8),
//             _buildDropdown(
//               'Gender',
//               Icons.person_outline,
//               _selectedGender,
//               ['male', 'female'],
//               (value) => setState(() => _selectedGender = value),
//             ),
//             const SizedBox(height: 8),
//             _buildDropdown(
//               'Status',
//               Icons.check_circle,
//               _selectedStatus,
//               ['pending', 'approved'],
//               (value) => setState(() => _selectedStatus = value),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: _cancelEditing,
//                   child: const Text('Cancel'),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _saveDoctor,
//                   child: const Text('Save'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool required) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: const OutlineInputBorder(),
//           filled: true,
//           fillColor: Colors.white,
//           contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//           isDense: true,
//           suffixIcon: required
//               ? const Padding(
//                   padding: EdgeInsets.only(right: 8.0),
//                   child: Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
//                 )
//               : null,
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown(String label, IconData icon, String? value, List<String> items, ValueChanged<String?> onChanged) {
//     return InputDecorator(
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: const OutlineInputBorder(),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//         isDense: true,
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: value,
//           isDense: true,
//           isExpanded: true,
//           items: items.map((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value[0].toUpperCase() + value.substring(1)),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               labelText: 'Search by Fullname...',
//               prefixIcon: const Icon(Icons.search),
//               suffixIcon: IconButton(
//                 icon: const Icon(Icons.clear),
//                 onPressed: () {
//                   _searchController.clear();
//                   setState(() => _searchQuery = '');
//                 },
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8.0),
//               ),
//             ),
//             onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
//           ),
//         ),
//         if (_editingDocId == null && !_isAdding)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Align(
//               alignment: Alignment.centerRight,
//               child: FloatingActionButton(
//                 onPressed: _startAdding,
//                 child: const Icon(Icons.add),
//                 mini: true,
//               ),
//             ),
//           ),
//         if (_editingDocId != null || _isAdding) _buildEditableRow(),
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }

//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final doctors = snapshot.data!.docs.where((doc) {
//                 final doctor = doc.data() as Map<String, dynamic>;
//                 final name = doctor['fullName']?.toString().toLowerCase() ?? '';
//                 return name.contains(_searchQuery);
//               }).toList();

//               if (doctors.isEmpty) {
//                 return Center(
//                   child: Text(_searchQuery.isEmpty 
//                     ? 'No doctors found' 
//                     : 'No doctors match your search'),
//                 );
//               }

//               return ListView.builder(
//                 itemCount: doctors.length,
//                 itemBuilder: (context, index) {
//                   final doctorDoc = doctors[index];
//                   final doctor = doctorDoc.data() as Map<String, dynamic>;
//                   return _buildDoctorRow(doctor, doctorDoc.id);
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }




































// class DoctorsTab extends StatefulWidget {
//   const DoctorsTab({super.key});

//   @override
//   State<DoctorsTab> createState() => _DoctorsTabState();
// }

// class _DoctorsTabState extends State<DoctorsTab> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _deleteDoctor(String doctorId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this doctor account?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
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

//   void _showAddEditDoctorDialog({Map<String, dynamic>? doctorData, String? docId}) {
//     final _formKey = GlobalKey<FormState>();
//     final _nameController = TextEditingController(text: doctorData?['fullName']);
//     final _specialtyController = TextEditingController(text: doctorData?['specialties']);
//     final _hospitalController = TextEditingController(text: doctorData?['hospital']);

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(docId == null ? 'Add New Doctor' : 'Edit Doctor'),
//         content: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: const InputDecoration(labelText: 'Full Name'),
//                   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
//                 ),
//                  TextFormField(
//                   controller: _hospitalController,
//                   decoration: const InputDecoration(labelText: 'email'icon (Icons.email) ),
//                   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
//                 ),
//                  TextFormField(
//                   controller: _hospitalController,
//                   decoration: const InputDecoration(labelText: 'phone'icon (Icons.phone) ),
//                   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
//                 ),
//                  TextFormField(
//                   controller: _hospitalController,
//                   decoration: const InputDecoration(labelText: 'address'icon (Icons.location_on) ),

//                 ),
//                 TextFormField(
//                   controller: _specialtyController,
//                   decoration: const InputDecoration(labelText: 'Specialty'icon (Icons.medical_services) ),
//                   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
//                 ),
//                  TextFormField(
//                   controller: _hospitalController,
//                   decoration: const InputDecoration(labelText: 'experience'icon (Icons.work) ),
//                   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
//                 ),
//                 DropdownButtonFormField<String>(
//                   decoration: const InputDecoration(labelText 'gender'icon (Icons.person) ),
//                   items: const DropdownMenuItem(value) female', child' male), 
//                    TextFormField(
//                   controller: _hospitalController,
//                   decoration: const InputDecoration(labelText: 'status'icon (Icons.check_circle) ),
//                   items: [
//                     DropdownMenuItem(value: 'pending', child: Text('Pending')),
//                     DropdownMenuItem(value: 'approved', child: Text('Approved')),
//                   ],
//                 ),

//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (_formKey.currentState?.validate() ?? false) {
//                 try {
//                   final doctorData = {
//                     'fullName': _nameController.text,
//                     'specialties': _specialtyController.text,
//                     'hospital': _hospitalController.text,
//                     'updatedAt': FieldValue.serverTimestamp(),
//                   };

//                   if (docId == null) {
//                     // Add new doctor
//                     await FirebaseFirestore.instance.collection('doctors').add(doctorData);
//                   } else {
//                     // Update existing doctor
//                     await FirebaseFirestore.instance.collection('doctors').doc(docId).update(doctorData);
//                   }

//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text(docId == null ? 'Doctor added!' : 'Doctor updated!')),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Error: $e')),
//                   );
//                 }
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               labelText: 'Search by Fullname . . . . .',
//               prefixIcon: const Icon(Icons.search),
//               suffixIcon: IconButton(
//                 icon: const Icon(Icons.clear),
//                 onPressed: () {
//                   _searchController.clear();
//                   setState(() => _searchQuery = '');
//                 },
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8.0),
//               ),
//             ),
//             onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
//           ),
//         ),
//         FloatingActionButton(
//           onPressed: () => _showAddEditDoctorDialog(),// when click show like table rows add doctor
//           child: const Icon(Icons.add),
//           mini: true,
//         ),
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }

//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final doctors = snapshot.data!.docs.where((doc) {
//                 final doctor = doc.data() as Map<String, dynamic>;
//                 final name = doctor['fullName']?.toString().toLowerCase() ?? '';
//                 return name.contains(_searchQuery);
//               }).toList();

//               if (doctors.isEmpty) {
//                 return Center(
//                   child: Text(_searchQuery.isEmpty 
//                     ? 'No doctors found' 
//                     : 'No doctors match your search'),
//                 );
//               }

//               return ListView.builder(
//                 itemCount: doctors.length,
//                 itemBuilder: (context, index) {
//                   final doctorDoc = doctors[index];
//                   final doctor = doctorDoc.data() as Map<String, dynamic>;
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: doctor['photoUrl'] != null 
//                             ? NetworkImage(doctor['photoUrl']) 
//                             : null,
//                         child: doctor['photoUrl'] == null 
//                             ? Text(doctor['fullName']?[0] ?? '?') 
//                             : null,
//                       ),
//                       title: Text(doctor['fullName'] ?? 'No name'),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(doctor['specialties'] ?? 'No specialization'),
//                           if (doctor['address'] != null)
//                             Text(doctor['address'] ?? 'No address'),
//                           if (doctor['phone'] != null)
//                             Text(doctor['phone'] ?? 'No phone number'),
//                           if (doctor['email'] != null)
//                             Text(doctor['email'] ?? 'No email'),
//                             if (doctor['experience'] != null)
//                             Text(doctor['experience'] ?? 'No experience'),
//                           if (doctor['gender'] != null)
//                             Text('gender: ${doctor['No gender']}'),//when add or edit doctor gender will be selected female or male
//                           if (doctor['status'] != null)
//                             Text('Status: ${doctor['status']}'),//when add or edit doctor, status will be selected pending or approved
//                           if (doctor['createdAt'] != null)
//                             Text('Registered: ${doctor['createdAt'].toDate().toLocal()}'),
//                           if (doctor['updatedAt'] != null)
//                             Text('Updated: ${doctor['updatedAt'].toDate().toLocal()}'),


//                         ],
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, size: 20),
//                             onPressed: () => _showAddEditDoctorDialog(
//                               doctorData: doctor,
//                               docId: doctorDoc.id,
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                             onPressed: () => _deleteDoctor(doctorDoc.id),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }



// class DoctorsTab extends StatelessWidget {
//   const DoctorsTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: () async {
//         // Force refresh logic here
//       },
//       child: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final doctors = snapshot.data!.docs;

//           if (doctors.isEmpty) {
//             return const Center(child: Text('No doctors found'));
//           }

//           return ListView.builder(
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index].data() as Map<String, dynamic>;
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundImage: doctor['photoUrl'] != null 
//                         ? NetworkImage(doctor['photoUrl']) 
//                         : null,
//                     child: doctor['photoUrl'] == null 
//                         ? Text(doctor['fullName']?[0] ?? '?') 
//                         : null,
//                   ),
//                   title: Text(doctor['fullName'] ?? 'No name'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(doctor['specialties'] ?? 'No specialization'),
//                       if (doctor['hospital'] != null)
//                         Text(doctor['hospital']),
//                     ],
//                   ),
//                   trailing: const Icon(Icons.chevron_right),
//                   onTap: () {
//                     // Navigate to doctor details
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';


// class ProfileManagementScreen extends StatelessWidget {
//   const ProfileManagementScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
  
    
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Profile Management', style: TextStyle(color: Colors.white)),
//           centerTitle: true,
//           backgroundColor: Colors.blue[900],
//           bottom: const TabBar(
//             indicatorColor: Colors.white,
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.white70,
//             tabs: [
//               Tab1(text: 'Doctors'),
//               Tab2(text: 'Patients'),
//             ],
//           ),
//         ),
        
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ProfileManagementScreen extends StatelessWidget {
//   const ProfileManagementScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Profile Management', style: TextStyle(color: Colors.white)),
//           centerTitle: true,
//           backgroundColor: Colors.blue[900],
//           bottom: const TabBar(
//             indicatorColor: Colors.white,
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.white70,
//             tabs: [
//               Tab(text: 'Schedules'),
//               Tab(text: 'Doctors'),   
//               Tab(text: 'Patients'),
//             ],
//           ),
//         ),
//         body: const TabBarView(
//           children: [
//             ScheduleManagementTab(),
//             UserList(collection: 'doctors', role: 'doctor'),
//             UserList(collection: 'patients', role: 'patient'),
//           ],
//         ),
//         backgroundColor: Colors.white,
//       ),
//     );
//   }
// }

// class ScheduleManagementTab extends StatefulWidget {
//   const ScheduleManagementTab({super.key});

//   @override
//   State<ScheduleManagementTab> createState() => _ScheduleManagementTabState();
// }

// class _ScheduleManagementTabState extends State<ScheduleManagementTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: TextField(
//             decoration: InputDecoration(
//               labelText: 'Search by doctor name',
//               labelStyle: TextStyle(color: Colors.blue[900]),
//               prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//               filled: true,
//               fillColor: Colors.white,
//               enabledBorder: OutlineInputBorder(
//                 borderSide: const BorderSide(color: Colors.blueGrey),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.blue[900]!),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//           ),
//         ),
        
//         ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue[900],
//             minimumSize: const Size(double.infinity, 50),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           onPressed: () => _showAddScheduleDialog(),
//           child: const Text(
//             'Add New Schedule',
//             style: TextStyle(color: Colors.white, fontSize: 16),
//           ),
//         ),
        
//         const SizedBox(height: 10),
        
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection('schedules').snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
              
//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return const Center(child: Text('No schedules found.'));
//               }
              
//               final schedules = snapshot.data!.docs.where((doc) {
//                 final schedule = doc.data() as Map<String, dynamic>;
//                 final doctorName = schedule['doctorName']?.toLowerCase() ?? '';
//                 return doctorName.contains(searchQuery);
//               }).toList();
              
//               if (schedules.isEmpty) {
//                 return const Center(child: Text('No matching schedules found.'));
//               }
              
//               return ListView.builder(
//                 itemCount: schedules.length,
//                 itemBuilder: (context, index) {
//                   final doc = schedules[index];
//                   final schedule = doc.data() as Map<String, dynamic>;
                  
//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.blue[900],
//                         child: const Icon(Icons.calendar_today, color: Colors.white),
//                       ),
//                       title: Text(
//                         schedule['doctorName'] ?? 'No Doctor',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Day: ${schedule['day']}'),
//                           Text('Time: ${schedule['startTime']} - ${schedule['endTime']}'),
//                         ],
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit, size: 20),
//                             onPressed: () => _showEditScheduleDialog(doc.id, schedule),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//                             onPressed: () => _confirmDeleteSchedule(doc.id, schedule['doctorName']),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _showAddScheduleDialog() async {
//     final formKey = GlobalKey<FormState>();
//     final Map<String, dynamic> newSchedule = {};
//     final TextEditingController doctorController = TextEditingController();
//     final TextEditingController dayController = TextEditingController();
//     final TextEditingController startTimeController = TextEditingController();
//     final TextEditingController endTimeController = TextEditingController();

//     // Fetch doctors list
//     final doctors = await _firestore.collection('doctors').get();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Add New Schedule'),
//         content: SingleChildScrollView(
//           child: Form(
//             key: formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 DropdownButtonFormField<String>(
//                   decoration: const InputDecoration(labelText: 'Doctor'),
//                   items: doctors.docs.map((doc) {
//                     final doctor = doc.data() as Map<String, dynamic>;
//                     return DropdownMenuItem<String>(
//                       value: doc.id,
//                       child: Text(doctor['fullName'] ?? 'Unknown Doctor'),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     newSchedule['doctorId'] = value;
//                     final doctor = doctors.docs.firstWhere((doc) => doc.id == value);
//                     newSchedule['doctorName'] = doctor['fullName'];
//                   },
//                   validator: (value) => value == null ? 'Required' : null,
//                 ),
//                 TextFormField(
//                   controller: dayController,
//                   decoration: const InputDecoration(labelText: 'Day (e.g., Monday)'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newSchedule['day'] = value,
//                 ),
//                 TextFormField(
//                   controller: startTimeController,
//                   decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newSchedule['startTime'] = value,
//                 ),
//                 TextFormField(
//                   controller: endTimeController,
//                   decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newSchedule['endTime'] = value,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (formKey.currentState!.validate()) {
//                 formKey.currentState!.save();
//                 try {
//                   await _firestore.collection('schedules').add(newSchedule);
//                   if (mounted) {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Schedule added successfully')),
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error adding schedule: $e')),
//                     );
//                   }
//                 }
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _showEditScheduleDialog(String scheduleId, Map<String, dynamic> schedule) async {
//     final formKey = GlobalKey<FormState>();
//     final TextEditingController dayController = TextEditingController(text: schedule['day']);
//     final TextEditingController startTimeController = TextEditingController(text: schedule['startTime']);
//     final TextEditingController endTimeController = TextEditingController(text: schedule['endTime']);

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Edit ${schedule['doctorName']}\'s Schedule'),
//         content: SingleChildScrollView(
//           child: Form(
//             key: formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(schedule['doctorName'] ?? 'Unknown Doctor'),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: dayController,
//                   decoration: const InputDecoration(labelText: 'Day'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                 ),
//                 TextFormField(
//                   controller: startTimeController,
//                   decoration: const InputDecoration(labelText: 'Start Time'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                 ),
//                 TextFormField(
//                   controller: endTimeController,
//                   decoration: const InputDecoration(labelText: 'End Time'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (formKey.currentState!.validate()) {
//                 try {
//                   await _firestore.collection('schedules').doc(scheduleId).update({
//                     'day': dayController.text,
//                     'startTime': startTimeController.text,
//                     'endTime': endTimeController.text,
//                     'updatedAt': FieldValue.serverTimestamp(),
//                   });
//                   if (mounted) {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Schedule updated successfully')),
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error updating schedule: $e')),
//                     );
//                   }
//                 }
//               }
//             },
//             child: const Text('Update'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _confirmDeleteSchedule(String scheduleId, String doctorName) async {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: Text('Are you sure you want to delete $doctorName\'s schedule?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await _deleteSchedule(scheduleId, doctorName);
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _deleteSchedule(String scheduleId, String doctorName) async {
//     try {
//       await _firestore.collection('schedules').doc(scheduleId).delete();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('$doctorName\'s schedule deleted successfully')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting schedule: $e')),
//         );
//       }
//     }
//   }
// }

// class UserList extends StatefulWidget {
//   final String collection;
//   final String role;
//   const UserList({super.key, required this.collection, required this.role});

//   @override
//   State<UserList> createState() => _UserListState();
// }

// class _UserListState extends State<UserList> {
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Search bar
//         Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: TextField(
//             decoration: InputDecoration(
//               labelText: 'Search by fullName',
//               labelStyle: TextStyle(color: Colors.blue[900]),
//               prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//               filled: true,
//               fillColor: Colors.white,
//               enabledBorder: OutlineInputBorder(
//                 borderSide: const BorderSide(color: Colors.blueGrey),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.blue[900]!),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//           ),
//         ),

//         // Add New User button
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue[900],
//               minimumSize: const Size(double.infinity, 50),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onPressed: () => _showAddUserDialog(),
//             child: Text(
//               'Add New ${widget.role == 'doctor' ? 'Doctor' : 'Patient'}',
//               style: const TextStyle(color: Colors.white, fontSize: 16),
//             ),
//           ),
//         ),

//         // StreamBuilder
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection(widget.collection)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return Center(child: Text('No ${widget.role}s found.'));
//               }

//               final users = snapshot.data!.docs.where((doc) {
//                 final user = doc.data() as Map<String, dynamic>;
//                 final fullName = user['fullName']?.toLowerCase() ?? '';
//                 return fullName.contains(searchQuery);
//               }).toList();

//               if (users.isEmpty) {
//                 return const Center(child: Text('No matching results.'));
//               }

//               return ListView.builder(
//                 itemCount: users.length,
//                 itemBuilder: (context, index) {
//                   final doc = users[index];
//                   final user = doc.data() as Map<String, dynamic>;

//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.blue[900],
//                         child: Icon(
//                           widget.role == 'doctor' ? Icons.medical_services : Icons.person,
//                           color: Colors.white,
//                         ),
//                       ),
//                       title: Text(
//                         user['fullName'] ?? 'No Name',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: widget.role == 'doctor'
//                           ? Text('${user['specialties'] ?? 'Specialty not specified'}')
//                           : Text(user['email'] ?? ''),
//                       trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
//                       onTap: () => _showUserDetails(context, doc, user),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   void _showUserDetails(BuildContext context, QueryDocumentSnapshot doc, Map<String, dynamic> user) {
//     final isDoctor = widget.role == 'doctor';
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Center(
//           child: Text(
//             user['fullName'] ?? 'User Details',
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Common fields for all users
//               _buildDetailRow('Email:', user['email']),
//               _buildDetailRow('Phone:', user['phone']),
//               _buildDetailRow('Gender:', user['gender']),
//               _buildDetailRow('Registration Date:', 
//                   (user['createdAt'] as Timestamp?)?.toDate().toString() ?? 'N/A'),
              
//               // Patient-specific fields
//               if (!isDoctor) ...[
//                 _buildDetailRow('Address:', user['address']),
//                 _buildDetailRow('Date of Birth:', user['dateOfBirth']),
//               ],
              
//               // Doctor-specific fields
//               if (isDoctor) ...[
//                 const SizedBox(height: 12),
//                 const Divider(),
//                 const Text('Professional Details:', style: TextStyle(fontWeight: FontWeight.bold)),
//                 _buildDetailRow('Specialization:', user['specialties']),
//                 _buildDetailRow('Experience:', '${user['experience']} years'),
//                 _buildDetailRow('Status:', user['status'] ?? 'N/A'),
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _editUser(doc.id, user),
//             child: const Text('Edit', style: TextStyle(color: Colors.blue)),
//           ),
//           TextButton(
//             onPressed: () => _confirmDeleteUser(context, doc, user),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//           if (isDoctor)
//             TextButton(
//               onPressed: () => _toggleAdminStatus(doc.id, !(user['isAdmin'] ?? false)),
//               child: Text(
//                 user['isAdmin'] == true ? 'Remove Admin' : 'Make Admin',
//                 style: TextStyle(color: user['isAdmin'] == true ? Colors.orange : Colors.green),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//           ),
//           const Text(': '),
//           Expanded(child: Text(value ?? 'Not specified')),
//         ],
//       ),
//     );
//   }

//   void _showAddUserDialog() {
//     final isDoctor = widget.role == 'doctor';
//     final formKey = GlobalKey<FormState>();
//     final Map<String, dynamic> newUser = {
//       'role': widget.role,
//       'createdAt': FieldValue.serverTimestamp(),
//       'status': isDoctor ? 'pending' : 'active',
//     };

//     final controllers = {
//       'fullName': TextEditingController(),
//       'email': TextEditingController(),
//       'phone': TextEditingController(),
//       'gender': TextEditingController(),
//       'dateOfBirth': TextEditingController(),
//       'address': TextEditingController(),
//       'specialties': TextEditingController(),
//       'experience': TextEditingController(),
//     };

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Add New ${isDoctor ? 'Doctor' : 'Patient'}'),
//         content: SingleChildScrollView(
//           child: Form(
//             key: formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: controllers['fullName'],
//                   decoration: const InputDecoration(labelText: 'Full Name'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newUser['fullName'] = value,
//                 ),
//                 TextFormField(
//                   controller: controllers['email'],
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newUser['email'] = value,
//                 ),
//                 TextFormField(
//                   controller: controllers['phone'],
//                   decoration: const InputDecoration(labelText: 'Phone'),
//                   keyboardType: TextInputType.phone,
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newUser['phone'] = value,
//                 ),
//                 TextFormField(
//                   controller: controllers['gender'],
//                   decoration: const InputDecoration(labelText: 'Gender'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newUser['gender'] = value,
//                 ),
                
//                 if (!isDoctor) ...[
//                   TextFormField(
//                     controller: controllers['dateOfBirth'],
//                     decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => newUser['dateOfBirth'] = value,
//                   ),
//                   TextFormField(
//                     controller: controllers['address'],
//                     decoration: const InputDecoration(labelText: 'Address'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => newUser['address'] = value,
//                   ),
//                 ],
                
//                 if (isDoctor) ...[
//                   TextFormField(
//                     controller: controllers['specialties'],
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => newUser['specialties'] = value,
//                   ),
//                   TextFormField(
//                     controller: controllers['experience'],
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => newUser['experience'] = int.tryParse(value!) ?? 0,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (formKey.currentState!.validate()) {
//                 formKey.currentState!.save();
//                 try {
//                   await FirebaseFirestore.instance
//                       .collection(widget.collection)
//                       .add(newUser);
//                   if (mounted) {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('${isDoctor ? 'Doctor' : 'Patient'} added successfully')),
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error adding user: $e')),
//                     );
//                   }
//                 }
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _confirmDeleteUser(BuildContext context, QueryDocumentSnapshot doc, Map<String, dynamic> user) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: Text('Are you sure you want to delete ${user['fullName']}?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context); // Close confirmation dialog
//               await _deleteUser(doc, user);
//               if (mounted) Navigator.pop(context); // Close details dialog
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _deleteUser(QueryDocumentSnapshot doc, Map<String, dynamic> user) async {
//     try {
//       // Backup the user before deleting
//       await FirebaseFirestore.instance
//           .collection('deleted_${widget.collection}')
//           .doc(doc.id)
//           .set(user);
      
//       await FirebaseFirestore.instance
//           .collection(widget.collection)
//           .doc(doc.id)
//           .delete();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('${user['fullName']} deleted successfully')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _editUser(String userId, Map<String, dynamic> currentData) async {
//     final isDoctor = widget.role == 'doctor';
//     final formKey = GlobalKey<FormState>();
//     final Map<String, dynamic> updatedUser = {};

//     final controllers = {
//       'fullName': TextEditingController(text: currentData['fullName']),
//       'email': TextEditingController(text: currentData['email']),
//       'phone': TextEditingController(text: currentData['phone']),
//       'gender': TextEditingController(text: currentData['gender']),
//       'dateOfBirth': TextEditingController(text: currentData['dateOfBirth']),
//       'address': TextEditingController(text: currentData['address']),
//       'specialties': TextEditingController(text: currentData['specialties']),
//       'experience': TextEditingController(text: currentData['experience']?.toString()),
//     };

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Edit ${isDoctor ? 'Doctor' : 'Patient'}'),
//         content: SingleChildScrollView(
//           child: Form(
//             key: formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: controllers['fullName'],
//                   decoration: const InputDecoration(labelText: 'Full Name'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => updatedUser['fullName'] = value,
//                 ),
//                 TextFormField(
//                   controller: controllers['email'],
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => updatedUser['email'] = value,
//                 ),
//                 TextFormField(
//                   controller: controllers['phone'],
//                   decoration: const InputDecoration(labelText: 'Phone'),
//                   keyboardType: TextInputType.phone,
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => updatedUser['phone'] = value,
//                 ),
//                 TextFormField(
//                   controller: controllers['gender'],
//                   decoration: const InputDecoration(labelText: 'Gender'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => updatedUser['gender'] = value,
//                 ),
                
//                 if (!isDoctor) ...[
//                   TextFormField(
//                     controller: controllers['dateOfBirth'],
//                     decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => updatedUser['dateOfBirth'] = value,
//                   ),
//                   TextFormField(
//                     controller: controllers['address'],
//                     decoration: const InputDecoration(labelText: 'Address'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => updatedUser['address'] = value,
//                   ),
//                 ],
                
//                 if (isDoctor) ...[
//                   TextFormField(
//                     controller: controllers['specialties'],
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => updatedUser['specialties'] = value,
//                   ),
//                   TextFormField(
//                     controller: controllers['experience'],
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => updatedUser['experience'] = int.tryParse(value!) ?? 0,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (formKey.currentState!.validate()) {
//                 formKey.currentState!.save();
//                 updatedUser['updatedAt'] = FieldValue.serverTimestamp();
//                 try {
//                   await FirebaseFirestore.instance
//                       .collection(widget.collection)
//                       .doc(userId)
//                       .update(updatedUser);
//                   if (mounted) {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('${isDoctor ? 'Doctor' : 'Patient'} updated successfully')),
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error updating user: $e')),
//                     );
//                   }
//                 }
//               }
//             },
//             child: const Text('Update'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _toggleAdminStatus(String userId, bool makeAdmin) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection(widget.collection)
//           .doc(userId)
//           .update({'isAdmin': makeAdmin});
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(makeAdmin ? 'Made admin successfully' : 'Admin rights removed')),
//         );
//         Navigator.pop(context); // Close the details dialog
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error updating admin status: $e')),
//         );
//       }
//     }
//   }
// }


























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ProfileManagementScreen extends StatelessWidget {
//   const ProfileManagementScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Profile Management', style: TextStyle(color: Colors.white)),
//           centerTitle: true,
//           backgroundColor: Colors.blue[900],
//           bottom: const TabBar(
//             indicatorColor: Colors.white,
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.white70,
//             tabs: [
//               Tab(text: 'Add SChedule'), 
//               Tab(text: 'Doctors'),   
//               Tab(text: 'Patients'),
//             ],
//           ),
//         ),
//         body: const TabBarView(
//           children: [

//             UserList(role: 'doctor'),
//             UserList(role: 'Patient'),
//           ],
//         ),
//         backgroundColor: Colors.white,
//       ),
//     );
//   }
// }

// class UserList extends StatefulWidget {
//   final String role;
//   const UserList({super.key, required this.role});

//   @override
//   State<UserList> createState() => _UserListState();
// }




// class _UserListState extends State<UserList> {
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Search bar
//         Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: TextField(
//             decoration: InputDecoration(
//               labelText: 'Search by fullName',
//               labelStyle: TextStyle(color: Colors.blue[900]),
//               prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//               filled: true,
//               fillColor: Colors.white,
//               enabledBorder: OutlineInputBorder(
//                 borderSide: const BorderSide(color: Colors.blueGrey),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.blue[900]!),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//           ),
//         ),

//         // Add New User button for admins
//         if (widget.role == 'doctor' || widget.role == 'patient')
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue[900],
//                 minimumSize: const Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onPressed: () => _showAddUserDialog(),
//               child: Text(
//                 'Add New ${widget.role == 'doctor' ? 'Doctor' : 'Patient'}',
//                 style: const TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             ),
//           ),

//         // StreamBuilder
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('users')
//                 .where('role', isEqualTo: widget.role)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return Center(child: Text('No ${widget.role}s found.'));
//               }

//               final users = snapshot.data!.docs.where((doc) {
//                 final user = doc.data() as Map<String, dynamic>;
//                 final fullName = user['fullName']?.toLowerCase() ?? '';
//                 return fullName.contains(searchQuery);
//               }).toList();

//               if (users.isEmpty) {
//                 return const Center(child: Text('No matching results.'));
//               }

//               return ListView.builder(
//                 itemCount: users.length,
//                 itemBuilder: (context, index) {
//                   final doc = users[index];
//                   final user = doc.data() as Map<String, dynamic>;

//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.blue[900],
//                         child: Icon(
//                           widget.role == 'doctor' ? Icons.medical_services : Icons.person,
//                           color: Colors.white,
//                         ),
//                       ),
//                       title: Text(
//                         user['fullName'] ?? 'No Name',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: widget.role == 'doctor'
//                           ? Text('${user['specialties'] ?? 'Specialty not specified'}')
//                           : Text(user['email'] ?? ''),
//                       trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
//                       onTap: () => _showUserDetails(context, doc, user),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   void _showUserDetails(BuildContext context, QueryDocumentSnapshot doc, Map<String, dynamic> user) {
//     final isDoctor = widget.role == 'doctor';
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Center(
//           child: Text(
//             user['fullName'] ?? 'User Details',
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Common fields for all users
//               _buildDetailRow('Email:', user['email']),
//               _buildDetailRow('Phone:', user['phone']),
//               _buildDetailRow('Gender:', user['gender']),
//               _buildDetailRow('Registration Date:', 
//                   (user['createdAt'] as Timestamp?)?.toDate().toString() ?? 'N/A'),
              
//               // Patient-specific fields
//               if (!isDoctor) ...[
//                 _buildDetailRow('Address:', user['address']),
//                 _buildDetailRow('Date of Birth:', user['dateOfBirth']),
//               ],
              
//               // Doctor-specific fields
//               if (isDoctor) ...[
//                 const SizedBox(height: 12),
//                 const Divider(),
//                 const Text('Professional Details:', style: TextStyle(fontWeight: FontWeight.bold)),
//                 _buildDetailRow('Specialization:', user['specialties']),
//                 _buildDetailRow('Experience:', '${user['experience']} years'),
//                 _buildDetailRow('Status:', user['status'] ?? 'N/A'),
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _editUser(doc.id, user),
//             child: const Text('Edit', style: TextStyle(color: Colors.blue)),
//           ),
//           TextButton(
//             onPressed: () => _confirmDeleteUser(context, doc, user),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//           if (isDoctor)
//             TextButton(
//               onPressed: () => _toggleAdminStatus(doc.id, !(user['isAdmin'] ?? false)),
//               child: Text(
//                 user['isAdmin'] == true ? 'Remove Admin' : 'Make Admin',
//                 style: TextStyle(color: user['isAdmin'] == true ? Colors.orange : Colors.green),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//           ),
//           const Text(': '),
//           Expanded(child: Text(value ?? 'Not specified')),
//         ],
//       ),
//     );
//   }

//   void _showAddUserDialog() {
//     final isDoctor = widget.role == 'doctor';
//     final formKey = GlobalKey<FormState>();
//     final Map<String, dynamic> newUser = {
//       'role': widget.role,
//       'createdAt': FieldValue.serverTimestamp(),
//       'status': isDoctor ? 'pending' : null,
//     };

//     final TextEditingController fullNameController = TextEditingController();
//     final TextEditingController emailController = TextEditingController();
//     final TextEditingController phoneController = TextEditingController();
//     final TextEditingController genderController = TextEditingController();
//     final TextEditingController dobController = TextEditingController();
//     final TextEditingController addressController = TextEditingController();
//     final TextEditingController specialtiesController = TextEditingController();
//     final TextEditingController experienceController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Add New ${isDoctor ? 'Doctor' : 'Patient'}'),
//         content: SingleChildScrollView(
//           child: Form(
//             key: formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: const InputDecoration(labelText: 'Full Name'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newUser['fullName'] = value,
//                 ),
//                 TextFormField(
//                   controller: emailController,
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newUser['email'] = value,
//                 ),
//                 TextFormField(
//                   controller: phoneController,
//                   decoration: const InputDecoration(labelText: 'Phone'),
//                   keyboardType: TextInputType.phone,
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newUser['phone'] = value,
//                 ),
//                 TextFormField(
//                   controller: genderController,
//                   decoration: const InputDecoration(labelText: 'Gender'),
//                   validator: (value) => value!.isEmpty ? 'Required' : null,
//                   onSaved: (value) => newUser['gender'] = value,
//                 ),
                
//                 if (!isDoctor) ...[
//                   TextFormField(
//                     controller: dobController,
//                     decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => newUser['dateOfBirth'] = value,
//                   ),
//                   TextFormField(
//                     controller: addressController,
//                     decoration: const InputDecoration(labelText: 'Address'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => newUser['address'] = value,
//                   ),
//                 ],
                
//                 if (isDoctor) ...[
//                   TextFormField(
//                     controller: specialtiesController,
//                     decoration: const InputDecoration(labelText: 'Specialization'),
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => newUser['specialties'] = value,
//                   ),
//                   TextFormField(
//                     controller: experienceController,
//                     decoration: const InputDecoration(labelText: 'Experience (years)'),
//                     keyboardType: TextInputType.number,
//                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                     onSaved: (value) => newUser['experience'] = int.tryParse(value!) ?? 0,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (formKey.currentState!.validate()) {
//                 formKey.currentState!.save();
//                 try {
//                   await FirebaseFirestore.instance
//                       .collection('users')
//                       .add(newUser);
//                   if (mounted) {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('${isDoctor ? 'Doctor' : 'Patient'} added successfully')),
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error adding user: $e')),
//                     );
//                   }
//                 }
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _confirmDeleteUser(BuildContext context, QueryDocumentSnapshot doc, Map<String, dynamic> user) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: Text('Are you sure you want to delete ${user['fullName']}?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context); // Close confirmation dialog
//               await _deleteUser(doc, user);
//               if (mounted) Navigator.pop(context); // Close details dialog
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _deleteUser(QueryDocumentSnapshot doc, Map<String, dynamic> user) async {
//     try {
//       // Backup the user before deleting
//       await FirebaseFirestore.instance
//           .collection('deleted_users')
//           .doc(doc.id)
//           .set(user);
      
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(doc.id)
//           .delete();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('${user['fullName']} deleted successfully')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting user: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _editUser(String userId, Map<String, dynamic> currentData) async {
//     // Implement your edit functionality here
//     // You might want to navigate to a separate edit screen
//     // or show a similar dialog to the add user dialog but pre-filled
//   }

//   Future<void> _toggleAdminStatus(String userId, bool makeAdmin) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .update({'isAdmin': makeAdmin});
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(makeAdmin ? 'Made admin successfully' : 'Admin rights removed')),
//         );
//         Navigator.pop(context); // Close the details dialog
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error updating admin status: $e')),
//         );
//       }
//     }
//   }
// }


























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ProfileManagementScreen extends StatelessWidget {
//   const ProfileManagementScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Profile Management', style: TextStyle(color: Colors.white)),
//           centerTitle: true,
//           backgroundColor: Colors.blue[900],
//           bottom: const TabBar(
//             indicatorColor: Colors.white,
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.white70,
//             tabs: [
//               Tab(text: 'Add SChedule'), //adding schedule admin for doctors
//               Tab(text: 'Doctors'),// when adding schedule admin for doctors see schedule for firebase   edit delete Add another doctor only make admin
//               Tab(text: 'Patients'),//add edit deleted patients only make admin
//             ],
//           ),
//         ),
//         body: const TabBarView(
//           children: [

//             UserList(role: 'doctor'),
//             UserList(role: 'Patient'),
//           ],
//         ),
//         backgroundColor: Colors.white,
//       ),
//     );
//   }
// }

// class UserList extends StatefulWidget {
//   final String role;
//   const UserList({super.key, required this.role});

//   @override
//   State<UserList> createState() => _UserListState();
// }

// class _UserListState extends State<UserList> {
//   String searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Search bar
//         Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: TextField(
//             decoration: InputDecoration(
//               labelText: 'Search by fullName',
//               labelStyle: TextStyle(color: Colors.blue[900]),
//               prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
//               filled: true,
//               fillColor: Colors.white,
//               enabledBorder: OutlineInputBorder(
//                 borderSide: const BorderSide(color: Colors.blueGrey),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.blue[900]!),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//           ),
//         ),

//         // StreamBuilder
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('users')
//                 .where('role', isEqualTo: widget.patient)
//                 .snapshots(),
//                 .collection('doctors')
//                 .where('role', isEqualTo: widget.doctor)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return Center(child: Text('No ${widget.role}s found.'));
//               }

//               final users = snapshot.data!.docs.where((doc) {
//                 final user = doc.data() as Map<String, dynamic>;
//                 final fullName = user['fullName']?.toLowerCase() ?? '';
//                 return fullName.contains(searchQuery);
//               }).toList();

//               if (users.isEmpty) {
//                 return const Center(child: Text('No matching results.'));
//               }

//               return ListView.builder(
//                 itemCount: users.length,
//                 itemBuilder: (context, index) {
//                   final doc = users[index];
//                   final user = doc.data() as Map<String, dynamic>;

//                   return Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.2),
//                           blurRadius: 8,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: ListTile(
//                       leading: Icon(Icons.person, color: Colors.blue[900], size: 40),
//                       contentPadding: const EdgeInsets.all(10.0),
//                       title: Text(
//                         user['fullName'] ?? 'No Name',
//                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                       ),
//                       onTap: () => showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: Center(
//                             child: Text(
//                               user['fullName'] ?? 'User Details',
//                               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [ // read like table markii loo baahdo edit delete
//                               Text('Fullname: ${user['fullName'] ?? 'N/A'}'),
//                               Text('Email: ${user['email'] ?? 'N/A'}'),
//                               Text('Phone: ${user['phone'] ?? 'N/A'}'),
//                               Text('address: ${user['address'] ?? 'N/A'}'),
//                               Text('Date of Birth: ${user['dateOfBirth'] ?? 'N/A'}'),
//                               Text('Gender: ${user['gender'] ?? 'N/A'}'),
//                               Text('Registration Date: ${user['createdAt'] ?? 'N/A'}'),


//                           get collection doctors{ // make like table
//                              Text('fullName: ${docId['fullName'] ?? 'N/A'}'),
//                              Text('email: ${docId['email'] ?? 'N/A'}'),
//                              Text('Phone: ${docId['phone'] ?? 'N/A'}'),
//                               Text('address: ${docId['address'] ?? 'N/A'}'),
//                               Text('Specialization: ${docId['specialization'] ?? 'N/A'}'),
//                               Text('Experience: ${docId['experience'] ?? 'N/A'}'),
//                                Text('Gender: ${docId['gender'] ?? 'N/A'}'),
//                               Text('Registration Date: ${docId['createdAt'] ?? 'N/A'}'),
//                               Text('Status: ${docId['status'] ?? 'N/A'}'),

                             
                             
//                           }
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.of(context).pop(),
//                               child: const Text('Edit'),
//                             ),
//                             TextButton(
//                               onPressed: () async {
//                                 final deletedUser = Map<String, dynamic>.from(user);
//                                 await FirebaseFirestore.instance
//                                     .collection('deleted_users')
//                                     .doc(doc.id)
//                                     .set(deletedUser);
//                                 await FirebaseFirestore.instance
//                                     .collection('users')
//                                     .doc(doc.id)
//                                     .delete();
//                                 Navigator.of(context).pop();
//                               },
//                               child: const Text('Delete', style: TextStyle(color: Colors.red)),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
