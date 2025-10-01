// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class VerificationScreen extends StatefulWidget {
//   final String email;
//   final String userId;
//   final String password;
  
//   const VerificationScreen({
//     Key? key,
//     required this.email,
//     required this.userId,
//     required this.password,
//   }) : super(key: key);

//   @override
//   _VerificationScreenState createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen> {
//   final TextEditingController _otpController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _isResending = false;
//   String? _errorMessage;

//   Future<void> _verifyOTP() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });



//       final otpData = otpDoc.data()!;
//       final storedOTP = otpData['otp'] as String? ?? '';
//       final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();
//       final otpUserId = otpData['userId'] as String?;

//       // Security checks
//       if (otpUserId != widget.userId) {
//         throw FirebaseAuthException(
//           code: 'user-mismatch',
//           message: 'OTP was not generated for this user',
//         );
//       }

//       if (DateTime.now().isAfter(expiresAt)) {
//         throw FirebaseAuthException(
//           code: 'expired-otp',
//           message: 'OTP has expired. Please request a new one.',
//         );
//       }

//       if (storedOTP != _otpController.text.trim()) {
//         throw FirebaseAuthException(
//           code: 'invalid-otp',
//           message: 'The OTP you entered is incorrect',
//         );
//       }

//       // Update user verification status
//       await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.userId)
//           .update({'isVerified': true, 'emailVerified': true});

//       // Sign in the user
//       final userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(
//         email: widget.email,
//         password: widget.password,
//       );

//       // Refresh user token to include verification status
//       await userCredential.user?.getIdToken(true);

//       // Delete the used OTP
//       await FirebaseFirestore.instance
//           .collection('otpCodes')
//           .doc(widget.email)
//           .delete();

//       // Navigate to home screen
//       Navigator.of(context).pushReplacementNamed('/home');

//     } on FirebaseAuthException catch (e) {
//       setState(() => _errorMessage = e.message);
//     } catch (e) {
//       setState(() => _errorMessage = 'Verification failed. Please try again.');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _resendOTP() async {
//     setState(() {
//       _isResending = true;
//       _errorMessage = null;
//     });

//     try {
//       // Your OTP resend logic here
//       // This would typically:
//       // 1. Generate a new OTP
//       // 2. Save to Firestore with expiration
//       // 3. Send email to user
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('New OTP sent to your email')),
//       );
//     } catch (e) {
//       setState(() => _errorMessage = 'Failed to resend OTP. Please try again.');
//     } finally {
//       setState(() => _isResending = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Verify Email')),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Text('Enter the 6-digit OTP sent to ${widget.email}'),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _otpController,
//                 keyboardType: TextInputType.number,
//                 maxLength: 6,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter OTP';
//                   }
//                   if (value.length != 6) {
//                     return 'OTP must be 6 digits';
//                   }
//                   return null;
//                 },
//                 decoration: const InputDecoration(
//                   labelText: 'OTP Code',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               if (_errorMessage != null)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 10),
//                   child: Text(
//                     _errorMessage!,
//                     style: TextStyle(color: Colors.red[700], fontSize: 16),
//                   ),
//                 ),
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _verifyOTP,
//                 child: _isLoading
//                     ? const CircularProgressIndicator()
//                     : const Text('Verify'),
//               ),
//               TextButton(
//                 onPressed: _isResending ? null : _resendOTP,
//                 child: _isResending
//                     ? const CircularProgressIndicator()
//                     : const Text('Resend OTP'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class VerificationScreen extends StatefulWidget {
//   final String email;
//   final String userId;
//   final String password;
  
//   const VerificationScreen({
//     Key? key,
//     required this.email,
//     required this.userId,
//     required this.password,
//   }) : super(key: key);

//   @override
//   _VerificationScreenState createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen> {
//   final TextEditingController _otpController = TextEditingController();
//   bool _isLoading = false;
//   bool _isResending = false;
//   String? _errorMessage;

//   Future<void> _verifyOTP() async {
//     final otp = _otpController.text.trim();
//     if (otp.isEmpty || otp.length != 6) {
//       setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       // Check if OTP exists and is not expired
//       final otpDoc = await FirebaseFirestore.instance
//           .collection('otpCodes')
//           .doc(widget.email)
//           .get();

//       if (!otpDoc.exists) {
//         throw Exception('OTP not found or expired');
//       }

//       final otpData = otpDoc.data()!;
//       final storedOTP = otpData['otp'] as String;
//       final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();

//       if (DateTime.now().isAfter(expiresAt)) {
//         throw Exception('OTP has expired');
//       }

//       if (storedOTP != otp) {
//         throw Exception('Invalid OTP');
//       }

//       // OTP is valid - mark user as verified
//       await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.userId)
//           .update({'isVerified': true});

//       // Sign in the user
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: widget.email,
//         password: widget.password,
//       );

//       // Delete the used OTP
//       await FirebaseFirestore.instance
//           .collection('otpCodes')
//           .doc(widget.email)
//           .delete();

//       // Navigate to home screen
//       // Navigator.pushReplacement(...);

//     } catch (e) {
//       setState(() => _errorMessage = e.toString());
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Verify Email')),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             Text('Enter the OTP sent to ${widget.email}'),
//             TextField(
//               controller: _otpController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: 'OTP Code'),
//             ),
//             if (_errorMessage != null)
//               Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _verifyOTP,
//               child: _isLoading 
//                   ? const CircularProgressIndicator() 
//                   : const Text('Verify'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
























// import 'package:flutter/material.dart';

// class VerificationScreen extends StatefulWidget {
//   final String email;

//   const VerificationScreen({Key? key, required this.email}) : super(key: key);

//   @override
//   _VerificationScreenState createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreenScreen> {
//   final List<TextEditingController> _codeControllers = List.generate(4, (index) => TextEditingController());
//   final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

//   @override
//   void dispose() {
//     for (var controller in _codeControllers) {
//       controller.dispose();
//     }
//     for (var node in _focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   void _onCodeChanged(int index, String value) {
//     if (value.length == 1 && index < 3) {
//       _focusNodes[index + 1].requestFocus();
//     } else if (value.isEmpty && index > 0) {
//       _focusNodes[index - 1].requestFocus();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verify Your Email'),
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Check Your Email',
//               style: Theme.of(context).textTheme.headline5?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             RichText(
//               text: TextSpan(
//                 style: Theme.of(context).textTheme.bodyText2,
//                 children: [
//                   const TextSpan(text: 'Please enter the code we have sent to '),
//                   TextSpan(
//                     text: widget.email,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 32),
            
//             // Verification Code Fields
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(4, (index) {
//                 return SizedBox(
//                   width: 60,
//                   child: TextField(
//                     controller: _codeControllers[index],
//                     focusNode: _focusNodes[index],
//                     textAlign: TextAlign.center,
//                     keyboardType: TextInputType.number,
//                     maxLength: 1,
//                     decoration: InputDecoration(
//                       counterText: '',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     onChanged: (value) => _onCodeChanged(index, value),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 24),
            
//             // Submit Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   final verificationCode = _codeControllers.map((c) => c.text).join();
//                   if (verificationCode.length == 4) {
//                     // Verify the code
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please enter the complete code')),
//                     );
//                   }
//                 },
//                 child: const Text('Verify Code'),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Resend Code Option
//             Center(
//               child: TextButton(
//                 onPressed: () {
//                   // Resend code logic
//                 },
//                 child: const Text("Didn't receive code? Resend"),
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Alternative Options
//             const Center(child: Text('or')),
//             const SizedBox(height: 16),
            
//             // Google Sign In Button
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 icon: Image.asset('assets/google_logo.png', height: 24),
//                 label: const Text('Sign in with Google'),
//                 onPressed: () {
//                   // Google sign in logic
//                 },
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   side: const BorderSide(color: Colors.grey),
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:async';

// class VerificationScreen extends StatefulWidget {
//   final String email;
//   const VerificationScreen({super.key, required this.email});

//   @override
//   State<VerificationScreen> createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen> {
//   bool _isLoading = false;
//   bool _isVerified = false;
//   Timer? _verificationTimer;

//   @override
//   void initState() {
//     super.initState();
//     _startVerificationCheck();
//   }

//   @override
//   void dispose() {
//     _verificationTimer?.cancel();
//     super.dispose();
//   }

//   void _startVerificationCheck() {
//     _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       _checkEmailVerification();
//     });
//   }

//   Future<void> _checkEmailVerification() async {
//     if (_isVerified) return;
    
//     await FirebaseAuth.instance.currentUser?.reload();
//     final user = FirebaseAuth.instance.currentUser;
    
//     if (user != null && user.emailVerified) {
//       if (mounted) {
//         setState(() {
//           _isVerified = true;
//           _isLoading = false;
//         });
//         _verificationTimer?.cancel();
//         Navigator.pushReplacementNamed(context, '/home');
//       }
//     }
//   }

//   Future<void> _resendVerification() async {
//     setState(() => _isLoading = true);
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await user.sendEmailVerification();
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Verification email resent!')),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _openEmailApp() async {
//     final url = Uri.parse('mailto:');
//     try {
//       if (await canLaunchUrl(url)) {
//         await launchUrl(url);
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Could not open email app')),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _isVerified ? Icons.verified : Icons.mark_email_read,
//               size: 80,
//               color: _isVerified ? Colors.green : Colors.blue,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _isVerified ? 'Email Verified!' : 'Verify Your Email',
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'We sent a verification link to:\n${widget.email}',
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 30),

//             if (!_isVerified) ...[
//               const Text(
//                 'Please click the verification link in your email',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _resendVerification,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator()
//                       : const Text('Resend Verification Email'),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextButton(
//                 onPressed: _openEmailApp,
//                 child: const Text('Open Email App'),
//               ),
//             ] else ...[
//               const CircularProgressIndicator(),
//               const SizedBox(height: 20),
//               const Text('Redirecting...'),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:async'; // Add this import for Timer

// class VerificationScreen extends StatefulWidget {
//   final String email;
//   const VerificationScreen({super.key, required this.email});

//   @override
//   State<VerificationScreen> createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen> {
//   bool _isLoading = false;
//   bool _isVerified = false;
//   Timer? _verificationTimer;

//   @override
//   void initState() {
//     super.initState();
//     _startVerificationCheck();
//   }

//   @override
//   void dispose() {
//     _verificationTimer?.cancel();
//     super.dispose();
//   }

//   void _startVerificationCheck() {
//     // Check every 3 seconds
//     _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       _checkEmailVerification();
//     });
//   }

//   Future<void> _checkEmailVerification() async {
//     if (_isVerified) return;
    
//     await FirebaseAuth.instance.currentUser?.reload();
//     final user = FirebaseAuth.instance.currentUser;
    
//     if (user != null && user.emailVerified) {
//       if (mounted) {
//         setState(() {
//           _isVerified = true;
//           _isLoading = false;
//         });
//         _verificationTimer?.cancel();
//         Navigator.pushReplacementNamed(context, '/home');
//       }
//     }
//   }

//   Future<void> _resendVerification() async {
//     setState(() => _isLoading = true);
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await user.sendEmailVerification();
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Verification email resent!')),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _isVerified ? Icons.verified : Icons.mark_email_read,
//               size: 80,
//               color: _isVerified ? Colors.green : Colors.blue,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _isVerified ? 'Email Verified!' : 'Verify Your Email',
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'We sent a verification link to:\n${widget.email}',
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 30),

//             if (!_isVerified) ...[
//               const Text(
//                 'Please click the verification link in your email',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _resendVerification,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator()
//                       : const Text('Resend Verification Email'),
//                 ),
//               ),
//             ] else ...[
//               const CircularProgressIndicator(),
//               const SizedBox(height: 20),
//               const Text('Redirecting...'),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:async';

// class VerificationScreen extends StatefulWidget {
//   final String email;
//   const VerificationScreen({super.key, required this.email});

//   @override
//   State<VerificationScreen> createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen> {
//   bool _isLoading = false;
//   bool _isVerified = false;
//   Timer? _verificationTimer;

//   @override
//   void initState() {
//     super.initState();
//     _startVerificationCheck();
//   }

//   @override
//   void dispose() {
//     _verificationTimer?.cancel();
//     super.dispose();
//   }

//   void _startVerificationCheck() {
//     // Check every 3 seconds
//     _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       _checkEmailVerification();
//     });
//   }

//   Future<void> _checkEmailVerification() async {
//     if (_isVerified) return;
    
//     await FirebaseAuth.instance.currentUser?.reload();
//     final user = FirebaseAuth.instance.currentUser;
    
//     if (user != null && user.emailVerified) {
//       if (mounted) {
//         setState(() {
//           _isVerified = true;
//           _isLoading = false;
//         });
//         _verificationTimer?.cancel();
//         Navigator.pushReplacementNamed(context, '/home');
//       }
//     }
//   }

//   Future<void> _resendVerification() async {
//     setState(() => _isLoading = true);
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await user.sendEmailVerification();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Verification email resent!')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _isVerified ? Icons.verified : Icons.mark_email_read,
//               size: 80,
//               color: _isVerified ? Colors.green : Colors.blue,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _isVerified ? 'Email Verified!' : 'Verify Your Email',
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'We sent a verification link to:\n${widget.email}',
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 30),

//             if (!_isVerified) ...[
//               const Text(
//                 'Please click the verification link in your email',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _resendVerification,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator()
//                       : const Text('Resend Verification Email'),
//                 ),
//               ),
//             ] else ...[
//               const CircularProgressIndicator(),
//               const SizedBox(height: 20),
//               const Text('Redirecting...'),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class VerificationScreen extends StatefulWidget {
//   final String email;
//   const VerificationScreen({super.key, required this.email});

//   @override
//   State<VerificationScreen> createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen> {
//   final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
//   final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     for (var controller in _otpControllers) {
//       controller.dispose();
//     }
//     for (var node in _focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> _verifyOTP() async {
//     setState(() => _isLoading = true);
//     try {
//       String otp = _otpControllers.map((c) => c.text).join();
//       if (otp.length != 4) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enter a 4-digit code')),
//         );
//         return;
//       }

//       // In a real app, you would verify with Firebase Auth:
//       // AuthCredential credential = PhoneAuthProvider.credential(
//       //   verificationId: verificationId,
//       //   smsCode: otp,
//       // );
//       // await FirebaseAuth.instance.signInWithCredential(credential);

//       // For demo, simulate success after 1 second
//       await Future.delayed(const Duration(seconds: 1));
//       if (!mounted) return;
      
//       Navigator.pushReplacementNamed(context, '/home'); // Replace with your success route
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Verification failed: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.mark_email_read, size: 80, color: Colors.blue),
//             const SizedBox(height: 20),
//             const Text(
//               'Check Your Email',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Please enter the code we sent to:\n${widget.email}',
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 30),

//             // OTP Input Fields
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(4, (index) {
//                 return SizedBox(
//                   width: 50,
//                   child: TextField(
//                     controller: _otpControllers[index],
//                     focusNode: _focusNodes[index],
//                     textAlign: TextAlign.center,
//                     keyboardType: TextInputType.number,
//                     maxLength: 1,
//                     decoration: InputDecoration(
//                       counterText: '',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                     ),
//                     onChanged: (value) {
//                       if (value.length == 1 && index < 3) {
//                         _focusNodes[index + 1].requestFocus();
//                       }
//                     },
//                   ),
//                 );
//               }),
//             ),
//             const SizedBox(height: 20),

//             // Verify Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _verifyOTP,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   backgroundColor: Colors.blue,
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text('VERIFY', style: TextStyle(fontSize: 16)),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Alternative Options
//             TextButton(
//               onPressed: () {
//                 // Resend OTP logic
//                 FirebaseAuth.instance.currentUser?.sendEmailVerification();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('New code sent!')),
//                 );
//               },
//               child: const Text("Didn't receive code? Resend"),
//             ),
//             const SizedBox(height: 10),
//             const Text('or', style: TextStyle(color: Colors.grey)),
//             const SizedBox(height: 10),

//             // Google Sign-In Button
//             OutlinedButton(
//               onPressed: () {
//                 // Implement Google Sign-In
//               },
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.blue),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
//                   SizedBox(width: 10),
//                   Text('Sign in with Google'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }