import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'en';

  final List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en', 'flag': '🇬🇧'},
    {'name': 'Soomaali', 'code': 'so', 'flag': '🇸🇴'},
    {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦'},
  ];

  String _getTitle() {
    switch (_selectedLanguage) {
      case 'so':
        return 'Xulo Luqaddaada';
      case 'ar':
        return 'اختر لغتك';
      default:
        return 'Select Your Language';
    }
  }

  String _getBackLabel() {
    switch (_selectedLanguage) {
      case 'so':
        return 'Dib u laabo';
      case 'ar':
        return 'رجوع';
      default:
        return 'Go Back';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, size: width * 0.06),
        //   onPressed: () => Navigator.pop(context),
        // ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    final isSelected = _selectedLanguage == language['code'];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Text(
                          language['flag']!,
                          style: TextStyle(fontSize: width * 0.06),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: width * 0.05,
                          vertical: width * 0.03,
                        ),
                        title: Text(
                          language['name']!,
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, 
                                color: Colors.blue, 
                                size: width * 0.06)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedLanguage = language['code']!;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.arrow_back_ios, size: width * 0.045),
                  label: Text(
                    _getBackLabel(),
                    style: TextStyle(fontSize: width * 0.045),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _selectedLanguage);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: width * 0.035,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}































// import 'package:flutter/material.dart';

// class LanguageScreen extends StatelessWidget {
//   final Function(Locale) changeLanguage;
//   final Locale currentLocale;

//   const LanguageScreen({
//     Key? key,
//     required this.changeLanguage,
//     required this.currentLocale,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final languages = [
//       {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
//       {'name': 'Soomaali', 'code': 'so', 'flag': '🇸🇴'},
//       {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦'},
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_getTranslation('Language Selection', currentLocale)),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: width * 0.05),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               Text(
//                 _getTranslation('Choose your preferred language', currentLocale),
//                 style: TextStyle(fontSize: width * 0.045),
//               ),
//               const SizedBox(height: 30),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: languages.length,
//                   itemBuilder: (context, index) {
//                     final language = languages[index];
//                     final isSelected = currentLocale.languageCode == language['code'];
//                     return Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 3,
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       child: ListTile(
//                         leading: Text(
//                           language['flag']!,
//                           style: TextStyle(fontSize: width * 0.06),
//                         ),
//                         title: Text(language['name']!),
//                         trailing: isSelected
//                             ? const Icon(Icons.check, color: Colors.blue)
//                             : null,
//                         onTap: () => changeLanguage(Locale(language['code']!)),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text(_getTranslation('Go Back', currentLocale)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _getTranslation(String text, Locale locale) {
//     switch (locale.languageCode) {
//       case 'ar':
//         switch (text) {
//           case 'Language Selection': return 'اختيار اللغة';
//           case 'Choose your preferred language': return 'اختر لغتك المفضلة';
//           case 'Go Back': return 'رجوع';
//           default: return text;
//         }
//       case 'so':
//         switch (text) {
//           case 'Language Selection': return 'Xulo Luqadda';
//           case 'Choose your preferred language': return 'Xulo luqadda aad door bidayso';
//           case 'Go Back': return 'Dib u laabo';
//           default: return text;
//         }
//       default: return text;
//     }
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:intl/intl.dart';
   

//    class LanguageSelectionScreen extends StatelessWidget {
//   final Function(Locale) changeLanguage;
//   final Locale currentLocale;

//   const LanguageSelectionScreen({
//     super.key,
//     required this.changeLanguage,
//     required this.currentLocale,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_getTranslation('Language Selection', context)),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               _getTranslation('Choose your preferred language', context),
//               style: const TextStyle(fontSize: 18),
//             ),
//             const SizedBox(height: 30),
//             LanguageOption(
//               languageCode: 'en',
//               languageName: 'English',
             
//               isSelected: currentLocale.languageCode == 'en',
//               onTap: () => changeLanguage(const Locale('en')),
//             ),
//             const SizedBox(height: 20),
//             LanguageOption(
//               languageCode: 'ar',
//               languageName: 'العربية', // Arabic
            
//               isSelected: currentLocale.languageCode == 'ar',
//               onTap: () => changeLanguage(const Locale('ar')),
//             ),
//             const SizedBox(height: 20),
//             LanguageOption(
//               languageCode: 'so',
//               languageName: 'Soomaali', // Somali
           
//               isSelected: currentLocale.languageCode == 'so',
//               onTap: () => changeLanguage(const Locale('so')),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getTranslation(String text, BuildContext context) {
//     switch (currentLocale.languageCode) {
//       case 'ar':
//         // Arabic translations
//         switch (text) {
//           case 'Language Selection':
//             return 'اختيار اللغة';
//           case 'Choose your preferred language':
//             return 'اختر لغتك المفضلة';
//           default:
//             return text;
//         }
//       case 'so':
//         // Somali translations
//         switch (text) {
//           case 'Language Selection':
//             return 'Xulo Luqadda';
//           case 'Choose your preferred language':
//             return 'Xulo luqadda aad door bidayso';
//           default:
//             return text;
//         }
//       default:
//         return text;
//     }
//   }
// }

// class LanguageOption extends StatelessWidget {
//   final String languageCode;
//   final String languageName;
//   final String flagAsset;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const LanguageOption({
//     super.key,
//     required this.languageCode,
//     required this.languageName,
//     required this.flagAsset,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: isSelected ? Colors.blue : Colors.grey,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Display flag (replace with actual Image.asset with your flag images)
//             Container(
//               width: 30,
//               height: 20,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//               ),
//               child: Center(
//                 child: Text(
//                   languageCode == 'en' 
//                     ? '🇺🇸' 
//                     : languageCode == 'ar' 
//                       ? '🇸🇦' 
//                       : '🇸🇴',
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 15),
//             Text(
//               languageName,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//             if (isSelected) ...[
//               const SizedBox(width: 10),
//               const Icon(Icons.check_circle, color: Colors.blue),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }


// class LanguageScreen extends StatefulWidget {
//   const LanguageScreen({Key? key}) : super(key: key);

//   @override
//   State<LanguageScreen> createState() => _LanguageScreenState();
// }

// class _LanguageScreenState extends State<LanguageScreen> {
//   late String _selectedLanguage;

//   final List<Map<String, String>> languages = [
//     {'name': 'English', 'code': 'en', 'flag': '🇬🇧'},
//     {'name': 'Soomaali', 'code': 'so', 'flag': '🇸🇴'},
//     {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _selectedLanguage = PregnancyApp.of(context)?.locale.languageCode ?? 'en';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_getTranslatedTitle()),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, size: width * 0.06),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: _buildLanguageSelectionBody(width),
//     );
//   }

//   String _getTranslatedTitle() {
//     switch (_selectedLanguage) {
//       case 'so':
//         return 'Xulo Luqaddaada';
//       case 'ar':
//         return 'اختر لغتك';
//       default:
//         return 'Select Your Language';
//     }
//   }

//   String _getTranslatedBackLabel() {
//     switch (_selectedLanguage) {
//       case 'so':
//         return 'Dib u laabo';
//       case 'ar':
//         return 'رجوع';
//       default:
//         return 'Go Back';
//     }
//   }

//   Widget _buildLanguageSelectionBody(double width) {
//     return SafeArea(
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: width * 0.05),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: languages.length,
//                 itemBuilder: (context, index) => _buildLanguageTile(width, index),
//               ),
//             ),
//             _buildBackButton(width),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLanguageTile(double width, int index) {
//     final language = languages[index];
//     final isSelected = _selectedLanguage == language['code'];
    
//     return Card(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       elevation: 3,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         leading: Text(
//           language['flag']!,
//           style: TextStyle(fontSize: width * 0.06),
//         ),
//         contentPadding: EdgeInsets.symmetric(
//           horizontal: width * 0.05,
//           vertical: width * 0.03,
//         ),
//         title: Text(
//           language['name']!,
//           style: TextStyle(
//             fontSize: width * 0.045,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         trailing: isSelected
//             ? Icon(Icons.check, color: Colors.blue, size: width * 0.06)
//             : null,
//         onTap: () => _handleLanguageSelection(language['code']!),
//       ),
//     );
//   }

//   Widget _buildBackButton(double width) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         icon: Icon(Icons.arrow_back_ios, size: width * 0.045),
//         label: Text(
//           _getTranslatedBackLabel(),
//           style: TextStyle(fontSize: width * 0.045),
//         ),
//         onPressed: () => Navigator.pop(context),
//         style: ElevatedButton.styleFrom(
//           padding: EdgeInsets.symmetric(vertical: width * 0.035),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.white,
//         ),
//       ),
//     );
//   }

//   void _handleLanguageSelection(String languageCode) {
//     setState(() {
//       _selectedLanguage = languageCode;
//     });
//     PregnancyApp.of(context)?.setLocale(Locale(languageCode));
//   }
// }
























// import 'package:flutter/material.dart';

// class LanguageScreen extends StatefulWidget {
//   const LanguageScreen({Key? key}) : super(key: key);

//   @override
//   _LanguageScreenState createState() => _LanguageScreenState();
// }

// class _LanguageScreenState extends State<LanguageScreen> {
//   String _selectedLanguage = 'en';

//   final List<Map<String, String>> languages = [
//     {'name': 'English', 'code': 'en', 'flag': '🇬🇧'},
//     {'name': 'Soomaali', 'code': 'so', 'flag': '🇸🇴'},
//     {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦'},
//   ];

//   String _getTitle() {
//     switch (_selectedLanguage) {
//       case 'so':
//         return 'Xulo Luqaddaada';
//       case 'ar':
//         return 'اختر لغتك';
//       default:
//         return 'Select Your Language';
//     }
//   }

//   String _getBackLabel() {
//     switch (_selectedLanguage) {
//       case 'so':
//         return 'Dib u laabo';
//       case 'ar':
//         return 'رجوع';
//       default:
//         return 'Go Back';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_getTitle()),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, size: width * 0.06),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: width * 0.05),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: languages.length,
//                   itemBuilder: (context, index) {
//                     final language = languages[index];
//                     final isSelected = _selectedLanguage == language['code'];
//                     return Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 3,
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       child: ListTile(
//                         leading: Text(
//                           language['flag']!,
//                           style: TextStyle(fontSize: width * 0.06),
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: width * 0.05,
//                           vertical: width * 0.03,
//                         ),
//                         title: Text(
//                           language['name']!,
//                           style: TextStyle(
//                             fontSize: width * 0.045,
//                             fontWeight:
//                                 isSelected ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: isSelected
//                             ? Icon(Icons.check, 
//                                 color: Colors.blue, 
//                                 size: width * 0.06)
//                             : null,
//                         onTap: () {
//                           setState(() {
//                             _selectedLanguage = language['code']!;
//                           });
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   icon: Icon(Icons.arrow_back_ios, size: width * 0.045),
//                   label: Text(
//                     _getBackLabel(),
//                     style: TextStyle(fontSize: width * 0.045),
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context, _selectedLanguage);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(
//                       vertical: width * 0.035,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }














// import 'package:flutter/material.dart';


// class LanguageScreen extends StatefulWidget {
//   const LanguageScreen({Key? key}) : super(key: key);

//   @override
//   _LanguageScreenState createState() => _LanguageScreenState();
// }

// class _LanguageScreenState extends State<LanguageScreen> {
//   String _selectedLanguage = 'en';

//   final List<Map<String, String>> languages = [
//     {'name': 'English', 'code': 'en'},
//     {'name': 'Soomaali', 'code': 'so'},
//     {'name': 'العربية', 'code': 'ar'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadSelectedLanguage();
//   }

//   Future<void> _loadSelectedLanguage() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _selectedLanguage = prefs.getString('languageCode') ?? 'en';
//     });
//   }

//   Future<void> _changeLanguage(String languageCode) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('languageCode', languageCode);
//     setState(() {
//       _selectedLanguage = languageCode;
//     });
//     // Optionally trigger locale change or app restart
//   }

//   String _getTitle() {
//     switch (_selectedLanguage) {
//       case 'so':
//         return 'Xulo Luqaddaada';
//       case 'ar':
//         return 'اختر لغتك';
//       default:
//         return 'Select Your Language';
//     }
//   }

//   String _getBackLabel() {
//     switch (_selectedLanguage) {
//       case 'so':
//         return 'Dib u laabo';
//       case 'ar':
//         return 'رجوع';
//       default:
//         return 'Go Back';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_getTitle()),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, size: width * 0.06),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: width * 0.05),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: languages.length,
//                   itemBuilder: (context, index) {
//                     final language = languages[index];
//                     final isSelected = _selectedLanguage == language['code'];
//                     return Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 3,
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       child: ListTile(
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: width * 0.05,
//                           vertical: width * 0.03,
//                         ),
//                         title: Text(
//                           language['name']!,
//                           style: TextStyle(
//                             fontSize: width * 0.045,
//                             fontWeight:
//                                 isSelected ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         trailing: isSelected
//                             ? Icon(Icons.check, color: Colors.blue, size: width * 0.06)
//                             : null,
//                         onTap: () => _changeLanguage(language['code']!),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   icon: Icon(Icons.arrow_back_ios, size: width * 0.045),
//                   label: Text(
//                     _getBackLabel(),
//                     style: TextStyle(fontSize: width * 0.045),
//                   ),
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(
//                       vertical: width * 0.035,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


















// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class LanguageScreen extends StatefulWidget {
//   const LanguageScreen({Key? key}) : super(key: key);

//   @override
//   _LanguageScreenState createState() => _LanguageScreenState();
// }

// class _LanguageScreenState extends State<LanguageScreen> {
//   String _selectedLanguage = 'en';
//   final List<Map<String, String>> languages = [
//     {'name': 'English', 'code': 'en'},
//     {'name': 'Soomaali', 'code': 'so'},
//     {'name': 'العربية', 'code': 'ar'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadSelectedLanguage();
//   }

//   Future<void> _loadSelectedLanguage() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _selectedLanguage = prefs.getString('languageCode') ?? 'en';
//     });
//   }

//   Future<void> _changeLanguage(String languageCode) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('languageCode', languageCode);
//     setState(() {
//       _selectedLanguage = languageCode;
//     });
//     // Restart app or update UI as needed
//   }

//   String _getTitle() {
//     switch (_selectedLanguage) {
//       case 'so':
//         return 'Xulo Luqaddaada';
//       case 'ar':
//         return 'اختر لغتك';
//       default:
//         return 'Select Your Language';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_getTitle()),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pushNamed(context, '/home'),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 itemCount: languages.length,
//                 itemBuilder: (context, index) {
//                   final language = languages[index];
//                   return Card(
//                     child: ListTile(
//                       title: Text(language['name']!),
//                       trailing: _selectedLanguage == language['code']
//                           ? Icon(Icons.check, color: Colors.blue)
//                           : null,
//                       onTap: () => _changeLanguage(language['code']!),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text(
//                 _selectedLanguage == 'so' 
//                   ? 'Dib u soo noqnoqoshada' 
//                   : _selectedLanguage == 'ar'
//                     ? 'رجوع'
//                     : 'Go Back',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }











// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final prefs = await SharedPreferences.getInstance();
//   final languageCode = prefs.getString('languageCode') ?? 'en';
//   runApp(MyApp(languageCode: languageCode));
// }

// class MyApp extends StatelessWidget {
//   final String languageCode;
  
//   const MyApp({Key? key, required this.languageCode}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Language Selection App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: LanguageSelectionScreen(),
//     );
//   }
// }

// class LanguageSelectionScreen extends StatefulWidget {
//   @override
//   _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
// }

// class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
//   String _searchQuery = '';
//   String _selectedLanguage = 'en';

//   final List<Map<String, String>> languages = [
//     {'name': 'English', 'code': 'en'},
//     {'name': 'German', 'code': 'de'},
//     {'name': 'Indian', 'code': 'hi'},
//     {'name': 'Brazil', 'code': 'pt'},
//     {'name': 'Italy', 'code': 'it'},
//     {'name': 'Soomaali', 'code': 'so'},
//     {'name': 'العربية', 'code': 'ar'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadSelectedLanguage();
//   }

//   Future<void> _loadSelectedLanguage() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _selectedLanguage = prefs.getString('languageCode') ?? 'en';
//     });
//   }

//   Future<void> _changeLanguage(String languageCode) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('languageCode', languageCode);
//     setState(() {
//       _selectedLanguage = languageCode;
//     });
//     // You can add navigation or app restart logic here if needed
//   }

//   List<Map<String, String>> get filteredLanguages {
//     return languages.where((lang) => 
//       lang['name']!.toLowerCase().contains(_searchQuery.toLowerCase())
//     ).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Select your preferred Language'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search your language',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                 ),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value;
//                 });
//               },
//             ),
//             SizedBox(height: 20),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredLanguages.length,
//                 itemBuilder: (context, index) {
//                   final language = filteredLanguages[index];
//                   return ListTile(
//                     title: Text(language['name']!),
//                     trailing: _selectedLanguage == language['code']
//                         ? Icon(Icons.check, color: Colors.blue)
//                         : null,
//                     onTap: () => _changeLanguage(language['code']!),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }








// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   final prefs = await SharedPreferences.getInstance();
//   final languageCode = prefs.getString('languageCode') ?? 'en';
  
//   runApp(MyApp(languageCode: languageCode));
// }

// class MyApp extends StatelessWidget {
//   final String languageCode;
  
//   const MyApp({Key? key, required this.languageCode}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Multi-Language App',
//       locale: Locale(languageCode),
//       localizationsDelegates: const [
//         AppLocalizations.delegate,
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: const [
//         Locale('en', ''), // English
//         Locale('so', ''), // Somali
//         Locale('ar', ''), // Arabic
//       ],
//       home: const LanguageScreen(),
//     );
//   }
// }

// class LanguageScreen extends StatefulWidget {
//   const LanguageScreen({Key? key}) : super(key: key);

//   @override
//   _LanguageScreenState createState() => _LanguageScreenState();
// }

// class _LanguageScreenState extends State<LanguageScreen> {
//   String _selectedLanguage = 'en';

//   @override
//   void initState() {
//     super.initState();
//     _loadSelectedLanguage();
//   }

//   Future<void> _loadSelectedLanguage() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _selectedLanguage = prefs.getString('languageCode') ?? 'en';
//     });
//   }

//   Future<void> _changeLanguage(String languageCode) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('languageCode', languageCode);
    
//     if (mounted) {
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (_) => MyApp(languageCode: languageCode)),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(AppLocalizations.of(context)!.languageTitle),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               AppLocalizations.of(context)!.selectLanguage,
//               style: const TextStyle(fontSize: 20),
//             ),
//             const SizedBox(height: 30),
//             LanguageOption(
//               language: 'English',
//               code: 'en',
//               selected: _selectedLanguage == 'en',
//               onTap: () => _changeLanguage('en'),
//             ),
//             LanguageOption(
//               language: 'Soomaali',
//               code: 'so',
//               selected: _selectedLanguage == 'so',
//               onTap: () => _changeLanguage('so'),
//             ),
//             LanguageOption(
//               language: 'العربية',
//               code: 'ar',
//               selected: _selectedLanguage == 'ar',
//               onTap: () => _changeLanguage('ar'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class LanguageOption extends StatelessWidget {
//   final String language;
//   final String code;
//   final bool selected;
//   final VoidCallback onTap;

//   const LanguageOption({
//     Key? key,
//     required this.language,
//     required this.code,
//     required this.selected,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text(language),
//       leading: Radio<String>(
//         value: code,
//         groupValue: selected ? code : null,
//         onChanged: (String? value) => onTap(),
//       ),
//       onTap: onTap,
//     );
//   }
// }





// import 'package:flutter/material.dart';

// class LanguageScreen extends StatelessWidget {
//     const LanguageScreen({Key? key}) : super(key: key);

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold(
//             appBar: AppBar(
//                 title: const Text('Language'),
//             ),
//             body: const Center(
//                 child: Text('Select your language'),
//             ),
//         );
//     }
// }