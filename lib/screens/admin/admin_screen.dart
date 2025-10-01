import 'package:flutter/material.dart';
import 'patient_screen.dart';
import 'doctor_screen.dart';
import 'schedule_screen.dart';
import 'report_screen.dart';


class AdminScreen extends StatelessWidget {
  const AdminScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          children: [
            _buildGridButton(
              context,
              icon: Icons.people,
              title: 'Patient Management',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientScreen()),
                );
              },
            ),
            _buildGridButton(
              context,
              icon: Icons.medical_services,
              title: 'Doctor Management',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorScreen()),
                );
              },
            ),
             _buildGridButton(
              context,
              icon: Icons.schedule,
              title: 'Schedule ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScheduleScreen()),
                );
              },
            ),
            _buildGridButton(
              context,
              icon: Icons.report,
              title: 'Report ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue[900]),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
















// import 'package:flutter/material.dart';

// class AdminScreen extends StatelessWidget {
//   final List<Map<String, String>> users = [
//     {'name': 'Fatima Yusuf', 'email': 'fatima@example.com'},
//     {'name': 'Amina Ali', 'email': 'amina@example.com'},
//     {'name': 'Layla Hassan', 'email': 'layla@example.com'},
//   ];

//   final List<Map<String, String>> appointments = [
//     {'user': 'Fatima Yusuf', 'time': '2025-05-20 10:00 AM'},
//     {'user': 'Amina Ali', 'time': '2025-05-21 02:00 PM'},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('Admin Panel'),
//           bottom: TabBar(
//             tabs: [
//               Tab(text: 'Users'),
//               Tab(text: 'Appointments'),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             // Users Tab
//             ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: users.length,
//               itemBuilder: (context, index) {
//                 return Card(
//                   child: ListTile(
//                     leading: Icon(Icons.person),
//                     title: Text(users[index]['name']!),
//                     subtitle: Text(users[index]['email']!),
//                     trailing: Icon(Icons.more_vert),
//                   ),
//                 );
//               },
//             ),
//             // Appointments Tab
//             ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: appointments.length,
//               itemBuilder: (context, index) {
//                 return Card(
//                   child: ListTile(
//                     leading: Icon(Icons.schedule),
//                     title: Text(appointments[index]['user']!),
//                     subtitle: Text('Appointment: ${appointments[index]['time']}'),
//                     trailing: Icon(Icons.check_circle_outline),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
