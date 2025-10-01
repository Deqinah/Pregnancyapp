import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart'; 
import '../home/home_screen.dart';
// import 'forgot_pass.dart';
import '../doctor/doctor_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin/admin_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool rememberMe = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
       List<String> adminEmails = [
       'daganabdi757@gmail.com',
       'shifa@gmail.com',
      ];

      // Check if the logged-in email is in the admin list
      bool isAdmin = adminEmails.contains(_emailController.text.trim());

      if (isAdmin) {
        // 👉 Navigate to ADMIN SCREEN
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome Admin!"),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

        // Check if user is a doctor
        DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(userCredential.user!.uid)
            .get();

        if (doctorDoc.exists) {
          // User is a doctor - check approval status
          String? role = doctorDoc.get('role');
          String? status = doctorDoc.get('status');

          if (role == 'doctor' && status == 'pending') {
            // Doctor with pending status - show message
            if (!mounted) return;
            await _auth.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Your account is pending admin approval. Please wait."),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (status == 'approved') {
            // Approved doctor - go to doctor screen
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const DoctorScreen(),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Login successful!"),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Other cases (rejected, etc.)
            if (!mounted) return;
            await _auth.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Your account is not approved. Please contact admin."),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Regular user - go to home screen
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login successful!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "Login failed";
        if (e.code == 'user-not-found') {
          errorMessage = "No user found with this email";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Incorrect password";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email format";
        } else if (e.code == 'user-disabled') {
          errorMessage = "This account has been disabled";
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Rest of your code remains the same...
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google login successful!"),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign in failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }
  //   // Rest of your code remains the same...
  // Future<void> _signInWithFacebook() async {
  //   setState(() {
  //     _isFacebookLoading = true;
  //   });

  //   try {
  //     final GoogleSignInAccount? facebookUser = await _facebookSignIn.signIn();
  //     if (facebookUser == null) return;

  //     final GoogleSignInAuthentication facebookAuth = await facebookUser.authentication;
      
  //     final AuthCredential credential = FacebookAuthProvider.credential(
  //       accessToken: facebookAuth.accessToken,
  //       idToken: facebookAuth.idToken,
  //     );

  //     await _auth.signInWithCredential(credential);

  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("facebook login successful!"),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
      
  //     Navigator.pushReplacementNamed(context, '/home');

  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Facebook sign in failed: ${e.toString()}")),
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isFacebookLoading = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                Icon(Icons.lock, size: 100, color: Colors.blue[900]),
                const SizedBox(height: 12),
                const Text(
                  "Login account",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your email";
                    }
                    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$").hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.blue[900],
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter password";
                    }
                    if (value.length < 6) {
                      return "Password must be 6+ characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            setState(() {
                              rememberMe = value!;
                            });
                          },
                        ),
                        const Text("Remember me"),
                      ],
                    ),
                    GestureDetector(
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     PageTransition(
                      //       type: PageTransitionType.bottomToTop,
                      //       child: const ForgotPass(),
                      //     ),
                      //   );
                      // },
                      child: Text(
                        "Forgot your password?",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SIGN IN",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // OR divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: _isGoogleLoading
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google.png',
                                height: 24,
                                width: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Sign in with Google",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Facebook Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                     onPressed: () {
      // TODO: Add Facebook sign-in logic here
    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                     ),
                    child
                    //  _isGoogleLoading
                    //     ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/facebook.png',
                                height: 24,
                                width: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Sign in with Facebook",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      child: Text(
                        "Sign up",
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'signup_screen.dart'; 
// import '../home/home_screen.dart';
// import 'forgot_pass.dart';
// import '../doctor/doctor_screen.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:google_fonts/google_fonts.dart';
// class SigninScreen extends StatefulWidget {
//   const SigninScreen({super.key});

//   @override
//   _SigninScreenState createState() => _SigninScreenState();
// }

// class _SigninScreenState extends State<SigninScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
  
//   bool _obscurePassword = true;
//   bool _isLoading = false;
//   bool _isGoogleLoading = false;
//   bool rememberMe = false;

//   // Firebase instances
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   Future<void> _signInWithEmailAndPassword() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         await _auth.signInWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );

//    Navigator.pushReplacementNamed(context, '/home');


        
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Login successful!"),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "Login failed";
//         if (e.code == 'user-not-found') {
//           errorMessage = "No user found with this email";
//         } else if (e.code == 'wrong-password') {
//           errorMessage = "Incorrect password";
//         } else if (e.code == 'invalid-email') {
//           errorMessage = "Invalid email format";
//         } else if (e.code == 'user-disabled') {
//           errorMessage = "This account has been disabled";
//         }
        
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       } catch (e) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: ${e.toString()}")),
//         );
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }
//   Future<void> _signInWithEmailAndPassword() async {
//   if (_formKey.currentState!.validate()) {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       // Get additional user data from Firestore (assuming you're using Firestore)
//       DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(userCredential.user!.uid)
//           .get();

//       if (doctorDoc.exists) {
//         String role = doctorDoc.get('role');
//         String status = doctorDoc.get('status');

//         if (role == 'doctor' && status == 'pending') {
//           // Doctor with pending status - show message
//           if (!mounted) return;
//           await _auth.signOut(); // Sign out the user
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Your account is pending admin approval. Please wait."),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         } else if (status == 'approved') {
//           // Approved user - proceed to home
//           if (!mounted) return;
//           navigator.pushReplacement(
//             context,
//             PageTransition(
//               type: PageTransitionType.rightToLeft,
//               child: DoctorScreen(), // Replace with your home screen widget
//             ),
//           );
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Login successful!"),
//               backgroundColor: Colors.green,
//             ),
//           );
//         } else {
//           // Other cases (rejected, etc.)
//           if (!mounted) return;
//           await _auth.signOut(); // Sign out the user
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Your account is not approved. Please contact admin."),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       } else {
//         // User document doesn't exist
//         if (!mounted) return;
//         await _auth.signOut(); // Sign out the user
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("User data not found. Please contact support."),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = "Login failed";
//       if (e.code == 'user-not-found') {
//         errorMessage = "No user found with this email";
//       } else if (e.code == 'wrong-password') {
//         errorMessage = "Incorrect password";
//       } else if (e.code == 'invalid-email') {
//         errorMessage = "Invalid email format";
//       } else if (e.code == 'user-disabled') {
//         errorMessage = "This account has been disabled";
//       }
      
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(errorMessage)),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
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

//   Future<void> _signInWithGoogle() async {
//     setState(() {
//       _isGoogleLoading = true;
//     });

//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) return;

//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       await _auth.signInWithCredential(credential);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Google login successful!"),
//           backgroundColor: Colors.green,
//         ),
//       );
      
//     Navigator.pushReplacementNamed(context, '/home');


//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Google sign in failed: ${e.toString()}")),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isGoogleLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _resetPassword() async {
//     if (_emailController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter your email first")),
//       );
//       return;
//     }

//     try {
//       await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Password reset email sent"),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error sending reset email: ${e.toString()}")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: Colors.white.withOpacity(0.9),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 const SizedBox(height: 60),
//                 Icon(Icons.lock, size: 100, color: Colors.blue[900]),
//                 const SizedBox(height: 12),
//                 const Text(
//                   "Welcome back",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Email Field
//                 TextFormField(
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: InputDecoration(
//                     labelText: "Email",
//                     prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your email";
//                     }
//                     if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$").hasMatch(value)) {
//                       return "Enter a valid email";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Password Field
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: _obscurePassword,
//                   decoration: InputDecoration(
//                     labelText: "Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter password";
//                     }
//                     if (value.length < 6) {
//                       return "Password must be 6+ characters";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 8),

//                Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: rememberMe,
//                         onChanged: (value) {
//                           setState(() {
//                             rememberMe = value!;
//                           });
//                         },
//                       ),
//                       const Text("Remember me"),
//                     ],
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         PageTransition(
//                           type: PageTransitionType.bottomToTop,
//                           child: const ForgotPass(),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       "Forgot your password?",
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.blue[900],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

                
//                 const SizedBox(height: 24),

//                 // Sign In Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _signInWithEmailAndPassword,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[900],
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text(
//                             "SIGN IN",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // OR divider
//                 Row(
//                   children: [
//                     const Expanded(child: Divider()),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                       child: Text(
//                         "OR",
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                     ),
//                     const Expanded(child: Divider()),
//                   ],
//                 ),
//                 const SizedBox(height: 16),

//                 // Google Sign In Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isGoogleLoading ? null : _signInWithGoogle,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey[5],
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         side: BorderSide(color: Colors.grey[300]!),
//                       ),
//                     ),
//                     child: _isGoogleLoading
//                         ? const CircularProgressIndicator()
//                         : Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Image.asset(
//                                 'assets/images/google.png', // Make sure to add this asset
//                                 height: 24,
//                                 width: 24,
//                               ),
//                               const SizedBox(width: 12),
//                               const Text(
//                                 "Sign in with Google",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.black87,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                   ),
//                 ),
//                  const SizedBox(height: 20),
//                 //Facebook Sign In Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isGoogleLoading ? null : _signInWithGoogle,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey[5],
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         side: BorderSide(color: Colors.grey[300]!),
//                       ),
//                     ),
//                     child: _isGoogleLoading
//                         ? const CircularProgressIndicator()
//                         : Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [

//                               Image.asset(
//                                 'assets/images/facebook.png', // Make sure to add this asset
//                                 height: 24,
//                                 width: 24,
//                               ),


//                               const SizedBox(width: 12),
//                               const Text(
//                                 "Sign in with Facebook",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.black87,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                   ),
//                 ),
//               const SizedBox(height: 30),

//                 // Sign Up Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Don't have an account? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const SignupScreen()),
//                         );
//                       },
//                       child: Text(
//                         "Sign up",
//                         style: TextStyle(
//                           color: Colors.blue[900],
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class SocialLoginButton extends StatelessWidget {
//   final String logo;
//   final String text;

//   const SocialLoginButton({super.key, required this.logo, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(logo, width: 24, height: 24),
//           const SizedBox(width: 10),
//           Text(text, style: const TextStyle(fontSize: 16)),
//         ],
//       ),
//     );
//   }
// }

































// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:page_transition/page_transition.dart';
// import 'forgot_pass.dart';
// import 'signup_screen.dart';
// import '../home/home_screen.dart';


// class SigninScreen extends StatefulWidget {
//   const SigninScreen({super.key});

//   @override
//   State<SigninScreen> createState() => _SigninScreenState();
// }

// class _SigninScreenState extends State<SigninScreen> {
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   bool rememberMe = false;
//   bool _obscurePassword = true;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const SizedBox(height: 60),
//               Icon(Icons.lock, size: 100, color: Colors.blue[900]),
//               const SizedBox(height: 12),
//               const Text(
//                 "Signin account",
//                 style: TextStyle(
//                   color: Colors.black87,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Email
//               TextFormField(
//                 controller: fullNameController,
//                 decoration: InputDecoration(
//                   labelText: "Email",
//                   prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return "Please enter your email";
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),

//               // Password
//               TextFormField(
//                 controller: passwordController,
//                 obscureText: _obscurePassword,
//                 decoration: InputDecoration(
//                   labelText: "Password",
//                   prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscurePassword
//                           ? Icons.visibility_off
//                           : Icons.visibility,
//                       color: Colors.blue[900],
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscurePassword = !_obscurePassword;
//                       });
//                     },
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // Remember me and Forgot password
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: rememberMe,
//                         onChanged: (value) {
//                           setState(() {
//                             rememberMe = value!;
//                           });
//                         },
//                       ),
//                       const Text("Remember me"),
//                     ],
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         PageTransition(
//                           type: PageTransitionType.bottomToTop,
//                           child: const ForgotPass(),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       "Forgot your password?",
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.blue[900],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // Sign In Button
//               ElevatedButton(
//                 onPressed: () {
//   Navigator.pushNamed(context, '/home');
// },

//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[900],
//                   minimumSize: const Size.fromHeight(50),
//                 ),
//                 child: const Text(
//                   "Login in",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 30),

//               // OR Divider
//               const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Expanded(child: Divider()),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 10),
//                     child: Text(
//                       "or",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   Expanded(child: Divider()),
//                 ],
//               ),

//               const SizedBox(height: 30),

//               // Social buttons
//               const SocialLoginButton(
//                 logo: "assets/images/google.png",
//                 text: "Sign in with Google",
//               ),
//               const SizedBox(height: 20),
//               const SocialLoginButton(
//                 logo: "assets/images/facebook.png",
//                 text: "Sign in with Facebook",
//               ),

//               const SizedBox(height: 30),

//               // Sign Up Redirect
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text("Don't have an account? "),
//                   GestureDetector(
//                    onTap: () {
//     Navigator.push(
//       context,
//       PageTransition(
//         type: PageTransitionType.rightToLeft,
//         child: SignupScreen(), // make sure this is imported correctly
//       ),
//     );
//   },
                    
//                     child: Text(
//                       "Sign up",
//                       style: TextStyle(
//                         color: Colors.blue[900],
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class SocialLoginButton extends StatelessWidget {
//   final String logo;
//   final String text;

//   const SocialLoginButton({super.key, required this.logo, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(logo, width: 24, height: 24),
//           const SizedBox(width: 10),
//           Text(text, style: const TextStyle(fontSize: 16)),
//         ],
//       ),
//     );
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:page_transition/page_transition.dart';
// import 'forgot_pass.dart';
// import '../home_screen.dart';


// class SigninScreen extends StatefulWidget {
//   const SigninScreen({super.key});

//   @override
//   State<SigninScreen> createState() => _SigninScreenState();
// }

// class _SigninScreenState extends State<SigninScreen> {
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   bool rememberMe = false;
//   bool _obscurePassword = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const SizedBox(height: 60),
//               Icon(Icons.lock, size: 100, color: Colors.blue[900]),
//               const SizedBox(height: 12),
//               const Text(
//                 "Signin account",
//                 style: TextStyle(
//                   color: Colors.black87,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Email
//               TextFormField(
//                 controller: fullNameController,
//                 decoration: InputDecoration(
//                   labelText: "Email",
//                   prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return "Please enter your email";
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),

//               // Password
//               TextFormField(
//                 controller: passwordController,
//                 obscureText: _obscurePassword,
//                 decoration: InputDecoration(
//                   labelText: "Password",
//                   prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscurePassword
//                           ? Icons.visibility_off
//                           : Icons.visibility,
//                       color: Colors.blue[900],
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscurePassword = !_obscurePassword;
//                       });
//                     },
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // Remember me and Forgot password
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: rememberMe,
//                         onChanged: (value) {
//                           setState(() {
//                             rememberMe = value!;
//                           });
//                         },
//                       ),
//                       const Text("Remember me"),
//                     ],
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         PageTransition(
//                           type: PageTransitionType.bottomToTop,
//                           child: const ForgotPass(),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       "Forgot your password?",
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.blue[900],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // Sign In Button
//               ElevatedButton(
//                  (context) => HomeScreen(
//               isDarkMode: _isDarkMode,
//               onToggleTheme: _toggleTheme,
//             ),
//       },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[900],
//                   minimumSize: const Size.fromHeight(50),
//                 ),
//                 child: const Text(
//                   "Login in",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 30),

//               // OR Divider
//               const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Expanded(child: Divider()),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 10),
//                     child: Text(
//                       "or",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   Expanded(child: Divider()),
//                 ],
//               ),

//               const SizedBox(height: 30),

//               // Social buttons
//               const SocialLoginButton(
//                 logo: "assets/images/google.png",
//                 text: "Sign in with Google",
//               ),
//               const SizedBox(height: 20),
//               const SocialLoginButton(
//                 logo: "assets/images/facebook.png",
//                 text: "Sign in with Facebook",
//               ),

//               const SizedBox(height: 30),

//               // Sign Up Redirect
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text("Don't have an account? "),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pushNamed(context, '/signup');
//                     },
//                     child: Text(
//                       "Sign up",
//                       style: TextStyle(
//                         color: Colors.blue[900],
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class SocialLoginButton extends StatelessWidget {
//   final String logo;
//   final String text;

//   const SocialLoginButton({super.key, required this.logo, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(logo, width: 24, height: 24),
//           const SizedBox(width: 10),
//           Text(text, style: const TextStyle(fontSize: 16)),
//         ],
//       ),
//     );
//   }
// }
