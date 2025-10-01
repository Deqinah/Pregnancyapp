import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../register/signin_screen.dart';

class Registerdoctor extends StatefulWidget {
  const Registerdoctor({super.key});

  @override
  _RegisterdoctorState createState() => _RegisterdoctorState();
}

class _RegisterdoctorState extends State<Registerdoctor> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController expirenceController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  String? _selectedGender;
  String? _selectedSpecialty;
  
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _specialties = [
    'OB-GYN',
    'Neonatologist',
    'Genetic Counselor/Geneticist',
    'Reproductive Endocrinologist',
    'Maternal-Fetal Medicine (MFM)',
    'Anesthesiologist (Obstetric)',
    'Psychiatrist (Perinatal)',
  ];

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please agree to the terms and conditions")),
        );
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Create user with email and password
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Save doctor data to Firestore
        await FirebaseFirestore.instance.collection('doctors').doc(userCredential.user!.uid).set({
          'fullName': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'specialties': _selectedSpecialty,
          'experience': int.parse(expirenceController.text.trim()),
          'gender': _selectedGender,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': userCredential.user!.uid,
          'status': 'pending',
          'role': 'doctor', // Added role for easier user management
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful! Waiting for admin approval."),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login after a short delay
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
                  "Create Doctor account",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Full Name Field
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

                // Phone Field
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

                // Address Field
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

                // Specialties Dropdown
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Specialties", Icons.medical_services),
                  value: _selectedSpecialty,
                  items: _specialties.map((specialty) => DropdownMenuItem(
                    value: specialty,
                    child: Text(specialty),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedSpecialty = value),
                  validator: (value) => value == null ? "Please select a specialty" : null,
                ),
                const SizedBox(height: 12),

                // Experience Field
                TextFormField(
                  controller: expirenceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Experience (years)", Icons.work),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter years of experience";
                    }
                    if (int.tryParse(value) == null) {
                      return "Please enter only number";
                    }
                    if (int.parse(value) <= 0) {
                      return "Experience must be at least 1 year";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Gender", Icons.person_outline),
                  value: _selectedGender,
                  items: _genders.map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator: (value) => value == null ? "Please select gender" : null,
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';

// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specialtiesController = TextEditingController();
//   final TextEditingController expirenceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;
  
//   final List<String> _genders = ['Male', 'Female'];

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       if (!_agreeTerms) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please agree to the terms and conditions")),
//         );
//         return;
//       }

//       if (passwordController.text != confirmPasswordController.text) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Passwords do not match")),
//         );
//         return;
//       }

//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         // Create user with email and password
//         UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//         );
//         final Map<String, String> SpecialtiesMap = { selected only one ka dhig dropdownlist
//    'OB-GYN',
//    'Neonatologist',
//    'Genetic Counselor/Geneticist',
//    'Reproductive Endocrinologist',
//    'Maternal-Fetal Medicine (MFM)',
//    'Anesthesiologist (Obstetric)',
//    'Psychiatrist (Perinatal)',
//   };

//         // Save doctor data to Firestore
//         await FirebaseFirestore.instance.collection('doctors').doc(userCredential.user!.uid).set({
//           'fullName': fullNameController.text.trim(),
//           'email': emailController.text.trim(),
//           'phone': phoneController.text.trim(),
//           'address': addressController.text.trim(),
//           'specialties': specialtiesController.text.trim(),
//           'experience': int.parse(expirenceController.text.trim()),
//           'gender': _selectedGender,
//           'createdAt': FieldValue.serverTimestamp(),
//           'uid': userCredential.user!.uid,
//           'status': 'pending',
//           'role': 'doctor', // Added role for easier user management
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful! Waiting for admin approval."),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to login after a short delay
//         await Future.delayed(const Duration(seconds: 1));
        
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const SigninScreen()),
//         );
//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "An error occurred";
//         if (e.code == 'weak-password') {
//           errorMessage = "The password provided is too weak";
//         } else if (e.code == 'email-already-in-use') {
//           errorMessage = "The account already exists for that email";
//         } else if (e.code == 'invalid-email') {
//           errorMessage = "The email address is invalid";
//         }
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       } catch (e) {
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
//                 const Text(
//                   "Create Doctor account",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 // Full Name Field
//                 TextFormField(
//   controller: fullNameController,
//   decoration: _inputDecoration("Full Name", Icons.person),
//   validator: (value) {
//     if (value == null || value.trim().isEmpty) {
//       return "Please enter your full name";
//     }

//     final parts = value.trim().split(RegExp(r'\s+'));

//     if (parts.length < 3) {
//       return "Full name must contain at least 3 words";
//     }

//     // Ensure each part is alphabetic and not purely numeric
//     for (var part in parts) {
//       if (!RegExp(r"^[a-zA-Z]+$").hasMatch(part)) {
//         return "Names must only contain letters (no numbers)";
//       }
//     }

//     return null;
//   },
// ),

//                 const SizedBox(height: 12),

//                 // Email Field
//                TextFormField(
//   controller: emailController,
//   keyboardType: TextInputType.emailAddress,
//   decoration: _inputDecoration("Email", Icons.email),
//   validator: (value) {
//     if (value == null || value.isEmpty) {
//       return "Please enter your email";
//     }

//     // Match only emails like: aisha@gmail.com or xamdi12@gmail.com
//     final regex = RegExp(r"^[a-zA-Z]+[0-9]*@gmail\.com$");

//     if (!regex.hasMatch(value)) {
//       return "Email must be like aisha@gmail.com or xamdi12@gmail.com";
//     }

//     return null;
//   },
// ),

//                 const SizedBox(height: 12),

//                 // Phone Field
//                 TextFormField(
//   controller: phoneController,
//   keyboardType: TextInputType.phone,
//   decoration: _inputDecoration("Phone", Icons.phone),
//   validator: (value) {
//     if (value == null || value.trim().isEmpty) {
//       return "Please enter phone number";
//     }
//     String phone = value.trim();
//     if (!phone.startsWith('25261')) {
//       return "Phone number must start with 25261";
//     }
//     if (!RegExp(r'^25261[0-9]{7}$').hasMatch(phone)) {
//       return "Invalid Somali phone number format. Must be 12 digits starting with 25261";
//     }
//     return null;
//   },
// ),
//                 const SizedBox(height: 12),

//                 // Address Field
//                 TextFormField(
//   controller: addressController,
//   decoration: _inputDecoration("Address", Icons.location_on),
//   validator: (value) {
//     if (value == null || value.trim().isEmpty) {
//       return "Please enter your address";
//     }

//     final trimmedValue = value.trim();
    
//     if (trimmedValue.length < 3) {
//       return "Address must contain at least 3 characters";
//     }

//     // Must start with letter, can contain letters, numbers, and spaces
//     final regex = RegExp(r"^[a-zA-Z][a-zA-Z0-9\s]*$");

//     if (!regex.hasMatch(trimmedValue)) {
//       return "Invalid address (must start with a letter and only contain letters, numbers, and spaces)";
//     }

//     return null;
//   },
// ),
//                 const SizedBox(height: 12),

//                 // Specialties Field
//                 TextFormField(
//                   controller: specialtiesController,
//                   decoration: _inputDecoration("Specialties", Icons.medical_services),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Specialty is required';
//                     }
//                     if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
//                       return 'Only letters and spaces allowed';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Experience Field
//                 TextFormField(
//                   controller: expirenceController,
//                   keyboardType: TextInputType.number,
//                   decoration: _inputDecoration("Experience (years)", Icons.work),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter years of experience";
//                     }
//                     if (int.tryParse(value) == null) {
//                       return "Please enter only number";
//                     }
//                     if (int.parse(value) <= 0) {
//                       return "Experience must be at least 1 year";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Gender Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration("Gender", Icons.person_outline),
//                   value: _selectedGender,
//                   items: _genders.map((gender) => DropdownMenuItem(
//                     value: gender,
//                     child: Text(gender),
//                   )).toList(),
//                   onChanged: (value) => setState(() => _selectedGender = value),
//                   validator: (value) => value == null ? "Please select gender" : null,
//                 ),
//                 const SizedBox(height: 12),

//                 // Password Field
//                 TextFormField(
//                   controller: passwordController,
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
//                 const SizedBox(height: 12),

//                 // Confirm Password Field
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords don't match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreeTerms,
//                       onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//                     ),
//                     const Text("I agree to the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitForm,
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
//                             "SIGN UP",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                  const SizedBox(height: 20),
//                   Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Already have an account? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const SigninScreen()),
//                         );
//                       },
//                       child: Text(
//                         "Sign in",
//                         style: TextStyle(
//                           color: Colors.blue[900],
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper method for input decoration
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.blue[900]),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }






















// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'Logindoctor.dart';

// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specialtiesController = TextEditingController();
//   final TextEditingController expirenceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;
  

//   final List<String> _genders = ['Male', 'Female'];

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       if (!_agreeTerms) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please agree to the terms and conditions")),
//         );
//         return;
//       }

//       if (passwordController.text != confirmPasswordController.text) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Passwords do not match")),
//         );
//         return;
//       }

//       setState(() {
//         _isLoading = true;
//       });

//         // Create user with email and password
//         UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//         );

//         // Save doctor data to Firestore
//         await FirebaseFirestore.instance.collection('doctors').doc(userCredential.user!.uid).set({
//           'fullName': fullNameController.text.trim(),
//           'email': emailController.text.trim(),
//           'phone': phoneController.text.trim(),
//           'address': addressController.text.trim(),
//           'specialties': specialtiesController.text.trim(),
//           'experience': int.parse(expirenceController.text.trim()),
//           'gender': _selectedGender,
//           'createdAt': FieldValue.serverTimestamp(),
//           'uid': userCredential.user!.uid,
//           'status': 'pending',
//           'role': 'doctor', // Added role for easier user management
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful! Waiting for admin approval."),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to login after a short delay
//         await Future.delayed(const Duration(seconds: 1));
        
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const Logindoctor()),
//         );
//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "An error occurred";
//         if (e.code == 'weak-password') {
//           errorMessage = "The password provided is too weak";
//         } else if (e.code == 'email-already-in-use') {
//           errorMessage = "The account already exists for that email";
//         } else if (e.code == 'invalid-email') {
//           errorMessage = "The email address is invalid";
//         }
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       } catch (e) {
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
//                 const Text(
//                   "Create Doctor account",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 // Full Name Field
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: _inputDecoration("Full Name", Icons.person),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter your full name";
//                     }
//                     if (value.trim().split(' ').length < 2) {
//                       return "Must contain at least 2 names";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Email Field
//                 TextFormField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: _inputDecoration("Email", Icons.email),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your email";
//                     }
//                     if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
//                       return "Enter a valid email";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Phone Field
//                 TextFormField(
//                   controller: phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: _inputDecoration("Phone", Icons.phone),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter phone number";
//                     }
//                     String phone = value.trim();
//                     if (!phone.startsWith('+252')) {
//                       return "Phone number must start with +252";
//                     }
//                     if (!RegExp(r'^\+252[0-9]{7,9}$').hasMatch(phone)) {
//                       return "Invalid Somali phone number format";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Address Field
//                 TextFormField(
//                   controller: addressController,
//                   decoration: _inputDecoration("Address", Icons.location_on),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Address is required';
//                     }
//                     if (value.trim().length < 5) {
//                       return 'Address must be at least 5 characters long';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Specialties Field
//                 TextFormField(
//                   controller: specialtiesController,
//                   decoration: _inputDecoration("Specialties", Icons.medical_services),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Specialty is required';
//                     }
//                     if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
//                       return 'Only letters and spaces allowed';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Experience Field
//                 TextFormField(
//                   controller: expirenceController,
//                   keyboardType: TextInputType.number,
//                   decoration: _inputDecoration("Experience (years)", Icons.work),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter years of experience";
//                     }
//                     if (int.tryParse(value) == null) {
//                       return "Please enter a valid number";
//                     }
//                     if (int.parse(value) <= 0) {
//                       return "Experience must be at least 1 year";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Gender Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration("Gender", Icons.person_outline),
//                   value: _selectedGender,
//                   items: _genders.map((gender) => DropdownMenuItem(
//                     value: gender,
//                     child: Text(gender),
//                   )).toList(),
//                   onChanged: (value) => setState(() => _selectedGender = value),
//                   validator: (value) => value == null ? "Please select gender" : null,
//                 ),
//                 const SizedBox(height: 12),

//                 // Password Field
//                 TextFormField(
//                   controller: passwordController,
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
//                 const SizedBox(height: 12),

//                 // Confirm Password Field
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords don't match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreeTerms,
//                       onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//                     ),
//                     const Text("I agree to the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitForm,
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
//                             "SIGN UP",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Sign In Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Already have an account? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const Logindoctor()),
//                         );
//                       },
//                       child: Text(
//                         "Sign in",
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

//   // Helper method for input decoration
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.blue[900]),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }




































// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/verification.dart';

// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specialtiesController = TextEditingController();
//   final TextEditingController expirenceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;
//   final List<String> _genders = ['Male', 'Female'];

//   // Generate a random 6-digit OTP
//   String _generateOTP() {
//     final random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   Future<void> _sendOTPEmail(String email, String otp) async 

  
// {
    
//     print("Sending OTP $otp to $email");
//     // Simulate email sending delay
//     await Future.delayed(const Duration(seconds: 2));
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       if (!_agreeTerms) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please agree to the terms and conditions")),
//         );
//         return;
//       }

//       if (passwordController.text != confirmPasswordController.text) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Passwords do not match")),
//         );
//         return;
//       }

//       setState(() => _isLoading = true);

//       try {
//         // 1. Create user in Firebase Auth (but don't sign in yet)
//         final auth = FirebaseAuth.instance;
//         final credential = await auth.createUserWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//         );

   


//         // 3. Generate and send OTP
//         final otp = _generateOTP();
//         await _sendOTPEmail(emailController.text.trim(), otp);

//         // 4. Save doctor data to Firestore (but mark as unverified)
//         await FirebaseFirestore.instance
//             .collection('doctors')
//             .doc(credential.user!.uid)
//             .set({
//           'fullName': fullNameController.text.trim(),
//           'email': emailController.text.trim(),
//           'phone': phoneController.text.trim(),
//           'address': addressController.text.trim(),
//           'specialties': specialtiesController.text.trim(),
//           'experience': int.parse(expirenceController.text.trim()),
//           'gender': _selectedGender,
//           'createdAt': FieldValue.serverTimestamp(),
//           'uid': credential.user!.uid,
//           'status': 'pending',
//           'role': 'doctor',
//          // Mark as unverified until OTP is confirmed
//         });

//         // 5. Navigate to verification screen with email and user ID
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VerificationScreen(
//                 enter otp code send email // Pass password for later sign-in
//             ),
//           ),
//         );

//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "Registration failed. Please try again.";
//         if (e.code == 'weak-password') {
//           errorMessage = "Password is too weak (use 6+ characters).";
//         } else if (e.code == 'email-already-in-use') {
//           errorMessage = "Email is already registered.";
//         } else if (e.code == 'invalid-email') {
//           errorMessage = "Invalid email format.";
//         }
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: ${e.toString()}")),
//         );
//       } finally {
//         if (mounted) setState(() => _isLoading = false);
//       }
//     }
//   }

  

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
//                 const Text(
//                   "Create Doctor account",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
                
//                 // Full Name Field
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: _inputDecoration("Full Name", Icons.person),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter your full name";
//                     }
//                     if (value.trim().split(' ').length < 3) {
//                       return "Must contain at least 3 names";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Email Field
//                 TextFormField(
//                   controller: emailController,
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
//                     if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
//                       return "Enter a valid email";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Phone Field
//                 TextFormField(
//                   controller: phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: _inputDecoration("Phone", Icons.phone),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter phone number";
//                     }
//                     String phone = value.trim();
//                     if (!phone.startsWith('+252')) {
//                       return "Phone number must start with +252";
//                     }
//                     if (!RegExp(r'^\+252[0-9]{7,9}$').hasMatch(phone)) {
//                       return "Invalid Somali phone number format";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Address Field
//                 TextFormField(
//                   controller: addressController,
//                   decoration: _inputDecoration("Address", Icons.location_on),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Address is required';
//                     }
//                     if (value.trim().length < 5) {
//                       return 'Address must be at least 5 characters long';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Specialties Field
//                 TextFormField(
//                   controller: specialtiesController,
//                   decoration: _inputDecoration("Specialties", Icons.medical_services),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Specialty is required';
//                     }
//                     if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
//                       return 'Only letters and spaces allowed';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Experience Field
//                 TextFormField(
//                   controller: expirenceController,
//                   keyboardType: TextInputType.number,
//                   decoration: _inputDecoration("Experience (years)", Icons.work),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter years of experience";
//                     }
//                     if (int.tryParse(value) == null) {
//                       return "Please enter a valid number";
//                     }
//                     if (int.parse(value) <= 0) {
//                       return "Experience must be at least 1 year";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Gender Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration("Gender", Icons.person_outline),
//                   value: _selectedGender,
//                   items: _genders.map((gender) => DropdownMenuItem(
//                     value: gender,
//                     child: Text(gender),
//                   )).toList(),
//                   onChanged: (value) => setState(() => _selectedGender = value),
//                   validator: (value) => value == null ? "Please select gender" : null,
//                 ),
//                 const SizedBox(height: 12),

//                 // Password Field
//                 TextFormField(
//                   controller: passwordController,
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
//                 const SizedBox(height: 12),

//                 // Confirm Password Field
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords don't match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreeTerms,
//                       onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//                     ),
//                     const Text("I agree to the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitForm,
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
//                             "SIGN UP",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper method for input decoration
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.blue[900]),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }







































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/verification.dart';


// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specialtiesController = TextEditingController();
//   final TextEditingController expirenceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;
//   final List<String> _genders = ['Male', 'Female'];

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       if (!_agreeTerms) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please agree to the terms and conditions")),
//         );
//         return;
//       }

//       setState(() => _isLoading = true);

//       try {
//         // 1. Create user in Firebase Auth
//         UserCredential userCredential = await FirebaseAuth.instance
//             .createUserWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//         );

//         // 2. Send email verification
//         await userCredential.user!.sendEmailVerification();

//         // 3. Save doctor data to Firestore
//         await FirebaseFirestore.instance
//             .collection('doctors')
//             .doc(userCredential.user!.uid)
//             .set({
//           'fullName': fullNameController.text.trim(),
//           'email': emailController.text.trim(), email: userCredential.user!.email!,
//           'phone': phoneController.text.trim(),
//           'address': addressController.text.trim(),
//           'specialties': specialtiesController.text.trim(),
//           'experience': int.parse(expirenceController.text.trim()),
//           'gender': _selectedGender,
//           'createdAt': FieldValue.serverTimestamp(),
//           'uid': userCredential.user!.uid,
//           'status': 'pending',
//           'role': 'doctor',
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful! Check your email for verification."),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to login after delay
//       // After successful registration
// if (!mounted) return;
// Navigator.pushReplacement(
//   context,
//   MaterialPageRoute(builder: (context) => VerificationScreen()),
// );

// // In VerificationScreen, verify the user's auth state again

//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "Registration failed. Please try again.";
//         if (e.code == 'weak-password') {
//           errorMessage = "Password is too weak (use 6+ characters).";
//         } else if (e.code == 'email-already-in-use') {
//           errorMessage = "Email is already registered.";
//         } else if (e.code == 'invalid-email') {
//           errorMessage = "Invalid email format.";
//         }
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: ${e.toString()}")),
//         );
//       } finally {
//         if (mounted) setState(() => _isLoading = false);
//       }
//     }
//   }


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
//                 const Text(
//                   "Create Doctor account",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 // Full Name Field
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: _inputDecoration("Full Name", Icons.person),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter your full name";
//                     }
//                     if (value.trim().split(' ').length < 3) {
//                       return "Must contain at least 3 names";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Email Field
//                 TextFormField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: _inputDecoration("Email", Icons.email),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your email";
//                     }
//                     if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
//                       return "Enter a valid email";
//                     }
//                     return null;
//                     void sendEmail(BuildContext context) async {
//     final String email = emailController.text.trim();
//     if (email.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter your email")),
//       );
//       return;
//     }

//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//            backgroundColor: Colors.green,
//           content: Text("Password reset email sent to $email",style: TextStyle(color: Colors.white),)),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
//       );
//     }
//   }
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Phone Field
//                 TextFormField(
//                   controller: phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: _inputDecoration("Phone", Icons.phone),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter phone number";
//                     }
//                     String phone = value.trim();
//                     if (!phone.startsWith('+252')) {
//                       return "Phone number must start with +252";
//                     }
//                     if (!RegExp(r'^\+252[0-9]{7,9}$').hasMatch(phone)) {
//                       return "Invalid Somali phone number format";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Address Field
//                 TextFormField(
//                   controller: addressController,
//                   decoration: _inputDecoration("Address", Icons.location_on),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Address is required';
//                     }
//                     if (value.trim().length < 5) {
//                       return 'Address must be at least 5 characters long';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Specialties Field
//                 TextFormField(
//                   controller: specialtiesController,
//                   decoration: _inputDecoration("Specialties", Icons.medical_services),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Specialty is required';
//                     }
//                     if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
//                       return 'Only letters and spaces allowed';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Experience Field
//                 TextFormField(
//                   controller: expirenceController,
//                   keyboardType: TextInputType.number,
//                   decoration: _inputDecoration("Experience (years)", Icons.work),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter years of experience";
//                     }
//                     if (int.tryParse(value) == null) {
//                       return "Please enter a valid number";
//                     }
//                     if (int.parse(value) <= 0) {
//                       return "Experience must be at least 1 year";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Gender Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration("Gender", Icons.person_outline),
//                   value: _selectedGender,
//                   items: _genders.map((gender) => DropdownMenuItem(
//                     value: gender,
//                     child: Text(gender),
//                   )).toList(),
//                   onChanged: (value) => setState(() => _selectedGender = value),
//                   validator: (value) => value == null ? "Please select gender" : null,
//                 ),
//                 const SizedBox(height: 12),

//                 // Password Field
//                 TextFormField(
//                   controller: passwordController,
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
//                 const SizedBox(height: 12),

//                 // Confirm Password Field
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords don't match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreeTerms,
//                       onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//                     ),
//                     const Text("I agree to the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitForm,
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
//                             "SIGN UP",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper method for input decoration
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.blue[900]),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }





































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// import 'Logindoctor.dart';

// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specialtiesController = TextEditingController();
//   final TextEditingController expirenceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;
//   File? _imageFile;
//   File? _certificateFile;
//   String? _imageUrl;
//   String? _certificateUrl;

//   final List<String> _genders = ['Male', 'Female'];
//   final ImagePicker _picker = ImagePicker();
//   // final FirebaseStorage _storage = FirebaseStorage.instance;

//   Future<void> _pickImage() async {
//     Future<void> _pickImage() async {
//   try {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 85, // Reduce quality for smaller file size
//       maxWidth: 800,    // Limit dimensions
//     );
    
//     if (pickedFile != null) {
//       final File imageFile = File(pickedFile.path);
      
//       // Check file size (e.g., limit to 5MB)
//       final fileSize = await imageFile.length();
//       if (fileSize > 5 * 1024 * 1024) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Image size must be less than 5MB')),
//           );
//         }
//         return;
//       }
      
//       setState(() {
//         _imageFile = imageFile;
//       });
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Image selection failed: ${e.toString()}')),
//       );
//     }
//   }
// }
//     try {
//       final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() {
//           _imageFile = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
//       );
//     }
//   }

//   Future<void> _pickCertificate() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//       );

//       if (result != null) {
//         setState(() {
//           _certificateFile = File(result.files.single.path!);
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to pick certificate: ${e.toString()}')),
//       );
//     }
//   }

//   Future<String?> _uploadFile(File file, String path) async {
//     try {
//       final ref = _storage.ref().child(path);
//       final uploadTask = ref.putFile(file);
//       final snapshot = await uploadTask.whenComplete(() {});
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Upload failed: ${e.toString()}')),
//       );
//       return null;
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       if (!_agreeTerms) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please agree to the terms and conditions")),
//         );
//         return;
//       }

//       if (_imageFile == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please select a profile image")),
//         );
//         return;
//       }

//       if (_certificateFile == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please upload your certificate")),
//         );
//         return;
//       }

//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         // Upload files first
//         _imageUrl = await _uploadFile(_imageFile!, 'doctor_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//         _certificateUrl = await _uploadFile(_certificateFile!, 'doctor_certificates/${DateTime.now().millisecondsSinceEpoch}.pdf');

//         if (_imageUrl == null || _certificateUrl == null) {
//           throw Exception('Failed to upload files');
//         }

//         // Create user with email and password
//         UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//         );

//         // Save doctor data to Firestore
//         await FirebaseFirestore.instance.collection('doctor').doc(userCredential.user!.uid).set({
//           'img': _imageUrl,
//           'certificate': _certificateUrl,
//           'fullName': fullNameController.text.trim(),
//           'email': emailController.text.trim(),
//           'phone': phoneController.text.trim(),
//           'address': addressController.text.trim(),
//           'specialties': specialtiesController.text.trim(),
//           'experience': int.parse(expirenceController.text.trim()), // Store as number
//           'gender': _selectedGender,
//           'createdAt': FieldValue.serverTimestamp(),
//           'uid': userCredential.user!.uid,
//           'status': 'pending', // Add status for admin approval
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful! Waiting for admin approval."),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to login after a short delay
//         await Future.delayed(const Duration(seconds: 1));
        
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const Logindoctor()),
//         );
//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "An error occurred";
//         if (e.code == 'weak-password') {
//           errorMessage = "The password provided is too weak";
//         } else if (e.code == 'email-already-in-use') {
//           errorMessage = "The account already exists for that email";
//         } else if (e.code == 'invalid-email') {
//           errorMessage = "The email address is invalid";
//         }
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       } catch (e) {
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
//                 const Text(
//                   "Create Doctor account",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Profile Image Picker
//                 Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Colors.grey[200],
//                       backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
//                       child: _imageFile == null
//                           ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                           : null,
//                     ),
//                     TextButton(
//                       onPressed: _pickImage,
//                       child: const Text('Select Profile Image'),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Certificate Upload
//                 Column(
//                   children: [
//                     ElevatedButton(
//                       onPressed: _pickCertificate,
//                       child: const Text('Upload Certificate (PDF)'),
//                     ),
//                     if (_certificateFile != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Text(
//                           'Selected: ${_certificateFile!.path.split('/').last}',
//                           style: const TextStyle(color: Colors.green),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Full Name Field
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: _inputDecoration("Full Name", Icons.person),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter your full name";
//                     }
//                     if (value.trim().split(' ').length < 3) {
//                       return "Must contain at least 3 names";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Email Field
//                 TextFormField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: _inputDecoration("Email", Icons.email),
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

//                 // Phone Field
//                TextFormField(
//       controller: phoneController,
//       keyboardType: TextInputType.phone,
//      decoration: _inputDecoration("Phone", Icons.phone),
//       validator: (value) {
//        if (value == null || value.trim().isEmpty) {
//        return "Please enter phone number";
//         }

//         String phone = value.trim();

//          // Ka bilow +252
//           if (!phone.startsWith('+252')) {
//             return "Phone number must start with +252";
//               }

//             // Waa in +252 kaddib ay jiraan ugu yaraan 8–9 digits oo dhan
//             String digitsOnly = phone.replaceAll('+', '').replaceAll(' ', '');
//            if (!RegExp(r'^\+252\d{7,9}$').hasMatch(phone)) {
//                return "Invalid Somali phone number format";
//              }

//             return null;
//               },
//               ),

//                 const SizedBox(height: 12),

//                 // Address Field
//                TextFormField(
//                controller: addressController,
//                decoration: _inputDecoration("Address", Icons.location_on),
//               validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//                return 'Address is required';
//            }
//             if (value.trim().length < 5) {
//             return 'Address must be at least 5 characters long';
//             }
//             return null;
//               },
//          ),
//                 const SizedBox(height: 12),

//                 // Specialties Field
//                TextFormField(
//               controller: specialtiesController,
//             decoration: _inputDecoration("Specialties", Icons.medical_services),
//             validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//              return 'Specialty is required';
//              }
//             if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
//               return 'Only letters and spaces allowed';
//               }
//                return null;
//                  },
//                ),
//                 const SizedBox(height: 12),

//                 // Experience Field - Updated for numeric input
//                 TextFormField(
//                   controller: expirenceController,
//                   keyboardType: TextInputType.number,
//                   decoration: _inputDecoration("Experience (years)", Icons.work),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter years of experience";
//                     }
//                     if (int.tryParse(value) == null) {
//                       return "Please enter a valid number";
//                     }
//                     if (int.parse(value) <= 0) {
//                       return "Experience must be at least 1 year";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Gender Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration("Gender", Icons.person_outline),
//                   value: _selectedGender,
//                   items: _genders.map((gender) => DropdownMenuItem(
//                     value: gender,
//                     child: Text(gender),
//                   )).toList(),
//                   onChanged: (value) => setState(() => _selectedGender = value),
//                   validator: (value) => value == null ? "Please select gender" : null,
//                 ),
//                 const SizedBox(height: 12),

//                 // Password Field
//                 TextFormField(
//                   controller: passwordController,
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
//                 const SizedBox(height: 12),

//                 // Confirm Password Field
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords don't match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreeTerms,
//                       onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//                     ),
//                     const Text("I agree to the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitForm,
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
//                             "SIGN UP",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Sign In Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Already have an account? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const Logindoctor()),
//                         );
//                       },
//                       child: Text(
//                         "Sign in",
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

//   // Helper method for input decoration
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.blue[900]),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }






































// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:imagekit_io/imagekit_io.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'Logindoctor.dart';

// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specialtiesController = TextEditingController();
//   final TextEditingController experienceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;
//   File? _imageFile;
//   File? _certificateFile;
//   String? _imageUrl;
//   String? _certificateUrl;

//   final List<String> _genders = ['Male', 'Female'];
 
//   final ImagePicker _picker = ImagePicker();
//   final imageKit = ImageKit();

//   Future<String?> _uploadToImageKit(File file, String folder, {bool isImage = true}) async {
//     try {
//       imageKit.config(
//         publicKey: 'public_RuagKeoNTRzrT3nH5mErWN2CmFg=',
//         privateKey: 'private_yEYC8P+crqcV3qHpolNLImee9o4=',
//         urlEndpoint: 'https://ik.imagekit.io/facfwraxz/',
//       );

//       final fileBytes = await file.readAsBytes();
//       final uploadResponse = await imageKit.uploadFile(
//         file: fileBytes,
//         fileName: '${folder}_${DateTime.now().millisecondsSinceEpoch}${isImage ? '.jpg' : '.pdf'}',
//         useUniqueFileName: true,
//         folder: '/doctors/$folder',
//       );

//       return uploadResponse.url;
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to upload ${isImage ? 'image' : 'certificate'}: ${e.toString()}')),
//         );
//       }
//       return null;
//     }
//   }

//   Future<void> _pickImage() async {
//     try {
//       final XFile? pickedFile = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//         maxWidth: 800,
//       );
      
//       if (pickedFile != null) {
//         // Crop the image first
//         final croppedFile = await ImageCropper().cropImage(
//           sourcePath: pickedFile.path,
//           aspectRatioPresets: [
//             CropAspectRatioPreset.square,
//             CropAspectRatioPreset.ratio3x2,
//             CropAspectRatioPreset.original,
//           ],
//           androidUiSettings: const AndroidUiSettings(
//             toolbarTitle: 'Crop Profile Image',
//             toolbarColor: Colors.blue,
//             toolbarWidgetColor: Colors.white,
//             initAspectRatio: CropAspectRatioPreset.original,
//             lockAspectRatio: false,
//           ),
//           iosUiSettings: const IOSUiSettings(
//             minimumAspectRatio: 1.0,
//           ),
//         );

//         if (croppedFile != null) {
//           final File imageFile = File(croppedFile.path);
          
//           final fileSize = await imageFile.length();
//           if (fileSize > 5 * 1024 * 1024) {
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Image size must be less than 5MB')),
//               );
//             }
//             return;
//           }
          
//           setState(() {
//             _imageFile = imageFile;
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Image selection failed: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _pickCertificate() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//         allowMultiple: false,
//       );

//       if (result != null && result.files.isNotEmpty) {
//         PlatformFile file = result.files.first;
//         if (file.size > 10 * 1024 * 1024) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Certificate must be less than 10MB')),
//             );
//           }
//           return;
//         }
        
//         setState(() {
//           _certificateFile = File(file.path!);
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to pick certificate: ${e.toString()}')),
//         );
//       }
//     }
//   }
  
//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (!_agreeTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please agree to the terms and conditions")),
//       );
//       return;
//     }

//     if (_imageFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select a profile image")),
//       );
//       return;
//     }

//     if (_certificateFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please upload your certificate")),
//       );
//       return;
//     }

//     if (_selectedGender == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select your gender")),
//       );
//       return;
//     }

//     if (passwordController.text != confirmPasswordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Passwords do not match")),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Upload files to ImageKit in parallel
//       final results = await Future.wait([
//         _uploadToImageKit(_imageFile!, 'profile'),
//         _uploadToImageKit(_certificateFile!, 'certificate', isImage: false),
//       ]);

//       _imageUrl = results[0];
//       _certificateUrl = results[1];

//       if (_imageUrl == null || _certificateUrl == null) {
//         throw Exception('Failed to upload one or more files');
//       }

//       // Create user account
//       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );

//       // Save doctor data to Firestore
//       await FirebaseFirestore.instance.collection('doctors').doc(userCredential.user!.uid).set({
//         'profileImage': _imageUrl,
//         'certificate': _certificateUrl,
//         'fullName': fullNameController.text.trim(),
//         'email': emailController.text.trim(),
//         'phone': phoneController.text.trim(),
//         'address': addressController.text.trim(),
//         'specialties': specialtiesController.text.trim(),
//         'experience': int.tryParse(experienceController.text.trim()) ?? 0,
//         'gender': _selectedGender,
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//         'uid': userCredential.user!.uid,
//         'status': 'pending',
//         'verified': false,
//       });

//       // Show success message
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful! Waiting for admin approval."),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 3),
//         ));

//         // Navigate to login after delay
//         await Future.delayed(const Duration(seconds: 2));
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const Logindoctor()),
//           (route) => false,
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = "Registration failed. Please try again.";
//       switch (e.code) {
//         case 'weak-password':
//           errorMessage = "Password should be at least 6 characters";
//           break;
//         case 'email-already-in-use':
//           errorMessage = "An account already exists with this email";
//           break;
//         case 'invalid-email':
//           errorMessage = "Please enter a valid email address";
//           break;
//       }
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("An unexpected error occurred. Please try again.")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctor Registration'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//              _buildImagePickerSection(),
//               const SizedBox(height: 20),
//               _buildCertificateUploadSection(),
//               const SizedBox(height: 20),
//               _buildPersonalInfoSection(),
//               const SizedBox(height: 20),
//               _buildProfessionalInfoSection(),
//               const SizedBox(height: 20),
//               _buildAccountSecuritySection(),
//               const SizedBox(height: 20),
//               _buildTermsAndSubmitSection(),
//               const SizedBox(height: 20),
//               _buildLoginLink(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildImagePickerSection() {
//     return Column(
//       children: [
//         Stack(
//           alignment: Alignment.bottomRight,
//           children: [
//             CircleAvatar(
//               radius: 50,
//               backgroundColor: Colors.grey[200],
//               backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
//               child: _imageFile == null
//                   ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                   : null,
//             ),
//             FloatingActionButton.small(
//               onPressed: _pickImage,
//               child: const Icon(Icons.camera_alt),
//               heroTag: 'profileImageBtn',
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Text(
//           _imageFile?.path.split('/').last ?? 'No image selected',
//           style: TextStyle(
//             color: _imageFile != null ? Colors.green : Colors.grey,
//             fontSize: 12,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildCertificateUploadSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         ElevatedButton.icon(
//           onPressed: _pickCertificate,
//           icon: const Icon(Icons.upload_file),
//           label: const Text('Upload Medical Certificate (PDF)'),
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 15),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           _certificateFile?.path.split('/').last ?? 'No certificate selected',
//           style: TextStyle(
//             color: _certificateFile != null ? Colors.green : Colors.grey,
//             fontSize: 12,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildPersonalInfoSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         const Text(
//           'Personal Information',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 15),
        
//         // Full Name
//         TextFormField(
//           controller: fullNameController,
//           decoration: _inputDecoration("Full Name", Icons.person),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return "Please enter your full name";
//             }
//             if (value.trim().split(' ').length < 3) {
//               return "Must contain at least 3 names";
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 15),
        
//         // Email
//         TextFormField(
//           controller: emailController,
//           keyboardType: TextInputType.emailAddress,
//           decoration: _inputDecoration("Email", Icons.email),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return "Please enter your email";
//             }
//             if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
//               return "Enter a valid email";
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 15),
        
//         // Phone
//         TextFormField(
//           controller: phoneController,
//           keyboardType: TextInputType.phone,
//           decoration: _inputDecoration("Phone Number", Icons.phone),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return "Please enter phone number";
//             }
            
//             String phone = value.trim();
            
//             if (!phone.startsWith('+252')) {
//               return "Phone number must start with +252";
//             }
            
//             if (!RegExp(r'^\+252\d{7,9}$').hasMatch(phone)) {
//               return "Invalid Somali phone number format";
//             }
            
//             return null;
//           },
//         ),
//         const SizedBox(height: 15),
        
//         // Address
//         TextFormField(
//           controller: addressController,
//           decoration: _inputDecoration("Address", Icons.location_on),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'Address is required';
//             }
//             if (value.trim().length < 5) {
//               return 'Address must be at least 5 characters long';
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 15),
        
//         // Gender
//         DropdownButtonFormField<String>(
//           decoration: _inputDecoration("Gender", Icons.person_outline),
//           value: _selectedGender,
//           items: _genders.map((gender) => DropdownMenuItem(
//             value: gender,
//             child: Text(gender),
//           )).toList(),
//           onChanged: (value) => setState(() => _selectedGender = value),
//           validator: (value) => value == null ? "Please select gender" : null,
//         ),
//       ],
//     );
//   }

//   Widget _buildProfessionalInfoSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         const Text(
//           'Professional Information',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 15),
        
//         // Specialties
//         TextFormField(
//           controller: specialtiesController,
//           decoration: _inputDecoration("Specialties", Icons.medical_services),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'Specialty is required';
//             }
//             if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
//               return 'Only letters and spaces allowed';
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 15),
        
//         // Experience
//         TextFormField(
//           controller: expirenceController,
//           keyboardType: TextInputType.number,
//           decoration: _inputDecoration("Experience (years)", Icons.work),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return "Please enter years of experience";
//             }
//             final years = int.tryParse(value);
//             if (years == null) {
//               return "Please enter a valid number";
//             }
//             if (years <= 0) {
//               return "Experience must be at least 1 year";
//             }
//             if (years > 50) {
//               return "Experience cannot be more than 50 years";
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildAccountSecuritySection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         const Text(
//           'Account Security',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 15),
        
//         // Password
//         TextFormField(
//           controller: passwordController,
//           obscureText: _obscurePassword,
//           decoration: InputDecoration(
//             labelText: "Password",
//             prefixIcon: const Icon(Icons.lock),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 _obscurePassword ? Icons.visibility_off : Icons.visibility,
//               ),
//               onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return "Please enter password";
//             }
//             if (value.length < 6) {
//               return "Password must be 6+ characters";
//             }
//             if (!RegExp(r'[A-Z]').hasMatch(value)) {
//               return "Must contain at least one uppercase letter";
//             }
//             if (!RegExp(r'[0-9]').hasMatch(value)) {
//               return "Must contain at least one number";
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 15),
        
//         // Confirm Password
//         TextFormField(
//           controller: confirmPasswordController,
//           obscureText: _obscureConfirmPassword,
//           decoration: InputDecoration(
//             labelText: "Confirm Password",
//             prefixIcon: const Icon(Icons.lock),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//               ),
//               onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return "Please confirm password";
//             }
//             if (value != passwordController.text) {
//               return "Passwords don't match";
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildTermsAndSubmitSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Row(
//           children: [
//             Checkbox(
//               value: _agreeTerms,
//               onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//             ),
//             Expanded(
//               child: GestureDetector(
//                 onTap: () {
//                   // Show terms and conditions dialog
//                   showDialog(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: const Text('Terms and Conditions'),
//                       content: const SingleChildScrollView(
//                         child: Text('Lorem ipsum dolor sit amet...'),
//                       ),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: const Text('I Understand'),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//                 child: const Text(
//                   "I agree to the terms and conditions",
//                   style: TextStyle(decoration: TextDecoration.underline),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 15),
        
//         ElevatedButton(
//           onPressed: _isLoading ? null : _submitForm,
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           child: _isLoading
//               ? const SizedBox(
//                   height: 24,
//                   width: 24,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : const Text(
//                   "REGISTER NOW",
//                   style: TextStyle(fontSize: 16),
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLoginLink() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Text("Already have an account? "),
//         TextButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const Logindoctor()),
//             );
//           },
//           child: const Text("Sign In"),
//         ),
//       ],
//     );
//   }

//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//     );
//   }
// }
  













































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// import 'Logindoctor.dart';

// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specialtiesController = TextEditingController();
//   final TextEditingController expirenceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;
//   File? _imageFile;
//   File? _certificateFile;
//   String? _imageUrl;
//   String? _certificateUrl;

//   final List<String> _genders = ['Male', 'Female'];
//   final ImagePicker _picker = ImagePicker();
// class UploadImageKitPage extends StatefulWidget {
//   @override
//   _UploadImageKitPageState createState() => _UploadImageKitPageState();
// }

// class _UploadImageKitPageState extends State<UploadImageKitPage> {
//   File? _image;
//   String? _uploadedImageUrl;

//   Future<void> pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//       await uploadImageToImageKit(_image!);
//     }
//   }

//   Future<void> uploadImageToImageKit(File imageFile) async {
//     final apiKey = 'YOUR_IMAGEKIT_API_KEY'; // Hel apiKey gudaha dashboard.
//     final uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

//     final bytes = await imageFile.readAsBytes();
//     final base64Image = base64Encode(bytes);
//     final fileName = 'flutter_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

//     final response = await http.post(
//       Uri.parse(uploadUrl),
//       headers: {
//         'Authorization': 'Basic ' + base64Encode(utf8.encode(apiKey + ':')),
//       },
//       body: {
//         'file': 'data:image/jpeg;base64,$base64Image',
//         'fileName': fileName,
//       },
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       setState(() {
//         _uploadedImageUrl = data['url'];
//       });
//       print('Image uploaded: ${data['url']}');
//     } else {
//       print('Failed to upload: ${response.body}');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Upload Image to ImageKit")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _image != null ? Image.file(_image!, height: 150) : Text("No Image Selected"),
//             SizedBox(height: 10),
//             ElevatedButton(onPressed: pickImage, child: Text("Pick and Upload Image")),
//             SizedBox(height: 10),
//             _uploadedImageUrl != null
//                 ? Column(
//                     children: [
//                       Text("Image URL:"),
//                       SelectableText(_uploadedImageUrl!),
//                       Image.network(_uploadedImageUrl!)
//                     ],
//                   )
//                 : Container(),
//           ],
//         ),
//       ),
//     );
//   }
// }

//   Future<void> _pickImage() async {
//     try {
//       final XFile? pickedFile = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//         maxWidth: 800,
//       );
      
//       if (pickedFile != null) {
//         final File imageFile = File(pickedFile.path);
        
//         // Check file size (limit to 5MB)
//         final fileSize = await imageFile.length();
//         if (fileSize > 5 * 1024 * 1024) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Image size must be less than 5MB')),
//             );
//           }
//           return;
//         }
        
//         setState(() {
//           _imageFile = imageFile;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Image selection failed: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _pickCertificate() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//       );

//       if (result != null) {
//         setState(() {
//           _certificateFile = File(result.files.single.path!);
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to pick certificate: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<String?> _uploadFile(File file, String path) async {
//     try {
//       final ref = _storage.ref().child(path);
//       final uploadTask = ref.putFile(file);
//       final snapshot = await uploadTask.whenComplete(() {});
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Upload failed: ${e.toString()}')),
//         );
//       }
//       return null;
//     }
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (!_agreeTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please agree to the terms and conditions")),
//       );
//       return;
//     }

//     if (_imageFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select a profile image")),
//       );
//       return;
//     }

//     if (_certificateFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please upload your certificate")),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Upload files first
//       _imageUrl = await _uploadFile(_imageFile!, 'doctor_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//       _certificateUrl = await _uploadFile(_certificateFile!, 'doctor_certificates/${DateTime.now().millisecondsSinceEpoch}.pdf');

//       if (_imageUrl == null || _certificateUrl == null) {
//         throw Exception('Failed to upload files');
//       }

//       // Create user with email and password
//       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );

//       // Save doctor data to Firestore
//       await FirebaseFirestore.instance.collection('doctor').doc(userCredential.user!.uid).set({
//         'img': _imageUrl,
//         'certificate': _certificateUrl,
//         'fullName': fullNameController.text.trim(),
//         'email': emailController.text.trim(),
//         'phone': phoneController.text.trim(),
//         'address': addressController.text.trim(),
//         'specialties': specialtiesController.text.trim(),
//         'experience': int.parse(expirenceController.text.trim()),
//         'gender': _selectedGender,
//         'createdAt': FieldValue.serverTimestamp(),
//         'uid': userCredential.user!.uid,
//         'status': 'pending', // Add status for admin approval
//       });

//       // Show success message
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful! Waiting for admin approval."),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to login after a short delay
//         await Future.delayed(const Duration(seconds: 1));
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const Logindoctor()),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = "An error occurred";
//       if (e.code == 'weak-password') {
//         errorMessage = "The password provided is too weak";
//       } else if (e.code == 'email-already-in-use') {
//         errorMessage = "The account already exists for that email";
//       } else if (e.code == 'invalid-email') {
//         errorMessage = "The email address is invalid";
//       }
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: ${e.toString()}")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

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
//                 const Text(
//                   "Create Doctor account",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Profile Image Picker
//                 Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Colors.grey[200],
//                       backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
//                       child: _imageFile == null
//                           ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                           : null,
//                     ),
//                     TextButton(
//                       onPressed: _pickImage,
//                       child: const Text('Select Profile Image'),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Certificate Upload
//                 Column(
//                   children: [
//                     ElevatedButton(
//                       onPressed: _pickCertificate,
//                       child: const Text('Upload Certificate (PDF)'),
//                     ),
//                     if (_certificateFile != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Text(
//                           'Selected: ${_certificateFile!.path.split('/').last}',
//                           style: const TextStyle(color: Colors.green),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Full Name Field
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: _inputDecoration("Full Name", Icons.person),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter your full name";
//                     }
//                     if (value.trim().split(' ').length < 3) {
//                       return "Must contain at least 3 names";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Email Field
//                 TextFormField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: _inputDecoration("Email", Icons.email),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your email";
//                     }
//                     if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
//                       return "Enter a valid email";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Phone Field
//                 TextFormField(
//                   controller: phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: _inputDecoration("Phone", Icons.phone),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter phone number";
//                     }
                    
//                     String phone = value.trim();
                    
//                     // Must start with +252
//                     if (!phone.startsWith('+252')) {
//                       return "Phone number must start with +252";
//                     }
                    
//                     // Must have 7-9 digits after +252
//                     if (!RegExp(r'^\+252\d{7,9}$').hasMatch(phone)) {
//                       return "Invalid Somali phone number format";
//                     }
                    
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Address Field
//                 TextFormField(
//                   controller: addressController,
//                   decoration: _inputDecoration("Address", Icons.location_on),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Address is required';
//                     }
//                     if (value.trim().length < 5) {
//                       return 'Address must be at least 5 characters long';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Specialties Field
//                 TextFormField(
//                   controller: specialtiesController,
//                   decoration: _inputDecoration("Specialties", Icons.medical_services),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Specialty is required';
//                     }
//                     if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
//                       return 'Only letters and spaces allowed';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Experience Field
//                 TextFormField(
//                   controller: expirenceController,
//                   keyboardType: TextInputType.number,
//                   decoration: _inputDecoration("Experience (years)", Icons.work),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter years of experience";
//                     }
//                     final years = int.tryParse(value);
//                     if (years == null) {
//                       return "Please enter a valid number";
//                     }
//                     if (years <= 0) {
//                       return "Experience must be at least 1 year";
//                     }
//                     if (years > 50) {
//                       return "Experience cannot be more than 50 years";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Gender Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration("Gender", Icons.person_outline),
//                   value: _selectedGender,
//                   items: _genders.map((gender) => DropdownMenuItem(
//                     value: gender,
//                     child: Text(gender),
//                   )).toList(),
//                   onChanged: (value) => setState(() => _selectedGender = value),
//                   validator: (value) => value == null ? "Please select gender" : null,
//                 ),
//                 const SizedBox(height: 12),

//                 // Password Field
//                 TextFormField(
//                   controller: passwordController,
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
//                 const SizedBox(height: 12),

//                 // Confirm Password Field
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords don't match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreeTerms,
//                       onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//                     ),
//                     const Text("I agree to the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitForm,
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
//                             "SIGN UP",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Sign In Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Already have an account? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const Logindoctor()),
//                         );
//                       },
//                       child: Text(
//                         "Sign in",
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

//   // Helper method for input decoration
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.blue[900]),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }






























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// import 'Logindoctor.dart';

// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specialtiesController = TextEditingController();
//   final TextEditingController expirenceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;
//   File? _imageFile;
//   File? _certificateFile;
//   String? _imageUrl;
//   String? _certificateUrl;

//   final List<String> _genders = ['Male', 'Female'];
//   final ImagePicker _picker = ImagePicker();
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   Future<void> _pickImage() async {
//     Future<void> _pickImage() async {
//   try {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 85, // Reduce quality for smaller file size
//       maxWidth: 800,    // Limit dimensions
//     );
    
//     if (pickedFile != null) {
//       final File imageFile = File(pickedFile.path);
      
//       // Check file size (e.g., limit to 5MB)
//       final fileSize = await imageFile.length();
//       if (fileSize > 5 * 1024 * 1024) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Image size must be less than 5MB')),
//           );
//         }
//         return;
//       }
      
//       setState(() {
//         _imageFile = imageFile;
//       });
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Image selection failed: ${e.toString()}')),
//       );
//     }
//   }
// }
//     try {
//       final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() {
//           _imageFile = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
//       );
//     }
//   }

//   Future<void> _pickCertificate() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//       );

//       if (result != null) {
//         setState(() {
//           _certificateFile = File(result.files.single.path!);
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to pick certificate: ${e.toString()}')),
//       );
//     }
//   }

//   Future<String?> _uploadFile(File file, String path) async {
//     try {
//       final ref = _storage.ref().child(path);
//       final uploadTask = ref.putFile(file);
//       final snapshot = await uploadTask.whenComplete(() {});
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Upload failed: ${e.toString()}')),
//       );
//       return null;
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       if (!_agreeTerms) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please agree to the terms and conditions")),
//         );
//         return;
//       }

//       if (_imageFile == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please select a profile image")),
//         );
//         return;
//       }

//       if (_certificateFile == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please upload your certificate")),
//         );
//         return;
//       }

//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         // Upload files first
//         _imageUrl = await _uploadFile(_imageFile!, 'doctor_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//         _certificateUrl = await _uploadFile(_certificateFile!, 'doctor_certificates/${DateTime.now().millisecondsSinceEpoch}.pdf');

//         if (_imageUrl == null || _certificateUrl == null) {
//           throw Exception('Failed to upload files');
//         }

//         // Create user with email and password
//         UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//         );

//         // Save doctor data to Firestore
//         await FirebaseFirestore.instance.collection('doctor').doc(userCredential.user!.uid).set({
//           'img': _imageUrl,
//           'certificate': _certificateUrl,
//           'fullName': fullNameController.text.trim(),
//           'email': emailController.text.trim(),
//           'phone': phoneController.text.trim(),
//           'address': addressController.text.trim(),
//           'specialties': specialtiesController.text.trim(),
//           'experience': int.parse(expirenceController.text.trim()), // Store as number
//           'gender': _selectedGender,
//           'createdAt': FieldValue.serverTimestamp(),
//           'uid': userCredential.user!.uid,
//           'status': 'pending', // Add status for admin approval
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful! Waiting for admin approval."),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to login after a short delay
//         await Future.delayed(const Duration(seconds: 1));
        
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const Logindoctor()),
//         );
//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "An error occurred";
//         if (e.code == 'weak-password') {
//           errorMessage = "The password provided is too weak";
//         } else if (e.code == 'email-already-in-use') {
//           errorMessage = "The account already exists for that email";
//         } else if (e.code == 'invalid-email') {
//           errorMessage = "The email address is invalid";
//         }
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       } catch (e) {
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
//                 const Text(
//                   "Create Doctor account",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Profile Image Picker
//                 Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Colors.grey[200],
//                       backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
//                       child: _imageFile == null
//                           ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                           : null,
//                     ),
//                     TextButton(
//                       onPressed: _pickImage,
//                       child: const Text('Select Profile Image'),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Certificate Upload
//                 Column(
//                   children: [
//                     ElevatedButton(
//                       onPressed: _pickCertificate,
//                       child: const Text('Upload Certificate (PDF)'),
//                     ),
//                     if (_certificateFile != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Text(
//                           'Selected: ${_certificateFile!.path.split('/').last}',
//                           style: const TextStyle(color: Colors.green),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Full Name Field
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: _inputDecoration("Full Name", Icons.person),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter your full name";
//                     }
//                     if (value.trim().split(' ').length < 3) {
//                       return "Must contain at least 3 names";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Email Field
//                 TextFormField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: _inputDecoration("Email", Icons.email),
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

//                 // Phone Field
//                TextFormField(
//       controller: phoneController,
//       keyboardType: TextInputType.phone,
//      decoration: _inputDecoration("Phone", Icons.phone),
//       validator: (value) {
//        if (value == null || value.trim().isEmpty) {
//        return "Please enter phone number";
//         }

//         String phone = value.trim();

//          // Ka bilow +252
//           if (!phone.startsWith('+252')) {
//             return "Phone number must start with +252";
//               }

//             // Waa in +252 kaddib ay jiraan ugu yaraan 8–9 digits oo dhan
//             String digitsOnly = phone.replaceAll('+', '').replaceAll(' ', '');
//            if (!RegExp(r'^\+252\d{7,9}$').hasMatch(phone)) {
//                return "Invalid Somali phone number format";
//              }

//             return null;
//               },
//               ),

//                 const SizedBox(height: 12),

//                 // Address Field
//                TextFormField(
//                controller: addressController,
//                decoration: _inputDecoration("Address", Icons.location_on),
//               validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//                return 'Address is required';
//            }
//             if (value.trim().length < 5) {
//             return 'Address must be at least 5 characters long';
//             }
//             return null;
//               },
//          ),
//                 const SizedBox(height: 12),

//                 // Specialties Field
//                TextFormField(
//               controller: specialtiesController,
//             decoration: _inputDecoration("Specialties", Icons.medical_services),
//             validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//              return 'Specialty is required';
//              }
//             if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
//               return 'Only letters and spaces allowed';
//               }
//                return null;
//                  },
//                ),
//                 const SizedBox(height: 12),

//                 // Experience Field - Updated for numeric input
//                 TextFormField(
//                   controller: expirenceController,
//                   keyboardType: TextInputType.number,
//                   decoration: _inputDecoration("Experience (years)", Icons.work),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter years of experience";
//                     }
//                     if (int.tryParse(value) == null) {
//                       return "Please enter a valid number";
//                     }
//                     if (int.parse(value) <= 0) {
//                       return "Experience must be at least 1 year";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Gender Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration("Gender", Icons.person_outline),
//                   value: _selectedGender,
//                   items: _genders.map((gender) => DropdownMenuItem(
//                     value: gender,
//                     child: Text(gender),
//                   )).toList(),
//                   onChanged: (value) => setState(() => _selectedGender = value),
//                   validator: (value) => value == null ? "Please select gender" : null,
//                 ),
//                 const SizedBox(height: 12),

//                 // Password Field
//                 TextFormField(
//                   controller: passwordController,
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
//                 const SizedBox(height: 12),

//                 // Confirm Password Field
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords don't match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreeTerms,
//                       onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//                     ),
//                     const Text("I agree to the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitForm,
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
//                             "SIGN UP",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Sign In Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Already have an account? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const Logindoctor()),
//                         );
//                       },
//                       child: Text(
//                         "Sign in",
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

//   // Helper method for input decoration
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.blue[900]),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }
























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'Logindoctor.dart';

// class Registerdoctor extends StatefulWidget {
//   const Registerdoctor ({super.key});

//   @override
//   _RegisterdoctorState createState() => _RegisterdoctorState();
// }

// class _RegisterdoctorState extends State<Registerdoctor> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController imgController(),
//   final TextEditingController certificateController(),//waxa uu soo galin karaa only pdf
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController spealitiesController = TextEditingController();
//   final TextEditingController expirenceController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeTerms = false;
//   bool _isLoading = false;

//   String? _selectedGender;

//   final List<String> _genders = ['Male', 'Female'];

//   // Firebase instances
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       if (!_agreeTerms) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please agree to the terms and conditions")),
//         );
//         return;
//       }

//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         // 1. Create user with email and password
//         DocCredential userCredential = await _auth.createUserWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//         );

//         // 2. Save additional user data to Firestore
//         await _firestore.collection('doctor').doc(userCredential.user!.uid).set({
//           'img': imgController(),
//           'certificate': certificateController(),
//           'fullName': fullNameController.text.trim(),
//           'email': emailController.text.trim(),
//           'phone': phoneController.text.trim(),
//           'address': addressController.text.trim(),
//           'specialties': spealitiesController.text.trim(),
//           'experience': expirenceController.text.trim(),
//           'gender': _selectedGender,
//           'createdAt': FieldValue.serverTimestamp(),
//           'uid': userCredential.user!.uid,
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful!"),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to SignInScreen after a short delay
//         await Future.delayed(const Duration(seconds: 1));
        
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const Logindoctor()),
//         );
//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "An error occurred";
//         if (e.code == 'weak-password') {
//           errorMessage = "The password provided is too weak";
//         } else if (e.code == 'email-already-in-use') {
//           errorMessage = "The account already exists for that email";
//         } else if (e.code == 'invalid-email') {
//           errorMessage = "The email address is invalid";
//         }
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage)),
//         );
//       } catch (e) {
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
//                 const Text(
//                   "Create Doctor account",
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     img(),
//                     certificate(),//waxa uu soo galin karaa only pdf
//                 )

//                 // Full Name Field
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: _inputDecoration("Full Name", Icons.person),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return "Please enter your full name";
//                     }
//                     if (value.trim().split(' ').length < 3) {
//                       return "Must contain at least 3 names";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 // Email Field
//                 TextFormField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: _inputDecoration("Email", Icons.email),
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

//                 // Phone Field
//                 TextFormField(
//                   controller: phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: _inputDecoration("Phone", Icons.phone),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter phone number";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration("Gender", Icons.person_outline),
//                   value: _selectedGender,
//                   items: _genders.map((gender) => DropdownMenuItem(
//                     value: gender,
//                     child: Text(gender),
//                   )).toList(),
//                   onChanged: (value) => setState(() => _selectedGender = value),
//                   validator: (value) => value == null ? "Please select gender" : null,
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: passwordController,
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
//                 const SizedBox(height: 12),

//                 // Confirm Password Field
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: "Confirm Password",
//                     prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                         color: Colors.blue[900],
//                       ),
//                       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please confirm password";
//                     }
//                     if (value != passwordController.text) {
//                       return "Passwords don't match";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Terms Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _agreeTerms,
//                       onChanged: (value) => setState(() => _agreeTerms = value ?? false),
//                     ),
//                     const Text("I agree to the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign Up Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitForm,
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
//                             "SIGN UP",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Sign In Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Already have an account? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const Logindoctor()),
//                         );
//                       },
//                       child: Text(
//                         "Sign in",
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

//   // Helper method for input decoration
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.blue[900]),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }


























// import 'package:flutter/material.dart';

// class Registerdoctor extends StatelessWidget {
//     const Registerdoctor ({Key? key}) : super(key: key);

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold(
//             appBar: AppBar(
//                 title: const Text('Rdoctor'),
//             ),
//             body: const Center(
//                 child: Text('Rdoctor Screen'),
//             ),
//         );
//     }
// }