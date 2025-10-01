import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signin_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController datebirthController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  String? _selectedTitle;
  

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please agree to the terms and conditions")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Create user with email and password
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
         await userCredential.user!.sendEmailVerification();

        // 2. Save additional user data to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'fullName': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'dateOfBirth': datebirthController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'uid': userCredential.user!.uid,
          'role': 'Patient',
          'emailVerified': false,
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to SignInScreen after a short delay
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = "An error occurred";
        if (e.code == 'weak-password') {
          errorMessage = "The password provided is too weak";
        } else if (e.code == 'email-already-in-use') {
          errorMessage = "The account already exists for that email";
        } else if (e.code == 'invalid-email') {
          errorMessage = "The email address is invalid";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
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
                  "Create account Patient",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name Field
                // TextFormField(
                //   controller: fullNameController,
                //   decoration: _inputDecoration("Full Name", Icons.person),
                //   validator: (value) {
                //     if (value == null || value.trim().isEmpty) {
                //       return "Please enter your full name";
                //     }
                //     if (value.trim().split(' ').length < 3) {
                //       return "Must contain at least 3 names";
                //     }
                //     return null;
                //   },
                // ),
                TextFormField(
  controller: fullNameController,
  decoration: _inputDecoration("Full Name", Icons.person),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your full name";
    }

    final parts = value.trim().split(RegExp(r'\s+'));

    if (parts.length < 3) {
      return "Full name must contain at least 3 words";
    }

    // Ensure each part is alphabetic and not purely numeric
    for (var part in parts) {
      if (!RegExp(r"^[a-zA-Z]+$").hasMatch(part)) {
        return "Names must only contain letters (no numbers)";
      }
    }

    return null;
  },
),

                const SizedBox(height: 12),
                // Email Field
                TextFormField(
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  decoration: _inputDecoration("Email", Icons.email),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return "Please enter your email";
    }

    // Match only emails like: aisha@gmail.com or xamdi12@gmail.com
    final regex = RegExp(r"^[a-zA-Z]+[0-9]*@gmail\.com$");

    if (!regex.hasMatch(value)) {
      return "Email must be like aisha@gmail.com or xamdi12@gmail.com";
    }

    return null;
  },
),

                const SizedBox(height: 12),

              
                  TextFormField(
  controller: phoneController,
  keyboardType: TextInputType.phone,
  decoration: _inputDecoration("Phone", Icons.phone),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter phone number";
    }
    String phone = value.trim();
    if (!phone.startsWith('25261')) {
      return "Phone number must start with 25261";
    }
    if (!RegExp(r'^25261[0-9]{7}$').hasMatch(phone)) {
      return "Invalid Somali phone number format. Must be 12 digits starting with 25261";
    }
    return null;
  },
),
                const SizedBox(height: 12),
  TextFormField(
  controller: addressController,
  decoration: _inputDecoration("Address", Icons.location_on),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your address";
    }

    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 3) {
      return "Address must contain at least 3 characters";
    }

    // Must start with letter, can contain letters, numbers, and spaces
    final regex = RegExp(r"^[a-zA-Z][a-zA-Z0-9\s]*$");

    if (!regex.hasMatch(trimmedValue)) {
      return "Invalid address (must start with a letter and only contain letters, numbers, and spaces)";
    }

    return null;
  },
),
                const SizedBox(height: 12),
                TextFormField(
  controller: datebirthController,
  decoration: _inputDecoration("Date of Birth", Icons.calendar_today),
  readOnly: true,
  onTap: () async {
    FocusScope.of(context).requestFocus(FocusNode());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final age = now.year - picked.year - ((now.month < picked.month || (now.month == picked.month && now.day < picked.day)) ? 1 : 0);

      if (age < 14) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Age must be at least 14 years old")),
        );
        return;
      }

      String formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      datebirthController.text = formattedDate;
    }
  },
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your date of birth";
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return "Enter a valid date (YYYY-MM-DD)";
    }

    try {
      final picked = DateTime.parse(value);
      final now = DateTime.now();
      final age = now.year - picked.year - ((now.month < picked.month || (now.month == picked.month && now.day < picked.day)) ? 1 : 0);

      if (age < 14) {
        return "Age must be at least 14 years old";
      }
    } catch (e) {
      return "Invalid date format";
    }

    return null;
  },
),

                
                const SizedBox(height: 12),

                // Password Field
                TextFormField(
                  controller: passwordController,
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
                const SizedBox(height: 12),

                // Confirm Password Field
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.blue[900],
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm password";
                    }
                    if (value != passwordController.text) {
                      return "Passwords don't match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Terms Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (value) => setState(() => _agreeTerms = value ?? false),
                    ),
                    const Text("I agree to the terms and conditions"),
                  ],
                ),
                const SizedBox(height: 24),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
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
                            "SIGN UP",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SigninScreen()),
                        );
                      },
                      child: Text(
                        "Sign in",
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

  // Helper method for input decoration
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue[900]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}






































// import 'package:flutter/material.dart';
// // ignore: unused_import
// import 'package:google_fonts/google_fonts.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   _SignupScreenState createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
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
//                 Text(
//                   "Create account",
//                   style: TextStyle(
//                     color: Colors.black87,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Full Name
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: InputDecoration(
//                     labelText: "Full Name",
//                     prefixIcon: Icon(Icons.person, color: Colors.blue[900]),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your full name";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Email
//                 TextFormField(
//                   controller: emailController,
//                   decoration: InputDecoration(
//                     labelText: "Email",
//                     prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your email";
//                     }
//                     if (!RegExp(
//                       r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$",
//                     ).hasMatch(value)) {
//                       return "Enter a valid email address";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Phone Number
//                 TextFormField(
//                   controller: phoneController,
//                   decoration: InputDecoration(
//                     labelText: "Phone",
//                     prefixIcon: Icon(Icons.phone, color: Colors.blue[900]),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   keyboardType: TextInputType.phone,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your phone number";
//                     }
//                     if (!RegExp(r'^\d{10}$').hasMatch(value)) {
//                       return "Enter a valid 10-digit phone number";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Password
//                 TextFormField(
//                   controller: passwordController,
//                   obscureText: _obscurePassword,
//                   decoration: InputDecoration(
//                     labelText: "Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword
//                             ? Icons.visibility_off
//                             : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscurePassword = !_obscurePassword;
//                         });
//                       },
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter a password";
//                     }
//                     if (value.length < 6) {
//                       return "Password must be at least 6 characters";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Confirm Password
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(
//                       Icons.lock_outline,
//                       color: Colors.blue[900],
//                     ),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword
//                             ? Icons.visibility_off
//                             : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscureConfirmPassword = !_obscureConfirmPassword;
//                         });
//                       },
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm your password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords do not match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms and Conditions Checkbox
//                 Row(
//                   children: [
//                     Checkbox(value: true, onChanged: (value) {}),
//                     const Expanded(
//                       child: Text("I agree to the terms and conditions"),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate()) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("Success...")),
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[900],
//                     minimumSize: const Size.fromHeight(50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   child: const Text(
//                     "Sign up",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Navigate to Login
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Already have an account? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.pushNamed(context, '/signin');
//                       },
//                       child: Text(
//                         "Sing in",
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

