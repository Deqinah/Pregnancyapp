import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;

  const DoctorProfileScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  late Future<Map<String, dynamic>> _doctorData;

  @override
  void initState() {
    super.initState();
    _doctorData = _fetchDoctorData();
  }

  Future<Map<String, dynamic>> _fetchDoctorData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Doctor not found');
      }
      
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load doctor data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _doctorData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final doctor = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      // Avatar widget
                      doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(doctor['avatar']),
                            )
                          : CircleAvatar(
                              radius: 50,
                             backgroundColor: Colors.blue[100],
                              child: Text(
                                doctor['fullName']?.isNotEmpty == true 
                                    ? doctor['fullName'][0].toUpperCase()
                                    : 'D',
                                style:  TextStyle(
                                  fontSize: 30,
                                   color: Colors.blue[900],
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Text(
                        doctor['fullName'] ?? 'No name',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        doctor['phone'] ?? 'No phone number',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                           
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Icons in a single row
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconButton(Icons.message, 'Message', () {
                      Navigator.pop(context); // Return to chat screen
                    }),
                    _buildIconButton(Icons.call, 'Call', () {}),
                    _buildIconButton(Icons.videocam, 'Video Call', () {}),
                  ],
                ),
                
                const SizedBox(height: 24),
               const Text(
               'Doctor Information',
                style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64B5F6),
                 ),
                ),
                const SizedBox(height: 8), 
                _buildInfoRow('Specialty:', doctor['specialties'] ?? 'General'),//ake fontsize
                _buildInfoRow('Experience:', '${doctor['experience'] ?? 0} years'),
                _buildInfoRow('Email:', doctor['email'] ?? 'No email'),
                _buildInfoRow('Address:', doctor['address'] ?? 'No address'),
                
                const SizedBox(height: 24),
                const Divider(),
                
                const SizedBox(height: 24),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildSettingOption(
                  title: 'Notifications',
                  hasSwitch: true,
                  value: true,
                ),
                _buildSettingOption(
                  title: 'Media visibility Off',
                  hasCheckbox: true,
                  value: false,
                ),
                _buildSettingOption(
                  title: 'Kept messages',
                  hasCheckbox: true,
                  value: false,
                ),
                _buildSettingOption(
                  title: 'Encryption',
                  subtitle: 'Messages and calls are end-to-end encrypted. Tap to verify.',
                  hasCheckbox: true,
                  value: false,
                ),
                _buildSettingOption(
                  title: 'Disappearing messages',
                  subtitle: '24 hours',
                  hasCheckbox: true,
                  value: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: Colors.blue[900],
          iconSize: 30,
          onPressed: onPressed,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                 fontSize: 17,
                fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption({
    required String title,
    String? subtitle,
    bool hasSwitch = false,
    bool hasCheckbox = false,
    bool value = false,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: hasSwitch
          ? Switch(
              value: value,
              onChanged: (newValue) {
                // Handle switch change
              },
            )
          : hasCheckbox
              ? Checkbox(
                  value: value,
                  onChanged: (newValue) {
                    // Handle checkbox change
                  },
                )
              : null,
      onTap: () {},
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class DoctorProfileScreen extends StatefulWidget {
//   final String doctorId;

//   const DoctorProfileScreen({Key? key, required this.doctorId}) : super(key: key);

//   @override
//   _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
// }

// class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
//   late Future<Map<String, dynamic>> _doctorData;

//   @override
//   void initState() {
//     super.initState();
//     _doctorData = _fetchDoctorData();
//   }

//   Future<Map<String, dynamic>> _fetchDoctorData() async {
//     try {
//       DocumentSnapshot doc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .get();
      
//       if (!doc.exists) {
//         throw Exception('Doctor not found');
//       }
      
//       return doc.data() as Map<String, dynamic>;
//     } catch (e) {
//       throw Exception('Failed to load doctor data: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _doctorData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
          
//           final doctor = snapshot.data!;
          
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Column(
//                     children: [
//                       // Avatar widget
//                       Widget avatarWidget;
//                       if (doctor['avatar'] != null && doctor['avatar'].toString().isNotEmpty) {
//                         avatarWidget = CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(doctor['avatar']),
//                         );
//                       } else {
//                         final String initials = doctor['fullName']?.isNotEmpty == true 
//                             ? doctor['fullName'][0].toUpperCase()
//                             : 'D';
//                       const SizedBox(height: 16),
//                       Text(
//                         doctor['fullName'] ?? 'No name',
//                         style: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         doctor['phone'] ?? 'No phone number',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Icons in a single row
//                 const SizedBox(height: 24),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildIconButton(Icons.message, 'Message', () {
//                       Navigator.pop(context); // Return to chat screen
//                     }),
//                     _buildIconButton(Icons.call, 'Call', () {}),
//                     _buildIconButton(Icons.videocam, 'Video Call', () {}),
//                   ],
//                 ),
                
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Professional Information',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildInfoRow('Specialty:', doctor['specialties'] ?? 'General'),
//                 _buildInfoRow('Experience:', '${doctor['experience'] ?? 0} years'),
//                 _buildInfoRow('Email:', doctor['email'] ?? 'No email'),
//                 _buildInfoRow('Address:', doctor['address'] ?? 'No address'),
                
//                 const SizedBox(height: 24),
//                 const Divider(),
                
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Settings',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 _buildSettingOption(
//                   title: 'Notifications',
//                   hasSwitch: true,
//                   value: true,
//                 ),
//                 _buildSettingOption(
//                   title: 'Media visibility Off',
//                   hasCheckbox: true,
//                   isChecked: false,
//                 ),
//                 _buildSettingOption(
//                   title: 'Kept messages',
//                   hasCheckbox: true,
//                   isChecked: false,
//                 ),
//                 _buildSettingOption(
//                   title: 'Encryption',
//                   subtitle: 'Messages and calls are end-to-end encrypted. Tap to verify.',
//                   hasCheckbox: true,
//                   isChecked: false,
//                 ),
//                 _buildSettingOption(
//                   title: 'Disappearing messages',
//                   subtitle: '24 hours',
//                   hasCheckbox: true,
//                   isChecked: true,
//                 ),
//               ],

//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
//     return Column(
//       children: [
//         IconButton(
//           icon: Icon(icon),
//           color: Colors.blue[900],
//           iconSize: 30,
//           onPressed: onPressed,
//         ),
//         Text(label),
//       ],
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSettingOption({
//     required String title,
//     bool hasSwitch = false,
//     bool value = false,
//   }) {
//     return ListTile(
//       title: Text(title),
//       trailing: hasSwitch
//           ? Switch(
//               value: value,
//               onChanged: (newValue) {
//                 // Handle switch change
//               },
//             )
//           : null,
//       onTap: () {},
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class DoctorProfileScreen extends StatefulWidget {
//   final String doctorId;

//   const DoctorProfileScreen({Key? key, required this.doctorId}) : super(key: key);

//   @override
//   _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
// }

// class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
//   late Future<Map<String, dynamic>> _doctorData;

//   @override
//   void initState() {
//     super.initState();
//     _doctorData = _fetchDoctorData();
//   }

//   Future<Map<String, dynamic>> _fetchDoctorData() async {
//     try {
//       DocumentSnapshot doc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .get();
      
//       if (!doc.exists) {
//         throw Exception('Doctor not found');
//       }
      
//       return doc.data() as Map<String, dynamic>;
//     } catch (e) {
//       throw Exception('Failed to load doctor data: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _doctorData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
          
//           final doctor = snapshot.data!;
          
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Column(
//                     children: [
//                       CircleAvatar(
//                         radius: 50,
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.person, size: 50, color: Colors.grey),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         doctor['fullName'] ?? 'No name',
//                         style: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         doctor['phone'] ?? 'No phone number',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Professional Information',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildInfoRow('Specialty:', doctor['specialties'] ?? 'General'),
//                 _buildInfoRow('Experience:', '${doctor['experience'] ?? 0} years'),
//                 _buildInfoRow('Email:', doctor['email'] ?? 'No email'),
//                 _buildInfoRow('Address:', doctor['address'] ?? 'No address'),
                
//                 const SizedBox(height: 24),
//                 const Divider(),
//                 _buildActionButton(Icons.message, 'Send Message', onTap: () {
//                   Navigator.pop(context); // Return to chat screen
//                 }),
//                 _buildActionButton(Icons.call, 'Voice Call'),
//                 _buildActionButton(Icons.videocam, 'Video Call'),
                
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Settings',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 _buildSettingOption(
//                   title: 'Notifications',
//                   hasSwitch: true,
//                   value: true,
//                 ),
//                 _buildSettingOption(
//                   title: 'Message Notifications',
//                   hasSwitch: true,
//                   value: true,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton(IconData icon, String text, {VoidCallback? onTap}) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.blue),
//       title: Text(text),
//       onTap: onTap ?? () {},
//     );
//   }

//   Widget _buildSettingOption({
//     required String title,
//     bool hasSwitch = false,
//     bool value = false,
//   }) {
//     return ListTile(
//       title: Text(title),
//       trailing: hasSwitch
//           ? Switch(
//               value: value,
//               onChanged: (newValue) {
//                 // Handle switch change
//               },
//             )
//           : null,
//       onTap: () {},
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class DoctorProfileScreen extends StatefulWidget {
//   final String doctorId;

//   const DoctorProfileScreen({Key? key, required this.doctorId}) : super(key: key);

//   @override
//   _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
// }

// class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
//   late Future<Map<String, dynamic>> _doctorData;

//   @override
//   void initState() {
//     super.initState();
//     _doctorData = _fetchDoctorData();
//   }

//   Future<Map<String, dynamic>> _fetchDoctorData() async {
//     DocumentSnapshot doc = await FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(widget.doctorId)
//         .get();
    
//     if (!doc.exists) {
//       throw Exception('Doctor not found');
//     }
    
//     return doc.data() as Map<String, dynamic>;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctor Profile'),
//       ),
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _doctorData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
          
//           final doctor = snapshot.data!;
          
//           return SingleChildScrollView(
//             child: Column(
//               children: [
//                 const SizedBox(height: 20),
//                 // Profile picture placeholder
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.grey[300],
//                   child: const Icon(Icons.person, size: 50, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 16),
//                 // Doctor name
//                 Text(
//                   doctor['fullName'] ?? 'No name',
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 // Phone number
//                 Text(
//                   doctor['phone'] ?? 'No phone',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 // Last seen
//                 const Text(
//                   'Last seen today at 13:42',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Divider(height: 1),
//                 // Action buttons
//                 _buildActionButton(Icons.mic, 'Audio'),
//                 const Divider(height: 1),
//                 _buildActionButton(Icons.videocam, 'Video'),
//                 const Divider(height: 1),
//                 const SizedBox(height: 20),
//                 // Default message
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Text(
//                     'Hey there! I am using WhatsApp.',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                  Text(
//                   doctor['address'] ?? 'No address',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 Text(
//                   doctor['email'] ?? 'No email',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                  Text(
//                 'Specialty: ${doctor['specialties'] ?? 'General'}',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                  Text(
//               '${doctor['experience'] ?? 0} years experience',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 // Settings options
//                 _buildSettingOption(
//                   title: 'Notifications',
//                   hasCheckbox: true,
//                   isChecked: false,
//                 ),
//                 _buildSettingOption(
//                   title: 'Media visibility Off',
//                   hasCheckbox: true,
//                   isChecked: false,
//                 ),
//                 _buildSettingOption(
//                   title: 'Kept messages',
//                   hasCheckbox: true,
//                   isChecked: false,
//                 ),
//                 _buildSettingOption(
//                   title: 'Encryption',
//                   subtitle: 'Messages and calls are end-to-end encrypted. Tap to verify.',
//                   hasCheckbox: true,
//                   isChecked: false,
//                 ),
//                 _buildSettingOption(
//                   title: 'Disappearing messages',
//                   subtitle: '24 hours',
//                   hasCheckbox: true,
//                   isChecked: true,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildActionButton(IconData icon, String text) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.teal),
//       title: Text(text),
//       onTap: () {
//         // Handle button tap
//       },
//     );
//   }

//   Widget _buildSettingOption({
//     required String title,
//     String? subtitle,
//     required bool hasCheckbox,
//     required bool isChecked,
//   }) {
//     return ListTile(
//       title: Text(title),
//       subtitle: subtitle != null ? Text(subtitle) : null,
//       trailing: hasCheckbox
//           ? Checkbox(
//               value: isChecked,
//               onChanged: (value) {
//                 // Handle checkbox change
//               },
//             )
//           : null,
//       onTap: () {
//         // Handle option tap
//       },
//     );
//   }
// }