import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;

    const Color primaryColor = Color(0xFF0D47A1);
    const Color textColor = Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: Colors.blue[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderText(
                "Haddii aadan fahmin sida app-kan u shaqeeyo sida bookings, tracking iyo wixii la mid ah, nala soo xiriir.",
                width,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("Email Support", primaryColor, width),
              _buildContactCard(
                context,
                width,                
                //  icon: Icons.email,
                contactList: const [
                  'daganabdi757@gmail.com',
                  'shifa@gmail.com',
                  'anas@gmail.com',
                  'zeynab@gmail.com',
                ],
                isEmail: true,
              ),
              const SizedBox(height: 30),
              _buildSectionTitle("Phone Support", primaryColor, width),
              _buildContactCard(
                context,
                width,
                // icon: Icons.phone,
                contactList: const [
                  "0613683011",
                  "0613435656",
                  "0617194354",
                  "0618601423",
                ],
                isEmail: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText(String text, double width) {
    return Text(
      text,
      style: TextStyle(
        fontSize: width * 0.042,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.05,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    double width, {
    // required IconData icon,
    required List<String> contactList,
    required bool isEmail,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(width * 0.045),
        child: Column(
          children: contactList.map((contact) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  // Icon(icon, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      contact,
                      style: TextStyle(fontSize: width * 0.038),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      isEmail
                          ? _sendEmail(contact, context)
                          : _makePhoneCall(contact, context);
                    },
                    icon: Icon(
                      isEmail ? Icons.send : Icons.call,
                      size: width * 0.035,
                    ),
                    label: Text(
                      isEmail ? 'Email' : 'Call',
                      style: TextStyle(fontSize: width * 0.032),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEmail ? Colors.blue[900] : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String number, BuildContext context) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError(context, "Can't open phone dialer.");
      }
    } catch (e) {
      _showError(context, 'Error making call: $e');
    }
  }

  Future<void> _sendEmail(String email, BuildContext context) async {
  if (!_isValidEmail(email)) {
    _showError(context, 'Invalid email: $email');
    return;
  }

  final Uri uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      'subject': 'Support Request',
      'body': 'Hello, I need help with...',
    },
  );

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError(context, 'No email client found.');
    }
  } catch (e) {
    _showError(context, 'Error sending email: $e');
  }
}

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
  }
}








// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final width = mediaQuery.size.width;
//     final height = mediaQuery.size.height;

//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Contact Us"),
//         backgroundColor: primaryColor,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(
//             horizontal: width * 0.05,
//             vertical: height * 0.02,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeaderText(
//                 "Haddii aadan fahmin sida app-kan u shaqeeyo sida bookings, tracking iyo wixii la mid ah, nala soo xiriir.",
//                 width,
//               ),
//               const SizedBox(height: 20),
//               _buildSectionTitle("Email Support", primaryColor, width),
//               _buildContactCard(
//                 context,
//                 width,
//                 icon: Icons.email,
//                 contactList: const [
//                   'daganabdi757@gmail.com',
//                   'shifa@gmail.com',
//                   'anas@gmail.com',
//                   'zeynab@gmail.com',
//                 ],
//                 isEmail: true,
//               ),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Phone Support", primaryColor, width),
//               _buildContactCard(
//                 context,
//                 width,
//                 icon: Icons.phone,
//                 contactList: const [
//                   "0613683011",
//                   "0613435656",
//                   "0617194354",
//                   "0618601423",
//                 ],
//                 isEmail: false,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderText(String text, double width) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: width * 0.042,
//         fontWeight: FontWeight.w500,
//         color: Colors.black87,
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title, Color color, double width) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: width * 0.05,
//         fontWeight: FontWeight.bold,
//         color: color,
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     double width, {
//     required IconData icon,
//     required List<String> contactList,
//     required bool isEmail,
//   }) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(width * 0.045),
//         child: Column(
//           children: contactList.map((contact) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Row(
//                 children: [
//                   Icon(icon, color: Colors.grey),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       contact,
//                       style: TextStyle(fontSize: width * 0.038),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       isEmail
//                           ? _sendEmail(contact, context)
//                           : _makePhoneCall(contact, context);
//                     },
//                     icon: Icon(
//                       isEmail ? Icons.send : Icons.call,
//                       size: width * 0.035,
//                     ),
//                     label: Text(
//                       isEmail ? 'Email' : 'Call',
//                       style: TextStyle(fontSize: width * 0.032),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isEmail ? Colors.blue : Colors.green,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Future<void> _makePhoneCall(String number, BuildContext context) async {
//     final Uri uri = Uri(scheme: 'tel', path: number);
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         _showError(context, "Can't open phone dialer.");
//       }
//     } catch (e) {
//       _showError(context, 'Error making call: $e');
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     if (!_isValidEmail(email)) {
//       _showError(context, 'Invalid email: $email');
//       return;
//     }

//     final Uri uri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {
        
//         'subject': 'Support Request',
//         'body': 'Hello, I need help with...',
//       },
//     );

//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         _showError(context, 'No email client found.');
//       }
//     } catch (e) {
//       _showError(context, 'Error sending email: $e');
//     }
//   }

//   void _showError(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
  

//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//     ).hasMatch(email);
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final width = mediaQuery.size.width;
//     final height = mediaQuery.size.height;

//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Contact Us"),
//         backgroundColor: primaryColor,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(
//             horizontal: width * 0.05,
//             vertical: height * 0.02,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeaderText(
//                 "Haddii aadan fahmin sida app-kan u shaqeeyo sida bookings, tracking iyo wixii la mid ah, nala soo xiriir.",
//                 width,
//               ),
//               const SizedBox(height: 20),
//               _buildSectionTitle("Email Support", primaryColor, width),
//               _buildContactCard(
//                 context,
//                 width,
//                 icon: Icons.email,
//                 contactList: const [
//                   'daganabdi757@gmail.com',
//                   'shifa@gmail.com',
//                   'anas@gmail.com',
//                   'zeynab@gmail.com',
//                 ],
//                 isEmail: true,
//               ),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Phone Support", primaryColor, width),
//               _buildContactCard(
//                 context,
//                 width,
//                 icon: Icons.phone,
//                 contactList: const [
//                   "0613683011",
//                   "0613435656",
//                   "0617194354",
//                   "0618601423",
//                 ],
//                 isEmail: false,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderText(String text, double width) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: width * 0.042,
//         fontWeight: FontWeight.w500,
//         color: Colors.black87,
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title, Color color, double width) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: width * 0.05,
//         fontWeight: FontWeight.bold,
//         color: color,
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     double width, {
//     required IconData icon,
//     required List<String> contactList,
//     required bool isEmail,
//   }) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(width * 0.045),
//         child: Column(
//           children: contactList.map((contact) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Row(
//                 children: [
//                   Icon(icon, color: Colors.grey),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       contact,
//                       style: TextStyle(fontSize: width * 0.038),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       isEmail
//                           ? _sendEmail(contact, context)
//                           : _makePhoneCall(contact, context);
//                     },
//                     icon: Icon(
//                       isEmail ? Icons.send : Icons.call,
//                       size: width * 0.035,
//                     ),
//                     label: Text(
//                       isEmail ? 'Email' : 'Call',
//                       style: TextStyle(fontSize: width * 0.032),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isEmail ? Colors.blue : Colors.green,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Future<void> _makePhoneCall(String number, BuildContext context) async {
//     final Uri uri = Uri(scheme: 'tel', path: number);
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         _showError(context, "Can't open phone dialer.");
//       }
//     } catch (e) {
//       _showError(context, 'Error making call: $e');
//     }
//   }
//     Future<void> _sendEmail(String email, BuildContext context) async {
//     final Uri uri = Uri(scheme: 'email', path: email);
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         _showError(context, "Can't open email client.");
//       }
//     } catch (e) {
//       _showError(context, 'Error sending email: $e');
//     }
//   }

//   // Future<void> _sendEmail(String email, BuildContext context) async {
//   //   if (!_isValidEmail(email)) {
//   //     _showError(context, 'Invalid email: $email');
//   //     return;
//   //   }

//   //   final Uri uri = Uri(
//   //     scheme: 'mailto',
//   //     path: email,
//   //     queryParameters: {
//   //       'subject': 'Support Request',
//   //       'body': 'Hello, I need help with...',
//   //     },
//   //   );

//   //   try {
//   //     if (await canLaunchUrl(uri)) {
//   //       await launchUrl(uri);
//   //     } else {
//   //       _showError(context, 'No email client found.');
//   //     }
//   //   } catch (e) {
//   //     _showError(context, 'Error sending email: $e');
//   //   }
//   // }

//   void _showError(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//     ).hasMatch(email);
//   }
// }



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final width = mediaQuery.size.width;
//     final height = mediaQuery.size.height;

//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Contact Us"),
//         backgroundColor: primaryColor,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(
//             horizontal: width * 0.05,
//             vertical: height * 0.02,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeaderText(
//                 "Haddii aadan fahmin sida app-kan u shaqeeyo sida bookings, tracking iyo wixii la mid ah, nala soo xiriir.",
//                 width,
//               ),
//               const SizedBox(height: 20),
//               _buildSectionTitle("Email Support", primaryColor, width),
//               _buildContactCard(
//                 context,
//                 width,
//                 icon: Icons.email,
//                 contactList: const [
//                   'daganabdi757@gmail.com',
//                   'shifa@gmail.com',
//                   'anas@gmail.com',
//                   'zeynab@gmail.com',
//                 ],
//                 isEmail: true,
//               ),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Phone Support", primaryColor, width),
//               _buildContactCard(
//                 context,
//                 width,
//                 icon: Icons.phone,
//                 contactList: const [
//                   "0613683011",
//                   "0613435656",
//                   "0617194354",
//                   "0618601423",
//                 ],
//                 isEmail: false,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderText(String text, double width) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: width * 0.042,
//         fontWeight: FontWeight.w500,
//         color: Colors.black87,
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title, Color color, double width) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: width * 0.05,
//         fontWeight: FontWeight.bold,
//         color: color,
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     double width, {
//     required IconData icon,
//     required List<String> contactList,
//     required bool isEmail,
//   }) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(width * 0.045),
//         child: Column(
//           children: contactList.map((contact) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Row(
//                 children: [
//                   Icon(icon, color: Colors.grey),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       contact,
//                       style: TextStyle(fontSize: width * 0.038),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       isEmail
//                           ? _sendEmail(contact, context)
//                           : _makePhoneCall(contact, context);
//                     },
//                     icon: Icon(
//                       isEmail ? Icons.send : Icons.call,
//                       size: width * 0.035,
//                     ),
//                     label: Text(
//                       isEmail ? 'Email' : 'Call',
//                       style: TextStyle(fontSize: width * 0.032),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isEmail ? Colors.blue : Colors.green,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Future<void> _makePhoneCall(String number, BuildContext context) async {
//     final Uri uri = Uri(scheme: 'tel', path: number);
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         _showError(context, "Can't open phone dialer.");
//       }
//     } catch (e) {
//       _showError(context, 'Error making call: $e');
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     if (!_isValidEmail(email)) {
//       _showError(context, 'Invalid email: $email');
//       return;
//     }

//     final Uri uri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {
//         'subject': 'Support Request',
//         'body': 'Hello, I need help with...',
//       },
//     );

//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         _showError(context, 'No email client found.');
//       }
//     } catch (e) {
//       _showError(context, 'Error sending email: $e');
//     }
//   }

//   void _showError(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//     ).hasMatch(email);
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pushNamed(context, '/home');
//           },
//         ),
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: EdgeInsets.all(constraints.maxWidth * 0.05),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                  const SizedBox(height: 10),
//                 Text(
//                   "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Nagala soo xiriir:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 _buildEmailCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by email",
//                   emails: const [
//                     'daganabdi757@gmail.com',
//                     'shifa@gmail.com',
//                     'anas@gmail.com',
//                     'zeynab@gmail.com',
//                   ],
//                   icon: Icons.support_agent,
//                   color: primaryColor,
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 _buildContactCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by number",
//                   numbers: const [
//                     "0613683011",
//                     "0613435656",
//                     "0617194354",
//                     "0618601423",
//                   ],
//                   icon: Icons.people,
//                   color: primaryColor,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context, constraints),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context, constraints),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(
//     String number,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(
//     String email,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//     required BoxConstraints constraints,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: constraints.maxWidth * 0.035),
//       label: Text(
//         label,
//         style: TextStyle(fontSize: constraints.maxWidth * 0.03),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: constraints.maxWidth * 0.02,
//           vertical: constraints.maxWidth * 0.015,
//         ),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     if (!_isValidEmail(email)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Invalid email format: $email'),
//           duration: const Duration(seconds: 3)),
//       );
//       return;
//     }

//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {
//         'subject': 'App Inquiry',
//         'body': 'Hello,\n\nI would like to get more information about...',
//       },
//     );

//     if (!await canLaunchUrl(emailUri)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('No email app found. Please install an email client.'),
//           duration: const Duration(seconds: 5),
//           action: SnackBarAction(
//             label: 'OK',
//             onPressed: () {},
//           ),
//         ),
//       );
//       return;
//     }

//     try {
//       await launchUrl(emailUri);
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to open email: ${e.toString()}'),
//           duration: const Duration(seconds: 3),
//       ),
//       );
//     }
//   }
  
//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
//     ).hasMatch(email);
//   }
// }

















// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pushNamed(context, '/home');
//           },
//         ),
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: EdgeInsets.all(constraints.maxWidth * 0.05),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Nagala soo xiriir:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 _buildEmailCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by email",
//                   emails: const [
//                     'daganabdi757@gmail.com',
//                     'shifa@gmail.com',
//                     'anas@gmail.com',
//                     'zeynab@gmail.com',
//                   ],
//                   icon: Icons.support_agent,
//                   color: primaryColor,
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 _buildContactCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by number",
//                   numbers: const [
//                     "0613683011",
//                     "0613435656",
//                     "0617194354",
//                     "0618601423",
//                   ],
//                   icon: Icons.people,
//                   color: primaryColor,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context, constraints),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context, constraints),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(
//     String number,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(
//     String email,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//     required BoxConstraints constraints,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: constraints.maxWidth * 0.035),
//       label: Text(
//         label,
//         style: TextStyle(fontSize: constraints.maxWidth * 0.03),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: constraints.maxWidth * 0.02,
//           vertical: constraints.maxWidth * 0.015,
//         ),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     if (!_isValidEmail(email)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Invalid email format: $email'),
//           duration: const Duration(seconds: 3)),
//       );
//       return;
//     }

//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {
//         'subject': 'App Inquiry',
//         'body': 'Hello,\n\nI would like to get more information about...',
//       },
//     );

//     if (!await canLaunchUrl(emailUri)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('No email app found. Please install an email client.'),
//           duration: const Duration(seconds: 5),
//           action: SnackBarAction(
//             label: 'OK',
//             onPressed: () {},
//           ),
//         ),
//       );
//       return;
//     }

//     try {
//       await launchUrl(emailUri);
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to open email: ${e.toString()}'),
//           duration: const Duration(seconds: 3),
//       ),
//       );
//     }
//   }
  
//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
//     ).hasMatch(email);
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//     //   appBar: AppBar(
//     //     title: const Text('Contact Us'),
//     //     backgroundColor: primaryColor,
//     //     elevation: 4,
//     //     centerTitle: true,
//     //  leading: true,
        
//     //   ),
//     appBar: AppBar(
//         title: const Text('Contact Us'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: (
//             Navigator.pushNamed(context, '/home');
//           ) => Navigator.maybePop(context),
//         ),
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: EdgeInsets.all(constraints.maxWidth * 0.05),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Nagala soo xiriir:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 _buildEmailCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by email",
//                   emails: const [
//                     'daganabdi757@gmail.com',
//                     'shifa@gmail.com',
//                     'anas@gmail.com',
//                     'zeynab@gmail.com',
//                   ],
//                   icon: Icons.support_agent,
//                   color: primaryColor,
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 _buildContactCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by number",
//                   numbers: const [
//                     "0613683011",
//                     "0613435656",
//                     "0617194354",
//                     "0618601423",
//                   ],
//                   icon: Icons.people,
//                   color: primaryColor,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // Rest of your helper methods remain unchanged...
//   Widget _buildContactCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context, constraints),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context, constraints),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(
//     String number,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(
//     String email,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//     required BoxConstraints constraints,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: constraints.maxWidth * 0.035),
//       label: Text(
//         label,
//         style: TextStyle(fontSize: constraints.maxWidth * 0.03),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: constraints.maxWidth * 0.02,
//           vertical: constraints.maxWidth * 0.015,
//         ),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     if (!_isValidEmail(email)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Invalid email format: $email'),
//           duration: const Duration(seconds: 3)),
//       );
//       return;
//     }

//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {
//         'subject': 'App Inquiry',
//         'body': 'Hello,\n\nI would like to get more information about...',
//       },
//     );

//     if (!await canLaunchUrl(emailUri)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('No email app found. Please install an email client.'),
//           duration: const Duration(seconds: 5),
//           action: SnackBarAction(
//             label: 'OK',
//             onPressed: () {},
//           ),
//         ),
//       );
//       return;
//     }

//     try {
//       await launchUrl(emailUri);
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to open email: ${e.toString()}'),
//           duration: const Duration(seconds: 3),
//       ),
//       );
//     }
//   }
  
//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
//     ).hasMatch(email);
//   }
// }












// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Contact Us'),
//         backgroundColor: primaryColor,
//         elevation: 4,
//         centerTitle: true,
//         automaticallyImplyLeading: true,
//       ),
//       body: LayoutBuilder(
//         ElevatedButton(
//   onPressed: () {
//     Navigator.pop(context);
//   },
//   child: Text("Back"),
// );
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: EdgeInsets.all(constraints.maxWidth * 0.05),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 // const SizedBox(height: 10),
//                 // Text(
//                 //   "Hadii aad rabto inan wax ku darno appkan ama aad qalad ka dhex dhacayo aad aragto nagala soo xariir emailadan",
//                 //   style: TextStyle(
//                 //     fontSize: constraints.maxWidth * 0.045,
//                 //     fontWeight: FontWeight.bold,
//                 //     color: textColor,
//                 //   ),
//                 // ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Nagala soo xiriir:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 _buildEmailCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by email",
//                   emails: const [
//                     'daganabdi757@gmail.com',
//                     'shifa@gmail.com',
//                     'anas@gmail.com',
//                     'zeynab@gmail.com',
//                   ],
//                   icon: Icons.support_agent,
//                   color: primaryColor,
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 _buildContactCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by number",
//                   numbers: const [
//                     "0613683011",
//                     "0613435656",
//                     "0617194354",
//                     "0618601423",
//                   ],
//                   icon: Icons.people,
//                   color: primaryColor,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // Rest of your helper methods remain unchanged...
//   Widget _buildContactCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context, constraints),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context, constraints),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(
//     String number,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(
//     String email,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//     required BoxConstraints constraints,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: constraints.maxWidth * 0.035),
//       label: Text(
//         label,
//         style: TextStyle(fontSize: constraints.maxWidth * 0.03),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: constraints.maxWidth * 0.02,
//           vertical: constraints.maxWidth * 0.015,
//         ),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     if (!_isValidEmail(email)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Invalid email format: $email'),
//           duration: const Duration(seconds: 3)),
//       );
//       return;
//     }

//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {
//         'subject': 'App Inquiry',
//         'body': 'Hello,\n\nI would like to get more information about...',
//       },
//     );

//     if (!await canLaunchUrl(emailUri)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('No email app found. Please install an email client.'),
//           duration: const Duration(seconds: 5),
//           action: SnackBarAction(
//             label: 'OK',
//             onPressed: () {},
//           ),
//         ),
//       );
//       return;
//     }

//     try {
//       await launchUrl(emailUri);
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to open email: ${e.toString()}'),
//           duration: const Duration(seconds: 3),
//       ),
//       );
//     }
//   }
  
//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
//     ).hasMatch(email);
//   }
// }

















// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);
  

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//   title: const Text('Contact Us'),
//   backgroundColor: primaryColor,
//   elevation: 4,
//   centerTitle: true,
//    automaticallyImplyLeading: true,
// ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: EdgeInsets.all(constraints.maxWidth * 0.05),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   "Hadii aad rabto inan wax ku darno appkan ama aad qalad ka dhex dhacayo aad aragto nagala soo xariir emailadan",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Nagala soo xiriir:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 _buildEmailCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by email",
//                   emails: const [
//                     'daganabdi757@gmail.com',
//                     'shifa@gmail.com',
//                     'anas@gmail.com',
//                     'zeynab@gmail.com',
//                   ],
//                   icon: Icons.support_agent,
//                   color: primaryColor,
//                 ),
//                 Navigator.pop(context)
                
//                 const SizedBox(height: 20),
                
//                 _buildContactCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by number",
//                   numbers: const [
//                     "0613683011",
//                     "0613435656",
//                     "0617194354",
//                     "0618601423",
//                   ],
//                   icon: Icons.people,
//                   color: primaryColor,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context, constraints),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context, constraints),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(
//     String number,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(
//     String email,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//     required BoxConstraints constraints,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: constraints.maxWidth * 0.035),
//       label: Text(
//         label,
//         style: TextStyle(fontSize: constraints.maxWidth * 0.03),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: constraints.maxWidth * 0.02,
//           vertical: constraints.maxWidth * 0.015,
//         ),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     // Validate email format first
//     if (!_isValidEmail(email)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Invalid email format: $email'),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//       return;
//     }

//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {
//         'subject': 'App Inquiry',
//         'body': 'Hello,\n\nI would like to get more information about...',
//       },
//     );

//     // Check if device can handle mailto links
//     if (!await canLaunchUrl(emailUri)) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('No email app found. Please install an email client.'),
//           duration: const Duration(seconds: 5),
//           action: SnackBarAction(
//             label: 'OK',
//             onPressed: () {},
//           ),
//         ),
//       );
//       return;
//     }

//     try {
//       await launchUrl(emailUri);
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to open email: ${e.toString()}'),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }
  

// bool _isValidEmail(String email) {
//   return RegExp(
//     r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
//   ).hasMatch(email);
//  }
// }

  










// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Theme colors
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Contact Us'),
//         backgroundColor: primaryColor,
//         elevation: 4,
//         centerTitle: true,
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: EdgeInsets.all(constraints.maxWidth * 0.05),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   "Hadii aad rabto inan wax ku darno appkan ama aad qalad ka dhex dhacayo aad aragto nagala soo xariir emailadan",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Nagala soo xiriir:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 _buildEmailCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by email",
//                   emails: const [
//                     'daganabdi757@gmail.com',
//                     'shifa@gmail.com',
//                     'anas@gmail.com',
//                     'zeynab@gmail.com',
//                   ],
//                   icon: Icons.support_agent,
//                   color: primaryColor,
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 _buildContactCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by number",
//                   numbers: const [
//                     "0613683011",
//                     "0613435656",
//                     "0617194354",
//                     "0618601423",
//                   ],
//                   icon: Icons.people,
//                   color: primaryColor,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context, constraints),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context, constraints),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(
//     String number,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(
//     String email,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//     required BoxConstraints constraints,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: constraints.maxWidth * 0.035),
//       label: Text(
//         label,
//         style: TextStyle(fontSize: constraints.maxWidth * 0.03),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: constraints.maxWidth * 0.02,
//           vertical: constraints.maxWidth * 0.015,
//         ),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'mailto',
//       path: email,
//       query: Uri.encodeFull('subject=App Inquiry&body=Hello, I need help with the app.'),
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No email app found. Please install an email client.')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Theme colors
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Contact Us'),
//         backgroundColor: primaryColor,
//         elevation: 4,
//         centerTitle: true,
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: EdgeInsets.all(constraints.maxWidth * 0.05), // Responsive padding
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045, // Responsive font size
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   "Hadii aad rabto inan wax ku darno appkan ama aad qalad ka dhex dhacayo aad aragto nagala soo xariir emailadan",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.045,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Nagala soo xiriir:",
//                   style: TextStyle(
//                     fontSize: constraints.maxWidth * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 // Email contact card
//                 _buildEmailCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by email",
//                   emails: const [
//                     'daganabdi757@gmail.com',
//                     'shifa@gmail.com',
//                     'anas@gmail.com',
//                     'zeynab@gmail.com',
//                   ],
//                   icon: Icons.support_agent,
//                   color: primaryColor,
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 // Phone contact card
//                 _buildContactCard(
//                   context,
//                   constraints,
//                   title: "Customer Support by number",
//                   numbers: const [
//                     "0613683011",
//                     "0613435656",
//                     "0617194354",
//                     "0618601423",
//                   ],
//                   icon: Icons.people,
//                   color: primaryColor,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context, constraints),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context,
//     BoxConstraints constraints, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(constraints.maxWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: constraints.maxWidth * 0.04,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context, constraints),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(
//     String number,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(
//     String email,
//     Color color,
//     BuildContext context,
//     BoxConstraints constraints,
//   ) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: TextStyle(fontSize: constraints.maxWidth * 0.035),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//           constraints: constraints,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//     required BoxConstraints constraints,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: constraints.maxWidth * 0.035),
//       label: Text(
//         label,
//         style: TextStyle(fontSize: constraints.maxWidth * 0.03),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: constraints.maxWidth * 0.02,
//           vertical: constraints.maxWidth * 0.015,
//         ),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     final Uri launchUri = Uri(
//   scheme: 'mailto',
//   path: email,
//   query: Uri.encodeFull('subject=App Inquiry&body=Hello, I need help with the app.'),
// );

    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No email app found. Please install an email client.')),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Theme colors
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Contact Us'),
//         backgroundColor: primaryColor,
//         elevation: 4,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               "Hadii aad rabto inan wax ku darno appkan ama aad qalad ka dhex dhacayo aad aragto nagala soo xariir emailadan",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Nagala soo xiriir:",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Email contact card
//             _buildEmailCard(
//               context,
//               title: "Customer Support by email",
//               emails: const [
//                 'daganabdi757@gmail.com',
//                 'shifa@gmail.com',
//                 'anas@gmail.com',
//                 'zeynab@gmail.com',
//               ],
//               icon: Icons.support_agent,
//               color: primaryColor,
//             ),
            
//             const SizedBox(height: 20),
            
//             // Phone contact card
//             _buildContactCard(
//               context,
//               title: "Customer Support by number",
//               numbers: const [
//                 "0613683011",
//                 "0613435656",
//                 "0617194354",
//                 "0618601423",
//               ],
//               icon: Icons.people,
//               color: primaryColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(String number, Color color, BuildContext context) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(String email, Color color, BuildContext context) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: 18),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'mailto',
//       path: email,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch email app')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Theme colors
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Contact Us'),
//         backgroundColor: primaryColor,
//         elevation: 4,
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan:",
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               "Hadii aad rabto inan wax ku darno appkan ama aad qalad ka dhex dhacayo aad aragto  nagala soo xariir emailadan",
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Nagala soo xiriir:",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Email contact card
//             _buildEmailCard(
//               context,
//               title: "Customer Support by email",
//               emails: const [
//                 'daganabdi757@gmail.com',
//                 'shifa@gmail.com',
//                 'anas@gmail.com',
//                 'zeynab@gmail.com',
//               ],
//               icon: Icons.support_agent,
//               color: primaryColor,
//             ),
            
//             const SizedBox(height: 20),
            
//             // Phone contact card
//             _buildContactCard(
//               context,
//               title: "Customer Support by number",
//               numbers: const [
//                 "0613683011",
//                 "0613435656",
//                 "0617194354",
//                 "0618601423",
//               ],
//               icon: Icons.people,
//               color: primaryColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailCard(
//     BuildContext context, {
//     required String title,
//     required List<String> emails,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...emails.map((email) => Column(
//               children: [
//                 _buildEmailRow(email, color, context),
//                 if (email != emails.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(String number, Color color, BuildContext context) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//         ),
//       ],
//     );
//   }

//   Widget _buildEmailRow(String email, Color color, BuildContext context) {
//     return Row(
//       children: [
//         const Icon(Icons.email, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             email,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.email,
//           color: Colors.blue,
//           label: 'Email',
//           onPressed: () => _sendEmail(email, context),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: 18),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _sendEmail(String email, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'mailto',
//       path: email,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch email app')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Theme colors
//     const Color primaryColor = Colors.blue;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         navigation push pop
//         title: const Text('Contact Us'),
//         backgroundColor: primaryColor,
//         elevation: 4,
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//              const Text(
//               "hadii aad fahmiweyso appkani siduu ushaqeynato si appointments ka tracking ka iyo wixii la midaa si toosa nagala soo xariir telephone numberskaan :"
//               "hadii aad rabto inan wax ku darno appkan ama aad qalad ka dhex dhacayo aad aragto nagala soo xariir emailadan",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const Text(
//               "Nagala soo xiriir:",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Contact list
//             _buildContactCard(
//               context,
//               title: "Customer Support",
//               title: "by email",
//               email: const[
//                daganabdi757@gmail.com,
//                shifa@gmail.com,
//                anas@gmail.com,
//                zeynab@gmail.com,
//               ],
//               icon: Icons.support_agent,
//               color: primaryColor,
//             ),
            
//             const SizedBox(height: 20),
            
//             _buildContactCard(
//               context,
//               title: "by number",
//               numbers: const [
//                 "0613683011",
//                 "0613435656",
//                 "0617194354",
//                 "0618601423",
//               ],
//               icon: Icons.people,
//               color: primaryColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(String number, Color color, BuildContext context) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: 18),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),
//       onPressed: onPressed,
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Theme colors
//     const Color primaryColor = Colors.pinkAccent;
//     const Color textColor = Colors.black87;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Contact Us'),
//         backgroundColor: primaryColor,
//         elevation: 4,
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Nagala soo xiriir:",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Contact list
//             _buildContactCard(
//               context,
//               title: "Customer Support",
//               numbers: const [
//                 "0612345678",
//                 "0623456789",
//               ],
//               icon: Icons.support_agent,
//               color: primaryColor,
//             ),
            
//             const SizedBox(height: 20),
            
//             _buildContactCard(
//               context,
//               title: "Sales Department",
//               numbers: const [
//                 "0634567890",
//                 "0645678901",
//               ],
//               icon: Icons.people,
//               color: primaryColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context, {
//     required String title,
//     required List<String> numbers,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             const Divider(),
//             ...numbers.map((number) => Column(
//               children: [
//                 _buildContactRow(number, color, context),
//                 if (number != numbers.last) const SizedBox(height: 10),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactRow(String number, Color color, BuildContext context) {
//     return Row(
//       children: [
//         const Icon(Icons.phone, color: Colors.grey),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             number,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ),
//         _buildActionButton(
//           icon: Icons.call,
//           color: Colors.green,
//           label: 'Call',
//           onPressed: () => _makePhoneCall(number, context),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: 18),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),
//       onPressed: onPressed,
//       ),
//     );

    
//   }

//   Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
    
//     try {
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone app')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
// }







// import 'package:flutter/material.dart';

// class ContactScreen extends StatelessWidget {
//   const ContactScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Midabka accent-ka
//     const Color accentColor = Colors.pinkAccent;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Contact Us'),
//         backgroundColor: accentColor,
//         elevation: 4,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Nagala soo xiriir:",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),

//             // UL 1
//             buildContactRow(Icons.call, "0612345678", accentColor),
//              _buildActionButton(
//             icon: Icons.phone,
//             color: Colors.green,
//             label: 'Call',
//             onPressed: () => makePhoneCall(widget. buildContactRow),
//           ),

//             const SizedBox(height: 15),
//             // UL 2
//             buildContactRow(Icons.call, "0623456789", accentColor),

//             const SizedBox(height: 15),
//             // UL 3
//             buildContactRow(Icons.call, "0634567890", accentColor),

//             const SizedBox(height: 15),
//             // UL 4
//             buildContactRow(Icons.call, "0645678901", accentColor),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildContactRow(IconData icon, String number, Color color) {
//     return Row(
//       children: [
//         Icon(icon, color: color),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               border: Border(bottom: BorderSide(color: color, width: 2)),
//             ),
//             padding: const EdgeInsets.only(bottom: 5),
//             child: Text(
//               number,
//               style: TextStyle(fontSize: 18, color: color),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }


















// import 'package:flutter/material.dart';

// class ContactScreen extends StatelessWidget {
//     const ContactScreen ({Key? key}) : super(key: key);

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold(
//             appBar: AppBar(
//                 title: const Text('Contact'),
//             ),
//             body: const Center(
//                 child: Text('Contact Screen'),
//             ),
//         );
//     }
// }