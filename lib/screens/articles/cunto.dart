// import 'package:flutter/material.dart';
// class ArticleScreen extends StatelessWidget {
//   final List<Map<String, String>> articles = [

// const weekFood = {
//   'id': 'week1_foods',
//   'title': 'Cuntada Uurka Toddobaadka 1aad',
//   'image': 'https://example.com/week1_foods.jpg',
//   'content': '''**Cuntada lagu taliyo toddobaadka 1aad ee uurka:**

// 1. **Khudaar cagaaran** (salad, spinach)
//    - Tayo Folic Acid aad u sarreeya
//    - Ka caawiya samaynta dhiig cas

// 2. **Canjeero**
//    - Bixin karta tamar nafaqeed
//    - Fudud oo la cuni karo

// 3. **Miris**
//    - Buun celin leh
//    - Ka caawiya xanuunka caloosha

// 4. **Hilibka doofaar** (hadii aad cuntid)
//    - Protein iyo iron badan

// 5. **Caano**
//    - Calcium lagama maarmaanka u ah

// **Loo maleynayo inaad ka fogaato:**
// - Cuntada la shiiday
// - Cabitaanada kafeynka badan
// - Saliida badan'''
// },
// //week2 food
//     {
//       'id': 'week2_foods',
//       'title': 'Cuntada Uurka Toddobaadka 2aad',
//       'description': 'Cuntooyin nafaqo leh ee toddobaadka 2aad',
//       'image': 'https://example.com/week2_foods.jpg',
//       'content': '''*Cuntooyinka lagu taliyo toddobaadka 2aad ee uurka:*

// 1. *Khudaar (broccoli, digir cagaaran)*
//    - Nafaqo badan, gaar ahaan folic acid iyo fiber

// 2. *Beed*
//    - Biyo badan iyo protein muhiim ah

// 3. *Qamadi dhan (whole grains)*
//    - Ka caawiya dheefshiidka iyo tamar joogto ah

// 4. *Kalluunka saliidda leh* (tusaale: salmon)
//    - Omega-3 oo muhiim u ah koritaanka maskaxda

// *Loo maleynayo inaad ka fogaato:*
// - Cunto aan si fiican loo karin
// - Hilibka aan bislaanin
// - Cuntooyin kafeyn badan'''
//     },

// };

// class Cunto extends StatelessWidget {
//   const Cunto({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(weekFood['title']!),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Image.network(
//               weekFood['image']!,
//               width: double.infinity,
//               height: 220,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) => 
//               Container(height: 220, color: Colors.grey),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 weekFood['content']!,
//                 style: TextStyle(fontSize: 16, height: 1.5),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

