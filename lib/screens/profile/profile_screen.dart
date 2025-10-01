import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../register/signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _datebirthController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _datebirthController.text = data['dateOfBirth'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'dateOfBirth': _datebirthController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _loadUserData();
    }
    setState(() => _isEditing = !_isEditing);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SigninScreen()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue[900]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue[900]!),
      ),
      filled: !_isEditing,
      enabled: _isEditing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
appBar: AppBar(
  title: const Text('Profile'),
  actions: [
    if (!_isEditing)
      IconTheme(
        data: IconThemeData(color: Colors.green),
        child: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _isLoading ? null : _toggleEditMode,
          tooltip: 'Edit Profile',
        ),
      ),
    if (_isEditing)
      IconTheme(
        data: IconThemeData(color: Colors.red),
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isLoading ? null : _toggleEditMode,
          tooltip: 'Cancel',
        ),
      ),
    if (_isEditing)
      IconTheme(
        data: IconThemeData(color: Colors.blue),
        child: IconButton(
          icon: const Icon(Icons.save),
          onPressed: _isLoading ? null : _updateProfile,
          tooltip: 'Save Changes',
        ),
      ),
  ],
),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            _fullNameController.text.isNotEmpty 
                                ? _fullNameController.text[0] 
                                : 'U',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '@${_fullNameController.text.isNotEmpty ? _fullNameController.text : 'username'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(),

                    // Full Name Field
                    TextFormField(
  controller: _fullNameController,
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
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  readOnly: true, // Email is read-only
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
  controller: _phoneController,
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
  controller: _addressController,
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
                    
                    // Date of Birth Field
                    TextFormField(
  controller: _datebirthController,
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
      _datebirthController.text = formattedDate;
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
                    
              

                    const SizedBox(height: 30),
                    
                    if (!_isEditing)
                      ElevatedButton(
                        onPressed: _showDeleteDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        ),
                        child: const Text('Delete Account'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

}



















// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../register/signin_screen.dart';
// import 'dart:io';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final _auth = FirebaseAuth.instance;
//   final _storage = FirebaseStorage.instance;


//   final _formKey = GlobalKey<FormState>();
//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _datebirthController = TextEditingController();
//   final _genderController = TextEditingController();


//   bool _isLoading = false;
//   bool _isEditing = false;


//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       final doc = await _firestore.collection('users').doc(user.uid).get();
//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           _fullNameController.text = data['fullName'] ?? '';
//           _emailController.text = data['email'] ?? '';
//           _phoneController.text = data['phone'] ?? '';
//           _addressController.text = data['address']?? '';
//           _datebirthController.text = data['dateOfBirth']?? '';
//           _genderController.text = data['gender'] ?? '';
        
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading data: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

  

//   Future<void> _updateProfile() async {
//     if (!_formKey.currentState!.validate()) return;
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       await _firestore.collection('users').doc(user.uid).update({
//         'fullName': _fullNameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'phone': _phoneController.text.trim(),
//         'address': _addressController.text.trim(),
//         'dateOfBirth': _datebirthController.text.trim(),
//         'gender': _genderController.text.trim(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Profile updated successfully!'),backgroundColor: Colors.green,),
//       );
//       setState(() => _isEditing = false);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating profile: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _toggleEditMode() {
//     if (_isEditing) {
//       _loadUserData();
//     }
//     setState(() => _isEditing = !_isEditing);
//   }

//   void _showDeleteDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Account'),
//           content: const Text(
//               'Are you sure you want to delete your account? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _deleteAccount();
//               },
//               child: const Text(
//                 'Delete',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _deleteAccount() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       await _firestore.collection('users').doc(user.uid).delete();
//       await user.delete();
      
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const SigninScreen()),
//         (route) => false,
//       );
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Account deleted successfully'),backgroundColor: Colors.green,),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting account: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           if (!_isEditing)
//             IconButton(
//               icon: const Icon(Icons.edit),
//               onPressed: _isLoading ? null : _toggleEditMode,
//               tooltip: 'Edit Profile',
//             ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: _isLoading ? null : _toggleEditMode,
//               tooltip: 'Cancel',
//             ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.save),
//               onPressed: _isLoading ? null : _updateProfile,
//               tooltip: 'Save Changes',
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     Stack(
//                       alignment: Alignment.bottomCenter,
//                       children: [
//                         GestureDetector(
//                           onTap: _pickImage,
//                           child: CircleAvatar(
//                             radius: 60,
                  
    
//                                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.blue[100],
//                   child: Text(
//                     userData['fullName']?.isNotEmpty == true 
//                         ? userData['fullName'][0] 
//                         : 'U',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                 ),
//                         ),
//                         if (_isEditing)
//                           Positioned(
//                             bottom: 0,
//                             right: 0,
//                             child: Container(
//                               padding: const EdgeInsets.all(6),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(color: Colors.white, width: 2),
//                               ),
//                               child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '@${_fullNameController.text.isNotEmpty ? _fullNameController.text : 'fullName'}',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
                    

//                     const SizedBox(height: 20),
//                     const Divider(),

//                     _buildEditableField(
//                       focusColor: Colors.blue[900],
//                       borderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _fullNameController,
//                       label: 'Full Name',
//                       icon: Icons.person,
//                       isEditing: _isEditing,
//                         TextFormField(
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
//                     ),
//                     _buildEditableField(
//                       focusColor: Colors.blue[900],
//                       borderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _emailController,
//                       label: 'Email',
//                       icon: Icons.email,
//                       isEditing: _isEditing,
//                       keyboardType: TextInputType.emailAddress,
//                     ),
//                     _buildEditableField(
//                       focusColor: Colors.blue[900],
//                       borderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _phoneController,
//                       label: 'Phone',
//                       icon: Icons.phone,
//                       isEditing: _isEditing,
//                       keyboardType: TextInputType.phone,
//                     ),
//                      _buildEditableField(
//                       focusColor: Colors.blue[900],
//                       borderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _addressController,
//                       label: 'address',
//                       icon: Icons.location_on,
//                       isEditing: _isEditing,
//                     ),
//                       _buildEditableField(
//                       focusColor: Colors.blue[900],
//                       borderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _datebirthController,
//                       keyboardType: TextInputType.datetime,
//                       label: 'dateOfBirth',
//                       icon: Icons.calendar_today,
//                       isEditing: _isEditing,
//                       TextFormField(
//                 controller: datebirthController,
//                 decoration: _inputDecoration("Date of Birth", Icons.calendar_today),
//                 readOnly: true,
//                 onTap: () async {
//                 FocusScope.of(context).requestFocus(FocusNode());


//                final DateTime? picked = await showDatePicker(
//                 context: context,
//                initialDate: DateTime.now(),
//                 firstDate: DateTime(1900),
//                lastDate: DateTime.now(),
//                initialEntryMode: DatePickerEntryMode.calendarOnly, // Opens calendar view first
//               initialDatePickerMode: DatePickerMode.year, // Starts with year selection
//               builder: (context, child) {
//               return Theme(
//              data: Theme.of(context).copyWith(
//               colorScheme: ColorScheme.light(
//               primary: Colors.blue,
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.blue,
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
    
//     if (picked != null) {
//       String formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
//       datebirthController.text = formattedDate;
//     }
//   },
//   validator: (value) {
//     if (value == null || value.trim().isEmpty) {
//       return "Please enter your date of birth";
//     }
//     if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
//       return "Enter a valid date (YYYY-MM-DD)";
//     }
//     return null;
//   },
// ),
//                 const SizedBox(height: 12),
//                     ),
//                     _buildGenderDropdown(),

//                     const SizedBox(height: 30),
                    
//                     if (!_isEditing)
//                       ElevatedButton(
//                         onPressed: _showDeleteDialog,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                         ),
//                         child: const Text('Delete Account'),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildGenderDropdown() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: DropdownButtonFormField<String>(
//         value: _genderController.text.isNotEmpty ? _genderController.text : null,
//         decoration: InputDecoration(
//           labelText: 'Gender',
//           prefixIcon: const Icon(Icons.transgender),
//           border: const OutlineInputBorder(),
//           filled: !_isEditing,
//           enabled: _isEditing,
//         ),
//         items: ['Male', 'Female', 'Other'].map((String value) {
//           return DropdownMenuItem<String>(
//             value: value,
//             child: Text(value),
//           );
//         }).toList(),
//         onChanged: _isEditing ? (newValue) {
//           setState(() {
//             _genderController.text = newValue!;
//           });
//         } : null,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please select gender';
//           }
//           return null;
//         },
//       ),
//     );
//   }

//   Widget _buildEditableField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required bool isEditing,
//     Color? focusColor,
//     Color? borderColor,
//     BorderRadius? borderRadius,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: OutlineInputBorder(
//             borderRadius: borderRadius ?? BorderRadius.circular(4),
//             borderSide: BorderSide(color: borderColor ?? Colors.grey),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: borderRadius ?? BorderRadius.circular(4),
//             borderSide: BorderSide(color: focusColor ?? Colors.blue),
//           ),
//           filled: !isEditing,
//           enabled: isEditing,
//         ),
//         keyboardType: keyboardType,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter $label';
//           }
//           if (label == 'Full Name' && value.length < 3) {
//             return 'Must contain at least 3 names';
//           }
//           return null;
//         },
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import '../register/signin_screen.dart';
// import 'dart:io';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   final _storage = FirebaseStorage.instance;
//   final _picker = ImagePicker();

//   final _formKey = GlobalKey<FormState>();
//   final _fullnameController = TextEditingController();
//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _titleController = TextEditingController();
//   final _genderController = TextEditingController();

//   File? _selectedImage;
//   String? _currentImageUrl;
//   bool _isLoading = false;
//   bool _isEditing = false;
//   bool _isImageUploading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       final doc = await _firestore.collection('users').doc(user.uid).get();
//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           _fullnameController.text = data['fullname'] ?? '';
//           _usernameController.text = data['username'] ?? '';
//           _emailController.text = data['email'] ?? '';
//           _phoneController.text = data['phone'] ?? '';
//           _titleController.text = data['title'] ?? '';
//           _genderController.text = data['gender'] ?? '';
//           _currentImageUrl = data['profileImage'];
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading data: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _pickImage() async {
//     if (!_isEditing) return;
    
//     try {
//       final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() {
//           _selectedImage = File(pickedFile.path);
//           _isImageUploading = true;
//         });
//         // Immediately upload the image when selected
//         await _uploadImage();
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error picking image: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isImageUploading = false);
//     }
//   }

//   Future<void> _uploadImage() async {
//     final user = _auth.currentUser;
//     if (user == null || _selectedImage == null) return;

//     try {
//       final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
//       await ref.putFile(_selectedImage!);
//       _currentImageUrl = await ref.getDownloadURL();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error uploading image: ${e.toString()}')),
//       );
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (!_formKey.currentState!.validate()) return;
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       await _firestore.collection('users').doc(user.uid).update({
//         'fullname': _fullnameController.text.trim(),
//         'username': _usernameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'phone': _phoneController.text.trim(),
//         'title': _titleController.text.trim(),
//         'gender': _genderController.text.trim(),
//         'profileImage': _currentImageUrl,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Profile updated successfully!')),
//       );
//       setState(() => _isEditing = false);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating profile: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _toggleEditMode() {
//     if (_isEditing) {
//       // If canceling edit, reload original data
//       _loadUserData();
//     }
//     setState(() => _isEditing = !_isEditing);
//   }

//   // ... [keep your existing delete account methods] ...

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           if (!_isEditing)
//             IconButton(
//               icon: const Icon(Icons.edit),
//               onPressed: _isLoading ? null : _toggleEditMode,
//               tooltip: 'Edit Profile',
//             ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: _isLoading ? null : _toggleEditMode,
//               tooltip: 'Cancel',
//             ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.save),
//               onPressed: _isLoading ? null : _updateProfile,
//               tooltip: 'Save Changes',
//             ),
//         ],
//       ),
//       body: _isLoading
//       bacgroundColor: Colors.white,
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     // Profile Image Section
//                     Stack(
//                       alignment: Alignment.bottomCenter,
//                       children: [
//                         GestureDetector(
//                           onTap: _pickImage,
//                           child: CircleAvatar(
//                             radius: 60,
//                             backgroundColor: Colors.grey[200],
//                             backgroundImage: _selectedImage != null
//                                 ? FileImage(_selectedImage!)
//                                 : (_currentImageUrl != null
//                                     ? NetworkImage(_currentImageUrl!)
//                                     : null),
//                             child: _isImageUploading
//                                 ? const CircularProgressIndicator()
//                                 : (_selectedImage == null && _currentImageUrl == null)
//                                     ? const Icon(Icons.person, size: 60, color: Colors.grey)
//                                     : null,
//                           ),
//                         ),
//                         if (_isEditing)
//                           Positioned(
//                             bottom: 0,
//                             right: 0,
//                             child: Container(
//                               padding: const EdgeInsets.all(6),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(color: Colors.white, width: 2),
//                               ),
//                               child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '@${_usernameController.text.isNotEmpty ? _usernameController.text : 'username'}',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     if (_isEditing)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Text(
//                           'Tap image to change',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),

//                     const SizedBox(height: 20),
//                     const Divider(),

//                     // Editable Fields
//                     _buildEditableField(
//                       focusColor: Colors.blue[900],
//                       boderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _fullnameController,
//                       label: 'Full Name',
//                       icon: Icons.person,
//                       isEditing: _isEditing,
//                     ),
//                     _buildEditableField(
//                             focusColor: Colors.blue[900],
//                       boderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _usernameController,
//                       label: 'Username',
//                       icon: Icons.alternate_email,
//                       isEditing: _isEditing,
//                     ),
//                     _buildEditableField(
//                       controller: _emailController,
//                       label: 'Email',
//                       icon: Icons.email,
//                       isEditing: _isEditing,
//                       keyboardType: TextInputType.emailAddress,
//                     ),
//                     _buildEditableField(
//                             focusColor: Colors.blue[900],
//                       boderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _phoneController,
//                       label: 'Phone',
//                       icon: Icons.phone,
//                       isEditing: _isEditing,
//                       keyboardType: TextInputType.phone,
//                     ),
//                     _buildEditableField(
//                             focusColor: Colors.blue[900],
//                       boderColor: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(10),
//                       controller: _titleController,
//                       label: 'Title',
//                       icon: Icons.work,
//                       isEditing: _isEditing,
//                     ),
//                     _buildGenderDropdown(),

//                     const SizedBox(height: 30),
                    
//                     if (!_isEditing)
//                       ElevatedButton(
//                         onPressed: _showDeleteDialog,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                         ),
//                         child: const Text('Delete Account'),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildGenderDropdown() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: DropdownButtonFormField<String>(
//         value: _genderController.text.isNotEmpty ? _genderController.text : null,
//         decoration: InputDecoration(
//           validator: (value) {
//   if (value == null || value.isEmpty) {
//     return 'Please enter your full name';
//   }
//   if (value.length < 3) {
//     return 'Name too short';
//   }
//   return null;
// },
//           labelText: 'Gender',
//           prefixIcon: const Icon(Icons.transgender),
//           border: const OutlineInputBorder(),
//           filled: !_isEditing,
//           enabled: _isEditing,
//         ),
//         items: ['Male', 'Female', 'Other'].map((String value) {
//           return DropdownMenuItem<String>(
//             value: value,
//             child: Text(value),
//           );
//         }).toList(),
//         onChanged: _isEditing ? (newValue) {
//           setState(() {
//             _genderController.text = newValue!;
//           });
//         } : null,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please select gender';
//           }
//           return null;
//         },
//       ),
//     );
//   }

//   Widget _buildEditableField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required bool isEditing,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: const OutlineInputBorder(),
//           filled: !isEditing,
//           enabled: isEditing,
//         ),
//         keyboardType: keyboardType,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter $label';
//           }
//           return null;
//         },
//       ),
//     );
//   }
//   void _showDeleteDialog() {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Delete Account'),
//         content: const Text(
//             'Are you sure you want to delete your account? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _deleteAccount();
//             },
//             child: const Text(
//               'Delete',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }

// Future<void> _deleteAccount() async {
//   final user = _auth.currentUser;
//   if (user == null) return;

//   setState(() => _isLoading = true);
//   try {
//     // Delete user data from Firestore
//     await _firestore.collection('users').doc(user.uid).delete();
    
//     // Delete user from Firebase Auth
//     await user.delete();
    
//     // Navigate to login screen
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => const SignInScreen()),
//       (route) => false,
//     );
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Account deleted successfully')),
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error deleting account: ${e.toString()}')),
//     );
//   } finally {
//     setState(() => _isLoading = false);
//   }
// }

//   // ... [keep your existing delete account methods] ...
// }
































// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import '../register/signin_screen.dart'; // Adjust the import based on your project structure
// import 'dart:io';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   final _storage = FirebaseStorage.instance;
//   final _picker = ImagePicker();

//   final _formKey = GlobalKey<FormState>();
//   final _fullnameController = TextEditingController();
//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _titleController = TextEditingController();
//   final _genderController = TextEditingController();

//   File? _selectedImage;
//   String? _currentImageUrl;
//   bool _isLoading = false;
//   bool _isEditing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       final doc = await _firestore.collection('users').doc(user.uid).get();
//       if (doc.exists) {
//         final data = doc.data()!;
//         _fullnameController.text = data['fullname'] ?? '';
//         _usernameController.text = data['username'] ?? '';
//         _emailController.text = data['email'] ?? '';
//         _phoneController.text = data['phone'] ?? '';
//         _titleController.text = data['title'] ?? '';
//         _genderController.text = data['gender'] ?? '';
//         _currentImageUrl = data['profileImage'];
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading data: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() => _selectedImage = File(pickedFile.path));
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (!_formKey.currentState!.validate()) return;
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       String? imageUrl = _currentImageUrl;

//       // Upload new image if selected
//       if (_selectedImage != null) {
//         final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
//         await ref.putFile(_selectedImage!);
//         imageUrl = await ref.getDownloadURL();
//       }

//       // Update user data
//       await _firestore.collection('users').doc(user.uid).update({
//         'fullname': _fullnameController.text.trim(),
//         'username': _usernameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'phone': _phoneController.text.trim(),
//         'title': _titleController.text.trim(),
//         'gender': _genderController.text.trim(),
//         'profileImage': imageUrl,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Profile updated successfully!')),
//       );
//       setState(() {
//         _isEditing = false;
//         _currentImageUrl = imageUrl; // Update the current image URL
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating profile: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _toggleEditMode() {
//     setState(() => _isEditing = !_isEditing);
//   }

//   void _showDeleteDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Account'),
//         content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: _deleteAccount,
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _deleteAccount() async {
//     Navigator.pop(context);
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       // Delete profile image if exists
//       if (_currentImageUrl != null) {
//         await _storage.refFromURL(_currentImageUrl!).delete();
//       }

//       // Delete user document
//       await _firestore.collection('users').doc(user.uid).delete();

//       // Delete auth user
//       await user.delete();

//       // Navigate to login
//       if (mounted) {
//         Navigator .push(
//           context,
//           MaterialPageRoute(builder: (context) => const SigninScreen()),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting account: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   void dispose() {
//     _fullnameController.dispose();
//     _usernameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _titleController.dispose();
//     _genderController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           IconButton(
//             icon: Icon(_isEditing ? Icons.close : Icons.edit),
//             onPressed: _isLoading ? null : _toggleEditMode,
//           ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.save),
//               onPressed: _isLoading ? null : _updateProfile,
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     // Profile Image Section with Username Below
//                     Column(
//                       children: [
//                         GestureDetector(
//                           onTap: _isEditing ? _pickImage : null,
//                           child: Stack(
//                             children: [
//                               CircleAvatar(
//                                 radius: 60,
//                                 backgroundImage: _selectedImage != null
//                                     ? FileImage(_selectedImage!)
//                                     : (_currentImageUrl != null
//                                         ? NetworkImage(_currentImageUrl!)
//                                         : const AssetImage('assets/default_profile.png')
//                                             as ImageProvider),
//                                 child: _selectedImage == null && _currentImageUrl == null
//                                     ? const Icon(Icons.person, size: 60)
//                                     : null,
//                               ),
//                               if (_isEditing)
//                                 Positioned(
//                                   bottom: 0,
//                                   right: 0,
//                                   child: Container(
//                                     padding: const EdgeInsets.all(4),
//                                     decoration: BoxDecoration(
//                                       color: Colors.blue,
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           _usernameController.text.isNotEmpty 
//                               ? '@${_usernameController.text}' 
//                               : 'No username set',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         if (_isEditing)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 8.0),
//                             child: Text(
//                               'Tap image to change',
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
                    
//                     // Form Fields
//                     _buildEditableField(
//                       controller: _fullnameController,
//                       label: 'Full Name',
//                       icon: Icons.person,
//                       isEditing: _isEditing,
//                     ),
//                     _buildEditableField(
//                       controller: _usernameController,
//                       label: 'Username',
//                       icon: Icons.alternate_email,
//                       isEditing: _isEditing,
//                     ),
//                     _buildEditableField(
//                       controller: _emailController,
//                       label: 'Email',
//                       icon: Icons.email,
//                       isEditing: _isEditing,
//                       keyboardType: TextInputType.emailAddress,
//                     ),
//                     _buildEditableField(
//                       controller: _phoneController,
//                       label: 'Phone',
//                       icon: Icons.phone,
//                       isEditing: _isEditing,
//                       keyboardType: TextInputType.phone,
//                     ),
//                     _buildEditableField(
//                       controller: _titleController,
//                       label: 'Title',
//                       icon: Icons.work,
//                       isEditing: _isEditing,
//                     ),
//                     _buildEditableField(
//                       controller: _genderController,
//                       label: 'Gender',
//                       icon: Icons.transgender,
//                       isEditing: _isEditing,
//                     ),
                    
//                     const SizedBox(height: 30),
                    
//                     // Delete Account Button
//                     if (!_isEditing)
//                       ElevatedButton(
//                         onPressed: _showDeleteDialog,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                         ),
//                         child: const Text('Delete Account'),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildEditableField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required bool isEditing,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: const OutlineInputBorder(),
//           filled: !isEditing,
//           enabled: isEditing,
//         ),
//         keyboardType: keyboardType,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter $label';
//           }
//           return null;
//         },
//       ),
//     );
//   }
// }





























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   final _storage = FirebaseStorage.instance;
//   final _picker = ImagePicker();

//   final _formKey = GlobalKey<FormState>();
//   final _fullnameController = TextEditingController();
//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _titleController = TextEditingController();
//   final _genderController = TextEditingController();

//   File? _selectedImage;
//   String? _currentImageUrl;
//   bool _isLoading = false;
//   bool _isEditing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       final doc = await _firestore.collection('users').doc(user.uid).get();
//       if (doc.exists) {
//         final data = doc.data()!;
//         _fullnameController.text = data['fullname'] ?? '';
//         _usernameController.text = data['username'] ?? '';
//         _emailController.text = data['email'] ?? '';
//         _phoneController.text = data['phone'] ?? '';
//         _titleController.text = data['title'] ?? '';
//         _genderController.text = data['gender'] ?? '';
//         _currentImageUrl = data['profileImage'];
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading data: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() => _selectedImage = File(pickedFile.path));
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (!_formKey.currentState!.validate()) return;
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       String? imageUrl = _currentImageUrl;

//       // Upload new image if selected
//       if (_selectedImage != null) {
//         final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
//         await ref.putFile(_selectedImage!);
//         imageUrl = await ref.getDownloadURL();
//       }

//       // Update user data
//       await _firestore.collection('users').doc(user.uid).update({
//         'fullname': _fullnameController.text.trim(),
//         'username': _usernameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'phone': _phoneController.text.trim(),
//         'title': _titleController.text.trim(),
//         'gender': _genderController.text.trim(),
//         'profileImage': imageUrl,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Profile updated successfully!')),
//       );
//       setState(() => _isEditing = false);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating profile: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _toggleEditMode() {
//     setState(() => _isEditing = !_isEditing);
//   }

//   void _showDeleteDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Account'),
//         content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: _deleteAccount,
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _deleteAccount() async {
//     Navigator.pop(context);
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isLoading = true);
//     try {
//       // Delete profile image if exists
//       if (_currentImageUrl != null) {
//         await _storage.refFromURL(_currentImageUrl!).delete();
//       }

//       // Delete user document
//       await _firestore.collection('users').doc(user.uid).delete();

//       // Delete auth user
//       await user.delete();

//       // Navigate to login
//       if (mounted) {
//         Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting account: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   void dispose() {
//     _fullnameController.dispose();
//     _usernameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _titleController.dispose();
//     _genderController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           IconButton(
//             icon: Icon(_isEditing ? Icons.close : Icons.edit),
//             onPressed: _isLoading ? null : _toggleEditMode,
//           ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.save),
//               onPressed: _isLoading ? null : _updateProfile,
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     // Profile Image
//                     GestureDetector(
//                       onTap: _isEditing ? _pickImage : null,
//                       child: Stack(
//                         children: [
//                           CircleAvatar(
//                             radius: 60,
//                             backgroundImage: _selectedImage != null
//                                 ? FileImage(_selectedImage!)
//                                 : (_currentImageUrl != null
//                                     ? NetworkImage(_currentImageUrl!)
//                                     : const AssetImage('assets/default_profile.png')
//                                         as ImageProvider),
//                             child: _selectedImage == null && _currentImageUrl == null
//                                 ? const Icon(Icons.person, size: 60)
//                                 : null,
//                           ),
//                           if (_isEditing)
//                             Positioned(
//                               bottom: 0,
//                               right: 0,
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
                    
//                     // Form Fields
//                     _buildEditableField(
//                       controller: _fullnameController,
//                       label: 'Full Name',
//                       icon: Icons.person,
//                       isEditing: _isEditing,
//                     ),
//                     _buildEditableField(
//                       controller: _usernameController,
//                       label: 'Username',
//                       icon: Icons.alternate_email,
//                       isEditing: _isEditing,
//                     ),
//                     _buildEditableField(
//                       controller: _emailController,
//                       label: 'Email',
//                       icon: Icons.email,
//                       isEditing: _isEditing,
//                       keyboardType: TextInputType.emailAddress,
//                     ),
//                     _buildEditableField(
//                       controller: _phoneController,
//                       label: 'Phone',
//                       icon: Icons.phone,
//                       isEditing: _isEditing,
//                       keyboardType: TextInputType.phone,
//                     ),
//                     _buildEditableField(
//                       controller: _titleController,
//                       label: 'Title',
//                       icon: Icons.work,
//                       isEditing: _isEditing,
//                     ),
//                     _buildEditableField(
//                       controller: _genderController,
//                       label: 'Gender',
//                       icon: Icons.transgender,
//                       isEditing: _isEditing,
//                     ),
                    
//                     const SizedBox(height: 30),
                    
//                     // Delete Account Button
//                     if (!_isEditing)
//                       ElevatedButton(
//                         onPressed: _showDeleteDialog,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                         ),
//                         child: const Text('Delete Account'),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildEditableField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required bool isEditing,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: const OutlineInputBorder(),
//           filled: !isEditing,
//           enabled: isEditing,
//         ),
//         keyboardType: keyboardType,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter $label';
//           }
//           return null;
//         },
//       ),
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';

// class UpdateProfileScreen extends StatefulWidget {
//   const UpdateProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
// }

// class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   final TextEditingController _fullnameController = TextEditingController();
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _genderController = TextEditingController();

//   User? get currentUser => _auth.currentUser;
//   File? _selectedImage;
//   String? _imageUrl;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     if (currentUser != null) {
//       final uid = currentUser!.uid;
//       final doc = await _firestore.collection('users').doc(uid).get();

//       if (doc.exists) {
//         final data = doc.data()!;
//         _fullnameController.text = data['fullname'] ?? '';
//         _usernameController.text = data['username'] ?? '';
//         _emailController.text = data['email'] ?? '';
//         _phoneController.text = data['phone'] ?? '';
//         _titleController.text = data['title'] ?? '';
//         _genderController.text = data['gender'] ?? '';
//         _imageUrl = data['profileImage'];
//         setState(() {});
//       }
//     }
//   }

//   Future<void> _pickImage() async {
//     final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() => _selectedImage = File(picked.path));
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (currentUser == null) return;

//     setState(() => _isLoading = true);
//     final uid = currentUser!.uid;

//     try {
//       String? downloadUrl = _imageUrl;

//       if (_selectedImage != null) {
//         final ref = _storage.ref().child('profileImages').child('$uid.jpg');
//         await ref.putFile(_selectedImage!);
//         downloadUrl = await ref.getDownloadURL();
//       }

//       await _firestore.collection('users').doc(uid).update({
//         'fullname': _fullnameController.text.trim(),
//         'username': _usernameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'phone': _phoneController.text.trim(),
//         'title': _titleController.text.trim(),
//         'gender': _genderController.text.trim(),
//         'profileImage': downloadUrl,
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Profile updated successfully")),
//       );
//     } catch (e) {
//       print("Update error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to update profile")),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _confirmDeleteAccount() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Delete Account"),
//         content: const Text("Are you sure you want to delete your account? This cannot be undone."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: _deleteAccount,
//             child: const Text("Delete", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _deleteAccount() async {
//     Navigator.pop(context); // close dialog
//     setState(() => _isLoading = true);

//     try {
//       final uid = currentUser!.uid;

//       // Delete profile image
//       if (_imageUrl != null) {
//         final ref = _storage.refFromURL(_imageUrl!);
//         await ref.delete();
//       }

//       // Delete Firestore user document
//       await _firestore.collection('users').doc(uid).delete();

//       // Delete user from FirebaseAuth
//       await currentUser!.delete();

//       // Navigate to login
//       if (mounted) {
//         Navigator.of(context).pushReplacementNamed('/login');
//       }
//     } catch (e) {
//       print("Delete error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Error deleting account. Please re-login and try again.")),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Update Profile"),
//       ),
//         @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Profile"),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.blue[900]),
//         titleTextStyle: TextStyle(
//           color: Colors.blue[900],
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit), 
//             onPressed: _editProfile,
//             color: Colors.blue[900],
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: _showDeleteConfirmation,
//             color: Colors.red,
//           ),
//         ],
//       ),
//      // Replace the body of your Scaffold with this:
// body: Container(
//   color: Colors.white, // This sets the background color
//   child: ListView(
//     padding: const EdgeInsets.all(16),
//     children: [
//       Center(
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 50,
//               backgroundImage: imageFile != null 
//                   ? FileImage(imageFile!) 
//                   : const AssetImage('assets/default_profile.png') as ImageProvider,
//               child: imageFile == null 
//                   ? const Icon(Icons.person, size: 40) 
//                   : null,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               username, 
//               style: const TextStyle(
//                 fontSize: 20, 
//                 fontWeight: FontWeight.bold
//               )
//             ),
//             Text(
//               "Tap camera to change photo",
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       )
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   GestureDetector(
//                     onTap: _pickImage,
//                     child: CircleAvatar(
//                       radius: 50,
//                       backgroundImage: _selectedImage != null
//                           ? FileImage(_selectedImage!)
//                           : (_imageUrl != null ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
//                       child: _selectedImage == null && _imageUrl == null
//                           ? const Icon(Icons.add_a_photo, size: 30)
//                           : null,
//                     ),
//                   ),
//                   await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Edit Profile"),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               GestureDetector(
//                 onTap: () async {
//                   final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//                   if (picked != null) {
//                     setState(() => imageFile = File(picked.path));
//                   }
//                 },
//                 child: CircleAvatar(
//                   radius: 40,
//                   backgroundImage: imageFile != null 
//                       ? FileImage(imageFile!) 
//                       : const AssetImage('assets/default_profile.png') as ImageProvider,
//                   child: imageFile == null ? const Icon(Icons.camera_alt) : null,
//                 ),
//               ),
//                   const SizedBox(height: 20),
//                   TextField(
//                     controller: _fullnameController,
//                     decoration: const InputDecoration(labelText: "Full Name"),
//                   ),
//                   const SizedBox(height: 10),
//                    TextField(
//                     controller: _usernameController,
//                     decoration: const InputDecoration(labelText: "Username"),
//                   ),
                 
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: _emailController,
//                     decoration: const InputDecoration(labelText: "Email"),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: _phoneController,
//                     decoration: const InputDecoration(labelText: "Phone"),
//                   ),
//                    const SizedBox(height: 10),
//                    TextField(
//                     controller: _titleController,
//                     decoration: const InputDecoration(labelText: "Title"),
//                   ),
//                   const SizedBox(height: 10),
//                    TextField(
//                     controller: _genderController,
//                     decoration: const InputDecoration(labelText: "Gender"),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: _updateProfile,
//                     child: const Text("Save Changes"),
//                   ),
//                   const SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: _confirmDeleteAccount,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                     ),
//                     child: const Text("Delete Account"),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }






















// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';


// class ProfileScreen extends StatefulWidget {
//   final String fullname;
//   final String username;
//   final String email;
//   final String phone;
//   final String title;
//   final String gender;
//   final File? imageFile;

//   const ProfileScreen({
//     super.key,
//     required this.fullname,
//     required this.username,
//     required this.email,
//     required this.phone,
//     required this.title,
//     required this.gender,
//     this.imageFile,
//   });

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   late String fullname;
//   late String username;
//   late String phone;
//   late String email;
//   late String title;
//   late String gender;
//   File? imageFile;

//   @override
//   void initState() {
//     super.initState();
//     fullname = widget.fullname;
//     username = widget.username;
//     phone = widget.phone;
//     email = widget.email;
//     title = widget.title;
//     gender = widget.gender;
//     imageFile = widget.imageFile;
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final uid = user.uid;
//       final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

//       if (doc.exists) {
//         final data = doc.data()!;
//         setState(() {
//           fullname = data['fullname'] ?? '';
//           username = data['username'] ?? '';
//           phone = data['phone'] ?? '';
//           email = data['email'] ?? user.email ?? '';
//           title = data['title'] ?? '';
//           gender = data['gender'] ?? '';
//         });
//       }
//     }
//   }

//   // (wax kale code-kaaga wuxuu ahaa sax UI + dialog + form)

// }


//   Future<void> _editProfile() async {
//     final fullnameController = TextEditingController(text: fullname);
//     final usernameController = TextEditingController(text: username);
//     final phoneController = TextEditingController(text: phone);
//     final titleController = TextEditingController(text: title);
//     final genderController = TextEditingController(text: gender);

//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Edit Profile"),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               GestureDetector(
//                 onTap: () async {
//                   final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//                   if (picked != null) {
//                     setState(() => imageFile = File(picked.path));
//                   }
//                 },
//                 child: CircleAvatar(
//                   radius: 40,
//                   backgroundImage: imageFile != null 
//                       ? FileImage(imageFile!) 
//                       : const AssetImage('assets/default_profile.png') as ImageProvider,
//                   child: imageFile == null ? const Icon(Icons.camera_alt) : null,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: fullnameController,
//                 decoration: const InputDecoration(labelText: 'Full Name'),
//               ),
//               TextField(
//                 controller: usernameController,
//                 decoration: const InputDecoration(labelText: 'Username'),
//               ),
//               TextField(
//                 controller: phoneController,
//                 decoration: const InputDecoration(labelText: 'Phone Number'),
//                 keyboardType: TextInputType.phone,
//               ),
//               TextField(
//                 controller: titleController,
//                 decoration: const InputDecoration(labelText: 'Title'),
//                 readOnly: true,
//                 onTap: () => _showTitleSelection(titleController),
//               ),
//               TextField(
//                 controller: genderController,
//                 decoration: const InputDecoration(labelText: 'Gender'),
//                 readOnly: true,
//                 onTap: () => _showGenderSelection(genderController),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context), 
//             child: const Text("Cancel")
//           ),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 fullname = fullnameController.text;
//                 username = usernameController.text;
//                 phone = phoneController.text;
//                 title = titleController.text;
//                 gender = genderController.text;
//               });
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Profile updated')),
//               );
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _showTitleSelection(TextEditingController controller) async {
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) => SimpleDialog(
//         title: const Text('Select Title'),
//         children: [
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(context, 'Doctor'),
//             child: const Text('Doctor'),
//           ),
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(context, 'User'),
//             child: const Text('User'),
//           ),
//         ],
//       ),
//     );
//     if (result != null) {
//       controller.text = result;
//     }
//   }

//   Future<void> _showGenderSelection(TextEditingController controller) async {
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) => SimpleDialog(
//         title: const Text('Select Gender'),
//         children: [
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(context, 'Male'),
//             child: const Text('Male'),
//           ),
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(context, 'Female'),
//             child: const Text('Female'),
//           ),
//         ],
//       ),
//     );
//     if (result != null) {
//       controller.text = result;
//     }
//   }

//   Future<void> _showDeleteConfirmation() async {
//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Are you sure?"),
//         content: const Text("Do you really want to delete your account?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               // Replace RegisterScreen with your actual register screen
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const SignupScreen()),
//               );
//             },
//             child: const Text("Yes"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Profile"),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.blue[900]),
//         titleTextStyle: TextStyle(
//           color: Colors.blue[900],
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit), 
//             onPressed: _editProfile,
//             color: Colors.blue[900],
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: _showDeleteConfirmation,
//             color: Colors.red,
//           ),
//         ],
//       ),
//      // Replace the body of your Scaffold with this:
// body: Container(
//   color: Colors.white, // This sets the background color
//   child: ListView(
//     padding: const EdgeInsets.all(16),
//     children: [
//       Center(
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 50,
//               backgroundImage: imageFile != null 
//                   ? FileImage(imageFile!) 
//                   : const AssetImage('assets/default_profile.png') as ImageProvider,
//               child: imageFile == null 
//                   ? const Icon(Icons.person, size: 40) 
//                   : null,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               username, 
//               style: const TextStyle(
//                 fontSize: 20, 
//                 fontWeight: FontWeight.bold
//               )
//             ),
//             Text(
//               "Tap camera to change photo",
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//       const SizedBox(height: 30),
//       _buildSettingItem(Icons.account_circle, 'Fullname', fullname),
//       _buildSettingItem(Icons.email, 'Email', email),
//       _buildSettingItem(Icons.phone, 'Phone', phone),
//       _buildSettingItem(Icons.work, 'Title', title),
//       _buildSettingItem(Icons.person, 'Gender', gender),
//     ],
//   ),
// ),
//     );
//   }

//   Widget _buildSettingItem(IconData icon, String title, String subtitle) {
//     return ListTile(
//       leading: Icon(icon),
//       title: Text(title),
//       subtitle: Text(
//         subtitle, 
//         style: const TextStyle(color: Colors.grey)
//       ),
//     );
//   }
// }
















// import 'package:flutter/material.dart';

// class ProfileScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Profile')),
//       body: Center(child: Text('Manage your profile')),
//     );
//   }
// }
