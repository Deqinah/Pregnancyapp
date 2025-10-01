import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'signin_screen.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  _ForgotPassState createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 80,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.topToBottom,
                child: const SigninScreen(),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Icon(Icons.lock, size: 100, color: Colors.blue[900]),
              const SizedBox(height: 40),
              Text(
                "Forgot your password?",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter your email or your phone number,\nwe will send you a confirmation code.",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 241, 241, 241),
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  unselectedLabelColor: Colors.grey,
                  labelColor: Colors.blue[900],
                  tabs: const [Tab(text: "Email"), Tab(text: "Phone")],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: tabController,
                  children: [
                    Tab1(emailController: emailController),
                    Tab2(phoneController: phoneController),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class Tab1 extends StatelessWidget {
  final TextEditingController emailController;
  const Tab1({super.key, required this.emailController});

  void sendResetEmail(BuildContext context) async {
    final String email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           backgroundColor: Colors.green,
          content: Text("Password reset email sent to $email",style: TextStyle(color: Colors.white),)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => sendResetEmail(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text(
            "Send Email Code",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// class Tab1 extends StatelessWidget {
//   final TextEditingController emailController;
//   const Tab1({super.key, required this.emailController});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         TextFormField(
//           controller: emailController,
//           decoration: InputDecoration(
//             labelText: "Email",
//             prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
//           ),
//           keyboardType: TextInputType.emailAddress,
//         ),
//         const SizedBox(height: 20),
//         ElevatedButton(
//           onPressed: () {
//             // Handle send email
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue[900],
//             minimumSize: const Size.fromHeight(50),
//           ),
//           child: const Text(
//             "Send Email Code",
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//       ],
//     );
//   }
// }

class Tab2 extends StatelessWidget {
  final TextEditingController phoneController;
  const Tab2({super.key, required this.phoneController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: "Phone Number",
            prefixIcon: Icon(Icons.phone, color: Colors.blue[900]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Handle send phone code
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text(
            "Send SMS Code",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
