import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'change_board.dart';
import 'board1.dart';
import 'board2.dart';
import 'board3.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:page_transition/page_transition.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BoardingScreen extends StatefulWidget {
  const BoardingScreen({super.key});

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 2);
              });
            },
            children: const [
              Board1Screen(),
              Board2Screen(),
              Board3Screen(),
            ],
          ),
          Align(
            alignment: const Alignment(0.0, 0.75),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Skip Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.bottomToTop,
                        child: const ChangeboardScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Skip",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // Dots
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: SlideEffect(
                    spacing: 4.0,
                    radius: 4.0,
                    dotWidth: 14.0,
                    dotHeight: 7.0,
                    strokeWidth: 1.5,
                    dotColor: const Color.fromARGB(255, 170, 255, 237),
                    activeDotColor: Colors.blue[900]!,
                  ),
                ),

                // Next / Done Button
                GestureDetector(
                  onTap: () {
                    if (onLastPage) {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.bottomToTop,
                          child: const ChangeboardScreen(),
                        ),
                      );
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.05,
                    width: MediaQuery.of(context).size.width * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.blue[900],
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            onLastPage ? "Done" : "Next",
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            onLastPage ? Icons.check : Icons.arrow_forward,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

























// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../change_board.dart';
// import 'board1.dart';
// import 'board2.dart';
// import 'board3.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// class BoardingScreen extends StatefulWidget {
//   const BoardingScreen({super.key});

//   @override
//   State<BoardingScreen> createState() => _BoardingScreenState();
// }

// class _BoardingScreenState extends State<BoardingScreen> {
//   final PageController _controller = PageController();
//   bool onLastPage = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           PageView(
//             controller: _controller,
//             onPageChanged: (index) {
//               setState(() {
//                 onLastPage = (index == 2);
//               });
//             },
//             children: const [
//               Board1Screen(),
//               Board2Screen(),
//               Board3Screen(),
//             ],
//           ),
//           Align(
//             alignment: const Alignment(0.0, 0.75),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Skip Button
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       PageTransition(
//                         type: PageTransitionType.bottomToTop,
//                         child: const ChangeboardScreen(),
//                       ),
//                     );
//                   },
//                   child: Text(
//                     "Skip",
//                     style: GoogleFonts.inter(
//                       fontSize: 15,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ),

//                 // Dots
//                 SmoothPageIndicator(
//                   controller: _controller,
//                   count: 3,
//                   effect: const SlideEffect(
//                     spacing: 4.0,
//                     radius: 4.0,
//                     dotWidth: 14.0,
//                     dotHeight: 7.0,
//                     strokeWidth: 1.5,
//                     dotColor: Color.fromARGB(255, 170, 255, 255),
//                     activeDotColor: Color.fromARGB(255, 3, 190, 150),
//                   ),
//                 ),

//                 // Next / Done Button
//                 GestureDetector(
//                   onTap: () {
//                     if (onLastPage) {
//                       Navigator.push(
//                         context,
//                         PageTransition(
//                           type: PageTransitionType.bottomToTop,
//                           child: const ChangeboardScreen(),
//                         ),
//                       );
//                     } else {
//                       _controller.nextPage(
//                         duration: const Duration(milliseconds: 300),
//                         curve: Curves.easeIn,
//                       );
//                     }
//                   },
//                   child: Container(
//                     height: MediaQuery.of(context).size.height * 0.05,
//                     width: MediaQuery.of(context).size.width * 0.3,
//                     decoration: BoxDecoration(
//                       color: const Color.fromARGB(255, 3, 190, 150),
//                       borderRadius: BorderRadius.circular(35),
//                     ),
//                     child: Center(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             onLastPage ? "Done" : "Next",
//                             style: GoogleFonts.inter(
//                               fontSize: 16.sp,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                               letterSpacing: 1,
//                             ),
//                           ),
//                           SizedBox(width: 2.w),
//                           Icon(
//                             onLastPage ? Icons.check : Icons.arrow_forward,
//                             color: Colors.white,
//                             size: 18.sp,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }







































// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../change_board.dart';
// import 'board1.dart';
// import 'board2.dart';
// import 'board3.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// class BoardingScreen extends StatefulWidget {
//   const BoardingScreen({super.key});

//   @override
//   State<BoardingScreen> createState() => _BoardingScreenState();
// }

// class _BoardingScreenState extends State<BoardingScreen> {
//   PageController _controller = PageController();

//   bool onLastpage = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           PageView(
//             controller: _controller,
//             onPageChanged: (index) {
//               setState(() {
//                 onLastpage = (index == 2);
//               });
//             },
//             children: const [
//               Board1Screen(),
//               Board2Screen(),
//               Board3Screen(),
//             ],
//           ),
//           Align(
//             alignment: const Alignment(0.0, 0.75), // Sax saxan
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     _controller.jumpToPage(2);
//                   },
//                   GestureDetector(
//   onTap: () {
//     Navigator.push(
//       context,
//       PageTransition(
//         type: PageTransitionType.bottomToTop,
//         child: const ChangeboardScreen(),
//       ),
//     );
//   },
//   child: Text(
//     "Skip",
//     style: GoogleFonts.inter(
//       fontSize: 15,
//       color: Colors.grey,
//     ),
//   ),
// ),

//                 ),
//                 SmoothPageIndicator(
//                   controller: _controller,
//                   count: 3,
//                   effect: const SlideEffect(
//                     spacing: 4.0,
//                     radius: 4.0,
//                     dotWidth: 14.0,
//                     dotHeight: 7.0,
//                     strokeWidth: 1.5,
//                     dotColor: Color.fromARGB(255, 170, 255, 237),
//                     activeDotColor: Color.fromARGB(255, 3, 190, 150),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     if (onLastpage) {
//                       Navigator.push(
//                         context,
//                         PageTransition(
//                           type: PageTransitionType.bottomToTop,
//                           child: const ChangeboardScreen(),
//                         ),
//                       );
//                     } else {
//                       _controller.nextPage(
//                         duration: const Duration(milliseconds: 300),
//                         curve: Curves.easeIn,
//                       );
//                     }
//                   },
//                   child: Container(
//                     height: MediaQuery.of(context).size.height * 0.05,
//                     width: MediaQuery.of(context).size.width * 0.3,
//                     decoration: BoxDecoration(
//                       color: const Color.fromARGB(255, 3, 190, 150),
//                       borderRadius: BorderRadius.circular(35),
//                     ),
//                     child: Center(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             onLastpage ? "Done " : "Next ",
//                             style: GoogleFonts.inter(
//                               fontSize: 16.sp,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                               letterSpacing: 1,
//                             ),
//                           ),
//                           SizedBox(width: 2.w),
//                           Icon(
//                             onLastpage ? Icons.check : Icons.arrow_forward,
//                             color: Colors.white,
//                             size: 18.sp,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }



































// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../Login.dart';
// import '../Signup.dart';
// import 'on_board1.dart';
// import 'on_board2.dart';
// import 'on_board3.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// class on_boarding extends StatefulWidget {
//   const on_boarding({super.key});

//   @override
//   State<on_boarding> createState() => _on_boardingState();
// }

// class _on_boardingState extends State<on_boarding> {
//   PageController _controller = PageController();

//   bool onLastpage = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           PageView(
//               controller: _controller,
//               onPageChanged: (index) {
//                 setState(() {
//                   onLastpage = (index == 2);
//                 });
//               },
//               children: const [
//                 on_board1(),
//                 on_board2(),
//                 on_board3(),
//               ]),
//           Align(
//             alignment: Alignment(0.0, 0.75),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 GestureDetector(
//                     onTap: () {
//                       _controller.jumpToPage(2);
//                     },
//                     child: Text(
//                       "Skip",
//                       style: GoogleFonts.inter(fontSize: 15, color: Colors.grey),
//                     )),
//                 SmoothPageIndicator(
//                   controller: _controller,
//                   count: 3,
//                   effect: const SlideEffect(
//                     spacing: 4.0,
//                     radius: 4.0,
//                     dotWidth: 14.0,
//                     dotHeight: 7.0,
//                     strokeWidth: 1.5,
//                     dotColor: Color.fromARGB(255, 170, 255, 237),
//                     activeDotColor: Color.fromARGB(255, 3, 190, 150),
//                   ),
//                 ),
//                 onLastpage
//                     ? GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                               context,
//                               PageTransition(
//                                   type: PageTransitionType.bottomToTop,
//                                   child: const LoginScreen()));
//                         },
//                         child: Container(
//                           height: MediaQuery.of(context).size.height * 0.05,
//                           width: MediaQuery.of(context).size.width * 0.3,
//                           decoration: BoxDecoration(
//                               color: const Color.fromARGB(255, 3, 190, 150),
//                               borderRadius: BorderRadius.circular(35)),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   "Done ",
//                                   style: GoogleFonts.inter(
//                                       fontSize: 16.sp,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                       letterSpacing: 1),
//                                 ),
//                                 SizedBox(width: 4.w),
//                                 Icon(Icons.check, color: Colors.white, size: 18.sp),
//                               ],
//                             ),
//                           ),
//                         ))
//                     : GestureDetector(
//                         onTap: () {
//                           _controller.nextPage(
//                               duration: const Duration(milliseconds: 300),
//                               curve: Curves.easeIn);
//                         },
//                         child: Container(
//                           height: MediaQuery.of(context).size.height * 0.05,
//                           width: MediaQuery.of(context).size.width * 0.3,
//                           decoration: BoxDecoration(
//                               color: const Color.fromARGB(255, 3, 190, 150),
//                               borderRadius: BorderRadius.circular(35)),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   "Next ",
//                                   style: GoogleFonts.inter(
//                                       fontSize: 16.sp,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                       letterSpacing: 1),
//                                 ),
//                                 SizedBox(width: 4.w),
//                                 Icon(Icons.arrow_forward, color: Colors.white, size: 18.sp),
//                               ],
//                             ),
//                           ),
//                         )),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }










































// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../Login.dart';
// import '../Signup.dart';
// import 'on_board1.dart';
// import 'on_board2.dart';
// import 'on_board3.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// class on_boarding extends StatefulWidget {
//   const on_boarding({super.key});

//   @override
//   State<on_boarding> createState() => _on_boardingState();
// }

// class _on_boardingState extends State<on_boarding> {
//   PageController _controller = PageController();

//   bool onLastpage = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: Stack(
//       children: [
//         PageView(
//             controller: _controller,
//             onPageChanged: (index) {
//               setState(() {
//                 onLastpage = (index == 2);
//               });
//             },
//             children: [
//               on_board1(),
//               on_board2(),
//               on_board3(),
//             ]),
//         Container(
//           alignment: Alignment(-0.6, 0.75),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               GestureDetector(
//                   onTap: () {
//                     _controller.jumpToPage(2);
//                   },
//                   child: Text(
//                     "Skip",
//                     style: GoogleFonts.inter(fontSize: 15, color: Colors.grey),
//                   )),
//               SmoothPageIndicator(
//                 controller: _controller,
//                 count: 3,
//                 effect: SlideEffect(
//                     spacing: 4.0,
//                     radius: 4.0,
//                     dotWidth: 14.0,
//                     dotHeight: 7.0,
//                     strokeWidth: 1.5,
//                     dotColor: Color.fromARGB(255, 170, 255, 237),
//                     activeDotColor: const Color.fromARGB(255, 3, 190, 150)),
//               ),
//               onLastpage
//                   ? GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                             context,
//                             PageTransition(
//                                 type: PageTransitionType.bottomToTop,
//                                 child: LoginScreen()));
//                       },
//                       child: Container(
//                         height: MediaQuery.of(context).size.height * 0.05,
//                         width: MediaQuery.of(context).size.width * 0.3,
//                         decoration: BoxDecoration(
//                             color: const Color.fromARGB(255, 3, 190, 150),
//                             borderRadius: BorderRadius.circular(35)),
//                         child: Center(
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 "Done ",
//                                 style: GoogleFonts.inter(
//                                     fontSize: 16.sp,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                     letterSpacing: 1),
//                               ),
//                               Container(
//                                 height:
//                                     MediaQuery.of(context).size.height * 0.04,
//                                 width: MediaQuery.of(context).size.width * 0.04,
//                                 //child: Image.asset("lib/icons/check.png"),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ))
//                   : GestureDetector(
//                       onTap: () {
//                         _controller.nextPage(
//                             duration: Duration(milliseconds: 300),
//                             curve: Curves.easeIn);
//                       },
//                       child: Container(
//                         height: MediaQuery.of(context).size.height * 0.05,
//                         width: MediaQuery.of(context).size.width * 0.3,
//                         decoration: BoxDecoration(
//                             color: const Color.fromARGB(255, 3, 190, 150),
//                             borderRadius: BorderRadius.circular(35)),
//                         child: Center(
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 "Next ",
//                                 style: GoogleFonts.inter(
//                                     fontSize: 16.sp,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                     letterSpacing: 1),
//                               ),
//                               Container(
//                                 height:
//                                     MediaQuery.of(context).size.height * 0.06,
//                                 width: MediaQuery.of(context).size.width * 0.06,
//                                // child: Image.asset("lib/icons/arrow.png"),
//                               ),
//                             ],
//                           ),
//                         ),
//                       )),
//             ],
//           ),
//         )
//       ],
//     ));
//   }
// }
