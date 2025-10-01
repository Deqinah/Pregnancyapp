import 'package:flutter/material.dart';
import 'screens/register/splash_screen.dart';
import 'screens/register/Board/boarding.dart';
import 'screens/home/home_screen.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const PregnancyApp());
}


class PregnancyApp extends StatefulWidget {
  const PregnancyApp({super.key});

  @override
  State<PregnancyApp> createState() => _PregnancyAppState();

  static _PregnancyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_PregnancyAppState>();
}

class _PregnancyAppState extends State<PregnancyApp> {
  bool _isDarkMode = false;
  

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }
   
  

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'Pregnancy App',
          debugShowCheckedModeBanner: false,
         
          theme: _isDarkMode
              ? ThemeData.dark()
              : ThemeData.light().copyWith(
                  primaryColor: Colors.blue[900],
                  useMaterial3: true,
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                  ),
                  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                    selectedItemColor: Colors.pink,
                    unselectedItemColor: Colors.grey,
                  ),
                ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/boarding': (context) => const BoardingScreen(),
            '/home': (context) => HomeScreen(
              isDarkMode: _isDarkMode,
              onToggleTheme: _toggleTheme,
            ),
          },
        );
      },
    );
  }
}

















// import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'screens/register/splash_screen.dart';
// import 'screens/register/boarding_screen.dart';
// import 'screens/home/home_screen.dart';
// import 'providers/app_provider.dart';
// import 'package:provider/provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
    
//     final prefs = await SharedPreferences.getInstance();
//     final languageCode = prefs.getString('languageCode') ?? 'en';
//     final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    
//     runApp(
//       MultiProvider(
//         providers: [
//           ChangeNotifierProvider(
//             create: (_) => AppProvider(
//               languageCode: languageCode,
//               isDarkMode: isDarkMode,
//             ),
//           ),
//         ],
//         child: const PregnancyApp(),
//       ),
//     );
//   } catch (e) {
//     runApp(const ErrorApp());
//   }
// }

// class PregnancyApp extends StatelessWidget {
//   const PregnancyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final appProvider = Provider.of<AppProvider>(context);
    
//     return ResponsiveSizer(
//       builder: (context, orientation, screenType) {
//         return MaterialApp(
//           title: 'Pregnancy App',
//           debugShowCheckedModeBanner: false,
//           locale: Locale(appProvider.languageCode),
//           localizationsDelegates: const [
//             AppLocalizations.delegate,
//             GlobalMaterialLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//           ],
//           supportedLocales: const [
//             Locale('en'), // English
//             Locale('so'), // Somali
//             Locale('ar'), // Arabic
//           ],
//           theme: appProvider.isDarkMode
//               ? _buildDarkTheme()
//               : _buildLightTheme(),
//           initialRoute: '/',
//           routes: {
//             '/': (context) => const SplashScreen(),
//             '/boarding': (context) => const BoardingScreen(),
//             '/home': (context) => const HomeScreen(),
//           },
//         );
//       },
//     );
//   }

//   ThemeData _buildLightTheme() {
//     return ThemeData.light().copyWith(
//       primaryColor: Colors.blue[900],
//       colorScheme: ColorScheme.fromSwatch().copyWith(
//         secondary: Colors.pink,
//       ),
//       appBarTheme: AppBarTheme(
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//       ),
//       bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//         selectedItemColor: Colors.pink,
//         unselectedItemColor: Colors.grey,
//       ),
//     );
//   }

//   ThemeData _buildDarkTheme() {
//     return ThemeData.dark().copyWith(
//       colorScheme: ColorScheme.dark().copyWith(
//         secondary: Colors.pinkAccent,
//       ),
//       bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//         selectedItemColor: Colors.pinkAccent,
//       ),
//     );
//   }
// }

// class ErrorApp extends StatelessWidget {
//   const ErrorApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               Icon(Icons.error_outline, size: 64, color: Colors.red),
//               SizedBox(height: 20),
//               Text('Failed to initialize app', style: TextStyle(fontSize: 18)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'screens/register/splash_screen.dart';
// import 'screens/register/Board/boarding.dart';
// import 'screens/home/home_screen.dart';


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
  
//   // Load saved language preference
//   final prefs = await SharedPreferences.getInstance();
//   final languageCode = prefs.getString('languageCode') ?? 'en';
  
//   runApp(PregnancyApp(languageCode: languageCode));
// }

// class PregnancyApp extends StatefulWidget {
//   final String languageCode;
  
//   const PregnancyApp({super.key, required this.languageCode});

//   @override
//   State<PregnancyApp> createState() => _PregnancyAppState();
// }

// class _PregnancyAppState extends State<PregnancyApp> {
//   bool _isDarkMode = false;
//   late String _currentLanguage;

//   @override
//   void initState() {
//     super.initState();
//     _currentLanguage = widget.languageCode;
//   }

//   void _toggleTheme() {
//     setState(() {
//       _isDarkMode = !_isDarkMode;
//     });
//   }

//   void _changeLanguage(String languageCode) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('languageCode', languageCode);
//     setState(() {
//       _currentLanguage = languageCode;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ResponsiveSizer(
//       builder: (context, orientation, screenType) {
//         return MaterialApp(
//           title: 'Pregnancy App',
//           debugShowCheckedModeBanner: false,
//           locale: Locale(_currentLanguage),
//           localizationsDelegates: const [
//             AppLocalizations.delegate,
//             GlobalMaterialLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//           ],
//           supportedLocales: const [
//             Locale('en'), // English
//             Locale('so'), // Somali
//             Locale('ar'), // Arabic
//           ],
//           theme: _isDarkMode
//               ? ThemeData.dark()
//               : ThemeData.light().copyWith(
//                   primaryColor: Colors.blue[900],
//                   useMaterial3: true,
//                   appBarTheme: AppBarTheme(
//                     backgroundColor: Colors.blue[900],
//                     foregroundColor: Colors.white,
//                   ),
//                   bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//                     selectedItemColor: Colors.pink,
//                     unselectedItemColor: Colors.grey,
//                   ),
//                 ),
//           initialRoute: '/',
//           routes: {
//             '/': (context) => const SplashScreen(),
//             '/boarding': (context) => const BoardingScreen(),
//             '/home': (context) => HomeScreen(
//                   isDarkMode: _isDarkMode,
//                   onToggleTheme: _toggleTheme,
//                   onChangeLanguage: _changeLanguage,
//                   currentLanguage: _currentLanguage,
//                 ),
           
//           },
//         );
//       },
//     );
//   }
// }








// import 'package:flutter/material.dart';
// import 'screens/register/splash_screen.dart';
// import 'screens/register/Board/boarding.dart';
// import 'screens/home/home_screen.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
// );
//   runApp(const PregnancyApp());
// }

// class PregnancyApp extends StatefulWidget {
//   const PregnancyApp({super.key});

//   @override
//   State<PregnancyApp> createState() => _PregnancyAppState();
// }

// class _PregnancyAppState extends State<PregnancyApp> {
//   bool _isDarkMode = false;

//   void _toggleTheme() {
//     setState(() {
//       _isDarkMode = !_isDarkMode;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ResponsiveSizer(
//       builder: (context, orientation, screenType) {
//         return MaterialApp(
//           title: 'Pregnancy App',
//           debugShowCheckedModeBanner: false,
//           theme: _isDarkMode
//               ? ThemeData.dark()
//               : ThemeData.light().copyWith(
//                   primaryColor: Colors.blue[900],
//                   useMaterial3: true,
//                   appBarTheme: AppBarTheme(
//                     backgroundColor: Colors.blue[900],
//                     foregroundColor: Colors.white,
//                   ),
//                   bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//                     selectedItemColor: Colors.pink,
//                     unselectedItemColor: Colors.grey,
//                   ),
//                 ),
//           initialRoute: '/',
//           routes: {
//             '/': (context) => const SplashScreen(),
//             '/boarding': (context) => const BoardingScreen(),
//             '/home': (context) => HomeScreen(
//               isDarkMode: _isDarkMode,
//               onToggleTheme: _toggleTheme,
//             ),
//           },
//         );
//       },
//     );
//   }
// }





















// import 'package:flutter/material.dart';
// import 'screens/register/splash_screen.dart';
// import 'screens/register/Board/boarding.dart';
// import 'screens/home/home_screen.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';


// void main() {
//   runApp(const PregnancyApp());
// }

// class PregnancyApp extends StatefulWidget {
//   const PregnancyApp({super.key});

//   @override
//   State<PregnancyApp> createState() => _PregnancyAppState();
// }

// class _PregnancyAppState extends State<PregnancyApp> {
//   bool _isDarkMode = false;

//   void _toggleTheme() {
//     setState(() {
//       _isDarkMode = !_isDarkMode;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Pregnancy App',
//       debugShowCheckedModeBanner: false,
//       theme: _isDarkMode
//           ? ThemeData.dark()
//           : ThemeData.light().copyWith(
//               primaryColor: Colors.blue[900],
//               useMaterial3: true,
//               appBarTheme: AppBarTheme(
//                 backgroundColor: Colors.blue[900],
//                 foregroundColor: Colors.white,
//               ),
//               bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//                 selectedItemColor: Colors.pink,
//                 unselectedItemColor: Colors.grey,
//               ),
//             ),
//      initialRoute: '/',
//       routes: {
//         '/': (context) => const SplashScreen(),
//         '/boarding': (context) => const BoardingScreen(),
//         '/home': (context) => HomeScreen(
//           isDarkMode: _isDarkMode,
//           onToggleTheme: _toggleTheme,
//         ),

//       },
//     );
//   }
// }

//  @override
// Widget build(BuildContext context) {
//   return ResponsiveSizer(
//     builder: (context, orientation, screenType) {
//       return MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Pregnancy App',
//         theme: ThemeData(
//           primarySwatch: Colors.pink,
//           scaffoldBackgroundColor: Colors.white,
//           visualDensity: VisualDensity.adaptivePlatformDensity,
//         ),
//       );
//     },
//   );
// }

















// import 'package:flutter/material.dart';
// import '..register/splash_screen.dart';

// void main() {
//   runApp(const PregnancyApp());
// }

// class PregnancyApp extends StatefulWidget {
//   const PregnancyApp({super.key});

//   @override
//   State<PregnancyApp> createState() => _PregnancyAppState();
// }

// class _PregnancyAppState extends State<PregnancyApp> {
//   bool _isDarkMode = false;

//   void _toggleTheme() {
//     setState(() {
//       _isDarkMode = !_isDarkMode;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Pregnancy App',
//       debugShowCheckedModeBanner: false,
//       home:const SplashScreen(),
//       theme: _isDarkMode
//           ? ThemeData.dark()
//           : ThemeData.light().copyWith(
//               primaryColor: Colors.blue[900],
//               useMaterial3: true,
//               appBarTheme: AppBarTheme(
//                 backgroundColor: Colors.blue[900],
//                 foregroundColor: Colors.white,
//               ),
//               bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//                 selectedItemColor: Colors.pink,
//                 unselectedItemColor: Colors.grey,
//               ),
//             ),
//       // initialRoute: '/',
//       // routes: {
//       //   '/': (context) => SplashScreen(),
//       // },
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'screens/splash_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/signup_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
  
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Pregnancy Women',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const SplashScreen(),
//         '/login': (context) => const LoginScreen(),
//         '/signup': (context) => const SignupScreen(),
//       },
//     );
//   }
// }







// import 'package:flutter/material.dart';
// import 'screens/home/home_screen.dart';

// void main() {
//   runApp(PregnancyApp());
// }

// class PregnancyApp extends StatefulWidget {
//   @override
//   _PregnancyAppState createState() => _PregnancyAppState();
// }

// class _PregnancyAppState extends State<PregnancyApp> {
//   bool _isDarkMode = false;

//   void _toggleTheme() {
//     setState(() {
//       _isDarkMode = !_isDarkMode;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Pregnancy App',
//       debugShowCheckedModeBanner: false,
//       theme: _isDarkMode ? ThemeData.dark() : ThemeData.light().copyWith(
//         primaryColor: Colors.blue[900],
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.blue[900],
//           foregroundColor: Colors.white,
//         ),
//         bottomNavigationBarTheme: BottomNavigationBarThemeData(
//           selectedItemColor: Colors.pink,
//           unselectedItemColor: Colors.grey,
//         ),
//       ),
//       home: HomeScreen(
//         isDarkMode: _isDarkMode,
//         onToggleTheme: _toggleTheme,
//       ),
//     );
//   }
// }
