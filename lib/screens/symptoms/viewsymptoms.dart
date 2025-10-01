import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ViewSymptoms extends StatelessWidget {
  const ViewSymptoms({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: currentUserId == null
          ? const Center(child: Text('Please sign in to view your symptoms'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('symptoms')
                  .where('userId', isEqualTo: currentUserId)
                  .where('status', isEqualTo: 'treated')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data?.docs.isEmpty ?? true) {
                  return const Center(child: Text('No treated symptoms found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [ 
                            // Selected Symptoms
                            if (data['selectedSymptoms'] != null && 
                                (data['selectedSymptoms'] as List).isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selected Symptoms:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  ...(data['selectedSymptoms'] as List).map(
                                    (symptom) => Text('- $symptom'),
                                  ).toList(),
                                ],
                              ),
                            
                            // Custom Symptoms
                            if (data['customSymptoms'] != null && 
                                data['customSymptoms'].toString().isNotEmpty)
                            
                            const Divider(height: 24),

                            Text(
                                   'Symptoms: ${data['customSymptoms'] ?? 'No Symptoms'}',
                                  style: const TextStyle(fontSize: 16),
                                  ),
                                 const SizedBox(height: 8),
                            
                            // Treatment Information
                            Text(
                              'Treatment: ${data['treatment'] ?? 'No treatment provided'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            
                            // Doctor Information
                            Text(
                              'Doctor: ${data['doctorName'] ?? 'Unknown doctor'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Updated: ${_formatTimestamp(data['updatedAt'])}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    try {
      final date = timestamp is Timestamp 
          ? timestamp.toDate() 
          : DateTime.parse(timestamp.toString());
      return DateFormat('MMM d, y hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ViewSymptoms extends StatelessWidget {
//   const ViewSymptoms({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;

//     return Scaffold(
//       body: currentUserId == null
//           ? const Center(child: Text('Please sign in to view your symptoms'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('symptoms')
//                   .where('userId', isEqualTo: currentUserId)
//                   .where('status', isEqualTo: 'treated')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return const Center(child: Text('Something went wrong'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.data?.docs.isEmpty ?? true) {
//                   return const Center(child: Text('No treated symptoms found'));
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data?.docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = snapshot.data!.docs[index];
//                     final data = doc.data() as Map<String, dynamic>;

//                     return Card(
//                       margin: const EdgeInsets.all(8.0),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             if (data['xanuun'] != null && data['xanuun'].toString().isNotEmpty)
//                               Text(
//                                 'Xanuun: ${data['xanuun']}',
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                             if (data['symptoms'] != null && data['symptoms'].toString().isNotEmpty)
//                               Text(
//                                 'Symptoms: ${data['symptoms']}',
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Treatment: ${data['treatment'] ?? 'No treatment provided'}',
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Doctor: ${data['doctorName'] ?? 'Not Assigned'}',
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Treated on: ${_formatTimestamp(data['treatedAt'])}',
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'Unknown date';
//     if (timestamp is Timestamp) {
//       return timestamp.toDate().toString();
//     }
//     return timestamp.toString();
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ViewSymptoms extends StatelessWidget {
//   const ViewSymptoms({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;

//     return Scaffold(
//       body: currentUserId == null
//           ? const Center(child: Text('Please sign in to view your symptoms'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('symptoms')
//                   .where('userId', isEqualTo: currentUserId)
//                   .where('status', isEqualTo: 'treated')
//                 //   .orderBy('treatedAt', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return const Center(child: Text('Something went wrong'));
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.data?.docs.isEmpty ?? true) {
//                   return const Center(child: Text('No treated symptoms found'));
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data?.docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = snapshot.data!.docs[index];
//                     final data = doc.data() as Map<String, dynamic>;

//                     return Card(
//                       margin: const EdgeInsets.all(8.0),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Symptoms: ${data['symptoms']}',
//                               style: const TextStyle(fontSize: 16),
//                                 final isUpdating = _isUpdating[docId] ?? false;
//     final hasSelectedSymptom = data['xanuun'] != null && data['xanuun'].toString().isNotEmpty;
//     final hasCustomSymptoms = data['symptoms'] != null && data['symptoms'].toString().isNotEmpty;
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Treatment: ${data['treatment']}',
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                             const SizedBox(height: 8),
//                             // Text(
//                             //   'Doctor: ${data['doctorName']}',
//                             //   style: const TextStyle(fontSize: 16),
//                             // ),
//                              Text(
//           'Doctor: ${data['doctorName'] ?? 'Not Assigned'}', // Fix here
//           style: const TextStyle(fontSize: 16),
//         ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Treated on: ${_formatTimestamp(data['treatedAt'])}',
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return 'Unknown date';
//     if (timestamp is Timestamp) {
//       return timestamp.toDate().toString();
//     }
//     return timestamp.toString();
//   }
// }




















// import 'package:flutter/material.dart';

// class ViewSymptoms extends StatelessWidget {
//     const ViewSymptoms({Key? key}) : super(key: key);

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold(
//             appBar: AppBar(
//                 title: const Text('View Symptoms'),
//             ),
//             body: const Center(
//                 child: Text('No symptoms to display.'),
//             ),
//         );
//     }
// }