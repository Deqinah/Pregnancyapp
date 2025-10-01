import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chat_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class BookingScreen extends StatefulWidget {
  final String doctorId;
  final String scheduleId;
  final Map<String, dynamic> doctorData;

  const BookingScreen({
    super.key, 
    required this.doctorId,
    required this.doctorData,
    required this.scheduleId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Map<String, dynamic>> schedules = [];
  int? selectedScheduleIndex;
  bool isLoading = true;
  bool hasExistingAppointment = false;
  bool isRequestingAppointment = false;
  late DateTime today;
  Set<String> busyScheduleIds = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    _loadInitialData();
  }

  Future<Map<String, Set<String>>> _getBusySchedules() async {
    final appointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('status', isEqualTo: 'pending')
        .get();
    
    final busySchedules = <String, Set<String>>{};
    
    for (final doc in appointments.docs) {
      final doctorId = doc['doctorId'] as String?;
      final scheduleId = doc['scheduleId'] as String?;
      
      if (doctorId != null && scheduleId != null) {
        if (!busySchedules.containsKey(doctorId)) {
          busySchedules[doctorId] = <String>{};
        }
        busySchedules[doctorId]!.add(scheduleId);
      }
    }
    
    return busySchedules;
  }

  void _showPaymentError(String errorCode, String message) {
    final userMessage = _translateErrorCode(errorCode, message);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  DateTime _parseFirestoreTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      throw Exception('Invalid timestamp format');
    }
  }

  String _formatAppointmentDate(dynamic timestamp) {
    final date = _parseFirestoreTimestamp(timestamp);
    return DateFormat.yMMMd().format(date);
  }

  String _formatAppointmentTime(dynamic timestamp) {
    final time = _parseFirestoreTimestamp(timestamp);
    return DateFormat('h:mm a').format(time);
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchSchedules(),
      _checkExistingAppointments(),
    ]);
  }

  Future<void> _checkExistingAppointments() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending'])
          .get();

      if (mounted) {
        setState(() {
          hasExistingAppointment = querySnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error checking existing appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error checking your existing appointments')),
        );
      }
    }
  }

  Future<void> _fetchSchedules() async {
    try {
      // Get busy schedules first
      final busySchedules = await _getBusySchedules();
      final busyDoctorSchedules = busySchedules[widget.doctorId] ?? {};

      final querySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .collection('schedules')
          .get();

      final filteredSchedules = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((schedule) => !busyDoctorSchedules.contains(schedule['id']))
          .toList();

      if (mounted) {
        setState(() {
          schedules = filteredSchedules;
          busyScheduleIds = busyDoctorSchedules;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch dialer';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making call: ${e.toString()}')),
        );
      }
    }
  }

  void showLocationDialog(String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clinic Location'),
        content: SingleChildScrollView(
          child: Text(address),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => _openMaps(address),
            child: const Text('Open in Maps'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(String address) async {
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address is empty')),
      );
      return;
    }

    final encodedAddress = Uri.encodeComponent(address);
    bool launched = false;

    final urlAttempts = [
      Uri.parse('geo:0,0?q=$encodedAddress'),
      
      if (Theme.of(context).platform == TargetPlatform.iOS)
        Uri.parse('http://maps.apple.com/?q=$encodedAddress')
      else
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress'),
      
      Uri.parse('https://www.google.com/search?q=$encodedAddress'),
    ];

    for (final url in urlAttempts) {
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        debugPrint('Failed to launch $url: $e');
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No application found to open maps')),
      );
    }
  }

  void _selectSchedule(int index) {
    setState(() {
      selectedScheduleIndex = index;
    });
  }

  Future<void> _requestAppointment() async {
    if (hasExistingAppointment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already have an appointment with this doctor')),
      );
      return;
    }

    if (selectedScheduleIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a schedule first')),
      );
      return;
    }

    final selectedSchedule = schedules[selectedScheduleIndex!];
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in')),
      );
      return;
    }

    setState(() {
      isRequestingAppointment = true;
    });

    try {
      final paymentSuccess = await _processPayment();
      final userFullName = await _getUserFullName();
      
      if (!paymentSuccess) {
        if (mounted) {
          setState(() {
            isRequestingAppointment = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed. Please try again')));
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Appointment requested and payment completed successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Failed to request appointment: $e');
      if (mounted) {
        setState(() {
          isRequestingAppointment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete request: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool> _processPayment() async {
    try {
      final doctorPhoneNumber = await _getDoctorPhoneNumber();
      final userPhoneNumber = await _getUserPhoneNumber();
      final userFullName = await _getUserFullName();

      if (userPhoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User phone number not found')),
          );
        }
        return false;
      }

      if (!_isValidSomaliNumber(userPhoneNumber)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please use a valid Somali mobile number')),
          );
        }
        return false;
      }

      var paymentRequest = { 
        "schemaVersion": "1.0", 
        "requestId": DateTime.now().millisecondsSinceEpoch.toString(),
        "timestamp": DateTime.now().toIso8601String(),
        "channelName": "WEB", 
        "serviceName": "API_PURCHASE", 
        "serviceParams": { 
          "merchantUid": "M0910291", 
          "apiUserId": "1000416",  
          "apiKey": "API-675418888AHX", 
          "paymentMethod": "mwallet_account", 
          "payerInfo": { 
            "accountNo": userPhoneNumber, 
            "accountName": userFullName,
          }, 
          "transactionInfo": { 
            "referenceId": "APP_${DateTime.now().millisecondsSinceEpoch}",
            "invoiceId": "INV_${DateTime.now().millisecondsSinceEpoch}",
            "amount": 0.01,  
            "currency": "USD", 
            "description": "Doctor Appointment Fee",
            "recipientInfo": {
              "accountNo": doctorPhoneNumber, 
              "accountType": "mwallet_account", 
              "accountName": widget.doctorData['fullName'] ?? 'Unknown Doctor',
            },
          }, 
        } 
      };

      debugPrint('Payment Request: ${jsonEncode(paymentRequest)}');

      final response = await http.post(
        Uri.parse('https://api.waafipay.net/asm'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(paymentRequest),
      ).timeout(const Duration(seconds: 30));

      return _handlePaymentResponse(response);
    } catch (e) {
      debugPrint('Payment Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Error: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  bool _isValidSomaliNumber(String phone) {
    final regex = RegExp(r'^252(61|62|65|66|67|68|69|71|77|79|90)\d{7}$');
    return regex.hasMatch(phone);
  }

  Future<bool> _handlePaymentResponse(http.Response response) async {
    debugPrint('Payment Response: ${response.statusCode}, ${response.body}');

    final responseData = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      if (responseData['responseCode'] == '200' || 
          responseData['responseMsg'] == 'RCS_SUCCESS') {
        
        try {
          await _savePaymentAndAppointment(
            transactionId: responseData['params']['transactionId'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
            orderId: responseData['params']['orderId'],
          );
          return true;
        } catch (e) {
          debugPrint('Error saving records: $e');
          return false;
        }
        
      } else {
        _showPaymentError(
          responseData['errorCode'] ?? 'UNKNOWN',
          responseData['responseMsg'] ?? 'Payment failed'
        );
        return false;
      }
    } else {
      _showPaymentError(
        'HTTP_${response.statusCode}',
        'Server error: ${response.statusCode}'
      );
      return false;
    }
  }

  Future<void> _savePaymentAndAppointment({
    required String transactionId,
    required String? orderId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final selectedSchedule = schedules[selectedScheduleIndex!];
    final userFullName = await _getUserFullName();
    final batch = FirebaseFirestore.instance.batch();

    // Payment Document
    final paymentRef = FirebaseFirestore.instance.collection('payments').doc();
    batch.set(paymentRef, {
      'userId': userId,
      'doctorId': widget.doctorId,
      'orderId': orderId,
      'transactionId': transactionId,
      'amount': 0.01,
      'currency': 'USD',
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
      'patientPhone': await _getUserPhoneNumber(),
      'doctorPhone': await _getDoctorPhoneNumber(),
      'fullName': userFullName,
      'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
    });

    // Appointment Document
    final appointmentRef = FirebaseFirestore.instance.collection('appointments').doc();
    batch.set(appointmentRef, {
      'doctorId': widget.doctorId,
      'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
      'userId': userId,
      'scheduleId': selectedSchedule['id'],
      'day': selectedSchedule['day'],
      'startTime': selectedSchedule['startTime'],
      'endTime': selectedSchedule['endTime'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'specialty': widget.doctorData['specialties'] ?? 'General',
      'fee': 0.01,
      'fullName': userFullName,
      'paymentStatus': 'completed',
      'paymentTransactionId': transactionId,
      'orderId': orderId,
    });

    await batch.commit();
  }

  Future<String> _getDoctorPhoneNumber() async {
    try {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .get();

      if (!doctorDoc.exists) {
        throw Exception('Doctor document not found');
      }

      final doctorPhone = doctorDoc.data()?['phone'] as String?;
      
      if (doctorPhone == null || doctorPhone.isEmpty) {
        throw Exception('Phone number not found in doctor document');
      }

      final cleanedPhone = doctorPhone.replaceAll(RegExp(r'[^0-9]'), '');

      if (!cleanedPhone.startsWith('252')) {
        throw Exception('Phone number must be in international format (252...)');
      }

      if (cleanedPhone.length != 12) {
        throw Exception('Invalid Somali phone number length');
      }

      return cleanedPhone;
    } catch (e) {
      debugPrint('Error getting doctor phone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting doctor phone: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  Future<String> _getUserPhoneNumber() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userPhone = userDoc.data()?['phone'] as String?;
      
      if (userPhone == null || userPhone.isEmpty) {
        throw Exception('Phone number not found in user document');
      }

      final cleanedPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');

      if (!cleanedPhone.startsWith('252')) {
        throw Exception('Please use international format (252...)');
      }

      if (cleanedPhone.length != 12) {
        throw Exception('Invalid phone number length');
      }

      return cleanedPhone;
    } catch (e) {
      debugPrint('Error getting user phone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting your phone: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  Future<String> _getUserFullName() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return 'unknown Patient';

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return 'unknown Patient';

      return userDoc.data()?['fullName'] ?? 
             'unknown Patient';
    } catch (e) {
      debugPrint('Error getting user full name: $e');
      return 'unknown Patient';
    }
  }

  String _translateErrorCode(String code, String defaultMsg) {
    switch (code) {
      case 'E10309':
        return 'Invalid account details. Please check your mobile wallet number and try again.';
      case 'E10308':
        return 'Insufficient funds in your mobile wallet.';
      case 'E10310':
        return 'Currency not supported. Please contact support.';
      case 'E10307':
        return 'Transaction limit exceeded. Try a smaller amount.';
      default:
        return '$defaultMsg (Error: $code)';
    }
  }

  Widget _buildDoctorInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: widget.doctorData['photoUrl'] != null
                  ? NetworkImage(widget.doctorData['photoUrl'])
                  : null,
              child: widget.doctorData['photoUrl'] == null
                  ? Text(
                      widget.doctorData['fullName']?.isNotEmpty == true
                          ? widget.doctorData['fullName'][0].toUpperCase()
                          : 'D',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.blue.shade900,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorData['fullName'] ?? 'Unknown Doctor',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fee: \$0.01 USD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.phone,
            color: Colors.green,
            label: 'Call',
            onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
          ),
          _buildActionButton(
            icon: Icons.message,
            color: Colors.blue,
            label: 'Message',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    doctorName: widget.doctorData['fullName'] ?? 'Doctor',
                    doctorId: widget.doctorId,
                  ),
                ),
              );
            },
          ),
          _buildActionButton(
            icon: Icons.location_on,
            color: Colors.red,
            label: 'Location',
            onPressed: () => showLocationDialog(
              widget.doctorData['address'] ?? 'Location not available',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 24, color: color),
            onPressed: onPressed,
            tooltip: label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (schedules.isEmpty) {
      return const Center(
        child: Text(
          'No available schedules',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final startTime = _parseFirestoreTimestamp(schedule['startTime']);
        final isSelected = selectedScheduleIndex == index;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isSelected ? Colors.blue.shade50 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              schedule['day'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue.shade800 : null,
              ),
            ),
            subtitle: Text(
              '${_formatAppointmentTime(schedule['startTime'])} - ${_formatAppointmentTime(schedule['endTime'])}',
              style: TextStyle(
                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () => _selectSchedule(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.grey : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                isSelected ? 'Selected' : 'Select',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            onTap: () => _selectSchedule(index),
          ),
        );
      },
    );
  }

  Widget _buildRequestButton() {
    return Column(
      children: [
        const Text(
          'Appointment Fee: \$0.01 USD',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Payment will be deducted from your mobile wallet',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isRequestingAppointment ? null : _requestAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isRequestingAppointment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Pay & Request Appointment',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment', 
               style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDoctorInfo(),
                        _buildActionButtons(),
                        const Divider(),
                        const Text(
                          'Available Schedules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildScheduleList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildRequestButton(),
                ),
              ],
            ),
    );
  }
}












// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:async';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final String scheduleId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//     required this.scheduleId,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//   bool hasExistingAppointment = false;
//   bool isRequestingAppointment = false;
//   late DateTime today;

//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//     _loadInitialData();
//   }

//   void _showPaymentError(String errorCode, String message) {
//     final userMessage = _translateErrorCode(errorCode, message);
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(userMessage),
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     }
//   }

//   DateTime _parseFirestoreTimestamp(dynamic timestamp) {
//     if (timestamp is Timestamp) {
//       return timestamp.toDate();
//     } else if (timestamp is DateTime) {
//       return timestamp;
//     } else {
//       throw Exception('Invalid timestamp format');
//     }
//   }

  
//   String _formatAppointmentDate(dynamic timestamp) {
//   final date = _parseFirestoreTimestamp(timestamp);
//   return DateFormat.yMMMd().format(date);
// }

//   String _formatAppointmentTime(dynamic timestamp) {
//     final time = _parseFirestoreTimestamp(timestamp);
//     return DateFormat('h:mm a').format(time);
//   }

//  Widget _buildScheduleTile(Map<String, dynamic> schedule) {
//   return ListTile(
//     title: Text(schedule['day']), // ✅ treat as String
//     subtitle: Text(
//       '${_formatAppointmentTime(schedule['startTime'])} - ${_formatAppointmentTime(schedule['endTime'])}',
//     ),
//   );
// }


//   Future<void> _loadInitialData() async {
//     await Future.wait([
//       _fetchSchedules(),
//       _checkExistingAppointments(),
//     ]);
//   }

//   Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending'])
//           .get();

//       if (mounted) {
//         setState(() {
//           hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error checking your existing appointments')),
//         );
//       }
//     }
//   }

//  Future<void> _fetchSchedules() async {
//   try {
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(widget.doctorId)
//         .collection('schedules')
//         .get();

//     // Halkan meesha filter-ka laga saaray — jadwalada oo dhan ayaa la keenayaa
//     final filteredSchedules = querySnapshot.docs
//         .map((doc) => {'id': doc.id, ...doc.data()})
//         .toList();

//     if (mounted) {
//       setState(() {
//         schedules = filteredSchedules;
//         isLoading = false;
//       });
//     }
//   } catch (e) {
//     debugPrint('Error loading schedules: $e');
//     if (mounted) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//       );
//     }
//   }
// }


//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         throw 'Could not launch dialer';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error making call: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clinic Location'),
//         content: SingleChildScrollView(
//           child: Text(address),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _openMaps(address),
//             child: const Text('Open in Maps'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openMaps(String address) async {
//     if (address.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Address is empty')),
//       );
//       return;
//     }

//     final encodedAddress = Uri.encodeComponent(address);
//     bool launched = false;

//     final urlAttempts = [
//       Uri.parse('geo:0,0?q=$encodedAddress'),
      
//       if (Theme.of(context).platform == TargetPlatform.iOS)
//         Uri.parse('http://maps.apple.com/?q=$encodedAddress')
//       else
//         Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress'),
      
//       Uri.parse('https://www.google.com/search?q=$encodedAddress'),
//     ];

//     for (final url in urlAttempts) {
//       try {
//         if (await canLaunchUrl(url)) {
//           await launchUrl(url, mode: LaunchMode.externalApplication);
//           launched = true;
//           break;
//         }
//       } catch (e) {
//         debugPrint('Failed to launch $url: $e');
//       }
//     }

//     if (!launched && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No application found to open maps')),
//       );
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (hasExistingAppointment) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You already have an appointment with this doctor')),
//       );
//       return;
//     }

//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = FirebaseAuth.instance.currentUser?.uid;
    
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You must be logged in')),
//       );
//       return;
//     }

//     setState(() {
//       isRequestingAppointment = true;
//     });

//     try {
//       final paymentSuccess = await _processPayment();
//       final userFullName = await _getUserFullName();
      
//       if (!paymentSuccess) {
//         if (mounted) {
//           setState(() {
//             isRequestingAppointment = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Payment failed. Please try again')));
//         }
//         return;
//       }

//       // await _savePaymentAndAppointment(
//       //   transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
//       //   orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
//       // );

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Appointment requested and payment completed successfully!',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint('Failed to request appointment: $e');
//       if (mounted) {
//         setState(() {
//           isRequestingAppointment = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to complete request: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<bool> _processPayment() async {
//     try {
//       final doctorPhoneNumber = await _getDoctorPhoneNumber();
//       final userPhoneNumber = await _getUserPhoneNumber();
//       final userFullName = await _getUserFullName();

//       if (userPhoneNumber.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('User phone number not found')),
//           );
//         }
//         return false;
//       }

//       if (!_isValidSomaliNumber(userPhoneNumber)) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please use a valid Somali mobile number')),
//           );
//         }
//         return false;
//       }

//       var paymentRequest = { 
//         "schemaVersion": "1.0", 
//         "requestId": DateTime.now().millisecondsSinceEpoch.toString(),
//         "timestamp": DateTime.now().toIso8601String(),
//         "channelName": "WEB", 
//         "serviceName": "API_PURCHASE", 
//         "serviceParams": { 
//           "merchantUid": "M0910291", 
//           "apiUserId": "1000416",  
//           "apiKey": "API-675418888AHX", 
//           "paymentMethod": "mwallet_account", 
//           "payerInfo": { 
//             "accountNo": userPhoneNumber, 
//             "accountName": userFullName,
//           }, 
//           "transactionInfo": { 
//             "referenceId": "APP_${DateTime.now().millisecondsSinceEpoch}",
//             "invoiceId": "INV_${DateTime.now().millisecondsSinceEpoch}",
//             "amount": 0.01,  
//             "currency": "USD", 
//             "description": "Doctor Appointment Fee",
//             "recipientInfo": {
//               "accountNo": doctorPhoneNumber, 
//               "accountType": "mwallet_account", 
//               "accountName": widget.doctorData['fullName'] ?? 'Unknown Doctor',
//             },
//           }, 
//         } 
//       };

//       debugPrint('Payment Request: ${jsonEncode(paymentRequest)}');

//       final response = await http.post(
//         Uri.parse('https://api.waafipay.net/asm'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(paymentRequest),
//       ).timeout(const Duration(seconds: 30));

//       return _handlePaymentResponse(response);
//     } catch (e) {
//       debugPrint('Payment Error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Payment Error: ${e.toString()}')),
//         );
//       }
//       return false;
//     }
//   }

//   bool _isValidSomaliNumber(String phone) {
//     final regex = RegExp(r'^252(61|62|65|66|67|68|69|71|77|79|90)\d{7}$');
//     return regex.hasMatch(phone);
//   }

//   Future<bool> _handlePaymentResponse(http.Response response) async {
//     debugPrint('Payment Response: ${response.statusCode}, ${response.body}');

//     final responseData = jsonDecode(response.body);
    
//     if (response.statusCode == 200) {
//       if (responseData['responseCode'] == '200' || 
//           responseData['responseMsg'] == 'RCS_SUCCESS') {
        
//         try {
//           await _savePaymentAndAppointment(
//             transactionId: responseData['params']['transactionId'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
//             orderId: responseData['params']['orderId'],
//           );
//           return true;
//         } catch (e) {
//           debugPrint('Error saving records: $e');
//           return false;
//         }
        
//       } else {
//         _showPaymentError(
//           responseData['errorCode'] ?? 'UNKNOWN',
//           responseData['responseMsg'] ?? 'Payment failed'
//         );
//         return false;
//       }
//     } else {
//       _showPaymentError(
//         'HTTP_${response.statusCode}',
//         'Server error: ${response.statusCode}'
//       );
//       return false;
//     }
//   }

//   Future<void> _savePaymentAndAppointment({
//     required String transactionId,
//     required String? orderId,
//   }) async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) throw Exception('User not logged in');

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userFullName = await _getUserFullName();
//     final batch = FirebaseFirestore.instance.batch();

//     // Payment Document
//     final paymentRef = FirebaseFirestore.instance.collection('payments').doc();
//     batch.set(paymentRef, {
//       'userId': userId,
//       'doctorId': widget.doctorId,
//       'orderId': orderId,
//       'transactionId': transactionId,
//       'amount': 0.01,
//       'currency': 'USD',
//       'status': 'completed',
//       'createdAt': FieldValue.serverTimestamp(),
//       'patientPhone': await _getUserPhoneNumber(),
//       'doctorPhone': await _getDoctorPhoneNumber(),
//       'fullName': userFullName,
//       'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//     });

//     // Appointment Document
//     final appointmentRef = FirebaseFirestore.instance.collection('appointments').doc();
//     batch.set(appointmentRef, {
//       'doctorId': widget.doctorId,
//       'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//       'userId': userId,
//       'scheduleId': selectedSchedule['id'],
//       'day': selectedSchedule['day'],
//       'startTime': selectedSchedule['startTime'],
//       'endTime': selectedSchedule['endTime'],
//       'status': 'pending',
//       'createdAt': FieldValue.serverTimestamp(),
//       'specialty': widget.doctorData['specialties'] ?? 'General',
//       'fee': 0.01,
//       'fullName': userFullName,
//       'paymentStatus': 'completed',
//       'paymentTransactionId': transactionId,
//       'orderId': orderId,
//     });

//     await batch.commit();
//   }

//   Future<String> _getDoctorPhoneNumber() async {
//     try {
//       final doctorDoc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .get();

//       if (!doctorDoc.exists) {
//         throw Exception('Doctor document not found');
//       }

//       final doctorPhone = doctorDoc.data()?['phone'] as String?;
      
//       if (doctorPhone == null || doctorPhone.isEmpty) {
//         throw Exception('Phone number not found in doctor document');
//       }

//       final cleanedPhone = doctorPhone.replaceAll(RegExp(r'[^0-9]'), '');

//       if (!cleanedPhone.startsWith('252')) {
//         throw Exception('Phone number must be in international format (252...)');
//       }

//       if (cleanedPhone.length != 12) {
//         throw Exception('Invalid Somali phone number length');
//       }

//       return cleanedPhone;
//     } catch (e) {
//       debugPrint('Error getting doctor phone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error getting doctor phone: ${e.toString()}')),
//         );
//       }
//       rethrow;
//     }
//   }

//   Future<String> _getUserPhoneNumber() async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) {
//         throw Exception('User not authenticated');
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .get();

//       if (!userDoc.exists) {
//         throw Exception('User document not found');
//       }

//       final userPhone = userDoc.data()?['phone'] as String?;
      
//       if (userPhone == null || userPhone.isEmpty) {
//         throw Exception('Phone number not found in user document');
//       }

//       final cleanedPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');

//       if (!cleanedPhone.startsWith('252')) {
//         throw Exception('Please use international format (252...)');
//       }

//       if (cleanedPhone.length != 12) {
//         throw Exception('Invalid phone number length');
//       }

//       return cleanedPhone;
//     } catch (e) {
//       debugPrint('Error getting user phone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error getting your phone: ${e.toString()}')),
//         );
//       }
//       rethrow;
//     }
//   }

//   Future<String> _getUserFullName() async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) return 'unknown Patient';

//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .get();

//       if (!userDoc.exists) return 'unknown Patient';

//       return userDoc.data()?['fullName'] ?? 
//              'unknown Patient';
//     } catch (e) {
//       debugPrint('Error getting user full name: $e');
//       return 'unknown Patient';
//     }
//   }

//   String _translateErrorCode(String code, String defaultMsg) {
//     switch (code) {
//       case 'E10309':
//         return 'Invalid account details. Please check your mobile wallet number and try again.';
//       case 'E10308':
//         return 'Insufficient funds in your mobile wallet.';
//       case 'E10310':
//         return 'Currency not supported. Please contact support.';
//       case 'E10307':
//         return 'Transaction limit exceeded. Try a smaller amount.';
//       default:
//         return '$defaultMsg (Error: $code)';
//     }
//   }

//   Widget _buildDoctorInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.blue.shade900,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Fee: \$0.01 USD',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
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

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildActionButton(
//             icon: Icons.phone,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//           ),
//           _buildActionButton(
//             icon: Icons.message,
//             color: Colors.blue,
//             label: 'Message',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                     doctorId: widget.doctorId,
//                   ),
//                 ),
//               );
//             },
//           ),
//           _buildActionButton(
//             icon: Icons.location_on,
//             color: Colors.red,
//             label: 'Location',
//             onPressed: () => showLocationDialog(
//               widget.doctorData['address'] ?? 'Location not available',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             icon: Icon(icon, size: 24, color: color),
//             onPressed: onPressed,
//             tooltip: label,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleList() {
//   if (isLoading) {
//     return const Center(child: CircularProgressIndicator());
//   }

//   if (schedules.isEmpty) {
//     return const Center(
//       child: Text(
//         'No available schedules',
//         style: TextStyle(color: Colors.grey),
//       ),
//     );
//   }

//   return ListView.builder(
//     shrinkWrap: true,
//     physics: const NeverScrollableScrollPhysics(),
//     itemCount: schedules.length,
//     itemBuilder: (context, index) {
//       final schedule = schedules[index];
//       final startTime = _parseFirestoreTimestamp(schedule['startTime']);
//       final isSelected = selectedScheduleIndex == index;

//       return Card(
//        margin: const EdgeInsets.symmetric(vertical: 4),
//         color: isSelected ? Colors.blue.shade50 : null,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//           side: BorderSide(
//             color: isSelected ? Colors.blue : Colors.grey.shade300,
//             width: isSelected ? 1.5 : 0.5,
//           ),
//         ),
//         child: ListTile(
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 8,
//           ),
//           title: Text(
//             schedule['day'], // ✅ just show the day string like "Monday"
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: isSelected ? Colors.blue.shade800 : null,
//             ),
//           ),
//           subtitle: Text(
//             '${_formatAppointmentTime(schedule['startTime'])} - ${_formatAppointmentTime(schedule['endTime'])}',
//             style: TextStyle(
//               color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
//             ),
//           ),
//           trailing: ElevatedButton(
//             onPressed: () => _selectSchedule(index),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isSelected ? Colors.grey : Colors.blue,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             child: Text(
//               isSelected ? 'Selected' : 'Select',
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//           onTap: () => _selectSchedule(index),
//         ),
//       );
//     },
//   );
// }

//   Widget _buildRequestButton() {
//     return Column(
//       children: [
//         const Text(
//           'Appointment Fee: \$0.01 USD',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.green,
//           ),
//         ),
//         const SizedBox(height: 8),
//         const Text(
//           'Payment will be deducted from your mobile wallet',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: isRequestingAppointment ? null : _requestAppointment,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade800,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: isRequestingAppointment
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   )
//                 : const Text(
//                     'Pay & Request Appointment',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildDoctorInfo(),
//                         _buildActionButtons(),
//                         const Divider(),
//                         const Text(
//                           'Available Schedules',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildScheduleList(),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: _buildRequestButton(),
//                 ),
//               ],
//             ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:async';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//   bool hasExistingAppointment = false;
//   bool isRequestingAppointment = false;
//   late DateTime today;

//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//     _loadInitialData();
//   }

//   void _showPaymentError(String errorCode, String message) {
//     final userMessage = _translateErrorCode(errorCode, message);
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(userMessage),
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     }
//   }

//   DateTime _parseFirestoreTimestamp(dynamic timestamp) {
//     if (timestamp is Timestamp) {
//       return timestamp.toDate();
//     } else if (timestamp is DateTime) {
//       return timestamp;
//     } else {
//       throw Exception('Invalid timestamp format');
//     }
//   }

//   String _formatAppointmentDate(dynamic timestamp) {
//     final date = _parseFirestoreTimestamp(timestamp);
//     return DateFormat('EEE, MMM d, y').format(date);
//   }

//   String _formatAppointmentTime(dynamic timestamp) {
//     final time = _parseFirestoreTimestamp(timestamp);
//     return DateFormat('h:mm a').format(time);
//   }

//   Widget _buildScheduleTile(Map<String, dynamic> schedule) {
//     return ListTile(
//       title: Text(_formatAppointmentDate(schedule['day'])),
//       subtitle: Text(
//         '${_formatAppointmentTime(schedule['startTime'])} - ${_formatAppointmentTime(schedule['endTime'])}',
//       ),
//     );
//   }

//   Future<void> _loadInitialData() async {
//     await Future.wait([
//       _fetchSchedules(),
//       _checkExistingAppointments(),
//     ]);
//   }

//   Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending'])
//           .get();

//       if (mounted) {
//         setState(() {
//           hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error checking your existing appointments')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       final filteredSchedules = querySnapshot.docs
//           .map((doc) => {'id': doc.id, ...doc.data()})
//           .where((schedule) {
//             final dayName = schedule['day'] as String? ?? 'Unknown Day';
//             return scheduleDate.isAfter(today) || 
//                    _isSameDay(scheduleDate, today);
                   
//           })
//           .toList();

//       if (mounted) {
//         setState(() {
//           schedules = filteredSchedules;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading schedules: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   bool _isSameDay(DateTime a, DateTime b) {
//     return a.year == b.year && a.month == b.month && a.day == b.day;
//   }

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         throw 'Could not launch dialer';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error making call: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clinic Location'),
//         content: SingleChildScrollView(
//           child: Text(address),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _openMaps(address),
//             child: const Text('Open in Maps'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openMaps(String address) async {
//     if (address.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Address is empty')),
//       );
//       return;
//     }

//     final encodedAddress = Uri.encodeComponent(address);
//     bool launched = false;

//     final urlAttempts = [
//       Uri.parse('geo:0,0?q=$encodedAddress'),
      
//       if (Theme.of(context).platform == TargetPlatform.iOS)
//         Uri.parse('http://maps.apple.com/?q=$encodedAddress')
//       else
//         Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress'),
      
//       Uri.parse('https://www.google.com/search?q=$encodedAddress'),
//     ];

//     for (final url in urlAttempts) {
//       try {
//         if (await canLaunchUrl(url)) {
//           await launchUrl(url, mode: LaunchMode.externalApplication);
//           launched = true;
//           break;
//         }
//       } catch (e) {
//         debugPrint('Failed to launch $url: $e');
//       }
//     }

//     if (!launched && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No application found to open maps')),
//       );
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (hasExistingAppointment) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You already have an appointment with this doctor')),
//       );
//       return;
//     }

//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = FirebaseAuth.instance.currentUser?.uid;
    
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You must be logged in')),
//       );
//       return;
//     }

//     setState(() {
//       isRequestingAppointment = true;
//     });

//     try {
//       final paymentSuccess = await _processPayment();
//        final userFullName = await _getUserFullName();
      
//       if (!paymentSuccess) {
//         if (mounted) {
//           setState(() {
//             isRequestingAppointment = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Payment failed. Please try again')));
//         }
//         return;
//       }

//       // await FirebaseFirestore.instance.collection('appointments').add({
//       //   'doctorId': widget.doctorId,
//       //   'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//       //   'userId': userId,
//       //   'scheduleId': selectedSchedule['id'],
//       //   'date': selectedSchedule['date'],
//       //   'startTime': selectedSchedule['startTime'],
//       //   'endTime': selectedSchedule['endTime'],
//       //   'status': 'pending',
//       //   'createdAt': FieldValue.serverTimestamp(),
//       //   'specialty': widget.doctorData['specialties'] ?? 'General',
//       //   'fee': 0.01,
//       //   'fullName': userFullName,
//       //   'paymentStatus': 'completed',
//       // });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Appointment requested and payment completed successfully!',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint('Failed to request appointment: $e');
//       if (mounted) {
//         setState(() {
//           isRequestingAppointment = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to complete request: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<bool> _processPayment() async {
//     try {
//       final doctorPhoneNumber = await _getDoctorPhoneNumber();
//       final userPhoneNumber = await _getUserPhoneNumber();
//       // final userFullName = await __getUserFullName();

//       if (userPhoneNumber.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('User phone number not found')),
//           );
//         }
//         return false;
//       }

//       if (!_isValidSomaliNumber(userPhoneNumber)) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please use a valid Somali mobile number')),
//           );
//         }
//         return false;
//       }

//       var paymentRequest = { 
//         "schemaVersion": "1.0", 
//         "requestId": DateTime.now().millisecondsSinceEpoch.toString(),
//         "timestamp": DateTime.now().toIso8601String(),
//         "channelName": "WEB", 
//         "serviceName": "API_PURCHASE", 
//         "serviceParams": { 
//           "merchantUid": "M0910291", 
//           "apiUserId": "1000416",  
//           "apiKey": "API-675418888AHX", 
//           "paymentMethod": "mwallet_account", 
//           "payerInfo": { 
//             "accountNo": userPhoneNumber, 
//             // "accountName": userFullName,
//           }, 
//           "transactionInfo": { 
//             "referenceId": "APP_${DateTime.now().millisecondsSinceEpoch}",
//             "invoiceId": "INV_${DateTime.now().millisecondsSinceEpoch}",
//             "amount": 0.01,  
//             "currency": "USD", 
//             "description": "Doctor Appointment Fee",
//             "recipientInfo": {
//               "accountNo": doctorPhoneNumber, 
//               "accountType": "mwallet_account", 
//               "accountName": widget.doctorData['fullName'] ?? 'Unknown Doctor',
//             },
//           }, 
//         } 
//       };

//       debugPrint('Payment Request: ${jsonEncode(paymentRequest)}');

//       final response = await http.post(
//         Uri.parse('https://api.waafipay.net/asm'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(paymentRequest),
//       ).timeout(const Duration(seconds: 30));

//       return _handlePaymentResponse(response);
//     } catch (e) {
//       debugPrint('Payment Error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Payment Error: ${e.toString()}')),
//         );
//       }
//       return false;
//     }
//   }

//   bool _isValidSomaliNumber(String phone) {
//     final regex = RegExp(r'^252(61|62|65|66|67|68|69|71|77|79|90)\d{7}$');
//     return regex.hasMatch(phone);
//   }

//   Future<bool> _handlePaymentResponse(http.Response response) async {
//     debugPrint('Payment Response: ${response.statusCode}, ${response.body}');

//     final responseData = jsonDecode(response.body);
    
//     if (response.statusCode == 200) {
//       if (responseData['responseCode'] == '200' || 
//           responseData['responseMsg'] == 'RCS_SUCCESS') {
        
//         try {
//           await _savePaymentAndAppointment(
//             transactionId: responseData['params']['transactionId'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
//             orderId: responseData['params']['orderId'],
//           );
//           return true;
//         } catch (e) {
//           debugPrint('Error saving records: $e');
//           return false;
//         }
        
//       } else {
//         _showPaymentError(
//           responseData['errorCode'] ?? 'UNKNOWN',
//           responseData['responseMsg'] ?? 'Payment failed'
//         );
//         return false;
//       }
//     } else {
//       _showPaymentError(
//         'HTTP_${response.statusCode}',
//         'Server error: ${response.statusCode}'
//       );
//       return false;
//     }
//   }

//   Future<void> _savePaymentAndAppointment({
//     required String transactionId,
//     required String? orderId,
//   }) async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) throw Exception('User not logged in');

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//      final userFullName = await _getUserFullName();
//     final batch = FirebaseFirestore.instance.batch();

//     // Payment Document
//     final paymentRef = FirebaseFirestore.instance.collection('payments').doc();
//     batch.set(paymentRef, {
//       'userId': userId,
//       'doctorId': widget.doctorId,
//       'orderId': orderId,
//       'transactionId': transactionId,
//       'amount': 0.01,
//       'currency': 'USD',
//       'status': 'completed',
//       'createdAt': FieldValue.serverTimestamp(),
//       'patientPhone': await _getUserPhoneNumber(),
//       'doctorPhone': await _getDoctorPhoneNumber(),
//       'fullName': userFullName,
//       'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//     });

//     // Appointment Document
//     final appointmentRef = FirebaseFirestore.instance.collection('appointments').doc();
//     batch.set(appointmentRef, {
//       'doctorId': widget.doctorId,
//       'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//       'userId': userId,
//       'scheduleId': selectedSchedule['id'],
//       'date': selectedSchedule['date'],
//       'startTime': selectedSchedule['startTime'],
//       'endTime': selectedSchedule['endTime'],
//       'status': 'pending',
//       'createdAt': FieldValue.serverTimestamp(),
//       'specialty': widget.doctorData['specialties'] ?? 'General',
//       'fee': 0.01,
//       'fullName': userFullName,
//       'paymentStatus': 'completed',
//       'paymentTransactionId': transactionId,
//       'orderId': orderId,
//     });

//     await batch.commit();
//   }

//   Future<String> _getDoctorPhoneNumber() async {
//     try {
//       final doctorDoc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .get();

//       if (!doctorDoc.exists) {
//         throw Exception('Doctor document not found');
//       }

//       final doctorPhone = doctorDoc.data()?['phone'] as String?;
      
//       if (doctorPhone == null || doctorPhone.isEmpty) {
//         throw Exception('Phone number not found in doctor document');
//       }

//       final cleanedPhone = doctorPhone.replaceAll(RegExp(r'[^0-9]'), '');

//       if (!cleanedPhone.startsWith('252')) {
//         throw Exception('Phone number must be in international format (252...)');
//       }

//       if (cleanedPhone.length != 12) {
//         throw Exception('Invalid Somali phone number length');
//       }

//       return cleanedPhone;
//     } catch (e) {
//       debugPrint('Error getting doctor phone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error getting doctor phone: ${e.toString()}')),
//         );
//       }
//       rethrow;
//     }
//   }

//   Future<String> _getUserPhoneNumber() async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) {
//         throw Exception('User not authenticated');
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .get();

//       if (!userDoc.exists) {
//         throw Exception('User document not found');
//       }

//       final userPhone = userDoc.data()?['phone'] as String?;
      
//       if (userPhone == null || userPhone.isEmpty) {
//         throw Exception('Phone number not found in user document');
//       }

//       final cleanedPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');

//       if (!cleanedPhone.startsWith('252')) {
//         throw Exception('Please use international format (252...)');
//       }

//       if (cleanedPhone.length != 12) {
//         throw Exception('Invalid phone number length');
//       }

//       return cleanedPhone;
//     } catch (e) {
//       debugPrint('Error getting user phone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error getting your phone: ${e.toString()}')),
//         );
//       }
//       rethrow;
//     }
//   }
//   Future<String> _getUserFullName() async {
//   try {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return 'unknown Patient';

//     final userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .get();

//     if (!userDoc.exists) return 'unknown Patient';

//     return userDoc.data()?['fullName'] ?? 
//            'unknown Patient';
//   } catch (e) {
//     debugPrint('Error getting user full name: $e');
//     return 'unknown Patient';
//   }
// }

//   String _translateErrorCode(String code, String defaultMsg) {
//     switch (code) {
//       case 'E10309':
//         return 'Invalid account details. Please check your mobile wallet number and try again.';
//       case 'E10308':
//         return 'Insufficient funds in your mobile wallet.';
//       case 'E10310':
//         return 'Currency not supported. Please contact support.';
//       case 'E10307':
//         return 'Transaction limit exceeded. Try a smaller amount.';
//       default:
//         return '$defaultMsg (Error: $code)';
//     }
//   }

//   Widget _buildDoctorInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.blue.shade900,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Fee: \$0.01 USD',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
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

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildActionButton(
//             icon: Icons.phone,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//           ),
//           _buildActionButton(
//             icon: Icons.message,
//             color: Colors.blue,
//             label: 'Message',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                     doctorId: widget.doctorId,
//                   ),
//                 ),
//               );
//             },
//           ),
//           _buildActionButton(
//             icon: Icons.location_on,
//             color: Colors.red,
//             label: 'Location',
//             onPressed: () => showLocationDialog(
//               widget.doctorData['address'] ?? 'Location not available',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             icon: Icon(icon, size: 24, color: color),
//             onPressed: onPressed,
//             tooltip: label,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleList() {
//     if (isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (schedules.isEmpty) {
//       return const Center(
//         child: Text(
//           'No available schedules',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: schedules.length,
//       itemBuilder: (context, index) {
//         final schedule = schedules[index];
//         final scheduleDate = (schedule['date'] as Timestamp).toDate();
//         final isSelected = selectedScheduleIndex == index;
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           color: isSelected ? Colors.blue.shade50 : null,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(
//               color: isSelected ? Colors.blue : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 0.5,
//             ),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             title: Text(
//               _formatDate(schedule['day']),
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? Colors.blue.shade800 : null,
//               ),
//             ),
//             subtitle: Text(
//               '${_formatTime(schedule['startTime'])} - ${_formatTime(schedule['endTime'])}',
//               style: TextStyle(
//                 color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
//               ),
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _selectSchedule(index),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 isSelected ? 'Selected' : 'Select',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             onTap: () => _selectSchedule(index),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRequestButton() {
//     return Column(
//       children: [
//         const Text(
//           'Appointment Fee: \$0.01 USD',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.green,
//           ),
//         ),
//         const SizedBox(height: 8),
//         const Text(
//           'Payment will be deducted from your mobile wallet',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: isRequestingAppointment ? null : _requestAppointment,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade800,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: isRequestingAppointment
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   )
//                 : const Text(
//                     'Pay & Request Appointment',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildDoctorInfo(),
//                         _buildActionButtons(),
//                         const Divider(),
//                         const Text(
//                           'Available Schedules',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildScheduleList(),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: _buildRequestButton(),
//                 ),
//               ],
//             ),
//     );
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:async';


// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
  
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//   bool hasExistingAppointment = false;
//   bool isRequestingAppointment = false;
//   late DateTime today;
  

//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//     _loadInitialData();
//   }
//   void _showPaymentError(String errorCode, String message) {
//   final userMessage = _translateErrorCode(errorCode, message);
  
//   if (mounted) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(userMessage),
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }
// }

// // Add these helper methods
// DateTime _parseFirestoreTimestamp(dynamic timestamp) {
//   if (timestamp is Timestamp) {
//     return timestamp.toDate();
//   } else if (timestamp is DateTime) {
//     return timestamp;
//   } else {
//     throw Exception('Invalid timestamp format');
//   }
// }

// String _formatAppointmentDate(dynamic timestamp) {
//   final date = _parseFirestoreTimestamp(timestamp);
//   return DateFormat('EEE, MMM d, y').format(date);
// }

// String _formatAppointmentTime(dynamic timestamp) {
//   final time = _parseFirestoreTimestamp(timestamp);
//   return DateFormat('h:mm a').format(time);
// }


// ListTile(
//   title: Text(_formatAppointmentDate(schedule['date'])),
//   subtitle: Text(
//     '${_formatAppointmentTime(schedule['startTime'])} - ${_formatAppointmentTime(schedule['endTime'])}',
//   ),
//   // ... rest of your ListTile code
// )
//   Future<void> _loadInitialData() async {
//     await Future.wait([
//       _fetchSchedules(),
//       _checkExistingAppointments(),
//     ]);
//   }

//   Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending'])
//           .get();

//       if (mounted) {
//         setState(() {
//           hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error checking your existing appointments')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
//           .orderBy('date', descending: false)
//           .get();

//       // Additional filtering to ensure no past dates
//       final filteredSchedules = querySnapshot.docs
//           .map((doc) => {'id': doc.id, ...doc.data()})
//           .where((schedule) {
//             final scheduleDate = (schedule['date'] as Timestamp).toDate();
//             return scheduleDate.isAfter(today) || 
//                    _isSameDay(scheduleDate, today);
//           })
//           .toList();

//       if (mounted) {
//         setState(() {
//           schedules = filteredSchedules;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading schedules: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   bool _isSameDay(DateTime a, DateTime b) {
//     return a.year == b.year && a.month == b.month && a.day == b.day;
//   }

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         throw 'Could not launch dialer';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error making call: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clinic Location'),
//         content: SingleChildScrollView(
//           child: Text(address),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _openMaps(address),
//             child: const Text('Open in Maps'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openMaps(String address) async {
//     if (address.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Address is empty')),
//       );
//       return;
//     }

//     final encodedAddress = Uri.encodeComponent(address);
//     bool launched = false;

//     final urlAttempts = [
//       Uri.parse('geo:0,0?q=$encodedAddress'),
      
//       if (Theme.of(context).platform == TargetPlatform.iOS)
//         Uri.parse('http://maps.apple.com/?q=$encodedAddress')
//       else
//         Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress'),
      
//       Uri.parse('https://www.google.com/search?q=$encodedAddress'),
//     ];

//     for (final url in urlAttempts) {
//       try {
//         if (await canLaunchUrl(url)) {
//           await launchUrl(url, mode: LaunchMode.externalApplication);
//           launched = true;
//           break;
//         }
//       } catch (e) {
//         debugPrint('Failed to launch $url: $e');
//       }
//     }

//     if (!launched && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No application found to open maps')),
//       );
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (hasExistingAppointment) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You already have an appointment with this doctor')),
//       );
//       return;
//     }

//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = FirebaseAuth.instance.currentUser?.uid;
    
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You must be logged in')),
//       );
//       return;
//     }

//     setState(() {
//       isRequestingAppointment = true;
//     });

//     try {
//       final paymentSuccess = await _processPayment();
      
//       if (!paymentSuccess) {
//         if (mounted) {
//           setState(() {
//             isRequestingAppointment = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Payment failed. Please try again')));
//         }
//         return;
//       }

//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'] ?? 'General',
//         'fee': 0.01,
//         'fullName': FirebaseAuth.instance.currentUser?.displayName ?? 'unknown Patient',
//         'paymentStatus': 'completed',
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Appointment requested and payment completed successfully!',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint('Failed to request appointment: $e');
//       if (mounted) {
//         setState(() {
//           isRequestingAppointment = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to complete request: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<bool> _processPayment() async {
//     try {
//       final doctorPhoneNumber = await _getDoctorPhoneNumber();
//       final userPhoneNumber = await _getUserPhoneNumber();

//       if (userPhoneNumber.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('User phone number not found')),
//           );
//         }
//         return false;
//       }

//       if (!_isValidSomaliNumber(userPhoneNumber)) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please use a valid Somali mobile number')),
//           );
//         }
//         return false;
//       }

//       var paymentRequest = { 
//         "schemaVersion": "1.0", 
//         "requestId": DateTime.now().millisecondsSinceEpoch.toString(),
//         "timestamp": DateTime.now().toIso8601String(),
//         "channelName": "WEB", 
//         "serviceName": "API_PURCHASE", 
//         "serviceParams": { 
//           "merchantUid": "M0910291", 
//           "apiUserId": "1000416",  
//           "apiKey": "API-675418888AHX", 
//           "paymentMethod": "mwallet_account", 
//           "payerInfo": { 
//             "accountNo": userPhoneNumber, 
//             "accountName": FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown Patient'
//           }, 
//           "transactionInfo": { 
//             "referenceId": "APP_${DateTime.now().millisecondsSinceEpoch}",
//             "invoiceId": "INV_${DateTime.now().millisecondsSinceEpoch}",
//             "amount": 0.01,  
//             "currency": "USD", 
//             "description": "Doctor Appointment Fee",
//             "recipientInfo": {
//               "accountNo": doctorPhoneNumber, 
//               "accountType": "mwallet_account", 
//               "accountName": widget.doctorData['fullName'] ?? 'Unknown Doctor',
//             },
//           }, 
//         } 
//       };

//       debugPrint('Payment Request: ${jsonEncode(paymentRequest)}');

//       final response = await http.post(
//         Uri.parse('https://api.waafipay.net/asm'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(paymentRequest),
//       ).timeout(const Duration(seconds: 30));

//       return _handlePaymentResponse(response);
//     } catch (e) {
//       debugPrint('Payment Error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Payment Error: ${e.toString()}')),
//         );
//       }
//       return false;
//     }
//   }

//   bool _isValidSomaliNumber(String phone) {
//     final regex = RegExp(r'^252(61|62|65|66|67|68|69|71|77|79|90)\d{7}$');
//     return regex.hasMatch(phone);
//   }

//  Future<bool> _handlePaymentResponse(http.Response response) async {
//   debugPrint('Payment Response: ${response.statusCode}, ${response.body}');

//   final responseData = jsonDecode(response.body);
  
//   if (response.statusCode == 200) {
//     if (responseData['responseCode'] == '200' || 
//         responseData['responseMsg'] == 'RCS_SUCCESS') {
      
//       // Save to both collections with proper error handling
//       try {
//         await _savePaymentAndAppointment(
//           transactionId: responseData['params']['transactionId'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
//           orderId: responseData['params']['orderId'],
//         );
//         return true;
//       } catch (e) {
//         debugPrint('Error saving records: $e');
//         return false;
//       }
      
//     } else {
//       _showPaymentError(
//         responseData['errorCode'] ?? 'UNKNOWN',
//         responseData['responseMsg'] ?? 'Payment failed'
//       );
//       return false;
//     }
//   } else {
//     _showPaymentError(
//       'HTTP_${response.statusCode}',
//       'Server error: ${response.statusCode}'
//     );
//     return false;
//   }
// }

// Future<void> _savePaymentAndAppointment({
//   required String transactionId,
//   required String orderId,
// }) async {
//   final userId = FirebaseAuth.instance.currentUser?.uid;
//   if (userId == null) throw Exception('User not logged in');

//   final selectedSchedule = schedules[selectedScheduleIndex!];
//   final batch = FirebaseFirestore.instance.batch();

//   // Payment Document
//   final paymentRef = FirebaseFirestore.instance.collection('payments').doc(transactionId);
//   batch.set(paymentRef, {
//     'userId': userId,
//     'doctorId': widget.doctorId,
//     'orderId': orderId,
//     'transactionId': transactionId,
//     'amount': 0.01,
//     'currency': 'USD',
//     'status': 'completed',
//     'timestamp': FieldValue.serverTimestamp(),
//     'patientPhone': await _getUserPhoneNumber(),
//     'doctorPhone': await _getDoctorPhoneNumber(),
//   });

//   // Appointment Document
//   final appointmentRef = FirebaseFirestore.instance.collection('appointments').doc();
//   batch.set(appointmentRef, {
//     'doctorId': widget.doctorId,
//     'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//     'userId': userId,
//     'scheduleId': selectedSchedule['id'],
//     'date': selectedSchedule['date'],
//     'startTime': selectedSchedule['startTime'],
//     'endTime': selectedSchedule['endTime'],
//     'status': 'pending',
//     'createdAt': FieldValue.serverTimestamp(),
//     'specialty': widget.doctorData['specialties'] ?? 'General',
//     'fee': 0.01,
//     'fullName': FirebaseAuth.instance.currentUser?.displayName ?? 'unknown Patient',
//     'paymentStatus': 'completed',
//     'paymentTransactionId': transactionId,
//     'orderId': orderId,
//   });
//     } catch (e) {
//       debugPrint('Error saving payment record: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Payment successful but record saving failed')),
//         );
//       }
//     }
//   }

//   Future<String> _getDoctorPhoneNumber() async {
//     try {
//       final doctorDoc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .get();

//       if (!doctorDoc.exists) {
//         throw Exception('Doctor document not found');
//       }

//       final doctorPhone = doctorDoc.data()?['phone'] as String?;
      
//       if (doctorPhone == null || doctorPhone.isEmpty) {
//         throw Exception('Phone number not found in doctor document');
//       }

//       final cleanedPhone = doctorPhone.replaceAll(RegExp(r'[^0-9]'), '');

//       if (!cleanedPhone.startsWith('252')) {
//         throw Exception('Phone number must be in international format (252...)');
//       }

//       if (cleanedPhone.length != 12) {
//         throw Exception('Invalid Somali phone number length');
//       }

//       return cleanedPhone;
//     } catch (e) {
//       debugPrint('Error getting doctor phone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error getting doctor phone: ${e.toString()}')),
//         );
//       }
//       rethrow;
//     }
//   }

//   Future<String> _getUserPhoneNumber() async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) {
//         throw Exception('User not authenticated');
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .get();

//       if (!userDoc.exists) {
//         throw Exception('User document not found');
//       }

//       final userPhone = userDoc.data()?['phone'] as String?;
      
//       if (userPhone == null || userPhone.isEmpty) {
//         throw Exception('Phone number not found in user document');
//       }

//       final cleanedPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');

//       if (!cleanedPhone.startsWith('252')) {
//         throw Exception('Please use international format (252...)');
//       }

//       if (cleanedPhone.length != 12) {
//         throw Exception('Invalid phone number length');
//       }

//       return cleanedPhone;
//     } catch (e) {
//       debugPrint('Error getting user phone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error getting your phone: ${e.toString()}')),
//         );
//       }
//       rethrow;
//     }
//   }

//  String _translateErrorCode(String code, String defaultMsg) {
//   switch (code) {
//     case 'E10309':
//       return 'Invalid account details. Please check your mobile wallet number and try again.';
//     case 'E10308':
//       return 'Insufficient funds in your mobile wallet.';
//     case 'E10310':
//       return 'Currency not supported. Please contact support.';
//     case 'E10307':
//       return 'Transaction limit exceeded. Try a smaller amount.';
//     default:
//       return '$defaultMsg (Error: $code)';
//   }
// }

//   Widget _buildDoctorInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.blue.shade900,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Fee: \$0.01 USD',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
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

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildActionButton(
//             icon: Icons.phone,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//           ),
//           _buildActionButton(
//             icon: Icons.message,
//             color: Colors.blue,
//             label: 'Message',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                     doctorId: widget.doctorId,
//                   ),
//                 ),
//               );
//             },
//           ),
//           _buildActionButton(
//             icon: Icons.location_on,
//             color: Colors.red,
//             label: 'Location',
//             onPressed: () => showLocationDialog(
//               widget.doctorData['address'] ?? 'Location not available',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             icon: Icon(icon, size: 24, color: color),
//             onPressed: onPressed,
//             tooltip: label,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleList() {
//     if (isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (schedules.isEmpty) {
//       return const Center(
//         child: Text(
//           'No available schedules',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: schedules.length,
//       itemBuilder: (context, index) {
//         final schedule = schedules[index];
//         final scheduleDate = (schedule['date'] as Timestamp).toDate();
//         final isSelected = selectedScheduleIndex == index;
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           color: isSelected ? Colors.blue.shade50 : null,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(
//               color: isSelected ? Colors.blue : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 0.5,
//             ),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             title: Text(
//               _formatDate(schedule['date']),
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? Colors.blue.shade800 : null,
//               ),
//             ),
//             subtitle: Text(
//               '${_formatTime(schedule['startTime'])} - ${_formatTime(schedule['endTime'])}',
//               style: TextStyle(
//                 color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
//               ),
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _selectSchedule(index),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 isSelected ? 'Selected' : 'Select',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             onTap: () => _selectSchedule(index),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRequestButton() {
//     return Column(
//       children: [
//         const Text(
//           'Appointment Fee: \$0.01 USD',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.green,
//           ),
//         ),
//         const SizedBox(height: 8),
//         const Text(
//           'Payment will be deducted from your mobile wallet',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: isRequestingAppointment ? null : _requestAppointment,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade800,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: isRequestingAppointment
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   )
//                 : const Text(
//                     'Pay & Request Appointment',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildDoctorInfo(),
//                         _buildActionButtons(),
//                         const Divider(),
//                         const Text(
//                           'Available Schedules',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildScheduleList(),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: _buildRequestButton(),
//                 ),
//               ],
//             ),
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:async';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//     final now = DateTime.now();
//     today = DateTime(now.year, now.month, now.day);
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//   bool hasExistingAppointment = false;
//   bool isRequestingAppointment = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     await Future.wait([
//       _fetchSchedules(),
//       _checkExistingAppointments(),
//     ]);
//   }

//   Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending'])
//           .get();

//       if (mounted) {
//         setState(() {
//           hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error checking your existing appointments')),
//         );
//       }
//     }
//   }

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         throw 'Could not launch dialer';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error making call: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clinic Location'),
//         content: SingleChildScrollView(
//           child: Text(address),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _openMaps(address),
//             child: const Text('Open in Maps'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openMaps(String address) async {
//     if (address.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Address is empty')),
//       );
//       return;
//     }

//     final encodedAddress = Uri.encodeComponent(address);
//     bool launched = false;

//     final urlAttempts = [
//       Uri.parse('geo:0,0?q=$encodedAddress'),
      
//       if (Theme.of(context).platform == TargetPlatform.iOS)
//         Uri.parse('http://maps.apple.com/?q=$encodedAddress')
//       else
//         Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress'),
      
//       Uri.parse('https://www.google.com/search?q=$encodedAddress'),
//     ];

//     for (final url in urlAttempts) {
//       try {
//         if (await canLaunchUrl(url)) {
//           await launchUrl(url, mode: LaunchMode.externalApplication);
//           launched = true;
//           break;
//         }
//       } catch (e) {
//         debugPrint('Failed to launch $url: $e');
//       }
//     }

//     if (!launched && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No application found to open maps')),
//       );
//     }
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
//           .orderBy('date', descending: false)
//           .get();

//       if (mounted) {
//         setState(() {
//           schedules = querySnapshot.docs.map((doc) {
//             return {
//               'id': doc.id,
//               ...doc.data(),
//             };
//           }).toList();
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading schedules: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (hasExistingAppointment) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You already have an appointment with this doctor')),
//       );
//       return;
//     }

//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = FirebaseAuth.instance.currentUser?.uid;
    
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You must be logged in')),
//       );
//       return;
//     }

//     setState(() {
//       isRequestingAppointment = true;
//     });

//     try {
//       final paymentSuccess = await _processPayment();
      
//       if (!paymentSuccess) {
//         if (mounted) {
//           setState(() {
//             isRequestingAppointment = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Payment failed. Please try again')));
//         }
//         return;
//       }

//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'] ?? 'General',
//         'fee': 0.01,
//         'fullName': FirebaseAuth.instance.currentUser?.displayName ?? 'unknown Patient',
//         'paymentStatus': 'completed', //when api "responseMsg":"RCS_SUCCESS" is paymentStatus are completed
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Appointment requested and payment completed successfully!',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint('Failed to request appointment: $e');
//       if (mounted) {
//         setState(() {
//           isRequestingAppointment = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to complete request: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<bool> _processPayment() async {
//     try {
//       final doctorPhoneNumber = await _getDoctorPhoneNumber();
//       final userPhoneNumber = await _getUserPhoneNumber();

//       if (userPhoneNumber.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('User phone number not found')),
//           );
//         }
//         return false;
//       }

//       if (!_isValidSomaliNumber(userPhoneNumber)) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please use a valid Somali mobile number')),
//           );
//         }
//         return false;
//       }

//       var paymentRequest = { 
//         "schemaVersion": "1.0", 
//         "requestId": DateTime.now().millisecondsSinceEpoch.toString(),
//         "timestamp": DateTime.now().toIso8601String(),
//         "channelName": "WEB", 
//         "serviceName": "API_PURCHASE", 
//         "serviceParams": { 
//           "merchantUid": "M0910291", 
//           "apiUserId": "1000416",  
//           "apiKey": "API-675418888AHX", 
//           "paymentMethod": "mwallet_account", 
//           "payerInfo": { 
//             "accountNo": userPhoneNumber, 
//              "accountName": widget.userData['fullName'] ?? 'Unknown Patient'
//           }, 
//           "transactionInfo": { 
//             "referenceId": "APP_${DateTime.now().millisecondsSinceEpoch}",
//             "invoiceId": "INV_${DateTime.now().millisecondsSinceEpoch}",
//             "amount": 0.01,  
//             "currency": "USD", 
//             "description": "Doctor Appointment Fee",
//             "recipientInfo": {
//               "accountNo": doctorPhoneNumber, 
//               "accountType": "mwallet_account", 
//               "accountName": widget.doctorData['fullName'] ?? 'Unknown Doctor',
//             },
//           }, 
//         } 
//       };

//       debugPrint('Payment Request: ${jsonEncode(paymentRequest)}');

//       final response = await http.post(
//         Uri.parse('https://api.waafipay.net/asm'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(paymentRequest),
//       ).timeout(const Duration(seconds: 30));

//       return _handlePaymentResponse(response);
//     } catch (e) {
//       debugPrint('Payment Error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Payment Error: ${e.toString()}')),
//         );
//       }
//       return false;
//     }
//   }

//   bool _isValidSomaliNumber(String phone) {
//     final regex = RegExp(r'^252(61|62|65|66|67|68|69|71|77|79|90)\d{7}$');
//     return regex.hasMatch(phone);
//   }

//   String transformPhone(String phone) {
//     return phone.replaceAll(RegExp(r'[^0-9]'), '');
//   }

//   Future<bool> _handlePaymentResponse(http.Response response) async {
//     debugPrint('Payment Response: ${response.statusCode}, ${response.body}');

//     final responseData = jsonDecode(response.body);
    
//     if (response.statusCode == 200) {
//       if (responseData['responseCode'] == '200' || 
//           responseData['responseCode'] == '0000' ||
//           responseData['responseCode'] == '00') {
        
//         await _savePaymentRecord(responseData['transactionId']);
//         return true;
//       } else {
//         _showPaymentError(
//           responseData['errorCode'] ?? 'UNKNOWN',
//           responseData['responseMsg'] ?? 'Payment failed'
//         );
//         return false;
//       }
//     } else {
//       _showPaymentError(
//         'HTTP_${response.statusCode}',
//         'Server error: ${response.statusCode}'
//       );
//       return false;
//     }
//   }

//   void _showPaymentError(String errorCode, String message) {
//     final userMessage = _translateErrorCode(errorCode, message);
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(userMessage),
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     }
//   }

//   Future<String> _getDoctorPhoneNumber() async {
//     try {
//       final doctorDoc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .get();

//       if (!doctorDoc.exists) {
//         throw Exception('Doctor document not found');
//       }

//       final doctorPhone = doctorDoc.data()?['phone'] as String?;
      
//       if (doctorPhone == null || doctorPhone.isEmpty) {
//         throw Exception('Phone number not found in doctor document');
//       }

//       final cleanedPhone = doctorPhone.replaceAll(RegExp(r'[^0-9]'), '');

//       if (!cleanedPhone.startsWith('252')) {
//         throw Exception('Phone number must be in international format (252...)');
//       }

//       if (cleanedPhone.length != 12) {
//         throw Exception('Invalid Somali phone number length');
//       }

//       return cleanedPhone;
//     } catch (e) {
//       debugPrint('Error getting doctor phone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error getting doctor phone: ${e.toString()}')),
//         );
//       }
//       rethrow;
//     }
//   }

//   Future<String> _getUserPhoneNumber() async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) {
//         throw Exception('User not authenticated');
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .get();

//       if (!userDoc.exists) {
//         throw Exception('User document not found');
//       }

//       final userPhone = userDoc.data()?['phone'] as String?;
      
//       if (userPhone == null || userPhone.isEmpty) {
//         throw Exception('Phone number not found in user document');
//       }

//       final cleanedPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');

//       if (!cleanedPhone.startsWith('252')) {
//         throw Exception('Please use international format (252...)');
//       }

//       if (cleanedPhone.length != 12) {
//         throw Exception('Invalid phone number length');
//       }

//       return cleanedPhone;
//     } catch (e) {
//       debugPrint('Error getting user phone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error getting your phone: ${e.toString()}')),
//         );
//       }
//       rethrow;
//     }
//   }

//   String _translateErrorCode(String code, String defaultMsg) {
//     switch (code) {
//       case 'E10309':
//         return 'Invalid account details. Please check your mobile wallet number and try again.';
//       case 'E10308':
//         return 'Insufficient funds in your mobile wallet.';
//       case 'E10310':
//         return 'Currency not supported. Please contact support.';
//       case 'E10307':
//         return 'Transaction limit exceeded. Try a smaller amount.';
//       default:
//         return '$defaultMsg (Error: $code)';
//     }
//   }

//   Future<void> _savePaymentRecord(String transactionId) async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) return;

//       await FirebaseFirestore.instance
//           .collection('payments')
//           .doc(transactionId)
//           .set({
//             'userId': userId,
//             'doctorId': widget.doctorId,
//             'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//             'fullName': FirebaseAuth.instance.currentUser?.displayName ?? 'unknown Patient',
//             'amount': 0.01,
//             'currency': 'USD',
//             'status': 'completed',
//             'timestamp': FieldValue.serverTimestamp(),
//             'transactionId': transactionId,
//             'patientPhone': await _getUserPhoneNumber(),
//             'doctorPhone': await _getDoctorPhoneNumber(),
//           });
//     } catch (e) {
//       debugPrint('Error saving payment record: $e');
//       snacbar payment succes fully
    
//     }
//   }

//   Widget _buildDoctorInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.blue.shade900,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Fee: \$0.01 USD',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
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

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildActionButton(
//             icon: Icons.phone,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//           ),
//           _buildActionButton(
//             icon: Icons.message,
//             color: Colors.blue,
//             label: 'Message',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                     doctorId: widget.doctorId,
//                   ),
//                 ),
//               );
//             },
//           ),
//           _buildActionButton(
//             icon: Icons.location_on,
//             color: Colors.red,
//             label: 'Location',
//             onPressed: () => showLocationDialog(
//               widget.doctorData['address'] ?? 'Location not available',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             icon: Icon(icon, size: 24, color: color),
//             onPressed: onPressed,
//             tooltip: label,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleList() {
//     if (schedules.isEmpty) {
//       return const Center(
//         child: Text(
//           'No available schedules',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: schedules.length,
//       itemBuilder: (context, index) {
//         final schedule = schedules[index];
//         final isSelected = selectedScheduleIndex == index;
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           color: isSelected ? Colors.blue.shade50 : null,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(
//               color: isSelected ? Colors.blue : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 0.5,
//             ),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             title: Text(
//               _formatDate(schedule['date']),
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? Colors.blue.shade800 : null,
//               ),
//             ),
//             subtitle: Text(
//               '${_formatTime(schedule['startTime'])} - ${_formatTime(schedule['endTime'])}',
//               style: TextStyle(
//                 color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
//               ),
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _selectSchedule(index),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 isSelected ? 'Selected' : 'Select',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             onTap: () => _selectSchedule(index),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRequestButton() {
//     return Column(
//       children: [
//         const Text(
//           'Appointment Fee: \$0.01 USD',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.green,
//           ),
//         ),
//         const SizedBox(height: 8),
//         const Text(
//           'Payment will be deducted from your mobile wallet',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: isRequestingAppointment ? null : _requestAppointment,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade800,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: isRequestingAppointment
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   )
//                 : const Text(
//                     'Pay & Request Appointment',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildDoctorInfo(),
//                         _buildActionButtons(),
//                         const Divider(),
//                         const Text(
//                           'Available Schedules',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildScheduleList(),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: _buildRequestButton(),
//                 ),
//               ],
//             ),
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }

























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:async'; // For TimeoutException

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//   bool hasExistingAppointment = false;
//   bool isRequestingAppointment = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     await Future.wait([
//       _fetchSchedules(),
//       _checkExistingAppointments(),
//     ]);
//   }

//   Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending'])
//           .get();

//       if (mounted) {
//         setState(() {
//           hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error checking your existing appointments')),
//         );
//       }
//     }
//   }

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         throw 'Could not launch dialer';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error making call: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clinic Location'),
//         content: SingleChildScrollView(
//           child: Text(address),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _openMaps(address),
//             child: const Text('Open in Maps'),
//           ),
//         ],
//       ),
//     );
//   }

  
//   Future<void> _openMaps(String address) async {
//   if (address.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Address is empty')),
//     );
//     return;
//   }

//   final encodedAddress = Uri.encodeComponent(address);
//   bool launched = false;

//   // Try these URL schemes in order
//   final urlAttempts = [
//     // Native maps
//     Uri.parse('geo:0,0?q=$encodedAddress'),
    
//     // Platform-specific maps
//     if (Theme.of(context).platform == TargetPlatform.iOS)
//       Uri.parse('http://maps.apple.com/?q=$encodedAddress')
//     else
//       Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress'),
    
//     // Universal fallback
//     Uri.parse('https://www.google.com/search?q=$encodedAddress'),
//   ];

//   for (final url in urlAttempts) {
//     try {
//       debugPrint('Attempting to launch: $url');
//       if (await canLaunchUrl(url)) {
//         await launchUrl(url, mode: LaunchMode.externalApplication);
//         launched = true;
//         break;
//       }
//     } catch (e) {
//       debugPrint('Failed to launch $url: $e');
//     }
//   }

//   if (!launched && mounted) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('No application found to open maps')),
//     );
//   }
// }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       if (mounted) {
//         setState(() {
//           schedules = querySnapshot.docs.map((doc) {
//             return {
//               'id': doc.id,
//               ...doc.data(),
//             };
//           }).toList();
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading schedules: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

// Future<void> _requestAppointment() async {
//   if (hasExistingAppointment) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('You already have an appointment with this doctor')),
//     );
//     return;
//   }

//   if (selectedScheduleIndex == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Please select a schedule first')),
//     );
//     return;
//   }

//   final selectedSchedule = schedules[selectedScheduleIndex!];
//   final userId = FirebaseAuth.instance.currentUser?.uid;
  
//   if (userId == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('You must be logged in')),
//     );
//     return;
//   }

//   setState(() {
//     isRequestingAppointment = true;
//   });

//   try {
//     // First process payment
//     final paymentSuccess = await _processPayment();
    
//     if (!paymentSuccess) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Payment failed. Please try again')));
//       }
//       return;
//     }

//     // If payment succeeds, create the appointment
//     await FirebaseFirestore.instance.collection('appointments').add({
//       'doctorId': widget.doctorId,
//       'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//       'userId': userId,
//       'scheduleId': selectedSchedule['id'],
//       'date': selectedSchedule['date'],
//       'startTime': selectedSchedule['startTime'],
//       'endTime': selectedSchedule['endTime'],
//       'status': 'pending',
//       'createdAt': FieldValue.serverTimestamp(),
//       'specialty': widget.doctorData['specialties'] ?? 'General',
//       'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//       'patientName': FirebaseAuth.instance.currentUser?.displayName ?? 'Patient',
//       'paymentStatus': 'completed', // Add payment status
//     });

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text(
//             'Appointment requested and payment completed successfully!',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       Navigator.pop(context);
//     }
//   } catch (e) {
//     debugPrint('Failed to request appointment: $e');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to complete request: ${e.toString()}')),
//       );
//     }
//   } final paymentSuccess = await _processPayment();

// if (!paymentSuccess) {
//   if (mounted) {
//     setState(() {
//       isRequestingAppointment = false;
//     });
//   }
//   return; // Don't proceed with appointment if payment fails
// }
// }

// // String transformPhone(String phone) {
// //   if (phone.startsWith('252')) {
// //     return phone.replaceFirst('252', '61'); // => 61xxxxxxx
// //   }
// //   return phone;
// // }

// Future<bool> _processPayment() async {
//   try {
//     // 1. Get doctors and users phone numbers
//     final doctorPhoneNumber = transformPhone(await _getDoctorPhoneNumber());
//     final userPhoneNumber = transformPhone(await _getUserPhoneNumber());

//     if (userPhoneNumber.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User phone number not found')),
//         );
//       }
//       return false;
//     }

//     // 2. Validate phone numbers
//     if (!_isValidSomaliNumber(userPhoneNumber)) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please use a valid Somali mobile number')),
//         );
//       }
//       return false;
//     }

    
//     var paymentRequest = { 
//         "schemaVersion": "1.0", 
//         "requestId": "10111331033", 
//         "timestamp": "client_timestamp", 
//         "channelName": "WEB", 
//         "serviceName": "API_PURCHASE", 
//         "serviceParams": { 
//           "merchantUid": "M0910291", 
//           "apiUserId": "1000416",  
//           "apiKey": "API-675418888AHX", 
//           "paymentMethod": "mwallet_account", 
//           "payerInfo": { 
//             "accountNo": userPhoneNumber 
//           }, 
//           "transactionInfo": { 
//             "referenceId": "1234",
//             "invoiceId": "7896504",
//             "amount": 1.00,  
//             "currency": "USD", 
//             "description": "Doctor Appointment Fee" ,
//           // "fee": _calculateFee(widget.doctorData['experience'] ?? 0),
//            "recipientInfo": {
//              "accountNo": doctorPhoneNumber, 
//             "accountType": "mwallet_account", 
//             "accountName": widget.doctorData['fullName'] ?? 'Unknown Doctor',
//           },
//           },
//         } 
//       };

//     debugPrint('Payment Request: ${jsonEncode(paymentRequest)}');

//     // 4. Send payment request
//     final response = await http.post(
//       Uri.parse('https://api.waafipay.net/asm'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//         'Authorization': 'Bearer YOUR_ACCESS_TOKEN' // If required
//       },
//       body: jsonEncode(paymentRequest),
//     ).timeout(const Duration(seconds: 30));

//     // 5. Process response
//     return _handlePaymentResponse(response);
//   } catch (e) {
//     debugPrint('Payment Error: $e');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Payment Error: ${e.toString()}')),
//       );
//     }
//     return false;
//   }
// }


// bool _isValidSomaliNumber(String phone) {
//   final regex = RegExp(r'^252(61|62|65|66|67|68|69|71|77|79|90)\d{7}$');
//   return regex.hasMatch(phone);
// }

// String transformPhone(String phone) {

//   return phone.replaceAll(RegExp(r'[^0-9]'), '');
// }

// Future<bool> _handlePaymentResponse(http.Response response) async {
//   debugPrint('Payment Response: ${response.statusCode}, ${response.body}');

//   final responseData = jsonDecode(response.body);
  
//   if (response.statusCode == 200) {
//     if (responseData['responseCode'] == '200' || 
//         responseData['responseCode'] == '0000' ||
//         responseData['responseCode'] == '00') {
      
//       await _savePaymentRecord(responseData['transactionId']);
//       return true;
//     } else {
//       _showPaymentError(
//         responseData['errorCode'] ?? 'UNKNOWN',
//         responseData['responseMsg'] ?? 'Payment failed'
//       );
//       return false;
//     }
//   } else {
//     _showPaymentError(
//       'HTTP_${response.statusCode}',
//       'Server error: ${response.statusCode}'
//     );
//     return false;
//   }
// }

// void _showPaymentError(String errorCode, String message) {
//   final userMessage = _translateErrorCode(errorCode, message);
  
//   if (mounted) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(userMessage),
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }
// }


// throw Exception('Phone number not found in doctor document');

// Future<String> _getDoctorPhoneNumber() async {
//   try {
//     final doctorDoc = await FirebaseFirestore.instance
//         .collection('doctors')
//         .doc(widget.doctorId)
//         .get();

//     if (!doctorDoc.exists) {
//       throw Exception('Doctor document not found');
//     }

//     final doctorPhone = doctorDoc.data()?['phone'] as String?;
    
//     if (doctorPhone == null || doctorPhone.isEmpty) {
//       throw Exception('Phone number not found in doctor document');
//     }

//     // Clean the phone number - remove all non-digit characters
//     final cleanedPhone = doctorPhone.replaceAll(RegExp(r'[^0-9]'), '');

//     // Ensure the phone is in international format (252...)
//     if (!cleanedPhone.startsWith('252')) {
//       throw Exception('Phone number must be in international format (252...)');
//     }

//     // Validate the Somali phone number format
//     if (cleanedPhone.length != 12) { // 252 + 9 digits
//       throw Exception('Invalid Somali phone number length');
//     }

//     return cleanedPhone;
//   } catch (e) {
//     debugPrint('Error getting doctor phone: $e');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error getting doctor phone: ${e.toString()}')),
//       );
//     }
//     rethrow;
//   }
// }
// Future<String> _getUserPhoneNumber() async {
//   try {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) {
//       throw Exception('User not authenticated');
//     }

//     final userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .get();

//     if (!userDoc.exists) {
//       throw Exception('User document not found');
//     }

//     final userPhone = userDoc.data()?['phone'] as String?;
    
//     if (userPhone == null || userPhone.isEmpty) {
//       throw Exception('Phone number not found in user document');
//     }

//     // Clean the phone number
//     final cleanedPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');

//     // Ensure international format
//     if (!cleanedPhone.startsWith('252')) {
//       throw Exception('Please use international format (252...)');
//     }

//     // Validate length
//     if (cleanedPhone.length != 12) {
//       throw Exception('Invalid phone number length');
//     }

//     return cleanedPhone;
//   } catch (e) {
//     debugPrint('Error getting user phone: $e');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error getting your phone: ${e.toString()}')),
//       );
//     }
//     rethrow;
//   }
// }



// String _translateErrorCode(String code, String defaultMsg) {
//   switch (code) {
//     case 'E10309':
//       return 'Invalid account details. Please check your mobile wallet number and try again.';
//     case 'E10308':
//       return 'Insufficient funds in your mobile wallet.';
//     case 'E10310':
//       return 'Currency not supported. Please contact support.';
//     case 'E10307':
//       return 'Transaction limit exceeded. Try a smaller amount.';
//     default:
//       return '$defaultMsg (Error: $code)';
//   }
// }

// Future<void> _savePaymentRecord(String transactionId) async {
//   try {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     await FirebaseFirestore.instance
//         .collection('payments')
//         .doc(transactionId)
//         .set({
//           'userId': userId,
//           'doctorId': widget.doctorId,
//           'amount': 1.00,
//           'currency': 'USD',
//           'status': 'completed',
//           'timestamp': FieldValue.serverTimestamp(),
//           'transactionId': transactionId,
//           'patientPhone': await _getUserPhoneNumber(),
//           'doctorPhone': await _getDoctorPhoneNumber(),
//         });
//   } catch (e) {
//     debugPrint('Error saving payment record: $e');
//   }
//   or 
//   snacbar('payment successfully')

// }



//   int _calculateFee(int experience) {
//     return 1;
//   }

//   Widget _buildDoctorInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.blue.shade900,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
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

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildActionButton(
//             icon: Icons.phone,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//           ),
//           _buildActionButton(
//             icon: Icons.message,
//             color: Colors.blue,
//             label: 'Message',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                     doctorId: widget.doctorId,
//                   ),
//                 ),
//               );
//             },
//           ),
//           _buildActionButton(
//             icon: Icons.location_on,
//             color: Colors.red,
//             label: 'Location',
//             onPressed: () => showLocationDialog(
//               widget.doctorData['address'] ?? 'Location not available',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             icon: Icon(icon, size: 24, color: color),
//             onPressed: onPressed,
//             tooltip: label,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleList() {
//     if (schedules.isEmpty) {
//       return const Center(
//         child: Text(
//           'No available schedules',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: schedules.length,
//       itemBuilder: (context, index) {
//         final schedule = schedules[index];
//         final isSelected = selectedScheduleIndex == index;
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           color: isSelected ? Colors.blue.shade50 : null,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(
//               color: isSelected ? Colors.blue : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 0.5,
//             ),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             title: Text(
//               _formatDate(schedule['date']),
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? Colors.blue.shade800 : null,
//               ),
//             ),
//             subtitle: Text(
//               '${_formatTime(schedule['startTime'])} - ${_formatTime(schedule['endTime'])}',
//               style: TextStyle(
//                 color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
//               ),
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _selectSchedule(index),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 isSelected ? 'Selected' : 'Select',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             onTap: () => _selectSchedule(index),
//           ),
//         );
//       },
//     );
//   }

// Widget _buildRequestButton() {
//   return Column(
//     children: [
//       const Text(
//         'Appointment Fee: \$1.00 USD',
//         style: TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Colors.green,
//         ),
//       ),
//       const SizedBox(height: 8),
//       const Text(
//         'Payment will be deducted from your mobile wallet',
//         style: TextStyle(
//           fontSize: 12,
//           color: Colors.grey,
//         ),
//         textAlign: TextAlign.center,
//       ),
//       const SizedBox(height: 8),
//       SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: isRequestingAppointment ? null : _requestAppointment,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue.shade800,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: isRequestingAppointment
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 )
//               : const Text(
//                   'Pay & Request Appointment',
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//         ),
//       ),
//     ],
//   );
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildDoctorInfo(),
//                         _buildActionButtons(),
//                         const Divider(),
//                         const Text(
//                           'Available Schedules',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildScheduleList(),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: _buildRequestButton(),
//                 ),
//               ],
//             ),
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }






//////////////////////////////////////////////////////////////////////////////////////////

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//   bool hasExistingAppointment = false;
//   bool isRequestingAppointment = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     await Future.wait([
//       _fetchSchedules(),
//       _checkExistingAppointments(),
//     ]);
//   }

//   Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending'])
//           .get();

//       if (mounted) {
//         setState(() {
//           hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error checking your existing appointments')),
//         );
//       }
//     }
//   }

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         throw 'Could not launch dialer';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error making call: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clinic Location'),
//         content: SingleChildScrollView(
//           child: Text(address),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _openMaps(address),
//             child: const Text('Open in Maps'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Future<void> _openMaps(String address) async {
//   //   final encodedAddress = Uri.encodeComponent(address);
//   //   final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
//   //   final appleMapsUrl = 'https://maps.apple.com/?q=$encodedAddress';
    
//   //   try {
//   //     // Try Google Maps first
//   //     if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
//   //       await launchUrl(Uri.parse(googleMapsUrl));
//   //       return;
//   //     }
      
//   //     // Fallback to Apple Maps if on iOS
//   //     if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
//   //       await launchUrl(Uri.parse(appleMapsUrl));
//   //       return;
//   //     }
      
//   //     // Final fallback to browser search
//   //     if (await canLaunchUrl(Uri.parse('https://www.google.com/search?q=$encodedAddress'))) {
//   //       await launchUrl(Uri.parse('https://www.google.com/search?q=$encodedAddress'));
//   //       return;
//   //     }

//   //     // If nothing works, show error
//   //     if (mounted) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(content: Text('No maps application found')),
//   //       );
//   //     }
//   //   } catch (e) {
//   //     debugPrint('Error opening maps: $e');
//   //     if (mounted) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         SnackBar(content: Text('Error opening maps: ${e.toString()}')),
//   //       );
//   //     }
//   //   }
//   // }
//   Future<void> _openMaps(String address) async {
//   if (address.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Address is empty')),
//     );
//     return;
//   }

//   final encodedAddress = Uri.encodeComponent(address);
//   bool launched = false;

//   // Try these URL schemes in order
//   final urlAttempts = [
//     // Native maps
//     Uri.parse('geo:0,0?q=$encodedAddress'),
    
//     // Platform-specific maps
//     if (Theme.of(context).platform == TargetPlatform.iOS)
//       Uri.parse('http://maps.apple.com/?q=$encodedAddress')
//     else
//       Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress'),
    
//     // Universal fallback
//     Uri.parse('https://www.google.com/search?q=$encodedAddress'),
//   ];

//   for (final url in urlAttempts) {
//     try {
//       debugPrint('Attempting to launch: $url');
//       if (await canLaunchUrl(url)) {
//         await launchUrl(url, mode: LaunchMode.externalApplication);
//         launched = true;
//         break;
//       }
//     } catch (e) {
//       debugPrint('Failed to launch $url: $e');
//     }
//   }

//   if (!launched && mounted) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('No application found to open maps')),
//     );
//   }
// }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       if (mounted) {
//         setState(() {
//           schedules = querySnapshot.docs.map((doc) {
//             return {
//               'id': doc.id,
//               ...doc.data(),
//             };
//           }).toList();
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading schedules: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (hasExistingAppointment) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You already have an appointment with this doctor')),
//       );
//       return;
//     }

//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = FirebaseAuth.instance.currentUser?.uid;
    
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You must be logged in')),
//       );
//       return;
//     }

//     setState(() {
//       isRequestingAppointment = true;
//     });

//     try {
//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'] ?? 'General',
//         'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//         'patientName': FirebaseAuth.instance.currentUser?.displayName ?? 'Patient',
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text(
//               'Appointment requested successfully!',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint('Failed to request appointment: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to request appointment: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isRequestingAppointment = false;
//         });
//       }
//     }
//   }

//   int _calculateFee(int experience) {
//     // if (experience <= 4) return 50;
//     // if (experience <= 7) return 150;
//     return 10;
//   }

//   Widget _buildDoctorInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.blue.shade900,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
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

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildActionButton(
//             icon: Icons.phone,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//           ),
//           _buildActionButton(
//             icon: Icons.message,
//             color: Colors.blue,
//             label: 'Message',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                     doctorId: widget.doctorId,
//                   ),
//                 ),
//               );
//             },
//           ),
//           _buildActionButton(
//             icon: Icons.location_on,
//             color: Colors.red,
//             label: 'Location',
//             onPressed: () => showLocationDialog(
//               widget.doctorData['address'] ?? 'Location not available',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             icon: Icon(icon, size: 24, color: color),
//             onPressed: onPressed,
//             tooltip: label,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleList() {
//     if (schedules.isEmpty) {
//       return const Center(
//         child: Text(
//           'No available schedules',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: schedules.length,
//       itemBuilder: (context, index) {
//         final schedule = schedules[index];
//         final isSelected = selectedScheduleIndex == index;
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           color: isSelected ? Colors.blue.shade50 : null,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(
//               color: isSelected ? Colors.blue : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 0.5,
//             ),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             title: Text(
//               _formatDate(schedule['date']),
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? Colors.blue.shade800 : null,
//               ),
//             ),
//             subtitle: Text(
//               '${_formatTime(schedule['startTime'])} - ${_formatTime(schedule['endTime'])}',
//               style: TextStyle(
//                 color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
//               ),
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _selectSchedule(index),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 isSelected ? 'Selected' : 'Select',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             onTap: () => _selectSchedule(index),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRequestButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: isRequestingAppointment ? null : _requestAppointment,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.blue.shade800,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: isRequestingAppointment
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//             : const Text(
//                 'Request Appointment',
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildDoctorInfo(),
//                         _buildActionButtons(),
//                         const Divider(),
//                         const Text(
//                           'Available Schedules',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildScheduleList(),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: _buildRequestButton(),
//                 ),
//               ],
//             ),
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }
































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//   bool hasExistingAppointment = false;
//   bool isRequestingAppointment = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     await Future.wait([
//       _fetchSchedules(),
//       _checkExistingAppointments(),
//     ]);
//   }

//   Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending'])
//           .get();

//       if (mounted) {
//         setState(() {
//           hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error checking your existing appointments')),
//         );
//       }
//     }
//   }

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         throw 'Could not launch dialer';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error making call: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clinic Location'),
//         content: SingleChildScrollView(
//           child: Text(address),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _openMaps(address),
//             child: const Text('Open in Maps'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openMaps(String address) async {
//     final Uri uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open maps')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       if (mounted) {
//         setState(() {
//           schedules = querySnapshot.docs.map((doc) {
//             return {
//               'id': doc.id,
//               ...doc.data(),
//             };
//           }).toList();
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading schedules: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (hasExistingAppointment) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You already have an appointment with this doctor')),
//       );
//       return;
//     }

//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = FirebaseAuth.instance.currentUser?.uid;
    
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You must be logged in')),
//       );
//       return;
//     }

//     setState(() {
//       isRequestingAppointment = true;
//     });

//     try {
//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'] ?? 'General',
//         'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//         'patientName': FirebaseAuth.instance.currentUser?.displayName ?? 'Patient',
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text(
//               'Appointment requested successfully!',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint('Failed to request appointment: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to request appointment: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isRequestingAppointment = false;
//         });
//       }
//     }
//   }

//   int _calculateFee(int experience) {
//     if (experience <= 4) return 50;
//     if (experience <= 7) return 150;
//     return 200;
//   }

//   Widget _buildDoctorInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.blue.shade900,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
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

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildActionButton(
//             icon: Icons.phone,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//           ),
//           _buildActionButton(
//             icon: Icons.message,
//             color: Colors.blue,
//             label: 'Message',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                     doctorId: widget.doctorId,
//                   ),
//                 ),
//               );
//             },
//           ),
//           _buildActionButton(
//             icon: Icons.location_on,
//             color: Colors.red,
//             label: 'Location',
//             onPressed: () => showLocationDialog(
//               widget.doctorData['address'] ?? 'Location not available',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             icon: Icon(icon, size: 24, color: color),
//             onPressed: onPressed,
//             tooltip: label,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleList() {
//     if (schedules.isEmpty) {
//       return const Center(
//         child: Text(
//           'No available schedules',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: schedules.length,
//       itemBuilder: (context, index) {
//         final schedule = schedules[index];
//         final isSelected = selectedScheduleIndex == index;
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           color: isSelected ? Colors.blue.shade50 : null,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(
//               color: isSelected ? Colors.blue : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 0.5,
//             ),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             title: Text(
//               _formatDate(schedule['date']),
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? Colors.blue.shade800 : null,
//               ),
//             ),
//             subtitle: Text(
//               '${_formatTime(schedule['startTime'])} - ${_formatTime(schedule['endTime'])}',
//               style: TextStyle(
//                 color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
//               ),
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _selectSchedule(index),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 isSelected ? 'Selected' : 'Select',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             onTap: () => _selectSchedule(index),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRequestButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: isRequestingAppointment ? null : _requestAppointment,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.blue.shade800,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: isRequestingAppointment
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//             : const Text(
//                 'Request Appointment',
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildDoctorInfo(),
//                         _buildActionButtons(),
//                         const Divider(),
//                         const Text(
//                           'Available Schedules',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildScheduleList(),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Request Appointment button at the bottom
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: _buildRequestButton(),
//                 ),
//               ],
//             ),
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//   bool hasExistingAppointment = false;
//   bool isRequestingAppointment = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     await Future.wait([
//       _fetchSchedules(),
//       _checkExistingAppointments(),
//     ]);
//   }

//   Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending', 'confirmed'])
//           .get();

//       if (mounted) {
//         setState(() {
//           hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error checking your existing appointments')),
//         );
//       }
//     }
//   }

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         throw 'Could not launch dialer';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error making call: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clinic Location'),
//         content: SingleChildScrollView(
//           child: Text(address),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _openMaps(address),
//             child: const Text('Open in Maps'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openMaps(String address) async {
//     final Uri uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open maps')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       if (mounted) {
//         setState(() {
//           schedules = querySnapshot.docs.map((doc) {
//             return {
//               'id': doc.id,
//               ...doc.data(),
//             };
//           }).toList();
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading schedules: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (hasExistingAppointment) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You already have an appointment with this doctor')),
//       );
//       return;
//     }

//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = FirebaseAuth.instance.currentUser?.uid;
    
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You must be logged in')),
//       );
//       return;
//     }

//     setState(() {
//       isRequestingAppointment = true;
//     });

//     try {
//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'] ?? 'General',
//         'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//         'patientName': FirebaseAuth.instance.currentUser?.displayName ?? 'Patient',
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text(
//               'Appointment requested successfully!',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint('Failed to request appointment: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to request appointment: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isRequestingAppointment = false;
//         });
//       }
//     }
//   }

//   int _calculateFee(int experience) {
//     if (experience <= 4) return 50;
//     if (experience <= 7) return 150;
//     return 200;
//   }

//   Widget _buildDoctorInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.blue.shade100,
//               backgroundImage: widget.doctorData['photoUrl'] != null
//                   ? NetworkImage(widget.doctorData['photoUrl'])
//                   : null,
//               child: widget.doctorData['photoUrl'] == null
//                   ? Text(
//                       widget.doctorData['fullName']?.isNotEmpty == true
//                           ? widget.doctorData['fullName'][0].toUpperCase()
//                           : 'D',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.blue.shade900,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
                  
//                   const SizedBox(height: 4),
//                   Text(
//                     'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
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

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildActionButton(
//             icon: Icons.call,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//           ),
//           _buildActionButton(
//             icon: Icons.message,
//             color: Colors.blue,
//             label: 'Message',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                     doctorId: widget.doctorId,
//                   ),
//                 ),
//               );
//             },
//           ),
//           _buildActionButton(
//             icon: Icons.location_on,
//             color: Colors.red,
//             label: 'Location',
//             onPressed: () => showLocationDialog(
//               widget.doctorData['address'] ?? 'Location not available',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         IconButton(
//           icon: Icon(icon, size: 30, color: color),
//           onPressed: onPressed,
//           tooltip: label,
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleList() {
//     if (schedules.isEmpty) {
//       return const Center(
//         child: Text(
//           'No available schedules',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: schedules.length,
//       itemBuilder: (context, index) {
//         final schedule = schedules[index];
//         final isSelected = selectedScheduleIndex == index;
        
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           color: isSelected ? Colors.blue.shade50 : null,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(
//               color: isSelected ? Colors.blue : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 0.5,
//             ),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             title: Text(
//               _formatDate(schedule['date']),
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? Colors.blue.shade800 : null,
//               ),
//             ),
//             subtitle: Text(
//               '${_formatTime(schedule['startTime'])} - ${_formatTime(schedule['endTime'])}',
//               style: TextStyle(
//                 color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
//               ),
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _selectSchedule(index),
//               style: ElevatedButton.styleFrom(
//                 // backgroundColor: isSelected ? Colors.blue.shade800 : Colors.grey,
//                  backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 isSelected ? 'Selected' : 'Select',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             onTap: () => _selectSchedule(index),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRequestButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: isRequestingAppointment ? null : _requestAppointment,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.blue.shade800,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: isRequestingAppointment
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//             : const Text(
//                 'Request Appointment',
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildDoctorInfo(),
//                   _buildActionButtons(),
//                   const Divider(),
//                   const Text(
//                     'Available Schedules',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   _buildScheduleList(),
//                   const SizedBox(height: 20),
//                   _buildRequestButton(),
//                 ],
//               ),
//             ),
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;
//    Future<void> _checkExistingAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('userId', isEqualTo: userId)
//           .where('status', whereIn: ['pending', 'confirmed'])
//           .get();

//       setState(() {
//         hasExistingAppointment = querySnapshot.docs.isNotEmpty;
//       });
//     } catch (e) {
//       debugPrint('Error checking existing appointments: $e');
//     }
//   }

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     if (await canLaunchUrl(launchUri)) {
//       await launchUrl(launchUri);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not launch dialer')),
//       );
//     }
//   }

//   void showLocationDialog(String address) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Location'),
//         content: Text(address),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchSchedules();
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();
          


//       setState(() {
//         schedules = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             ...doc.data(),
//           };
//         }).toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading schedules: ${e.toString()}')),
//       );
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = FirebaseAuth.instance.currentUser?.uid;
    
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You must be logged in')),
//       );
//       return;
//     }

//     try {
//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'] ?? 'Unknown Doctor',
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'] ?? 'General',
//         'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//       });

//      ScaffoldMessenger.of(context).showSnackBar(
//   SnackBar(
//     content: const Text(
//       'Appointment requested successfully!',
//       style: TextStyle(color: Colors.white),
//     ),
//     backgroundColor: Colors.green,
//   ),
// );
      
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to request appointment: ${e.toString()}')),
//       );
//     }
//   }

//   int _calculateFee(int experience) {
//     if (experience <= 4) return 50;
//     if (experience <= 7) return 150;
//     return 200;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Doctor Info Card
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 30,
//                             backgroundColor: Colors.blue.shade100,
//                             child: Text(
//                               widget.doctorData['fullName']?.isNotEmpty == true
//                                   ? widget.doctorData['fullName'][0].toUpperCase()
//                                   : 'D',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 color: Colors.blue.shade900,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                                 ),
//                                 Text(
//                                   'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
                  
//                   // Action Buttons
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.call, size: 30, color: Colors.green),
//                           onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//                           tooltip: 'Call Doctor',
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.message, size: 30, color: Colors.blue),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ChatScreen(
//                                   doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                                   doctorId: widget.doctorId,
//                                 ),
//                               ),
//                             );
//                           },
//                           tooltip: 'Send Message',
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.location_on, size: 30, color: Colors.red),
//                           onPressed: () => showLocationDialog(
//                             widget.doctorData['address'] ?? 'Location not available',
//                           ),
//                           tooltip: 'Show Location',
//                         ),
//                       ],
//                     ),
//                   ),
                  
//                   const Divider(),
                  
//                   // Available Schedules
//                   const Text(
//                     'Available Schedules',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
                  
//                   Expanded(
//                     child: schedules.isEmpty
//                         ? const Center(child: Text('No available schedules'))
//                         : ListView.builder(
//                             itemCount: schedules.length,
//                             itemBuilder: (context, index) {
//                               final schedule = schedules[index];
//                               final isSelected = selectedScheduleIndex == index;
                              
//                               return Card(
//                                 margin: const EdgeInsets.symmetric(vertical: 4),
//                                 color: isSelected ? Colors.blue.shade50 : null,
//                                 child: ListTile(
//                                   title: Text(
//                                     _formatDate(schedule['date']),
//                                     style: const TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                   subtitle: Text(
//                                     '${_formatTime(schedule['startTime'])} - ${_formatTime(schedule['endTime'])}',
//                                   ),
//                                   trailing: ElevatedButton(
//                                     onPressed: () => _selectSchedule(index),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                                     ),
//                                     child: Text(
//                                       isSelected ? 'Selected' : 'Select',
//                                       style: const TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                   onTap: () => _selectSchedule(index),
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
                  
//                   // Request Appointment Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _requestAppointment,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue.shade800,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       child: const Text(
//                         'Request Appointment',
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp timestamp) {
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: cleanedNumber,
//     );
    
//     if (await canLaunchUrl(launchUri)) {
//       await launchUrl(launchUri);
//     } else {
//       throw 'Could not launch dialer';
//     }
//   }

//   void showLocationDialog(String address, String? location) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Location'),
//         content: Text(address),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchSchedules();
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       setState(() {
//         schedules = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             ...doc.data(),
//           };
//         }).toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading schedules: $e')),
//       );
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = 'current_user_id'; // Replace with actual user ID

//     try {
//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'],
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'],
//         'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Appointment requested successfully!')),
//       );
      
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to request appointment: $e')),
//       );
//     }
//   }

//   int _calculateFee(int experience) {
//     if (experience >= 1 && experience <= 4) return 50;
//     if (experience >= 5 && experience <= 7) return 150;
//     return 200;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Doctor Info Card
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 30,
//                             backgroundColor: Colors.blue.shade100,
//                             child: Text(
//                               widget.doctorData['fullName']?.isNotEmpty == true
//                                   ? widget.doctorData['fullName'][0].toUpperCase()
//                                   : 'D',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 color: Colors.blue.shade900,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                                 ),
//                                 Text(
//                                   'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.call, size: 30, color: Colors.green),
//                         onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//                         tooltip: 'Call Doctor',
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.message, size: 30, color: Colors.blue),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => ChatScreen(
//                                 doctorName: widget.doctorData['fullName'] ?? 'Doctor',
//                                 doctorImage: widget.doctorData['image'] ?? '',
//                               ),
//                             ),
//                           );
//                         },
//                         tooltip: 'Send Message',
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.location_on, size: 30, color: Colors.red),
//                         onPressed: () => showLocationDialog(
//                           widget.doctorData['address'] ?? 'Location not available',
//                           widget.doctorData['location']?.toString(),
//                         ),
//                         tooltip: 'Show Location',
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Available Schedules
//                   const Text(
//                     'Available Schedules',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
                  
//                   Expanded(
//                     child: schedules.isEmpty
//                         ? const Center(child: Text('No available schedules'))
//                         : ListView.builder(
//                             itemCount: schedules.length,
//                             itemBuilder: (context, index) {
//                               final schedule = schedules[index];
//                               final isSelected = selectedScheduleIndex == index;
                              
//                               return Card(
//                                 color: isSelected ? Colors.blue.shade50 : null,
//                                 child: ListTile(
//                                   title: Text(
//                                     _formatDate(schedule['date'] as Timestamp?),
//                                     style: const TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                   subtitle: Text(
//                                     '${_formatTime(schedule['startTime'] as Timestamp?)} - ${_formatTime(schedule['endTime'] as Timestamp?)}',
//                                   ),
//                                   trailing: ElevatedButton(
//                                     onPressed: () => _selectSchedule(index),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                                     ),
//                                     child: Text(
//                                       isSelected ? 'Selected' : 'Select',
//                                       style: const TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Request Appointment Button
//                   ElevatedButton(
//                     onPressed: _requestAppointment,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue.shade800,
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     child: const Text(
//                       'Request Appointment',
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'No date';
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'No time';
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }

















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;

//   Future<void> makePhoneCall(String phoneNumber) async {
//     final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: cleanedNumber,
//     );
    
//     if (await canLaunchUrl(launchUri)) {
//       await launchUrl(launchUri);
//     } else {
//       throw 'Could not launch dialer';
//     }
//   }

//   void showLocationDialog(String address, String? location) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Location'),
//         content: Text(address),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchSchedules();
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       setState(() {
//         schedules = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             ...doc.data(),
//           };
//         }).toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading schedules: $e')),
//       );
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = 'current_user_id'; // Replace with actual user ID

//     try {
//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'],
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'],
//         'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Appointment requested successfully!')),
//       );
      
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to request appointment: $e')),
//       );
//     }
//   }

//   int _calculateFee(int experience) {
//     if (experience >= 1 && experience <= 4) return 50;
//     if (experience >= 5 && experience <= 7) return 150;
//     return 200;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Doctor Info Card
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 30,
//                             backgroundColor: Colors.blue.shade100,
//                             child: Text(
//                               widget.doctorData['fullName']?.isNotEmpty == true
//                                   ? widget.doctorData['fullName'][0].toUpperCase()
//                                   : 'D',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 color: Colors.blue.shade900,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                                 ),
//                                 Text(
//                                   'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.call, size: 30, color: Colors.green),
//                         onPressed: () => makePhoneCall(widget.doctorData['phone'] ?? ''),
//                         tooltip: 'Wac Dhakhtarka',
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.message, size: 30, color: Colors.blue),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => ChatScreen(
//                                 doctorName: widget.doctorData['fullName'] ?? 'Dhakhtar',
//                                 doctorImage: widget.doctorData['image'] ?? '',
//                               ),
//                             ),
//                           );
//                         },
//                         tooltip: 'Fariin u dir',
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.location_on, size: 30, color: Colors.red),
//                         onPressed: () => showLocationDialog(
//                           widget.doctorData['address'] ?? 'Goobta aan la garanayn',
//                           widget.doctorData['location']?.toString(),
//                         ),
//                         tooltip: 'Muuji Goobta',
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Available Schedules
//                   const Text(
//                     'Available Schedules',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
                  
//                   Expanded(
//                     child: schedules.isEmpty
//                         ? const Center(child: Text('No available schedules'))
//                         : ListView.builder(
//                             itemCount: schedules.length,
//                             itemBuilder: (context, index) {
//                               final schedule = schedules[index];
//                               final isSelected = selectedScheduleIndex == index;
                              
//                               return Card(
//                                 color: isSelected ? Colors.blue.shade50 : null,
//                                 child: ListTile(
//                                   title: Text(
//                                     _formatDate(schedule['date'] as Timestamp?),
//                                     style: const TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                   subtitle: Text(
//                                     '${_formatTime(schedule['startTime'] as Timestamp?)} - ${_formatTime(schedule['endTime'] as Timestamp?)}',
//                                   ),
//                                   trailing: ElevatedButton(
//                                     onPressed: () => _selectSchedule(index),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                                     ),
//                                     child: Text(
//                                       isSelected ? 'Selected' : 'Select',
//                                       style: const TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Request Appointment Button
//                   ElevatedButton(
//                     onPressed: _requestAppointment,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue.shade800,
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     child: const Text(
//                       'Request Appointment',
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'No date';
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'No time';
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }






























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../chat/chat_screen.dart';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;


//   Future<void> makePhoneCall(String phoneNumber) async {
//     // First clean the phone number by removing any non-digit characters
//     final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
//     // Create the tel URI which will open the dialer with the number pre-filled
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: cleanedNumber,
//       //doctorka numberkiisa ka soo aqriso collector doctors
//     );
    
//     if (await canLaunchUrl(launchUri)) {
//       await launchUrl(launchUri);
//     } else {
//       throw 'Could not launch dialer';
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchSchedules();
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       setState(() {
//         schedules = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             ...doc.data(),
//           };
//         }).toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading schedules: $e')),
//       );
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = 'current_user_id'; // Replace with actual user ID

//     try {
//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'],
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'],
//         'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Appointment requested successfully!')),
//       );
      
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to request appointment: $e')),
//       );
//     }
//   }

//   int _calculateFee(int experience) {
//     if (experience >= 1 && experience <= 4) return 50;
//     if (experience >= 5 && experience <= 7) return 150;
//     return 200;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', 
//                style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade900,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Doctor Info Card
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 30,
//                             backgroundColor: Colors.blue.shade100,
//                             child: Text(
//                               widget.doctorData['fullName']?.isNotEmpty == true
//                                   ? widget.doctorData['fullName'][0].toUpperCase()
//                                   : 'D',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 color: Colors.blue.shade900,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                                 ),
//                                 Text(
//                                   'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.call, size: 30, color: Colors.green),
//                   onPressed: () => makePhoneCall(doctorData['phone'] ?? ''),
//                   tooltip: 'Wac Dhakhtarka',
//                 ),
//                 // ... [rest of your existing buttons] ...
//               ],
//             ),
//              IconButton(
//                   icon: const Icon(Icons.message, size: 30, color: Colors.blue),
//                   onPressed: () => ChatScreen(
//                     doctorData['fullName'] ?? 'Dhakhtar',
//                     doctorData['image'] ?? '',
//                   ),
//                   tooltip: 'Fariin u dir',
//                 ),

//             IconButton(
//                   icon: const Icon(Icons.location_on, size: 30, color: Colors.red),
//                   onPressed: () => showLocationDialog(
//                     doctorData['address'] ?? 'Goobta aan la garanayn',
//                     doctorData['location']?.toString(),
//                   ),
//                   tooltip: 'Muuji Goobta',
//                 ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Available Schedules
//                   const Text(
//                     'Available Schedules',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
                  
//                   Expanded(
//                     child: schedules.isEmpty
//                         ? const Center(child: Text('No available schedules'))
//                         : ListView.builder(
//                             itemCount: schedules.length,
//                             itemBuilder: (context, index) {
//                               final schedule = schedules[index];
//                               final isSelected = selectedScheduleIndex == index;
                              
//                               return Card(
//                                 color: isSelected ? Colors.blue.shade50 : null,
//                                 child: ListTile(
//                                   title: Text(
//                                     _formatDate(schedule['date'] as Timestamp?),
//                                     style: const TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                   subtitle: Text(
//                                     '${_formatTime(schedule['startTime'] as Timestamp?)} - ${_formatTime(schedule['endTime'] as Timestamp?)}',
//                                   ),
//                                   trailing: ElevatedButton(
//                                     onPressed: () => _selectSchedule(index),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                                     ),
//                                     child: Text(
//                                       isSelected ? 'Selected' : 'Select',
//                                       style: const TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Request Appointment Button
//                   ElevatedButton(
//                     onPressed: _requestAppointment,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue.shade800,
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     child: const Text(
//                       'Request Appointment',
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'No date';
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'No time';
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }

























// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';
// import 'package:intl/intl.dart';

// class BookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;

//   const BookingScreen({
//     super.key, 
//     required this.doctorId,
//     required this.doctorData,
//   });

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   List<Map<String, dynamic>> schedules = [];
//   int? selectedScheduleIndex;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchSchedules();
//   }

//   Future<void> _fetchSchedules() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       setState(() {
//         schedules = querySnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             ...doc.data(),
//           };
//         }).toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading schedules: $e')),
//       );
//     }
//   }

//   void _selectSchedule(int index) {
//     setState(() {
//       selectedScheduleIndex = index;
//     });
//   }

//   Future<void> _requestAppointment() async {
//     if (selectedScheduleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a schedule first')),
//       );
//       return;
//     }

//     final selectedSchedule = schedules[selectedScheduleIndex!];
//     final userId = 'current_user_id'; // Replace with actual user ID

//     try {
//       // Create appointment in appointments collection
//       await FirebaseFirestore.instance.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['fullName'],
//         'userId': userId,
//         'scheduleId': selectedSchedule['id'],
//         'date': selectedSchedule['date'],
//         'startTime': selectedSchedule['startTime'],
//         'endTime': selectedSchedule['endTime'],
//         'status': 'pending',
//         'createdAt': FieldValue.serverTimestamp(),
//         'specialty': widget.doctorData['specialties'],
//         'fee': _calculateFee(widget.doctorData['experience'] ?? 0),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Appointment requested successfully!')),
//       );
      
//       Navigator.pop(context); // Return to previous screen
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to request appointment: $e')),
//       );
//     }
//   }

//   int _calculateFee(int experience) {
//     if (experience >= 1 && experience <= 4) return 50;
//     if (experience >= 5 && experience <= 7) return 150;
//     return 200;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue[900],
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Doctor Info Card
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 30,
//                             backgroundColor: Colors.blue[100],
//                             child: Text(
//                               widget.doctorData['fullName']?.isNotEmpty == true
//                                   ? widget.doctorData['fullName'][0].toUpperCase()
//                                   : 'D',
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 color: Colors.blue[900],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   widget.doctorData['fullName'] ?? 'Unknown Doctor',
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   'Specialty: ${widget.doctorData['specialties'] ?? 'General'}',
//                                 ),
//                                 Text(
//                                   'Fee: \$${_calculateFee(widget.doctorData['experience'] ?? 0)}',
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Available Schedules
//                   const Text(
//                     'Available Schedules',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
                  
//                   Expanded(
//                     child: schedules.isEmpty
//                         ? const Center(child: Text('No available schedules'))
//                         : ListView.builder(
//                             itemCount: schedules.length,
//                             itemBuilder: (context, index) {
//                               final schedule = schedules[index];
//                               final isSelected = selectedScheduleIndex == index;
                              
//                               return Card(
//                                 color: isSelected ? Colors.blue[50] : null,
//                                 child: ListTile(
//                                   title: Text(
//                                     _formatDate(schedule['date'] as Timestamp?),
//                                     style: const TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                   subtitle: Text(
//                                     '${_formatTime(schedule['startTime'] as Timestamp?)} - ${_formatTime(schedule['endTime'] as Timestamp?)}',
//                                   ),
//                                   trailing: ElevatedButton(
//                                     onPressed: () => _selectSchedule(index),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                                     ),
//                                     child: Text(
//                                       isSelected ? 'Selected' : 'Select',
//                                       style: const TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Request Appointment Button
//                   ElevatedButton(
//                     onPressed: _requestAppointment,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[800],
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     child: const Text(
//                       'Request Appointment',
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'No date';
//     return DateFormat('EEE, MMM d, y').format(timestamp.toDate());
//   }

//   String _formatTime(Timestamp? timestamp) {
//     if (timestamp == null) return 'No time';
//     return DateFormat('h:mm a').format(timestamp.toDate());
//   }
// }
















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../chat/chat_screen.dart';


// class BookingScreen extends StatefulWidget {
//   final String doctorId; // Now accepting doctor ID instead of full data

//   const BookingScreen({super.key, required this.doctorId});

//   @override
//   State<BookingScreen> createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   late Future<Map<String, dynamic>> _doctorFuture;
//   List<Map<String, dynamic>> schedule = [];
//   int? selectedIndex;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _doctorFuture = _fetchDoctorData();
//   }

//   Future<Map<String, dynamic>> _fetchDoctorData() async {
//     try {
//       // Fetch doctor main data
//       final doctorDoc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .get();
      
//       if (!doctorDoc.exists) {
//         throw Exception('Doctor not found');
//       }

//       final doctorData = doctorDoc.data() as Map<String, dynamic>;

//       // Fetch schedule subcollection
//       final scheduleQuery = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('schedules')
//           .get();

//       schedule = scheduleQuery.docs.map((doc) => doc.data()).toList();

//       setState(() {
//         isLoading = false;
//       });

//       return doctorData;
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       throw Exception('Failed to load doctor data: $e');
//     }
//   }

//   void selectSchedule(int index) {
//     if (selectedIndex == null) {
//       setState(() {
//         selectedIndex = index;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(
//           'Appointment booked for ${schedule[index]['day']}!',
//           style: const TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.green,
//       ));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: const Text(
//           'You already booked a schedule. Only one can be selected.',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.red,
//       ));
//     }
//   }

//   void openChatScreen(String doctorName, String imageUrl) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChatScreen(
//           fullName: doctorName,
//           image: imageUrl,
//         ),
//       ),
//     );
//   }

//   void showLocationDialog(String address, String? locationCoords) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Doctor Location'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Address: ${address.isNotEmpty ? address : 'No address provided'}'),
//             const SizedBox(height: 10),
//             SizedBox(
//               height: 200,
//               width: double.infinity,
//               child: locationCoords != null && locationCoords.isNotEmpty
//                   ? Image.network(
//                       'https://maps.googleapis.com/maps/api/staticmap?center=$locationCoords&zoom=15&size=600x300&maptype=roadmap&markers=color:red%7C$locationCoords&key=YOUR_API_KEY',
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => 
//                           const Center(child: Text('Could not load map')),
//                     )
//                   : const Center(child: Text('Location not available')),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   void makePhoneCall(String phoneNumber) async {
//     if (phoneNumber.trim().isNotEmpty) {
//       final Uri phoneUri = Uri.parse('tel:$phoneNumber');
//       if (await canLaunchUrl(phoneUri)) {
//         await launchUrl(phoneUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text('Could not launch phone dialer'),
//           backgroundColor: Colors.red,
//         ));
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text("Doctor doesn't have a phone number."),
//         backgroundColor: Colors.orange,
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book Appointment', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue[900],
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _doctorFuture,
//         builder: (context, snapshot) {
//           if (isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
          
//           if (!snapshot.hasData) {
//             return const Center(child: Text('Doctor data not found'));
//           }
          
//           final doctor = snapshot.data!;
          
//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 35,
//                       backgroundImage: NetworkImage(doctor['image'] ?? ''),
//                       onBackgroundImageError: (_, __) => const Icon(Icons.person),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(doctor['fullName'] ?? 'Unknown Doctor',
//                               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                           Text(doctor['specialization'] ?? 'General Practitioner'),
//                           Text('Fee: \$${doctor['fee'] ?? '20'}'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.call, size: 30, color: Colors.green),
//                       onPressed: () => makePhoneCall(doctor['phone'] ?? ''),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.message, size: 30, color: Colors.blue),
//                       onPressed: () => openChatScreen(
//                         doctor['fullName'] ?? 'Doctor',
//                         doctor['image'] ?? '',
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.location_on, size: 30, color: Colors.red),
//                       onPressed: () => showLocationDialog(
//                         doctor['address'] ?? '',
//                         doctor['location']?.toString(),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 const Text('Available Schedule',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 10),
//                 Expanded(
//                   child: schedule.isNotEmpty
//                       ? ListView.builder(
//                           itemCount: schedule.length,
//                           itemBuilder: (context, index) {
//                             final item = schedule[index];
//                             final isSelected = selectedIndex == index;

//                             return Card(
//                               color: isSelected ? Colors.blue[100] : null,
//                               child: ListTile(
//                                 title: Text(item['day'] ?? 'No day specified'),
//                                 subtitle: Text(item['time'] ?? 'No time specified'),
//                                 trailing: ElevatedButton(
//                                   onPressed: () => selectSchedule(index),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: isSelected ? Colors.grey : Colors.blue,
//                                   ),
//                                   child: Text(
//                                     isSelected ? 'Selected' : 'Book',
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         )
//                       : const Center(child: Text('No available schedules')),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.calendar_month, color: Colors.white),
//                   onPressed: () {
//                     if (selectedIndex != null) {
//                       final item = schedule[selectedIndex!];

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => ConfirmAppointmentScreen(
//                             doctorName: doctor['fullName'] ?? 'Unknown Doctor',
//                             doctorImage: doctor['image'] ?? '',
//                             day: item['day'] ?? '',
//                             time: item['time'] ?? '',
//                             fee: doctor['fee']?.toString() ?? '',
//                           ),
//                         ),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                         content: Text(
//                           'Please select a schedule before Requested.',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                         backgroundColor: Colors.orange,
//                       ));
//                     }
//                   },
//                   label: const Text('Request Appointment', style: TextStyle(color: Colors.white)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                     textStyle: const TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }