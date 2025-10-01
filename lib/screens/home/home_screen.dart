import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../register/signin_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_screen.dart';
// import '../chat/pchat_screen.dart';
import '../tracker/tracker_screen.dart';
import '../tracker/track1.dart';
import '../articles/article_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/Doctorlist_screen.dart';
import '../myappoi/myappointment_screen.dart';
import '../cunto/mealplan_screen.dart';
import '../symptoms/symptoms.dart';
import '../symptoms/viewsymptoms.dart';
// import '../language/language.dart';
import '../contact/contact.dart';
import 'dart:async'; 


class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  int _currentBottomNavIndex = 0;
  String _searchQuery = '';

  void _onBottomNavTap(BuildContext context, int index)async {
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorlistScreen()),
        );
        break;
   case 2:
        await _checkBeforeChatting(context);
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen()),
        );
        break;
    }
  }
Future<bool> _hasExistingTracking() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final querySnapshot = await _firestore
        .collection('trackingweeks')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();
        
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _checkUserTrackingStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _goToPregnancyTrackerScreen();
        return;
      }

      final trackingExists = await _hasExistingTracking();
      if (!trackingExists) {
        _goToPregnancyTrackerScreen();
        return;
      }

      final querySnapshot = await _firestore
          .collection('trackingweeks')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final currentWeek = data['currentWeek'] as int;
        final lastPeriodDate = data['lastPeriodDate']?.toDate(); // Get the date from Firestore
        
        if (lastPeriodDate != null) {
          _goToTrackerDetailScreen(currentWeek, lastPeriodDate);
        } else {
          _goToPregnancyTrackerScreen();
        }
      } else {
        _goToPregnancyTrackerScreen();
      }
    } catch (e) {
      print('Error checking tracking status: $e');
      _goToPregnancyTrackerScreen();
    }
  }

  void _goToPregnancyTrackerScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PregnancyTrackerScreen(),
      ),
    );
  }

  void _goToTrackerDetailScreen(int pregnancyWeek, DateTime lastPeriodDate) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TrackerDetailScreen(
          pregnancyWeek: pregnancyWeek,
          lastPeriodDate: lastPeriodDate,
        ),
      ),
    );
  }
Future<bool> _hasExistingAppointment() async {
  final user = _auth.currentUser;
  if (user == null) return false;

  final querySnapshot = await _firestore
      .collection('appointments')
      .where('userId', isEqualTo: user.uid)
      .get();

  return querySnapshot.docs.isNotEmpty;
}

Future<void> _checkBeforeSymptoms() async {
  try {
    final hasAppointment = await _hasExistingAppointment();

    if (hasAppointment) {
      _goToSymptomsScreen();
    } else {
      _showMakeAppointmentAlert();
    }
  } catch (e) {
    print('Error checking appointment: $e');
    _showMakeAppointmentAlert();
  }
}

void _goToSymptomsScreen() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const Symptoms(),
    ),
  );
}

void _showMakeAppointmentAlert() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('No Appointment Found'),
      content: const Text('Fadlan marka hore samee balan ka hor intaadan calaamado ku darin.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorlistScreen(),
              ),
            );
          },
          child: const Text('Samee Balan'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

  //////////////
//////
Future<bool> _hasExistingAppointments() async {
  try {
    final user = _auth.currentUser;
    if (user == null) return false;

    final querySnapshot = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        // .where('status', isEqualTo: 'active') // Consider adding status check
        .limit(1) // More efficient since we only need to know if any exist
        .get();

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    print('Error checking appointments: $e');
    return false; // Default to false on error
  }
}

Future<void> _checkBeforeChatting(BuildContext context) async {
  final hasAppointment = await _hasExistingAppointments();

  if (hasAppointment) {
    _goToChattingScreen(context);
  } else {
    _showMakeAppointmentsAlert(context);
  }
}

void _goToChattingScreen(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const ChatListScreen(),
    ),
  );
}

void _showMakeAppointmentsAlert(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('No Appointment Found'),
      content: const Text('Fadlan marka hore samee balan ka hor intaadan bilaabin chatting-ka dhakhtarka.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorlistScreen(),
              ),
            );
          },
          child: const Text('Samee Balan'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}


///////
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
         
      title: const Text('Pregnancy ', style: TextStyle(color: Colors.black)),
      iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        // elevation: 1,
      ),
      drawer: Drawer(
         backgroundColor: Colors.white, 
        width: 250,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 100,
               alignment: Alignment.center,
              width: double.infinity,
              color: Colors.blue[900],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue[900]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Pregnancy Woman",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          

ListTile(
  leading: const Icon(Icons.pregnant_woman),
  title: const Text("Pregnancy Tracker"),
  onTap: _checkUserTrackingStatus, // No need for context parameter
),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.fastfood),
              title: const Text(" FoodPlan"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HealthyMealScreen()),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text("Articles & Tips"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ArticleScreen()),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Myappointments"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Myappointment()),
              ),
            ),

            const SizedBox(height: 10),
            ListTile(
  leading: const Icon(Icons.sick),
  title: const Text("Symptoms"),
  onTap: () async {
     await _checkBeforeSymptoms();
  },
),
            const SizedBox(height: 10),
             ListTile(
              leading: const Icon(Icons.healing),
              title: const Text("View Symptoms"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ViewSymptoms()),
              ),
            ),
             const SizedBox(height: 30),
            const Divider(
              height: 20,      
              thickness: 2,     
              indent: 16,       
              endIndent: 16,    
              color: Colors.grey,
              ),
              ListTile(
              leading: const Icon(Icons.support_agent), 
              title: const Text("Contact Us"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ContactScreen()),
                );
              },
            ),
             const SizedBox(height: 10),
            //  ListTile(
            //  leading: const Icon(Icons.language),
            //  title: const Text("Language"),
            //   onTap: () {
            //     Navigator.pushReplacement(
            //       context,
            //       MaterialPageRoute(builder: (_) => LanguageScreen()),
            //     );
            //   },
            // ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SigninScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("Dark Mode"),
              secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
              value: widget.isDarkMode,
              onChanged: (_) => widget.onToggleTheme(),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for doctors...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    GestureDetector(
      onTap: () async {
            await _checkBeforeChatting(context);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => ChatListScreen()),
        // );
      },
      child: const _CategoryIcon(icon: Icons.chat, label: 'Chatting'),
    ),
   
    GestureDetector(
      onTap: ()  {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorlistScreen()),
        );
      },
      child: const _CategoryIcon(icon: Icons.book, label: 'Booking'),
    ),
    GestureDetector(
      onTap: () async{
        await _checkBeforeSymptoms();
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => Symptoms()),
        // );
      },
      child: const _CategoryIcon(icon: Icons.sick, label: 'Symptoms'),
    ),
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ContactScreen()),
        );
      },
      child: const _CategoryIcon(icon: Icons.support_agent, label: 'Contact'),
    ),
  ],
),
            const SizedBox(height: 20),
            
            // Featured Doctor Card
            _buildFeaturedDoctorCard(),
            const SizedBox(height: 20),
            
            // Top Doctors Section
            const Text("Top Doctors",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _buildDoctorsList(),
            
            // Health Articles Section
            const SizedBox(height: 20),
            const Text("Health Articles",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.blue),
              title: const Text("How to protect your pregnancy"),
              subtitle: const Text("Read now"),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArticleScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.blue),
              title: const Text("Pregnancy nutrition guide"),
              subtitle: const Text("Read now"),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArticleScreen()),
                );
              },
            ),
          ],
        ),
      ),
       
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
          _onBottomNavTap(context, index);
        },
         type: BottomNavigationBarType.fixed,
         backgroundColor: Colors.white, 
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Appointment",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
          ),
          BottomNavigationBarItem(
           icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDoctorCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.teal.shade100,
      borderRadius: BorderRadius.circular(16),
    ),
    child: StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('appointments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingFeaturedDoctor();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildDefaultFeaturedDoctor();
        }

        // 1. Tirinta balamaha dhaqtarka kasta
        final Map<String, int> doctorCounts = {};
        for (var doc in snapshot.data!.docs) {
          final doctorId = doc['doctorId'];
          doctorCounts[doctorId] = (doctorCounts[doctorId] ?? 0) + 1;
        }

        // 2. Hel doctorId-ga leh balanta ugu badan
        final topDoctorId = doctorCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        // 3. Soo qaado macluumaadka dhaqtarka kaliya
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('doctors').doc(topDoctorId).get(),
          builder: (context, doctorSnapshot) {
            if (doctorSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingFeaturedDoctor();
            }

            if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
              return _buildDefaultFeaturedDoctor();
            }

            final doctorData =
                doctorSnapshot.data!.data() as Map<String, dynamic>;
            final doctorName = doctorData['fullName'] ?? 'Doctor';
            final specialties = doctorData['specialties'] ?? 'Specialist';
            final firstLetter =
                doctorName.isNotEmpty ? doctorName[0] : 'D';

            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Featured Doctor",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Dr. $doctorName",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(specialties,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Text(firstLetter,
                      style:
                          TextStyle(fontSize: 24, color: Colors.blue[900])),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}


  Widget _buildLoadingFeaturedDoctor() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Featured Doctor", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Loading...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey,
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDefaultFeaturedDoctor() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Featured Doctor", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("No featured doctor available",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

Widget _buildDoctorsList() {
  return SizedBox(
    height: 110,
    child: StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('appointments').snapshots(),
      builder: (context, appointmentSnapshot) {
        if (appointmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!appointmentSnapshot.hasData || appointmentSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No appointments found",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Tirinta balamaha doctor kasta
        final Map<String, int> doctorCounts = {};
        for (var doc in appointmentSnapshot.data!.docs) {
          final doctorId = doc['doctorId'] as String;
          doctorCounts[doctorId] = (doctorCounts[doctorId] ?? 0) + 1;
        }

        // Kala sooc 4-ta doctor ee leh balamaha ugu badan
        final topDoctors = doctorCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final top4Doctors = topDoctors.take(5).toList();

        if (top4Doctors.isEmpty) {
          return const Center(
            child: Text(
              "No doctors with appointments found",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Hadda ka soo qaado macluumaadka doctors-ka top4-ka
        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(
            top4Doctors.map((e) => _firestore.collection('doctors').doc(e.key).get()),
          ),
          builder: (context, doctorSnapshot) {
            if (doctorSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!doctorSnapshot.hasData || doctorSnapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No doctors data found",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final doctors = doctorSnapshot.data!;

            // Haddii aad rabto search filter, ka samee halkan (optional)

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctorDoc = doctors[index];
                if (!doctorDoc.exists) {
                  return const SizedBox();
                }
                final doctorData = doctorDoc.data() as Map<String, dynamic>;
                final fullName = doctorData['fullName'] ?? 'Doctor';
                final specialties = doctorData['specialties'] ?? 'Specialist';
                final firstLetter = fullName.isNotEmpty ? fullName[0] : 'D';

                return _DoctorCard(
                  fullName: fullName,
                  specialties: specialties,
                  child: Text(
                    firstLetter,
                    style: TextStyle(fontSize: 24, color: Colors.blue[900]),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          doctorName: fullName,
                          doctorId: doctorDoc.id,
                        ),
                      ),
                    );
          //           Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => DoctorProfileScreen(
          //       doctorId: widget.doctorId,
          //     ),
          //   ),
          // );
                  },
                );
              },
            );
          },
        );
      },
    ),
  );
}

}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final String fullName;
  final String specialties;
  final Widget child;
  final VoidCallback onTap;

  const _DoctorCard({
    required this.fullName,
    required this.specialties,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[100],
              child: child,
            ),
            const SizedBox(height: 6),
            Text(fullName, 
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            Text(specialties,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}
































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/Doctorlist_screen.dart';
// import '../myappoi/myappointment_screen.dart';
// import '../cunto/mealplan_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _searchController = TextEditingController();

//   bool _isLoading = false;
//   int _currentBottomNavIndex = 0;
//   String _searchQuery = '';

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationScreen()),
//               );
//             },
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         width: 250,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfileScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.pregnant_woman),
//               title: const Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => PregnancyTrackerScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.apple),
//               title: const Text("MealPlan"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => HealthyMealApp()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ArticleScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.book),
//               title: const Text("Myappointments"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => Myappointment()),
//               ),
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => SigninScreen()),
//                 );
//               },
//             ),
//             SwitchListTile(
//               title: const Text("Dark Mode"),
//               secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: widget.isDarkMode,
//               onChanged: (_) => widget.onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Search Field
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Search for doctors...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             // Categories Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Featured Doctor Card
//             _buildFeaturedDoctorCard(),
//             const SizedBox(height: 20),
            
//             // Top Doctors Section
//             const Text("Top Doctors",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 12),
//             _buildDoctorsList(),
            
//             // ... rest of the existing code ...
//           ],
//         ),
//       ),
//       // ... bottomNavigationBar ...
//     );
//   }

//   Widget _buildFeaturedDoctorCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.teal.shade100,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('appointments')
//           .orderBy('createdAt', descending: true)
//           .limit(1)
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return _buildLoadingFeaturedDoctor();
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return _buildDefaultFeaturedDoctor();
//           }
          
//           final appointment = snapshot.data!.docs.first;
//           final doctorId = appointment['doctorId'];
          
//           return FutureBuilder<DocumentSnapshot>(
//             future: _firestore.collection('doctors').doc(doctorId).get(),
//             builder: (context, doctorSnapshot) {
//               if (doctorSnapshot.connectionState == ConnectionState.waiting) {
//                 return _buildLoadingFeaturedDoctor();
//               }
              
//               if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
//                 return _buildDefaultFeaturedDoctor();
//               }
              
//               final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
//               final doctorName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = doctorName.isNotEmpty ? doctorName[0] : 'D';
              
//               return Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text("Featured Doctor", 
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 8),
//                         Text("Dr. $doctorName",
//                             style: const TextStyle(fontWeight: FontWeight.bold)),
//                         Text(specialties,
//                             style: const TextStyle(color: Colors.grey)),
//                       ],
//                     ),
//                   ),
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.blue[100],
//                     child: Text(firstLetter, 
//                         style: TextStyle(fontSize: 24, color: Colors.blue[900])),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLoadingFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("Loading...", style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildDefaultFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("No featured doctor available",
//                   style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: Icon(Icons.person, color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildDoctorsList() {
//     return SizedBox(
//       height: 110,
//       child: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text("No doctors available", 
//                   style: TextStyle(color: Colors.grey)),
//             );
//           }
          
//           List<QueryDocumentSnapshot> doctors = snapshot.data!.docs;
          
//           // Apply search filter if query exists
//           if (_searchQuery.isNotEmpty) {
//             doctors = doctors.where((doc) {
//               final data = doc.data() as Map<String, dynamic>;
//               final name = data['fullName']?.toString().toLowerCase() ?? '';
//               final specialty = data['specialties']?.toString().toLowerCase() ?? '';
//               return name.contains(_searchQuery) || specialty.contains(_searchQuery);
//             }).toList();
//           }
          
//           // Sort by number of appointments (descending)
//           doctors.sort((a, b) {
//             final aAppointments = (a.data() as Map<String, dynamic>)['appointments'] ?? 0;
//             final bAppointments = (b.data() as Map<String, dynamic>)['appointments'] ?? 0;
//             return bAppointments.compareTo(aAppointments);
//           });
          
//           // Limit to top 4 doctors
//           if (doctors.length > 4) {
//             doctors = doctors.sublist(0, 4);
//           }
          
//           if (doctors.isEmpty) {
//             return const Center(
//               child: Text("No matching doctors found", 
//                   style: TextStyle(color: Colors.grey)),
//             );
//           }
          
//           return ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               final doctorData = doctor.data() as Map<String, dynamic>;
//               final fullName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = fullName.isNotEmpty ? fullName[0] : 'D';
              
//               return _DoctorCard(
//                 fullName: fullName,
//                 specialties: specialties,
//                 child: Text(
//                   firstLetter,
//                   style:  TextStyle(fontSize: 24, color: Colors.blue[900]),
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => ChatListScreen()),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//     const SizedBox(height: 20),
//             const Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 10),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("How to protect your heart health"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("Pregnancy nutrition guide"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentBottomNavIndex,
//         onTap: (index) {
//           setState(() {
//             _currentBottomNavIndex = index;
//           });
//           _onBottomNavTap(context, index);
//         },
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Appointment",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }
// }
//   }
// }
// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String fullName;
//   final String specialties;
//   final Widget child;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.fullName,
//     required this.specialties,
//     required this.child,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue[100],
//               child: child,
//             ),
//             const SizedBox(height: 6),
//             Text(fullName, 
//                 style: const TextStyle(fontSize: 14),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1),
//             Text(specialties,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1),
//           ],
//         ),
//       ),
//     );
//   }
// }









































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/Doctorlist_screen.dart';
// import '../myappoi/myappointment_screen.dart';
// import '../cunto/mealplan_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _searchController = TextEditingController();

//   bool _isLoading = false;
//   int _currentBottomNavIndex = 0;
//   String _searchQuery = '';

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationScreen()),
//               );
//             },
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         width: 250,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfileScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.pregnant_woman),
//               title: const Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => PregnancyTrackerScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.apple),
//               title: const Text("MealPlan"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => HealthyMealApp()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ArticleScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.book),
//               title: const Text("Myappointments"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => Myappointment()),
//               ),
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => SigninScreen()),
//                 );
//               },
//             ),
//             SwitchListTile(
//               title: const Text("Dark Mode"),
//               secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: widget.isDarkMode,
//               onChanged: (_) => widget.onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Search Field
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Search for doctors...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             // Categories Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Featured Doctor Card
//             _buildFeaturedDoctorCard(),
//             const SizedBox(height: 20),
            
//             // Top Doctors Section
//             const Text("Top Doctors",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 12),
//             _buildTopDoctorsList(),
            
//             const SizedBox(height: 20),
//             const Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 10),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("How to protect your heart health"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("Pregnancy nutrition guide"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentBottomNavIndex,
//         onTap: (index) {
//           setState(() {
//             _currentBottomNavIndex = index;
//           });
//           _onBottomNavTap(context, index);
//         },
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Appointment",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeaturedDoctorCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.teal.shade100,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('appointments')
//           .orderBy('createdAt', descending: true)
//           .limit(1)
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return _buildLoadingFeaturedDoctor();
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return _buildDefaultFeaturedDoctor();
//           }
          
//           final appointment = snapshot.data!.docs.first;
//           final doctorId = appointment['doctorId'];
          
//           return FutureBuilder<DocumentSnapshot>(
//             future: _firestore.collection('doctors').doc(doctorId).get(),
//             builder: (context, doctorSnapshot) {
//               if (doctorSnapshot.connectionState == ConnectionState.waiting) {
//                 return _buildLoadingFeaturedDoctor();
//               }
              
//               if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
//                 return _buildDefaultFeaturedDoctor();
//               }
              
//               final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
//               final doctorName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = doctorName.isNotEmpty ? doctorName[0] : 'D';
              
//               return Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text("Featured Doctor", 
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 8),
//                         Text("Dr. $doctorName",
//                             style: const TextStyle(fontWeight: FontWeight.bold)),
//                         Text(specialties,
//                             style: const TextStyle(color: Colors.grey)),
//                       ],
//                     ),
//                   ),
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.blue[100],
//                     child: Text(firstLetter, 
//                         style: TextStyle(fontSize: 24, color: Colors.blue[900])),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLoadingFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("Loading...", style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildDefaultFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("No featured doctor available",
//                   style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: Icon(Icons.person, color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildTopDoctorsList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore.collection('doctors')
//         .orderBy('appointments', descending: true)
//         .limit(4)
//         .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SizedBox(
//             height: 110,
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (snapshot.hasError) {
//           return SizedBox(
//             height: 110,
//             child: Center(
//               child: Text(
//                 "Error loading doctors",
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return SizedBox(
//             height: 110,
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.people_outline, size: 40, color: Colors.grey),
//                   SizedBox(height: 8),
//                   Text(
//                     "No doctors available",
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                   SizedBox(height: 8),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//                       );
//                     },
//                     child: Text("Check back later"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[900],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         List<QueryDocumentSnapshot> doctors = snapshot.data!.docs;

//         // Apply search filter if query exists
//         if (_searchQuery.isNotEmpty) {
//           doctors = doctors.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             final name = data['fullName']?.toString().toLowerCase() ?? '';
//             final specialty = data['specialties']?.toString().toLowerCase() ?? '';
//             return name.contains(_searchQuery) || specialty.contains(_searchQuery);
//           }).toList();

//           if (doctors.isEmpty) {
//             return SizedBox(
//               height: 110,
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.search_off, size: 40, color: Colors.grey),
//                     SizedBox(height: 8),
//                     Text(
//                       "No matching doctors found",
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _searchController.clear();
//                           _searchQuery = '';
//                         });
//                       },
//                       child: Text("Clear search"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue[900],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }
//         }

//         return SizedBox(
//           height: 110,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               final doctorData = doctor.data() as Map<String, dynamic>;
//               final fullName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = fullName.isNotEmpty ? fullName[0] : 'D';
//               final appointmentCount = doctorData['appointments'] ?? 0;
              
//               return _DoctorCard(
//                 fullName: fullName,
//                 specialties: '$specialties ($appointmentCount appointments)',
//                 child: Text(
//                   firstLetter,
//                   style: TextStyle(fontSize: 24, color: Colors.blue[900]),
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//                   );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }

// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String fullName;
//   final String specialties;
//   final Widget child;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.fullName,
//     required this.specialties,
//     required this.child,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue[100],
//               child: child,
//             ),
//             const SizedBox(height: 6),
//             Text(fullName, 
//                 style: const TextStyle(fontSize: 14),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1),
//             Text(specialties,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2),
//           ],
//         ),
//       ),
//     );
//   }
// }





























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/Doctorlist_screen.dart';
// import '../myappoi/myappointment_screen.dart';
// import '../cunto/mealplan_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _searchController = TextEditingController();

//   bool _isLoading = false;
//   int _currentBottomNavIndex = 0;
//   String _searchQuery = '';

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationScreen()),
//               );
//             },
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         width: 250,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfileScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.pregnant_woman),
//               title: const Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => PregnancyTrackerScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.apple),
//               title: const Text("MealPlan"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => HealthyMealApp()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ArticleScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.book),
//               title: const Text("Myappointments"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => Myappointment()),
//               ),
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => SigninScreen()),
//                 );
//               },
//             ),
//             SwitchListTile(
//               title: const Text("Dark Mode"),
//               secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: widget.isDarkMode,
//               onChanged: (_) => widget.onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Search Field
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Search for doctors...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             // Categories Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Featured Doctor Card
//             _buildFeaturedDoctorCard(),
//             const SizedBox(height: 20),
            
//             // Top Doctors Section
//             const Text("Top Doctors",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 12),
//             _buildTopDoctorsList(),
            
//             const SizedBox(height: 20),
//             const Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 10),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("How to protect your heart health"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("Pregnancy nutrition guide"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentBottomNavIndex,
//         onTap: (index) {
//           setState(() {
//             _currentBottomNavIndex = index;
//           });
//           _onBottomNavTap(context, index);
//         },
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Appointment",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeaturedDoctorCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.teal.shade100,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('appointments')
//           .orderBy('createdAt', descending: true)
//           .limit(1)
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return _buildLoadingFeaturedDoctor();
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return _buildDefaultFeaturedDoctor();
//           }
          
//           final appointment = snapshot.data!.docs.first;
//           final doctorId = appointment['doctorId'];
          
//           return FutureBuilder<DocumentSnapshot>(
//             future: _firestore.collection('doctors').doc(doctorId).get(),
//             builder: (context, doctorSnapshot) {
//               if (doctorSnapshot.connectionState == ConnectionState.waiting) {
//                 return _buildLoadingFeaturedDoctor();
//               }
              
//               if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
//                 return _buildDefaultFeaturedDoctor();
//               }
              
//               final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
//               final doctorName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = doctorName.isNotEmpty ? doctorName[0] : 'D';
              
//               return Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text("Featured Doctor", 
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 8),
//                         Text("Dr. $doctorName",
//                             style: const TextStyle(fontWeight: FontWeight.bold)),
//                         Text(specialties,
//                             style: const TextStyle(color: Colors.grey)),
//                       ],
//                     ),
//                   ),
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.blue[100],
//                     child: Text(firstLetter, 
//                         style: TextStyle(fontSize: 24, color: Colors.blue[900])),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLoadingFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("Loading...", style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildDefaultFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("No featured doctor available",
//                   style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: Icon(Icons.person, color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildTopDoctorsList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore.collection('doctors')
//         .orderBy('appointments', descending: true)
//         .limit(4)
//         .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SizedBox(
//             height: 110,
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (snapshot.hasError) {
//           return SizedBox(
//             height: 110,
//             child: Center(
//               child: Text(
//                 "Error loading doctors",
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return SizedBox(
//             height: 110,
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.people_outline, size: 40, color: Colors.grey),
//                   SizedBox(height: 8),
//                   Text(
//                     "No doctors available",
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         List<QueryDocumentSnapshot> doctors = snapshot.data!.docs;

//         // Apply search filter if query exists
//         if (_searchQuery.isNotEmpty) {
//           doctors = doctors.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             final name = data['fullName']?.toString().toLowerCase() ?? '';
//             final specialty = data['specialties']?.toString().toLowerCase() ?? '';
//             return name.contains(_searchQuery) || specialty.contains(_searchQuery);
//           }).toList();

//           if (doctors.isEmpty) {
//             return SizedBox(
//               height: 110,
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.search_off, size: 40, color: Colors.grey),
//                     SizedBox(height: 8),
//                     Text(
//                       "No matching doctors found",
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }
//         }

//         return SizedBox(
//           height: 110,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               final doctorData = doctor.data() as Map<String, dynamic>;
//               final fullName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = fullName.isNotEmpty ? fullName[0] : 'D';
//               final appointmentCount = doctorData['appointments'] ?? 0;
              
//               return _DoctorCard(
//                 fullName: fullName,
//                 specialties: '$specialties ($appointmentCount appointments)',
//                 child: Text(
//                   firstLetter,
//                   style: TextStyle(fontSize: 24, color: Colors.blue[900]),
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//                   );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }

// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String fullName;
//   final String specialties;
//   final Widget child;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.fullName,
//     required this.specialties,
//     required this.child,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue[100],
//               child: child,
//             ),
//             const SizedBox(height: 6),
//             Text(fullName, 
//                 style: const TextStyle(fontSize: 14),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1),
//             Text(specialties,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2),
//           ],
//         ),
//       ),
//     );
//   }
// }




























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/Doctorlist_screen.dart';
// import '../myappoi/myappointment_screen.dart';
// import '../cunto/mealplan_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _searchController = TextEditingController();

//   bool _isLoading = false;
//   int _currentBottomNavIndex = 0;
//   String _searchQuery = '';

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationScreen()),
//               );
//             },
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         width: 250,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfileScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.pregnant_woman),
//               title: const Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => PregnancyTrackerScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.apple),
//               title: const Text("MealPlan"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => HealthyMealApp()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ArticleScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.book),
//               title: const Text("Myappointments"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => Myappointment()),
//               ),
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => SigninScreen()),
//                 );
//               },
//             ),
//             SwitchListTile(
//               title: const Text("Dark Mode"),
//               secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: widget.isDarkMode,
//               onChanged: (_) => widget.onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Search Field
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Search for doctors...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             // Categories Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Featured Doctor Card
//             _buildFeaturedDoctorCard(),
//             const SizedBox(height: 20),
            
//             // Top Doctors Section
//             const Text("Top Doctors",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 12),
//             _buildTopDoctorsList(),
            
//             const SizedBox(height: 20),
//             const Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 10),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("How to protect your heart health"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("Pregnancy nutrition guide"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentBottomNavIndex,
//         onTap: (index) {
//           setState(() {
//             _currentBottomNavIndex = index;
//           });
//           _onBottomNavTap(context, index);
//         },
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Appointment",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeaturedDoctorCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.teal.shade100,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('appointments')
//           .orderBy('createdAt', descending: true)
//           .limit(1)
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return _buildLoadingFeaturedDoctor();
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return _buildDefaultFeaturedDoctor();
//           }
          
//           final appointment = snapshot.data!.docs.first;
//           final doctorId = appointment['doctorId'];
          
//           return FutureBuilder<DocumentSnapshot>(
//             future: _firestore.collection('doctors').doc(doctorId).get(),
//             builder: (context, doctorSnapshot) {
//               if (doctorSnapshot.connectionState == ConnectionState.waiting) {
//                 return _buildLoadingFeaturedDoctor();
//               }
              
//               if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
//                 return _buildDefaultFeaturedDoctor();
//               }
              
//               final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
//               final doctorName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = doctorName.isNotEmpty ? doctorName[0] : 'D';
              
//               return Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text("Featured Doctor", 
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 8),
//                         Text("Dr. $doctorName",
//                             style: const TextStyle(fontWeight: FontWeight.bold)),
//                         Text(specialties,
//                             style: const TextStyle(color: Colors.grey)),
//                       ],
//                     ),
//                   ),
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.blue[100],
//                     child: Text(firstLetter, 
//                         style: TextStyle(fontSize: 24, color: Colors.blue[900])),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLoadingFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("Loading...", style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildDefaultFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("No featured doctor available",
//                   style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: Icon(Icons.person, color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildTopDoctorsList() {
//     return SizedBox(
//       height: 110,
//       child: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors')
//           .orderBy('appointments', descending: true)
//           .limit(4)
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text("No doctors available", 
//                   style: TextStyle(color: Colors.grey)),
//             );
//           }
          
//           List<QueryDocumentSnapshot> doctors = snapshot.data!.docs;
          
//           // Apply search filter if query exists
//           if (_searchQuery.isNotEmpty) {
//             doctors = doctors.where((doc) {
//               final data = doc.data() as Map<String, dynamic>;
//               final name = data['fullName']?.toString().toLowerCase() ?? '';
//               final specialty = data['specialties']?.toString().toLowerCase() ?? '';
//               return name.contains(_searchQuery) || specialty.contains(_searchQuery);
//             }).toList();
//           }
          
//           if (doctors.isEmpty) {
//             return const Center(
//               child: Text("No matching doctors found", 
//                   style: TextStyle(color: Colors.grey)),
//             );
//           }
          
//           return ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               final doctorData = doctor.data() as Map<String, dynamic>;
//               final fullName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = fullName.isNotEmpty ? fullName[0] : 'D';
//               final appointmentCount = doctorData['appointments'] ?? 0;
              
//               return _DoctorCard(
//                 fullName: fullName,
//                 specialties: '$specialties ($appointmentCount)',
//                 child: Text(
//                   firstLetter,
//                   style: TextStyle(fontSize: 24, color: Colors.blue[900]),
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String fullName;
//   final String specialties;
//   final Widget child;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.fullName,
//     required this.specialties,
//     required this.child,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue[100],
//               child: child,
//             ),
//             const SizedBox(height: 6),
//             Text(fullName, 
//                 style: const TextStyle(fontSize: 14),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1),
//             Text(specialties,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1),
//           ],
//         ),
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/Doctorlist_screen.dart';
// import '../myappoi/myappointment_screen.dart';
// import '../cunto/mealplan_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _searchController = TextEditingController();

//   bool _isLoading = false;
//   int _currentBottomNavIndex = 0;
//   String _searchQuery = '';

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationScreen()),
//               );
//             },
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         width: 250,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfileScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.pregnant_woman),
//               title: const Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => PregnancyTrackerScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.apple),
//               title: const Text("MealPlan"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => HealthyMealApp()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ArticleScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.book),
//               title: const Text("Myappointments"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => Myappointment()),
//               ),
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => SigninScreen()),
//                 );
//               },
//             ),
//             SwitchListTile(
//               title: const Text("Dark Mode"),
//               secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: widget.isDarkMode,
//               onChanged: (_) => widget.onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Search Field
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Search for doctors...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             // Categories Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Featured Doctor Card
//             _buildFeaturedDoctorCard(),
//             const SizedBox(height: 20),
            
//             // Top Doctors Section
//             const Text("Top Doctors",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 12),
//             _buildDoctorsList(),
            
//             // ... rest of the existing code ...
//           ],
//         ),
//       ),
//       // ... bottomNavigationBar ...
//     );
//   }

//   Widget _buildFeaturedDoctorCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.teal.shade100,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('appointments')
//           .orderBy('createdAt', descending: true)
//           .limit(1)
//           .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return _buildLoadingFeaturedDoctor();
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return _buildDefaultFeaturedDoctor();
//           }
          
//           final appointment = snapshot.data!.docs.first;
//           final doctorId = appointment['doctorId'];
          
//           return FutureBuilder<DocumentSnapshot>(
//             future: _firestore.collection('doctors').doc(doctorId).get(),
//             builder: (context, doctorSnapshot) {
//               if (doctorSnapshot.connectionState == ConnectionState.waiting) {
//                 return _buildLoadingFeaturedDoctor();
//               }
              
//               if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
//                 return _buildDefaultFeaturedDoctor();
//               }
              
//               final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
//               final doctorName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = doctorName.isNotEmpty ? doctorName[0] : 'D';
              
//               return Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text("Featured Doctor", 
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 8),
//                         Text("Dr. $doctorName",
//                             style: const TextStyle(fontWeight: FontWeight.bold)),
//                         Text(specialties,
//                             style: const TextStyle(color: Colors.grey)),
//                       ],
//                     ),
//                   ),
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.blue[100],
//                     child: Text(firstLetter, 
//                         style: TextStyle(fontSize: 24, color: Colors.blue[900])),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLoadingFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("Loading...", style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildDefaultFeaturedDoctor() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("Featured Doctor", 
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Text("No featured doctor available",
//                   style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.grey,
//           child: Icon(Icons.person, color: Colors.white),
//         ),
//       ],
//     );
//   }

//   Widget _buildDoctorsList() {
//     return SizedBox(
//       height: 110,
//       child: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('doctors').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text("No doctors available", 
//                   style: TextStyle(color: Colors.grey)),
//             );
//           }
          
//           List<QueryDocumentSnapshot> doctors = snapshot.data!.docs;
          
//           // Apply search filter if query exists
//           if (_searchQuery.isNotEmpty) {
//             doctors = doctors.where((doc) {
//               final data = doc.data() as Map<String, dynamic>;
//               final name = data['fullName']?.toString().toLowerCase() ?? '';
//               final specialty = data['specialties']?.toString().toLowerCase() ?? '';
//               return name.contains(_searchQuery) || specialty.contains(_searchQuery);
//             }).toList();
//           }
          
//           // Sort by number of appointments (descending)
//           doctors.sort((a, b) {
//             final aAppointments = (a.data() as Map<String, dynamic>)['appointments'] ?? 0;
//             final bAppointments = (b.data() as Map<String, dynamic>)['appointments'] ?? 0;
//             return bAppointments.compareTo(aAppointments);
//           });
          
//           // Limit to top 4 doctors
//           if (doctors.length > 4) {
//             doctors = doctors.sublist(0, 4);
//           }
          
//           if (doctors.isEmpty) {
//             return const Center(
//               child: Text("No matching doctors found", 
//                   style: TextStyle(color: Colors.grey)),
//             );
//           }
          
//           return ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctor = doctors[index];
//               final doctorData = doctor.data() as Map<String, dynamic>;
//               final fullName = doctorData['fullName'] ?? 'Doctor';
//               final specialties = doctorData['specialties'] ?? 'Specialist';
//               final firstLetter = fullName.isNotEmpty ? fullName[0] : 'D';
              
//               return _DoctorCard(
//                 fullName: fullName,
//                 specialties: specialties,
//                 child: Text(
//                   firstLetter,
//                   style:  TextStyle(fontSize: 24, color: Colors.blue[900]),
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => ChatListScreen()),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//     const SizedBox(height: 20),
//             const Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 10),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("How to protect your heart health"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.article, color: Colors.blue),
//               title: const Text("Pregnancy nutrition guide"),
//               subtitle: const Text("Read now"),
//               trailing: const Icon(Icons.arrow_forward),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentBottomNavIndex,
//         onTap: (index) {
//           setState(() {
//             _currentBottomNavIndex = index;
//           });
//           _onBottomNavTap(context, index);
//         },
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Appointment",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }
// }
//   }
// }
// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String fullName;
//   final String specialties;
//   final Widget child;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.fullName,
//     required this.specialties,
//     required this.child,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue[100],
//               child: child,
//             ),
//             const SizedBox(height: 6),
//             Text(fullName, 
//                 style: const TextStyle(fontSize: 14),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1),
//             Text(specialties,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1),
//           ],
//         ),
//       ),
//     );
//   }
// }





























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/Doctorlist_screen.dart';
// import '../myappoi/myappointment_screen.dart';
// import '../cunto/mealplan_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _searchController = TextEditingController();

//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   int _currentBottomNavIndex = 0;
//   String _searchQuery = '';

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationScreen()),
//               );
//             },
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         width: 250,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfileScreen()),
//               ),
//             ),
           
//             ListTile(
//               leading: const Icon(Icons.pregnant_woman),
//               title: const Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => PregnancyTrackerScreen()),
//               ),
//             ),
//              ListTile(
//               leading: const Icon(Icons.apple),
//               title: const Text(" MealPlan"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => HealthyMealApp()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ArticleScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.book),
//               title: const Text("Myappointments"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => Myappointment()),
//               ),
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => SigninScreen()),
//                 );
//               },
//             ),
//             SwitchListTile(
//               title: const Text("Dark Mode"),
//               secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: widget.isDarkMode,
//               onChanged: (_) => widget.onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: "Search for doctors...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade100,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _firestore.collection('appointments').limit(1).snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: const [
//                               Text("Easy protection for", style: TextStyle(fontSize: 16)),
//                               Text("your family health",
//                                   style: TextStyle(
//                                       fontSize: 16, fontWeight: FontWeight.bold)),
//                               SizedBox(height: 10),
//                             ],
//                           ),
//                         ),
//                         CircleAvatar(
//                           child: Text('D', style: const TextStyle(fontSize: 24)),
//                         ),
//                       ],
//                     );
//                   }
                  
//                   final appointment = snapshot.data!.docs.first;
//                   final doctorId = appointment['doctorId'];
                  
//                   return FutureBuilder<DocumentSnapshot>(
//                     future: _firestore.collection('doctors').doc(doctorId).get(),
//                     builder: (context, doctorSnapshot) {
//                       if (!doctorSnapshot.hasData) {
//                         return Row(
//                           children: [
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: const [
//                                   Text("Easy protection for", style: TextStyle(fontSize: 16)),
//                                   Text("your family health",
//                                       style: TextStyle(
//                                           fontSize: 16, fontWeight: FontWeight.bold)),
//                                   SizedBox(height: 10),
//                                 ],
//                               ),
//                             ),
//                             CircleAvatar(
//                               child: Text('D', style: const TextStyle(fontSize: 24)),
//                             ),
//                           ],
//                         );
//                       }
                      
//                       final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
//                       final doctorName = doctorData['fullName'] ?? 'Doctor';
//                       final firstLetter = doctorName.isNotEmpty ? doctorName[0] : 'D';
                      
//                       return Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text("Easy protection for", style: TextStyle(fontSize: 16)),
//                                 const Text("your family health",
//                                     style: TextStyle(
//                                         fontSize: 16, fontWeight: FontWeight.bold)),
//                                 const SizedBox(height: 10),
//                                 Text("Dr. $doctorName",
//                                     style: const TextStyle(fontWeight: FontWeight.bold)),
//                               ],
//                             ),
//                           ),
//                           CircleAvatar(
//                             child: Text(firstLetter, style: const TextStyle(fontSize: 24)),
//                           ),
//                         ],
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("Top Doctors",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 110,
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _firestore.collection('doctors')
//                   .orderBy('appointments', descending: true)
//                   .limit(4)
//                   .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
                  
//                   final doctors = snapshot.data!.docs;
                  
//                   return ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: doctors.length,
//                     itemBuilder: (context, index) {
//                       final doctor = doctors[index];
//                       final doctorData = doctor.data() as Map<String, dynamic>;
//                       final fullName = doctorData['fullName'] ?? 'Doctor';
//                       final specialties = doctorData['specialties'] ?? 'Specialist';
//                       final firstLetter = fullName.isNotEmpty ? fullName[0] : 'D';
                      
//                       return _DoctorCard(
//                         fullName: fullName,
//                         specialties: specialties,
//                         child: Text(
//                           firstLetter,
//                           style: const TextStyle(fontSize: 24),
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => ChatListScreen()),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("How to protect your heart health"),
//               subtitle: const Text("Read now"),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         onTap: (index) => _onBottomNavTap(context, index),
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.blue[300],
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Appointment",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String fullName;
//   final String specialties;
//   final Widget child;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.fullName,
//     required this.specialties,
//     required this.child,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               child: child,
//             ),
//             const SizedBox(height: 6),
//             Text(fullName, 
//                 style: const TextStyle(fontSize: 14),
//                 overflow: TextOverflow.ellipsis),
//             Text(specialties,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 overflow: TextOverflow.ellipsis),
//           ],
//         ),
//       ),
//     );
//   }
// }































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/Doctorlist_screen.dart';
// import '../myappoi/myappointment_screen.dart';
// import '../cunto/mealplan_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   int _currentBottomNavIndex = 0;

//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => DoctorlistScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationScreen()),
//               );
//             },
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         drawer width ka yaree qoraal body drawwerka ku yaal centerka gee ul draweka iga qurxi
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfileScreen()),
//               ),
//             ),
           
//             ListTile(
//               leading: const Icon(Icons.pregnant_woman),
//               title: const Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => PregnancyTrackerScreen()),
//               ),
//             ),
//              ListTile(
//               leading: const Icon(Icons.apple),
//               title: const Text(" MealPlan"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => HealthyMealApp()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ArticleScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.book),
//               title: const Text("Myappointments"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => Myappointment()),
//               ),
//             ),
//             login iyo darkmode drawerka qeeybta ugu hooseysa ku dhaji 
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => SigninScreen()),
//                 );
//               },
//             ),
//             SwitchListTile(
//               title: const Text("Dark Mode"),
//               secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: widget.isDarkMode,
//               onChanged: (_) => widget.onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             search for e doctor collection:doctors and fildrerin   ku raadi fullName  as search
//             TextField(
//               decoration: InputDecoration(
//                 hintText: "Search ...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade100,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         Text("Easy protection for", style: TextStyle(fontSize: 16)),
//                         Text("your family health",
//                             style: TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold)),
//                         SizedBox(height: 10),
//                       ],
//                     ),
//                   ),
//                   CircleAvatar(
//                     dhaqtarka balantiisu ay saa id u badan tahay oo lamber one galaya inta keenaya 
//                     ka soo aqriso collection appointments
//                      as doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("Top Doctors",
//             afarta dhaqtar aad inta ku soo aqrintooto ha noqdaan dhaqaatiir ugu fiican ay dadku wax badan balan la qabsadeen  kana soo aqri collection appointments
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 110,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   _DoctorCard(
//                      get fullName from doctors collection
//                      get specialties from doctors collection
                    
//                   child: Text(
//                      get as img from doctors collection
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => ChatScreen()),
//                       );
//                     },
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => ChatScreen()),
//                       );
//                     },
//                   ),
//                   _DoctorCard(
                    
//                     get fullName from doctors collection
//                      get specialties from doctors collection
                    
//                   child: Text(
//                      get as img from doctors collection
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => ChatScreen()),
//                       );
//                     },
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => ChatScreen()),
//                       );
//                     },
//                   ),
//                   _DoctorCard(
//                     get fullName from doctors collection
//                      get specialties from doctors collection
                    
//                   child: Text(
//                      get as img from doctors collection
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => ChatScreen()),
//                       );
//                     },
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => ChatScreen()),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//              _DoctorCard(
//                    get fullName from doctors collection
//                      get specialties from doctors collection
                    
//                   child: Text(
//                      get  from doctors collection
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => ChatScreen()),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("How to protect your heart health"),
//               subtitle: const Text("Read now"),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ArticleScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         onTap: (index) => _onBottomNavTap(context, index),
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.blue[300],
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Appointment",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String fullName;
//   final String specialties;
//    child: Text(
//                      get  from doctors collection
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.fullName,
//     required this.specialties,
//      child: Text(
//                      get  from doctors collection
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               child: Text(
//                      get  from doctors collection
//                     doctorData['fullName']?.isNotEmpty == true 
//                         ? doctorData['fullName'][0] 
//                         : 'D',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//             ),
//             const SizedBox(height: 6),
//             Text(fullName, style: const TextStyle(fontSize: 14)),
//             Text(specialties,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }
// }

























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../admin/admin_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/booking_screen.dart';
// import '../calender/calender_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   const HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   int _currentBottomNavIndex = 0;

//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();



//      void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => BookingScreen( )),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

// final List<String> _adminEmails = [
//   'daganabdi757@gmail.com',
//   'superadmin@example.com',
//   // Ku dar email-yada admin-ka ah
// ];

// Future<void> _signInWithEmailAndPassword() async {
//   if (_formKey.currentState!.validate()) {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
      
//       // After successful login, check if user is admin
//       if (_adminEmails.contains(_emailController.text.trim())) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => AdminScreen()),
//         );
//       } else {
//         // Handle regular user login
//         Navigator.pop(context); // Close the dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Welcome regular user!')),
//         );
//       }
//     } catch (e) {
//       // Handle errors
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Login failed: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
// }

// void _showLoginDialog() {
//   _emailController.clear();
//   _passwordController.clear();

//   showDialog(
//     context: context,
//     builder: (_) => AlertDialog(
//       title: Text('Login as Admin'),
//       content: Form(
//         key: _formKey,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextFormField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//               validator: (value) => value!.isEmpty ? 'Enter your email' : null,
//             ),
//             const SizedBox(height: 10),
//             TextFormField(
//               controller: _passwordController,
//               obscureText: _obscurePassword,
//               decoration: InputDecoration(
//                 labelText: "Password",
//                 prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                     color: Colors.blue[900],
//                   ),
//                   onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return "Please enter password";
//                 }
//                 if (value.length < 6) {
//                   return "Password must be 6+ characters";
//                 }
//                 return null;
//               },
//             ),
//             if (_isLoading) 
//               const Padding(
//                 padding: EdgeInsets.only(top: 10),
//                 child: CircularProgressIndicator(),
//               ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text("Cancel"),
//         ),
//        void _showLoginDialog() {
//   _emailController.clear();
//   _passwordController.clear();

//   showDialog(
//     context: context,
//     builder: (_) => AlertDialog(
//       title: Text('Login as Admin'),
//       content: Form(
//         key: _formKey,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextFormField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//               validator: (value) => value!.isEmpty ? 'Enter your email' : null,
//             ),
//             const SizedBox(height: 10),
//             TextFormField(
//               controller: _passwordController,
//               obscureText: _obscurePassword,
//               decoration: InputDecoration(
//                 labelText: "Password",
//                 prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                     color: Colors.blue[900],
//                   ),
//                   onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return "Please enter password";
//                 }
//                 if (value.length < 6) {
//                   return "Password must be 6+ characters";
//                 }
//                 return null;
//               },
//             ),
//             if (_isLoading) 
//               const Padding(
//                 padding: EdgeInsets.only(top: 10),
//                 child: CircularProgressIndicator(),
//               ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text("Cancel"),
//         ),
//         ElevatedButton(
//           onPressed: _isLoading 
//               ? null 
//               : () {
//                   _signInWithEmailAndPassword();
//                 },
//           child: const Text("gal gudaha"),
//         ),
//       ],
//     ),
//   );
// }
//       ],
//     ),
//   );
// }



//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) =>  NotificationScreen()),
//               );
//             },
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.admin_panel_settings),
//               title: const Text("Admin"),
//               onTap: () => _showLoginDialog
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) =>  ProfileScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.calendar_today),
//               title: const Text("Doctor"),
//               // onTap: () => _showLoginDialog("Doctor"),
//             ),
//             ListTile(
//               leading: const Icon(Icons.pregnant_woman),
//               title: const Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => PregnancyTrackerScreen()),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) =>  ArticleScreen()),
//               ),
//             ),
//               ListTile(
//               leading: const Icon(Icons.calendar_today),
//               title: const Text("Calendar"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => CalenderScreen()),
//               ),
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) =>  SigninScreen()),
//                 );
//               },
//             ),
//             SwitchListTile(
//               title: const Text("Dark Mode"),
//               secondary: Icon(widget.isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: widget.isDarkMode,
//               onChanged: (_) => widget.onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               decoration: InputDecoration(
//                 hintText: "Search ...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade100,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         Text("Easy protection for", style: TextStyle(fontSize: 16)),
//                         Text("your family health",
//                             style: TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold)),
//                         SizedBox(height: 10),
//                       ],
//                     ),
//                   ),
//                   CircleAvatar(
//                     backgroundImage: const AssetImage("assets/images/15.png"),
//                     radius: 40,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("Top Doctors",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 110,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   _DoctorCard(
//                     name: "Dr. Marcus",
//                     specialty: "Cardiologist",
//                     image: "assets/images/12.jpg",
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) =>  ProfileScreen()),
//                       );
//                     },
//                   ),
//                   _DoctorCard(
//                     name: "Dr. Maria",
//                     specialty: "Pediatrician",
//                     image: "assets/images/6.jpg",
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) =>  ProfileScreen()),
//                       );
//                     },
//                   ),
//                   _DoctorCard(
//                     name: "Dr. Amina",
//                     specialty: "Dentist",
//                     image: "assets/images/1.png",
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) =>  ProfileScreen()),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             ListTile(
//               leading: const Icon(Icons.article),
//               title: const Text("How to protect your heart health"),
//               subtitle: const Text("Read now"),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) =>  ArticleScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
      
//         bottomNavigationBar: BottomNavigationBar(
//         onTap: (index) => _onBottomNavTap(context, index),
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.blue[300],
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Booking",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String name;
//   final String specialty;
//   final String image;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.name,
//     required this.specialty,
//     required this.image,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               backgroundImage: AssetImage(image),
//               radius: 30,
//             ),
//             const SizedBox(height: 6),
//             Text(name, style: const TextStyle(fontSize: 14)),
//             Text(specialty,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }
// }
























































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import '../chat/chat_list_screen.dart';
// import '../doctor/doctor_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../admin/admin_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/booking_screen.dart';

// class HomeScreen extends StatelessWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   HomeScreen({required this.isDarkMode, required this.onToggleTheme});

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => BookingScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatListScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isLoading = false;
//   bool _obscurePassword = true;

//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   Future<void> _signInWithTitleBasedUser(String expectedTitle) async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       // Step 1: Login
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       final user = userCredential.user;
//       if (user == null) throw Exception("User not found");

//       // Step 2: Get user doc by email and check title
//       QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: _emailController.text.trim())
//           .limit(1)
//           .get();

//       if (snapshot.docs.isEmpty) {
//         throw Exception("User not found in Firestore.");
//       }

//       final userData = snapshot.docs.first.data() as Map<String, dynamic>;
//       final userTitle = userData['title']?.toString().toLowerCase();

//       if (userTitle != expectedTitle.toLowerCase()) {
//         throw Exception("You don't have access to $expectedTitle.");
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Welcome $expectedTitle!',style: TextStyle(color: Colors.white),),
//       backgroundColor: Colors.green,
//      ),
//   );


//       // Step 3: Navigate
//       if (expectedTitle == 'Admin') {
//         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
//       } else if (expectedTitle == 'Doctor') {
//         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorScreen()));
//       }

//     } on FirebaseAuthException catch (e) {
//       String message = 'Login failed.';
//       if (e.code == 'user-not-found') message = 'No user with that email.';
//       if (e.code == 'wrong-password') message = 'Incorrect password.';
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void _showLoginDialog(String title) {
//     _emailController.clear();
//     _passwordController.clear();

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Login as $title'),
//         content: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(labelText: 'Email'),
//                 validator: (value) => value!.isEmpty ? 'Enter your email' : null,
//               ),
//               const SizedBox(height: 10),
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
//                     onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                   ),
//                 ),
//                 validator: (value) => value!.isEmpty ? 'Enter your password' : null,
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _signInWithTitleBasedUser(title);
//             },
//             child: const Text("Login"),
//           ),
//         ],
//       ),
//     );
//   }


















//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Baby Birth'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.notifications),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationScreen()),
//               );
//             },
//           ),
//           Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundImage: 
//                      AssetImage('assets/images/14.png'),
//               radius: 15,
//             ),
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 10,
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               color: Colors.blue[900],
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, color: Colors.blue[900]),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     "Pregnancy Woman",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.admin_panel_settings),
//               title: Text("Admin"),
//               onTap: () => _showLoginDialog("Admin"),
//             ),
//             ListTile(
//               leading: Icon(Icons.person),
//               title: Text("Profile"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfileScreen()),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.calendar_today),
//               title: Text("Doctor"),
//               onTap: () => _showLoginDialog("Doctor"),
//             ),
//             ListTile(
//               leading: Icon(Icons.pregnant_woman),
//               title: Text("Pregnancy Tracker"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => TrackerScreen()),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.article),
//               title: Text("Articles & Tips"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ArticleScreen()),
//               ),
//             ),
//             Divider(),
//             ListTile(
//               leading: Icon(Icons.logout),
//               title: Text("Logout"),
//               onTap: () {
//                 Navigator.pushReplacement(
//                 context,
//               MaterialPageRoute(builder: (_) => SigninScreen()),
//               );
//               },

//             ),
//             SwitchListTile(
//               title: Text("Dark Mode"),
//               secondary: Icon(isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//               value: isDarkMode,
//               onChanged: (_) => onToggleTheme(),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               decoration: InputDecoration(
//                 hintText: "Search ...",
//                 prefixIcon: Icon(Icons.search),
//                 border:
//                     OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
//               ),
//             ),
//             SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//                 _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//                 _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//                 _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//               ],
//             ),
//             SizedBox(height: 20),
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade100,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         Text("Easy protection for", style: TextStyle(fontSize: 16)),
//                         Text("your family health",
//                             style: TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold)),
//                         SizedBox(height: 10),
//                       ],
//                     ),
//                   ),
//                   CircleAvatar(
//                     backgroundImage:
//                         AssetImage("assets/images/15.png"),
//                     radius: 40,
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//             Text("Top Doctors",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             SizedBox(height: 12),
//             SizedBox(
//               height: 110,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   _DoctorCard(
//                     name: "Dr. Marcus",
//                     specialty: "Cardiologist",
//                     image: "assets/images/12.jpg",
//                     onTap: () {
//                       Navigator.push(context,
//                           MaterialPageRoute(builder: (_) => ProfileScreen()));
//                     },
//                   ),
//                   _DoctorCard(
//                     name: "Dr. Maria",
//                     specialty: "Pediatrician",
//                     image: "assets/images/6.jpg",
//                     onTap: () {
//                       Navigator.push(context,
//                           MaterialPageRoute(builder: (_) => ProfileScreen()));
//                     },
//                   ),
//                   _DoctorCard(
//                     name: "Dr. Amina",
//                     specialty: "Dentist",
//                     image: "assets/images/1.png",
//                     onTap: () {
//                       Navigator.push(context,
//                           MaterialPageRoute(builder: (_) => ProfileScreen()));
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//             Text("Health Articles",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             ListTile(
//               leading: Icon(Icons.article),
//               title: Text("How to protect your heart health"),
//               subtitle: Text("Read now"),
//               onTap: () {
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (_) => ArticleScreen()));
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         onTap: (index) => _onBottomNavTap(context, index),
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.blue[300],
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Booking",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: Icon(icon, color: Colors.white),
//         ),
//         SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String name;
//   final String specialty;
//   final String image;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.name,
//     required this.specialty,
//     required this.image,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(
//               backgroundImage: AssetImage(image),
//               radius: 30,
//             ),
//             SizedBox(height: 6),
//             Text(name, style: TextStyle(fontSize: 14)),
//             Text(specialty,
//                 style: TextStyle(fontSize: 12, color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }
// }






























































// import 'package:flutter/material.dart';
// import '../chat/chat_screen.dart';
// import '../appointments/appointment_screen.dart';
// import '../tracker/tracker_screen.dart';
// import '../notifications/notification_screen.dart';
// import '../articles/article_screen.dart';
// import '../profile/profile_screen.dart';
// import '../admin/admin_screen.dart';
// import '../setting/setting_screen.dart';
// import '../booking/booking_screen.dart';

// class HomeScreen extends StatelessWidget {
//   final bool isDarkMode;
//   final VoidCallback onToggleTheme;

//   HomeScreen({required this.isDarkMode, required this.onToggleTheme});
  
 

//   void _onBottomNavTap(BuildContext context, int index) {
//     switch (index) {
//       // case 0:
//       //   Navigator.push(
//       //     context,(builder: (_) => HomeScreen()),
//       //   );
//       //   break;
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => BookingScreen()),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ChatScreen()),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SettingScreen()),
//         );
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
     
//      appBar: AppBar(
//   title: Text('Baby Birth'),
//   actions: [
//     IconButton(
//       icon: Icon(Icons.notifications),
//       padding: EdgeInsets.all(8.2),
//       onPressed: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => NotificationScreen()),
//         );
//       },
//     ),
//     Padding(
//       padding: EdgeInsets.all(8.2),
//       child: CircleAvatar(
//         radius: 15,
//         //backgroundImage: AssetImage('assets/images/article1.png'),
//       ),
//     ),
//   ],
//   backgroundColor: Colors.blue[900],
//   foregroundColor: Colors.white,
//   elevation: 10,
// ),

//   //   appBar: AppBar(
//   //   toolbarHeight: 80,
//   //   elevation: 50,
//   //   backgroundColor: Colors.white, // Corrected here
//   //   title: Column(
//   //     crossAxisAlignment: CrossAxisAlignment.start,
//   //     children: const [
//   //       Text(
//   //         'Pregnancy_app!',
//   //         style: TextStyle(
//   //           color: Colors.orange,
//   //           fontSize: 16,
//   //           fontWeight: FontWeight.bold,
//   //         ),
//   //       ),
//   //     ],
//   //   ),
//   //   actions: [
//   //     Padding(
//   //       padding: const EdgeInsets.only(right: 16.0),
//   //       child: CircleAvatar(
//   //         radius: 22,
//   //         //backgroundImage: AssetImage('assets/images/article1.png'),
//   //       ),
//   //     ),
//   //     IconButton(
//   //       icon: const Icon(Icons.notifications),
//   //       onPressed: () {
//   //         Navigator.push(
//   //           context,
//   //           MaterialPageRoute(builder: (_) => const NotificationScreen()),
//   //         );
//   //       },
//   //     ),
//   //   ],
//   //   centerTitle: false, // Title on the left (not centered)
//   // ),


//       drawer: Drawer(
//   child: ListView(
//     padding: EdgeInsets.zero,
//     children: [
//       Container(
//         height: 100,
//         width: double.infinity,
//         decoration: BoxDecoration(color: Colors.blue[900]),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Colors.blue[900]),
//             ),
//             SizedBox(height: 8),
//             Text(
//               "Pregnancy Woman",
//               style: TextStyle(fontSize: 14, color: Colors.white),
//             ),
//           ],
//         ),
//       ),
//       ListTile(
//         leading: Icon(Icons.admin_panel_settings),
//         title: Text("Admin"),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => AdminScreen()),
//         ),
//       ),
//       ListTile(
//         leading: Icon(Icons.person),
//         title: Text("Profile"),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ProfileScreen()),
//         ),
//       ),
//       ListTile(
//         leading: Icon(Icons.calendar_today),
//         title: Text("Appointments"),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => AppointmentScreen()),
//         ),
//       ),
//       ListTile(
//         leading: Icon(Icons.pregnant_woman),
//         title: Text("Pregnancy Tracker"),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => TrackerScreen()),
//         ),
//       ),
//       ListTile(
//         leading: Icon(Icons.article),
//         title: Text("Articles & Tips"),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ArticleScreen()),
//         ),
//       ),
//       Divider(),
//       ListTile(
//         leading: Icon(Icons.logout),
//         title: Text("Logout"),
//         onTap: () {
//           Navigator.pop(context);
//           // Add logout logic here
//         },
//       ),
//       SwitchListTile(
//         title: Text("Dark Mode"),
//         secondary: Icon(isDarkMode ? Icons.nights_stay : Icons.wb_sunny),
//         value: isDarkMode,
//         onChanged: (_) => onToggleTheme(),
//       ),
//     ],
//   ),
// ),
//        body: SingleChildScrollView(
//   padding: const EdgeInsets.all(16),
//   child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       TextField(
//         decoration: InputDecoration(
//           hintText: "Search ...",
//           prefixIcon: const Icon(Icons.search),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
//         ),
//       ),
//       const SizedBox(height: 16),
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: const [
//           _CategoryIcon(icon: Icons.favorite, label: 'Cardio'),
//           _CategoryIcon(icon: Icons.local_hospital, label: 'General'),
//           _CategoryIcon(icon: Icons.healing, label: 'Surgery'),
//           _CategoryIcon(icon: Icons.medication, label: 'Pharmacy'),
//         ],
//       ),
//       const SizedBox(height: 20),
//       Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.teal.shade100,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: const [
//                   Text("Easy protection for", style: TextStyle(fontSize: 16)),
//                   Text("your family health", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                   SizedBox(height: 10),
//                 ],
//               ),
//             ),
//             const CircleAvatar(
//               backgroundImage: AssetImage("assets/images/doctor_banner.png"),
//               radius: 40,
//             ),
//           ],
//         ),
//       ),
//       const SizedBox(height: 20),
//       const Text("Top Doctors", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//       const SizedBox(height: 12),
//       SizedBox(
//         height: 110,
//         child: ListView(
//           scrollDirection: Axis.horizontal,
//           children: [
//             _DoctorCard(
//               name: "Dr. Marcus",
//               specialty: "Cardiologist",
//               image: "assets/images/doctor1.png",
//               onTap: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
//               },
//             ),
//             _DoctorCard(
//               name: "Dr. Maria",
//               specialty: "Pediatrician",
//               image: "assets/images/doctor2.png",
//               onTap: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
//               },
//             ),
//             _DoctorCard(
//               name: "Dr. Amina",
//               specialty: "Dentist",
//               image: "assets/images/doctor3.png",
//               onTap: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
//               },
//             ),
//           ],
//         ),
//       ),
//       const SizedBox(height: 20),
//       const Text("Health Articles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//       ListTile(
//         leading: const Icon(Icons.article),
//         title: const Text("How to protect your heart health"),
//         subtitle: const Text("Read now"),
//         onTap: () {
//           Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticleScreen()));
//         },
//       ),
//     ],
//   ),
// ),

//       // backgroundcolor:Colors.white,
//       bottomNavigationBar: BottomNavigationBar( 
//          onTap: (index) => _onBottomNavTap(context, index),
//         selectedItemColor: Colors.blue[900],
//         unselectedItemColor: Colors.blue[900],
//         showUnselectedLabels: true,
        

//         items: [
//            BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//            BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Booking",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: "Chat",
//           ),
//            BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Setting",
//           ),
          
//         ],
     
//       ),
//     );
//   }
// }


// lass _CategoryIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _CategoryIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(backgroundColor: Colors.blue, child: Icon(icon, color: Colors.white)),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }

// class _DoctorCard extends StatelessWidget {
//   final String name;
//   final String specialty;
//   final String image;
//   final VoidCallback onTap;

//   const _DoctorCard({
//     required this.name,
//     required this.specialty,
//     required this.image,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         margin: const EdgeInsets.only(right: 12),
//         child: Column(
//           children: [
//             CircleAvatar(backgroundImage: AssetImage(image), radius: 30),
//             const SizedBox(height: 6),
//             Text(name, style: const TextStyle(fontSize: 14)),
//             Text(specialty, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }
// }