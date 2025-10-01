import 'package:flutter/material.dart';

class HealthyMealScreen extends StatelessWidget {
  const HealthyMealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMealCard(
              title: 'Quraac (07:00 - 08:00 subaxnimo)',
              items: [
                'Caano diirran ama casiir oranji (Vitamin C)',
                'Rooti/Doolsho + avocado ama subag lawska',
                'Ukun la kariyey ama la shiilay (borotiin)',
                'Midho: tufaax, moos, ama babaay',
              ],
              icon: Icons.breakfast_dining,
              color: Colors.orange,
              imagePath: 'assets/images/f1.png',
            ),
            const SizedBox(height: 20),
            _buildMealCard(
              title: 'cunto fudud (10:00 - 10:30 subaxnimo)',
              items: [
                'Caano fadhi (yogurt) + lows ama lawska badda',
                'Midho cusub sida canab ama cambe',
              ],
              icon: Icons.local_cafe,
              color: Colors.green,
              imagePath: 'assets/images/f2.png',
            ),
            const SizedBox(height: 20),
            _buildMealCard(
              title: 'Qado (01:00 - 02:00 duhurnimo)',
              items: [
                'Bariis ama baasto + hilib digaag, geel, ama kalluun',
                'Khudaar la kariyey: karootada, digirta cagaaran, yaanyo',
                'Salad: khudaar cagaaran, basal, iyo tufaax yar',
                'Casiir dabiici ah (orange, babaay, ama cambe)',
              ],
              icon: Icons.lunch_dining,
              color: Colors.blue,
              imagePath: 'assets/images/f3.png',
            ),
            const SizedBox(height: 20),
            _buildMealCard(
              title: 'Casriyo (04:00 - 04:30 galabnimo)',
              items: [
                'Qamadi la shiiday (oats) oo caano lagu daray',
                'Moos ama tufaax + lowska',
              ],
              icon: Icons.cake,
              color: Colors.purple,
              imagePath: 'assets/images/f4.png',
            ),
            const SizedBox(height: 20),
            _buildMealCard(
              title: 'Casho (07:00 - 08:00 fiidnimo)',
              items: [
                'Muufo ama malawax + caano',
                'Ukun, kalluun, ama digaag',
                'Khudaar cagaar ah (broccoli, spinach, digir)',
              ],
              icon: Icons.dinner_dining,
              color: Colors.red,
              imagePath: 'assets/images/f5.png',
            ),
            const SizedBox(height: 30),
            _buildNutritionTipsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
    required String imagePath,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Sawir lama helin',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTipsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tilmaamaha Muhiimka ah:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            _buildTipItem('🚫 Ka fogow shaah, kafe, iyo cabitaanada aan loo baahnayn'),
            _buildTipItem('💧 Cab biyo badan (8-10 koob maalin kasta)'),
            _buildTipItem('🏃‍♀️ Samee jimicsi khafiif ah maalin kasta'),
            const SizedBox(height: 16),
            const Text(
              'Faa iidooyinka Trimester-ka:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            _buildTipItem('Bisha 1-3: Aad ugu fiirso calcium (caano) iyo folic acid (khudaar cagaaran)'),
            _buildTipItem('Bisha 4-6: Kordho borotiin (hilib) iyo bir (cereals)'),
            _buildTipItem('Bisha 7-9: Ku sii kordhi nafaqada (calories) si aad u qabsato tamar'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}














// import 'package:flutter/material.dart';

// class HealthyMealScreen extends StatelessWidget {
//   const HealthyMealScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Qorshe Cunto Hooyo Uurka Leh'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildMealCard(
//               title: 'Quraac (07:00 - 08:00 subaxnimo)',
//               items: [
//                 'Caano diirran ama casiir oranji (Vitamin C)',
//                 'Rooti/Doolsho + avocado ama subag lawska',
//                 'Ukun la kariyey ama la shiilay (borotiin)',
//                 'Midho: tufaax, moos, ama babaay',
//               ],
//               icon: Icons.breakfast_dining,
//               color: Colors.orange,
//               imagePath: 'assets/images/f1.png', // PNG or JPG, labadaba waa OK
//             ),
//             const SizedBox(height: 20),
//             _buildMealCard(
//               title: 'Nasasho 1 (10:00 - 10:30 subaxnimo)',
//               items: [
//                 'Caano fadhi (yogurt) + lows ama lawska badda',
//                 'Midho cusub sida canab ama cambe',
//               ],
//               icon: Icons.local_cafe,
//               color: Colors.green,
//               imagePath: 'assets/images/f2.jpg', // Waxaad beddeli kartaa JPG ama PNG
//             ),
//             const SizedBox(height: 20),
//             _buildMealCard(
//               title: 'Qado (01:00 - 02:00 duhurnimo)',
//               items: [
//                 'Bariis ama baasto + hilib digaag, geel, ama kalluun',
//                 'Khudaar la kariyey: karootada, digirta cagaaran, yaanyo',
//                 'Salad: khudaar cagaaran, basal, iyo tufaax yar',
//                 'Casiir dabiici ah (orange, babaay, ama cambe)',
//               ],
//               icon: Icons.lunch_dining,
//               color: Colors.blue,
//               imagePath: 'assets/images/lunch.png',
//             ),
//             const SizedBox(height: 20),
//             _buildMealCard(
//               title: 'Nasasho 2 (04:00 - 04:30 galabnimo)',
//               items: [
//                 'Qamadi la shiiday (oats) oo caano lagu daray',
//                 'Moos ama tufaax + lowska',
//               ],
//               icon: Icons.cake,
//               color: Colors.purple,
//               imagePath: 'assets/images/afternoon_snack.jpg',
//             ),
//             const SizedBox(height: 20),
//             _buildMealCard(
//               title: 'Casho (07:00 - 08:00 fiidnimo)',
//               items: [
//                 'Muufo ama malawax + caano',
//                 'Ukun, kalluun, ama digaag',
//                 'Khudaar cagaar ah (broccoli, spinach, digir)',
//               ],
//               icon: Icons.dinner_dining,
//               color: Colors.red,
//               imagePath: 'assets/images/dinner.png',
//             ),
//             const SizedBox(height: 30),
//             _buildNutritionTipsCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMealCard({
//     required String title,
//     required List<String> items,
//     required IconData icon,
//     required Color color,
//     required String imagePath,
//   }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color, size: 30),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 15),
//             ...items.map((item) => Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('•', style: TextStyle(fontSize: 18)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       item,
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             )),
//             const SizedBox(height: 20),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Image.asset(
//                 imagePath,
//                 width: double.infinity,
//                 height: 900,
//                 fit: BoxFit.contain,
//   // Bedelkan: BoxFit.cover = sawirka buuxa oo la jaray si u buuxiyo card
//                 // Haddii aad rabto sawir dhan oo aan la jarin isticmaal BoxFit.contain halkii cover
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 900,
//                   color: Colors.grey[200],
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.image_not_supported,
//                             size: 40,
//                             color: Colors.grey),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Sawir lama helin',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNutritionTipsCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       color: Colors.blue[50],
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Tilmaamaha Muhiimka ah:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildTipItem('🚫 Ka fogow shaah, kafe, iyo cabitaanada aan loo baahnayn'),
//             _buildTipItem('💧 Cab biyo badan (8-10 koob maalin kasta)'),
//             _buildTipItem('🏃‍♀️ Samee jimicsi khafiif ah maalin kasta'),
//             const SizedBox(height: 16),
//             const Text(
//               'Faa iidooyinka Trimester-ka:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildTipItem('Bisha 1-3: Aad ugu fiirso calcium (caano) iyo folic acid (khudaar cagaaran)'),
//             _buildTipItem('Bisha 4-6: Kordho borotiin (hilib) iyo bir (cereals)'),
//             _buildTipItem('Bisha 7-9: Ku sii kordhi nafaqada (calories) si aad u qabsato tamar'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








// import 'package:flutter/material.dart';

// class HealthyMealScreen extends StatelessWidget {
//   const HealthyMealScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Qorshe Cunto Hooyo Uurka Leh'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildMealCard(
//               title: 'Quraac (07:00 - 08:00 subaxnimo)',
//               items: [
//                 'Caano diirran ama casiir oranji (Vitamin C)',
//                 'Rooti/Doolsho + avocado ama subag lawska',
//                 'Ukun la kariyey ama la shiilay (borotiin)',
//                 'Midho: tufaax, moos, ama babaay',
//               ],
//               icon: Icons.breakfast_dining,
//               color: Colors.orange,
//               imagePath: 'assets/images/f1.png',
//             ),
//             const SizedBox(height: 20),
//             _buildMealCard(
//               title: 'Nasasho 1 (10:00 - 10:30 subaxnimo)',
//               items: [
//                 'Caano fadhi (yogurt) + lows ama lawska badda',
//                 'Midho cusub sida canab ama cambe',
//               ],
//               icon: Icons.local_cafe,
//               color: Colors.green,
//               imagePath: 'assets/images/f2.png',
//             ),
//             const SizedBox(height: 20),
//             _buildMealCard(
//               title: 'Qado (01:00 - 02:00 duhurnimo)',
//               items: [
//                 'Bariis ama baasto + hilib digaag, geel, ama kalluun',
//                 'Khudaar la kariyey: karootada, digirta cagaaran, yaanyo',
//                 'Salad: khudaar cagaaran, basal, iyo tufaax yar',
//                 'Casiir dabiici ah (orange, babaay, ama cambe)',
//               ],
//               icon: Icons.lunch_dining,
//               color: Colors.blue,
//               imagePath: 'assets/images/lunch.png',
//             ),
//             const SizedBox(height: 20),
//             _buildMealCard(
//               title: 'Nasasho 2 (04:00 - 04:30 galabnimo)',
//               items: [
//                 'Qamadi la shiiday (oats) oo caano lagu daray',
//                 'Moos ama tufaax + lowska',
//               ],
//               icon: Icons.cake,
//               color: Colors.purple,
//               imagePath: 'assets/images/afternoon_snack.png',
//             ),
//             const SizedBox(height: 20),
//             _buildMealCard(
//               title: 'Casho (07:00 - 08:00 fiidnimo)',
//               items: [
//                 'Muufo ama malawax + caano',
//                 'Ukun, kalluun, ama digaag',
//                 'Khudaar cagaar ah (broccoli, spinach, digir)',
//               ],
//               icon: Icons.dinner_dining,
//               color: Colors.red,
//               imagePath: 'assets/images/dinner.png',
//             ),
//             const SizedBox(height: 30),
//             _buildNutritionTipsCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMealCard({
//     required String title,
//     required List<String> items,
//     required IconData icon,
//     required Color color,
//     required String imagePath,
//   }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color, size: 30),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 15),
//             ...items.map((item) => Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('•', style: TextStyle(fontSize: 18)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       item,
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             )),
//             const SizedBox(height: 20),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Image.asset(
//                 imagePath,
//                 width: double.infinity,
//                 height: 180,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 180,
//                   color: Colors.grey[200],
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.image_not_supported, 
//                                 size: 40, 
//                                 color: Colors.grey),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Sawir lama helin',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNutritionTipsCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       color: Colors.blue[50],
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Tilmaamaha Muhiimka ah:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildTipItem('🚫 Ka fogow shaah, kafe, iyo cabitaanada aan loo baahnayn'),
//             _buildTipItem('💧 Cab biyo badan (8-10 koob maalin kasta)'),
//             _buildTipItem('🏃‍♀️ Samee jimicsi khafiif ah maalin kasta'),
//             const SizedBox(height: 16),
//             const Text(
//               'Faa iidooyinka Trimester-ka:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildTipItem('Bisha 1-3: Aad ugu fiirso calcium (caano) iyo folic acid (khudaar cagaaran)'),
//             _buildTipItem('Bisha 4-6: Kordho borotiin (hilib) iyo bir (cereals)'),
//             _buildTipItem('Bisha 7-9: Ku sii kordhi nafaqada (calories) si aad u qabsato tamar'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








// import 'package:flutter/material.dart';


// class HealthyMealScreen extends StatelessWidget {
//   const HealthyMealScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Qorshe Cunto Hooyo Uurka Leh'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildMealTimeCard(
//               context,
//               'Quraac (07:00 - 08:00 subaxnimo)',
//               [
//                 'Caano diirran ama casiir oranji (Vitamin C)',
//                 'Rooti/Doolsho + avocado ama subag lawska',
//                 'Ukun la kariyey ama la shiilay (borotiin)',
//                 'Midho: tufaax, moos, ama babaay',
//               ],
//               const SizedBox(height: 30),
//               Icons.breakfast_dining,
//               Colors.orange,
//               'assets/images/f1.png', // or .png
//             ),
//             const SizedBox(height: 16),
//             _buildMealTimeCard(
//               context,
//               'Nasasho 1 (10:00 - 10:30 subaxnimo)',
//               [
//                 'Caano fadhi (yogurt) + lows ama lawska badda',
//                 'Midho cusub sida canab ama cambe',
//               ],
//               Icons.local_cafe,
//               Colors.green,
//               'assets/images/f2.png', // or .jpg
//             ),
//             const SizedBox(height: 16),
//             _buildMealTimeCard(
//               context,
//               'Qado (01:00 - 02:00 duhurnimo)',
//               [
//                 'Bariis ama baasto + hilib digaag, geel, ama kalluun (borotiin + bir)',
//                 'Khudaar la kariyey: karootada, digirta cagaaran, yaanyo',
//                 'Salad: khudaar cagaaran, basal, iyo tufaax yar',
//                 'Casiir dabiici ah (orange, babaay, ama cambe)',
//               ],
//               Icons.lunch_dining,
//               Colors.blue,
//               'assets/images/qado.jpg', // or .png
//             ),
//             const SizedBox(height: 16),
//             _buildMealTimeCard(
//               context,
//               'Nasasho 2 (04:00 - 04:30 galabnimo)',
//               [
//                 'Qamadi la shiiday (oats) oo caano lagu daray',
//                 'Moos ama tufaax + lowska',
//               ],
//               Icons.cake,
//               Colors.purple,
//               'assets/images/nasasho2.png', // or .jpg
//             ),
//             const SizedBox(height: 16),
//             _buildMealTimeCard(
//               context,
//               'Casho (07:00 - 08:00 fiidnimo)',
//               [
//                 'Muufo ama malawax + caano',
//                 'Ukun, kalluun, ama digaag',
//                 'Khudaar cagaar ah (broccoli, spinach, digir)',
//               ],
//               Icons.dinner_dining,
//               Colors.red,
//               'assets/images/casho.jpg', // or .png
//             ),
//             const SizedBox(height: 24),
//             _buildNutritionTipsCard(context),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMealTimeCard(BuildContext context, String title, List<String> items, 
//                            IconData icon, Color color, String imagePath) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color, size: 28),
//                 const SizedBox(width: 12),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             ...items.map((item) => Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('•', style: TextStyle(fontSize: 16)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       item,
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             )).toList(),
//             const SizedBox(height: 16),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Image.asset(
//                 imagePath,
//                 width: double.infinity,
//                 height: 150,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 150,
//                   color: Colors.grey[200],
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
//                         Text(
//                           'Sawir lama helin',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNutritionTipsCard(BuildContext context) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       color: Colors.blue[50],
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Tilmaamaha Muhiimka ah:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildTipItem('🚫 Ka fogow shaah, kafe, iyo cabitaanada aan loo baahnayn'),
//             _buildTipItem('💧 Cab biyo badan (8-10 koob maalin kasta)'),
//             _buildTipItem('🏃‍♀️ Samee jimicsi khafiif ah maalin kasta'),
//             const SizedBox(height: 12),
//             const Text(
//               'Faa iidooyinka Trimester-ka:',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 8),
//             _buildTipItem('Bisha 1-3: Aad ugu fiirso calcium (caano) iyo folic acid (khudaar cagaaran)'),
//             _buildTipItem('Bisha 4-6: Kordho borotiin (hilib) iyo bir (cereals)'),
//             _buildTipItem('Bisha 7-9: Ku sii kordhi nafaqada (calories) si aad u qabsato tamar'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }












// import 'package:flutter/material.dart';

// class HealthyMealScreen extends StatelessWidget {
//   const HealthyMealScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Qorshe Cunto Hooyo Uurka Leh'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildMealTimeCard(
//               context,
//               'Quraac (07:00 - 08:00 subaxnimo)',
//               [
//                 'Caano diirran ama casiir oranji (Vitamin C)',
//                 'Rooti/Doolsho + avocado ama subag lawska',
//                 'Ukun la kariyey ama la shiilay (borotiin)',
//                 'Midho: tufaax, moos, ama babaay',
//               ],
//               Icons.breakfast_dining,
//               Colors.orange,
//               'assets/images/f1.png',
//             ),
//             const SizedBox(height: 16),
//             _buildMealTimeCard(
//               context,
//               'Nasasho 1 (10:00 - 10:30 subaxnimo)',
//               [
//                 'Caano fadhi (yogurt) + lows ama lawska badda',
//                 'Midho cusub sida canab ama cambe',
//               ],
//               Icons.local_cafe,
//               Colors.green,
//               'assets/images/f2.png',
//             ),
//             const SizedBox(height: 16),
//             _buildMealTimeCard(
//               context,
//               'Qado (01:00 - 02:00 duhurnimo)',
//               [
//                 'Bariis ama baasto + hilib digaag, geel, ama kalluun (borotiin + bir)',
//                 'Khudaar la kariyey: karootada, digirta cagaaran, yaanyo',
//                 'Salad: khudaar cagaaran, basal, iyo tufaax yar',
//                 'Casiir dabiici ah (orange, babaay, ama cambe)',
//               ],
//               Icons.lunch_dining,
//               Colors.blue,
//               'assets/images/lunch.jpg',
//             ),
//             const SizedBox(height: 16),
//             _buildMealTimeCard(
//               context,
//               'Nasasho 2 (04:00 - 04:30 galabnimo)',
//               [
//                 'Qamadi la shiiday (oats) oo caano lagu daray',
//                 'Moos ama tufaax + lowska',
//               ],
//               Icons.cake,
//               Colors.purple,
//               'assets/images/snack2.jpg',
//             ),
//             const SizedBox(height: 16),
//             _buildMealTimeCard(
//               context,
//               'Casho (07:00 - 08:00 fiidnimo)',
//               [
//                 'Muufo ama malawax + caano',
//                 'Ukun, kalluun, ama digaag',
//                 'Khudaar cagaar ah (broccoli, spinach, digir)',
//               ],
//               Icons.dinner_dining,
//               Colors.red,
//               'assets/images/dinner.jpg',
//             ),
//             const SizedBox(height: 24),
//             _buildNutritionTipsCard(context),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMealTimeCard(BuildContext context, String title, List<String> items, 
//                            IconData icon, Color color, String imagePath) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           ClipRRect(
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//             child: Image.asset(
//               imagePath,
//               width: double.infinity,
//               height: 150,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) => Container(
//                 height: 150,
//                 color: Colors.grey[200],
//                 child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(icon, color: color, size: 28),
//                     const SizedBox(width: 12),
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 ...items.map((item) => Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text('•', style: TextStyle(fontSize: 16)),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           item,
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )).toList(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNutritionTipsCard(BuildContext context) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       color: Colors.blue[50],
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Tilmaamaha Muhiimka ah:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildTipItem('🚫 Ka fogow shaah, kafe, iyo cabitaanada aan loo baahnayn'),
//             _buildTipItem('💧 Cab biyo badan (8-10 koob maalin kasta)'),
//             _buildTipItem('🏃‍♀️ Samee jimicsi khafiif ah maalin kasta'),
//             const SizedBox(height: 12),
//             const Text(
//               'Faa iidooyinka Trimester-ka:',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 8),
//             _buildTipItem('Bisha 1-3: Aad ugu fiirso calcium (caano) iyo folic acid (khudaar cagaaran)'),
//             _buildTipItem('Bisha 4-6: Kordho borotiin (hilib) iyo bir (cereals)'),
//             _buildTipItem('Bisha 7-9: Ku sii kordhi nafaqada (calories) si aad u qabsato tamar'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTipItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }










// import 'package:flutter/material.dart';

// class HealthyMealApp extends StatelessWidget {
//   const HealthyMealApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.blue,
//           primary: Colors.blue.shade700,
//           secondary: Colors.orange.shade400,
//         ),
//         useMaterial3: true,
//       ),
//       home: const MealPlanScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class MealPlanScreen extends StatelessWidget {
//   const MealPlanScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 350;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Food Healthy Meal Plan'),
//         centerTitle: true,
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           if (constraints.maxWidth > 600) {
//             // Tablet or landscape layout
//             return GridView.count(
//               padding: const EdgeInsets.all(16),
//               crossAxisCount: 2,
//               childAspectRatio: 1.5,
//               mainAxisSpacing: 16,
//               crossAxisSpacing: 16,
//               children: [
//                 _buildMealCard(
//                   context: context,
//                   title: 'Breakfast',
//                   recipe: 'Overnight Berry Oatmeal',
//                   prepTime: '5 min',
//                   cookTime: '5 min',
//                   imagePath: 'assets/images/f1.png',
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const OvernightOatmealScreen()),
//                   ),
//                 ),
//                 _buildMealCard(
//                   context: context,
//                   title: 'Morning Snack',
//                   recipe: 'Fresh Fruit',
//                   prepTime: '2 min',
//                   cookTime: '0 min',
//                   imagePath: 'assets/images/f2.png',
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const FreshFruitScreen()),
//                   ),
//                 ),
//                 _buildMealCard(
//                   context: context,
//                   title: 'Lunch',
//                   recipe: 'Broccoli & Baked Salmon',
//                   prepTime: '10 min',
//                   cookTime: '20 min',
//                   imagePath: 'assets/images/f9.jpg',
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const BroccoliBakedSalmonScreen()),
//                   ),
//                 ),
//                 _buildMealCard(
//                   context: context,
//                   title: 'Afternoon Snack',
//                   recipe: 'Greek Yogurt',
//                   prepTime: '1 min',
//                   cookTime: '0 min',
//                   imagePath: 'assets/images/f8.jpg',
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const AfternoonSnackScreen()),
//                   ),
//                 ),
//                 _buildMealCard(
//                   context: context,
//                   title: 'Dinner',
//                   recipe: 'Roasted Chicken & Veggies',
//                   prepTime: '10 min',
//                   cookTime: '30 min',
//                   imagePath: 'assets/images/f6.jpg',
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const RoastedChickenVeggiesScreen()),
//                   ),
//                 ),
//               ],
//             );
//           } else {
//             // Mobile portrait layout
//             return SingleChildScrollView(
//               padding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12 : 16,
//                 vertical: 16,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   _buildMealCard(
//                     context: context,
//                     title: 'Breakfast',
//                     recipe: 'Overnight Berry Oatmeal',
//                     prepTime: '5 min',
//                     cookTime: '5 min',
//                     imagePath: 'assets/images/f1.png',
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const OvernightOatmealScreen()),
//                     ),
//                   ),
//                   SizedBox(height: isSmallScreen ? 12 : 16),
//                   _buildMealCard(
//                     context: context,
//                     title: 'Morning Snack',
//                     recipe: 'Fresh Fruit',
//                     prepTime: '2 min',
//                     cookTime: '0 min',
//                     imagePath: 'assets/images/f1.png',
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const FreshFruitScreen()),
//                     ),
//                   ),
//                   SizedBox(height: isSmallScreen ? 12 : 16),
//                   _buildMealCard(
//                     context: context,
//                     title: 'Lunch',
//                     recipe: 'Broccoli & Baked Salmon',
//                     prepTime: '10 min',
//                     cookTime: '20 min',
//                     imagePath: 'assets/images/f9.jpg',
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const BroccoliBakedSalmonScreen()),
//                     ),
//                   ),
//                   SizedBox(height: isSmallScreen ? 12 : 16),
//                   _buildMealCard(
//                     context: context,
//                     title: 'Afternoon Snack',
//                     recipe: 'Greek Yogurt',
//                     prepTime: '1 min',
//                     cookTime: '0 min',
//                     imagePath: 'assets/images/f8.jpg',
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const AfternoonSnackScreen()),
//                     ),
//                   ),
//                   SizedBox(height: isSmallScreen ? 12 : 16),
//                   _buildMealCard(
//                     context: context,
//                     title: 'Dinner',
//                     recipe: 'Roasted Chicken & Veggies',
//                     prepTime: '10 min',
//                     cookTime: '30 min',
//                     imagePath: 'assets/images/f6.jpg',
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const RoastedChickenVeggiesScreen()),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildMealCard({
//     required BuildContext context,
//     required String title,
//     required String recipe,
//     required String prepTime,
//     required String cookTime,
//     required String imagePath,
//     VoidCallback? onTap,
//   }) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 350;
//     final imageSize = isSmallScreen ? 60.0 : 80.0;

//     return Card(
//       elevation: 2,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onTap,
//         splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//         highlightColor: Colors.transparent,
//         child: Padding(
//           padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.asset(
//                   imagePath,
//                   width: imageSize,
//                   height: imageSize,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) => Container(
//                     width: imageSize,
//                     height: imageSize,
//                     color: Colors.grey.shade200,
//                     child: const Icon(Icons.fastfood, color: Colors.grey),
//                   ),
//                 ),
//               ),
//               SizedBox(width: isSmallScreen ? 8 : 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title.toUpperCase(),
//                       style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                             color: Theme.of(context).colorScheme.primary,
//                             fontWeight: FontWeight.bold,
//                             fontSize: isSmallScreen ? 12 : null,
//                           ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       recipe,
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             fontSize: isSmallScreen ? 14 : null,
//                           ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: [
//                         _buildTimeChip(context, Icons.timer_outlined, 'Prep: $prepTime'),
//                         _buildTimeChip(context, Icons.restaurant_outlined, 'Cook: $cookTime'),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               if (onTap != null) 
//                 Icon(Icons.chevron_right, size: isSmallScreen ? 20 : 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTimeChip(BuildContext context, IconData icon, String text) {
//     return Chip(
//       avatar: Icon(icon, size: 16),
//       label: Text(text),
//       backgroundColor: Colors.grey.shade100,
//       labelStyle: Theme.of(context).textTheme.labelSmall,
//       visualDensity: VisualDensity.compact,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }
// }

// // Recipe screen classes
// class OvernightOatmealScreen extends StatelessWidget {
//   const OvernightOatmealScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Overnight Berry Oatmeal',
//       prepTime: '5 min',
//       cookTime: '5 min',
//       servings: '2',
//       imagePath: 'assets/images/f1.png',
//       ingredients: [
//         '2 cup rolled oats',
//         '2 cup unsweetened almond milk',
//         '1/2 cup plain Greek yogurt',
//         '1 tsp chia seeds or ground flax seeds',
//         '1 tbsp almond or peanut butter',
//         '2 tbsp honey',
//         '2 cup fresh strawberries',
//       ],
//       directions: [
//         'Whisk together all ingredients except strawberries in a medium-sized mixing bowl. Spoon mixture into a jar with a tight-fitting lid.',
//         'Place in the refrigerator, covered, for at least 6 h or overnight.',
//       ],
//     );
//   }
// }

// class FreshFruitScreen extends StatelessWidget {
//   const FreshFruitScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Fresh Fruit',
//       prepTime: '2 min',
//       cookTime: '0 min',
//       servings: '1',
//       imagePath: 'assets/images/f2.png',
//       ingredients: [
//         'Fresh fruit of your choice: banana, orange, kiwi, or pear.',
//       ],
//       directions: [
//         'Fresh fruit is an excellent snack during pregnancy, as it provides vitamins and minerals that are important for you and your baby.',
//         'Wash the fruit thoroughly before you peel it.',
//       ],
//     );
//   }
// }

// class BroccoliBakedSalmonScreen extends StatelessWidget {
//   const BroccoliBakedSalmonScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Broccoli & Baked Salmon',
//       prepTime: '10 min',
//       cookTime: '20 min',
//       servings: '2',
//       imagePath: 'assets/images/f9.jpg',
//       ingredients: [
//         '2 salmon fillets',
//         '2 cups broccoli florets',
//         '1 tbsp olive oil',
//         '1/2 tsp garlic powder',
//         '1/2 tsp salt',
//         '1/4 tsp black pepper',
//         '1 lemon, sliced',
//       ],
//       directions: [
//         'Preheat oven to 400°F (200°C).',
//         'Place salmon on baking sheet and surround with broccoli.',
//         'Drizzle with olive oil and season with garlic powder, salt, and pepper.',
//         'Top with lemon slices and bake for 15-20 minutes until salmon flakes easily.',
//       ],
//     );
//   }
// }

// class AfternoonSnackScreen extends StatelessWidget {
//   const AfternoonSnackScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Greek Yogurt',
//       prepTime: '1 min',
//       cookTime: '0 min',
//       servings: '1',
//       imagePath: 'assets/images/f8.jpg',
//       ingredients: [
//         '1 cup plain Greek yogurt',
//         '1 tbsp honey',
//         '1/4 cup granola',
//         '1/2 cup mixed berries',
//       ],
//       directions: [
//         'Scoop yogurt into a bowl.',
//         'Top with honey, granola, and berries.',
//         'Enjoy immediately.',
//       ],
//     );
//   }
// }

// class RoastedChickenVeggiesScreen extends StatelessWidget {
//   const RoastedChickenVeggiesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Roasted Chicken & Veggies',
//       prepTime: '10 min',
//       cookTime: '30 min',
//       servings: '2',
//       imagePath: 'assets/images/f6.jpg',
//       ingredients: [
//         '2 chicken breasts',
//         '2 cups mixed vegetables (carrots, zucchini, bell peppers)',
//         '2 tbsp olive oil',
//         '1 tsp dried thyme',
//         '1/2 tsp salt',
//         '1/4 tsp black pepper',
//       ],
//       directions: [
//         'Preheat oven to 425°F (220°C).',
//         'Toss vegetables with 1 tbsp olive oil and spread on baking sheet.',
//         'Rub chicken with remaining oil and season with thyme, salt, and pepper.',
//         'Place chicken on top of vegetables and roast for 25-30 minutes until chicken reaches 165°F (74°C).',
//       ],
//     );
//   }
// }

// class RecipeScreen extends StatelessWidget {
//   final String title;
//   final String prepTime;
//   final String cookTime;
//   final String servings;
//   final List<String> ingredients;
//   final List<String> directions;
//   final String imagePath;

//   const RecipeScreen({
//     super.key,
//     required this.title,
//     required this.prepTime,
//     required this.cookTime,
//     required this.servings,
//     required this.ingredients,
//     required this.directions,
//     required this.imagePath,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 350;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(
//           horizontal: isSmallScreen ? 12 : 16,
//           vertical: 16,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.asset(
//                 imagePath,
//                 width: double.infinity,
//                 height: isPortrait ? 200 : 150,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: isPortrait ? 200 : 150,
//                   color: Colors.grey.shade200,
//                   child: Center(
//                     child: Icon(
//                       Icons.fastfood,
//                       size: 60,
//                       color: Colors.grey.shade400,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildInfoRow(context),
//             const SizedBox(height: 24),
//             _buildSection(context, 'Ingredients', ingredients),
//             const SizedBox(height: 24),
//             _buildSection(context, 'Directions', directions),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 350;

//     return Flex(
//       direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildInfoItem(context, Icons.timer_outlined, 'Prep Time', prepTime),
//         if (isSmallScreen) const SizedBox(height: 16),
//         _buildInfoItem(context, Icons.restaurant_outlined, 'Cook Time', cookTime),
//         if (isSmallScreen) const SizedBox(height: 16),
//         _buildInfoItem(context, Icons.people_outline, 'Servings', servings),
//       ],
//     );
//   }

//   Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value) {
//     return Column(
//       children: [
//         Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.labelSmall,
//         ),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSection(BuildContext context, String title, List<String> items) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 350;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: Theme.of(context).colorScheme.primary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: isSmallScreen ? 20 : null,
//               ),
//         ),
//         const SizedBox(height: 8),
//         ...items.map((item) => Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title == 'Ingredients' ? '•' : '${items.indexOf(item) + 1}.',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: isSmallScreen ? 14 : null,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   item,
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 14 : null,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         )),
//       ],
//     );
//   }
// }





















// import 'package:flutter/material.dart';


// class HealthyMealApp extends StatelessWidget {
//   const HealthyMealApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.blue,
//           primary: Colors.blue.shade700,
//           secondary: Colors.orange.shade400,
//         ),
//         useMaterial3: true,
//       ),
//       home: const MealPlanScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class MealPlanScreen extends StatelessWidget {
//   const MealPlanScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Food Healthy Meal Plan'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // _buildDateTable(),
//             // const SizedBox(height: 24),
//             _buildMealCard(
//               context,
//               title: 'Breakfast',
//               recipe: 'Overnight Berry Oatmeal',
//               prepTime: '5 min',
//               cookTime: '5 min',
//               imagePath: 'assets/images/f4.jpg',
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const OvernightOatmealScreen()),
//               ),
//             ),
//             _buildMealCard(
//               context,
//               title: 'Morning Snack',
//               recipe: 'Fresh Fruit',
//               prepTime: '2 min',
//               cookTime: '0 min',
//               imagePath: 'assets/images/f7.jpg',
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const FreshFruitScreen()),
//               ),
//               ),
//             _buildMealCard(
//               context,
//               title: 'Lunch',
//               recipe: 'Broccoli & Baked Salmon',
//               prepTime: '10 min',
//               cookTime: '20 min',
//               imagePath: 'assets/images/f9.jpg',
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const BroccoliBakedSalmonScreen()),
//               ),
//             ),
//             _buildMealCard(
//               context,
//               title: 'Afternoon Snack',
//               recipe: 'Greek Yogurt',
//               prepTime: '1 min',
//               cookTime: '0 min',
//               imagePath: 'assets/images/f8.jpg',
//                 onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AfternoonSnackScreen()),
//               ),
//             ),
//             _buildMealCard(
//               context,
//               title: 'Dinner',
//               recipe: 'Roasted Chicken & Veggies',
//               prepTime: '10 min',
//               cookTime: '30 min',
//               imagePath: 'assets/images/f6.jpg',
//                 onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const RoastedChickenVeggiesScreen()),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }


//   Widget _buildMealCard(
//     BuildContext context, {
//     required String title,
//     required String recipe,
//     required String prepTime,
//     required String cookTime,
//     required String imagePath,
//     VoidCallback? onTap,
//   }) {
//     return Card(
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.asset(
//                   imagePath,
//                   width: 80,
//                   height: 80,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) => Container(
//                     width: 80,
//                     height: 80,
//                     color: Colors.grey.shade200,
//                     child: const Icon(Icons.fastfood, color: Colors.grey),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title.toUpperCase(),
//                       style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                             color: Theme.of(context).colorScheme.primary,
//                             fontWeight: FontWeight.bold,
//                           ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       recipe,
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         _TimeChip(Icons.timer_outlined, 'Prep: $prepTime'),
//                         const SizedBox(width: 8),
//                         _TimeChip(Icons.restaurant_outlined, 'Cook: $cookTime'),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               if (onTap != null) const Icon(Icons.chevron_right),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _DateCell extends StatelessWidget {
//   final String text;
//   final bool isHeader;

//   const _DateCell(this.text, {this.isHeader = false});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
//       child: Text(
//         text,
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//           color: isHeader ? Theme.of(context).colorScheme.primary : null,
//         ),
//       ),
//     );
//   }
// }

// class _TimeChip extends StatelessWidget {
//   final IconData icon;
//   final String text;

//   const _TimeChip(this.icon, this.text);

//   @override
//   Widget build(BuildContext context) {
//     return Chip(
//       avatar: Icon(icon, size: 16),
//       label: Text(text),
//       backgroundColor: Colors.grey.shade100,
//       labelStyle: Theme.of(context).textTheme.labelSmall,
//       visualDensity: VisualDensity.compact,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }
// }

// class RecipeScreen extends StatelessWidget {
//   final String title;
//   final String prepTime;
//   final String cookTime;
//   final String servings;
//   final List<String> ingredients;
//   final List<String> directions;
//   final String imagePath;

//   const RecipeScreen({
//     super.key,
//     required this.title,
//     required this.prepTime,
//     required this.cookTime,
//     required this.servings,
//     required this.ingredients,
//     required this.directions,
//     required this.imagePath,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.asset(
//                 imagePath,
//                 height: 200,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 200,
//                   color: Colors.grey.shade200,
//                   child: Center(
//                     child: Icon(
//                       Icons.fastfood,
//                       size: 60,
//                       color: Colors.grey.shade400,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildInfoRow(context),
//             const SizedBox(height: 24),
//             _buildSection(context, 'Ingredients', ingredients),
//             const SizedBox(height: 24),
//             _buildSection(context, 'Directions', directions),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _InfoItem(Icons.timer_outlined, 'Prep Time', prepTime),
//         _InfoItem(Icons.restaurant_outlined, 'Cook Time', cookTime),
//         _InfoItem(Icons.people_outline, 'Servings', servings),
//       ],
//     );
//   }

//   Widget _buildSection(BuildContext context, String title, List<String> items) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: Theme.of(context).colorScheme.primary,
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//         const SizedBox(height: 8),
//         ...items.map((item) => Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title == 'Ingredients' ? '•' : '${items.indexOf(item) + 1}.',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(width: 8),
//               Expanded(child: Text(item)),
//             ],
//           ),
//         )),
//       ],
//     );
//   }
// }

// class _InfoItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;

//   const _InfoItem(this.icon, this.label, this.value);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.labelSmall,
//         ),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//       ],
//     );
//   }
// }

// class OvernightOatmealScreen extends StatelessWidget {
//   const OvernightOatmealScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Overnight Berry Oatmeal',
//       prepTime: '5 min',
//       cookTime: '5 min',
//       servings: '2',
//       imagePath: 'assets/images/f4.jpg',
//       ingredients: [
//         '2 cup rolled oats',
//         '2 cup unsweetened almond milk',
//         '1/2 cup plain Greek yogurt',
//         '1 tsp chia seeds or ground flax seeds',
//         '1 tbsp almond or peanut butter',
//         '2 tbsp honey',
//         '2 cup fresh strawberries',
//       ],
//       directions: [
//         'Whisk together all ingredients except strawberries in a medium-sized mixing bowl. Spoon mixture into a jar with a tight-fitting lid.',
//         'Place in the refrigerator, covered, for at least 6 h or overnight.',
//       ],
//     );
//   }
// }

// class FreshFruitScreen extends StatelessWidget {
//   const FreshFruitScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Fresh Fruit',
//       prepTime: '2 min',
//       cookTime: '0 min',
//       servings: '1',
//       imagePath: 'assets/images/f7.jpg',
//       ingredients: [
//         'Fresh fruit of your choice: banana, orange, kiwi, or pear.',
//       ],
//       directions: [
//         'Fresh fruit is an excellent snack during pregnancy, as it provides vitamins and minerals that are important for you and your baby.',
//         'Wash the fruit thoroughly before you peel it.',
//       ],
//     );
//   }
// }

// class BroccoliBakedSalmonScreen extends StatelessWidget {
//   const BroccoliBakedSalmonScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Broccoli & Baked Salmon',
//       prepTime: '5 min',
//       cookTime: '5 min',
//       servings: '2',
//       imagePath: 'assets/images/f9.jpg',
//       ingredients: [
//         '2 cup rolled oats',
//         '2 cup unsweetened almond milk',
//         '1/2 cup plain Greek yogurt',
//         '1 tsp chia seeds or ground flax seeds',
//         '1 tbsp almond or peanut butter',
//         '2 tbsp honey',
//         '2 cup fresh strawberries',
//       ],
//       directions: [
//         'Whisk together all ingredients except strawberries in a medium-sized mixing bowl. Spoon mixture into a jar with a tight-fitting lid.',
//         'Place in the refrigerator, covered, for at least 6 h or overnight.',
//       ],
//     );
//   }
// }

// class AfternoonSnackScreen extends StatelessWidget {
//   const AfternoonSnackScreen ({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Afternoon Snack',
//       prepTime: '2 min',
//       cookTime: '0 min',
//       servings: '1',
//       imagePath: 'assets/images/f8.jpg',
//       ingredients: [
//         'Afternoon Snack of your choice: banana, orange, kiwi, or pear.',
//       ],
//       directions: [
//         'Fresh fruit is an excellent snack during pregnancy, as it provides vitamins and minerals that are important for you and your baby.',
//         'Wash the fruit thoroughly before you peel it.',
//       ],
//     );
//   }
// }

// class RoastedChickenVeggiesScreen extends StatelessWidget {
//   const RoastedChickenVeggiesScreen ({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const RecipeScreen(
//       title: 'Roasted Chicken & Veggies',
//       prepTime: '5 min',
//       cookTime: '5 min',
//       servings: '2',
//       imagePath: 'assets/images/f6.jpg',
//       ingredients: [
//         '2 cup rolled oats',
//         '2 cup unsweetened almond milk',
//         '1/2 cup plain Greek yogurt',
//         '1 tsp chia seeds or ground flax seeds',
//         '1 tbsp almond or peanut butter',
//         '2 tbsp honey',
//         '2 cup fresh strawberries',
//       ],
//       directions: [
//         'Whisk together all ingredients except strawberries in a medium-sized mixing bowl. Spoon mixture into a jar with a tight-fitting lid.',
//         'Place in the refrigerator, covered, for at least 6 h or overnight.',
//       ],
//     );
//   }
// }







































///////////////////////////

//   Widget _buildDateTable() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Table(
//           columnWidths: const {
//             0: FlexColumnWidth(1),
//             1: FlexColumnWidth(1),
//             2: FlexColumnWidth(1),
//             3: FlexColumnWidth(1),
//           },
//           children: [
//             // TableRow(
//             //   decoration: BoxDecoration(
//             //     color: Colors.teal.shade50,
//             //     borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
//             //   ),
//             //   children: const [
//             //     _DateCell('Today', isHeader: true),
//             //     _DateCell('Tomorrow', isHeader: true),
//             //     _DateCell('Jun 9', isHeader: true),
//             //     _DateCell('Jun 10', isHeader: true),
//             //   ],
//             // ),
//             // TableRow(
//             //   children: [
//             //     _DateCell('Overnight\nOatmeal'),
//             //     _DateCell(''),
//             //     _DateCell(''),
//             //     _DateCell(''),
//             //   ],
//             // ),
//           ],
//         ),
//       ),
//     );
//   }

////////////////////////////
















// import 'package:flutter/material.dart';


// class MealPlanScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Healthy Meal Plan'),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             _buildMealPlanTable(),
//             Divider(height: 1),
//             _buildMealSection(
//               title: 'Breakfast',
//               recipe: 'Overnight berry oatmeal',
//               prepTime: '5 min',
//               cookTime: '5 min',
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => OvernightOatmealScreen()),
//                 );
//               },
//             ),
//             Divider(height: 1),
//             _buildMealSection(
//               title: 'Snack',
//               recipe: 'Fresh fruit',
//               prepTime: '2 min',
//               cookTime: '0 min',
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => FreshFruitScreen()),
//                 );
//               },
//             ),
//             Divider(height: 1),
//             _buildMealSection(
//               title: 'Lunch',
//               recipe: 'Broccoli and baked salmon',
//               prepTime: '10 min',
//               cookTime: '20 min',
//             ),
//             Divider(height: 1),
//             _buildMealSection(
//               title: 'Snack',
//               recipe: 'Greek yogurt',
//               prepTime: '1 min',
//               cookTime: '0 min',
//             ),
//             Divider(height: 1),
//             _buildMealSection(
//               title: 'Dinner',
//               recipe: 'Roasted chicken and veggies',
//               prepTime: '10 min',
//               cookTime: '30 min',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMealPlanTable() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Table(
//         border: TableBorder.all(),
//         children: [
//           TableRow(
//             children: [
//               _buildTableCell('Today', isHeader: true),
//               _buildTableCell('Tomorrow', isHeader: true),
//               _buildTableCell('Jun 9', isHeader: true),
//               _buildTableCell('Jun 10', isHeader: true),
//             ],
//           ),
//           TableRow(
//             children: [
//               _buildTableCell('Breakfast'),
//               _buildTableCell(''),
//               _buildTableCell(''),
//               _buildTableCell(''),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTableCell(String text, {bool isHeader = false}) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }

//   Widget _buildMealSection({
//     required String title,
//     required String recipe,
//     required String prepTime,
//     required String cookTime,
//     VoidCallback? onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               recipe,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 8),
//             Row(
//               children: [
//                 Text('Prep time: $prepTime'),
//                 SizedBox(width: 16),
//                 Text('Cook time: $cookTime'),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class OvernightOatmealScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Overnight berry oatmeal'),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildRecipeHeader(
//               prepTime: '5 min',
//               cookTime: '5 min',
//               servings: '2',
//             ),
//             SizedBox(height: 24),
//             Text(
//               'Ingredients:',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             SizedBox(height: 8),
//             Text('- 2 cup rolled oats'),
//             Text('- 2 cup unsweetened almond milk'),
//             Text('- 1/2 cup plain Greek yogurt'),
//             Text('- 1 tsp chia seeds or ground flax seeds'),
//             Text('- 1 tbsp almond or peanut butter'),
//             Text('- 2 tbsp honey'),
//             Text('- 2 cup fresh strawberries'),
//             SizedBox(height: 24),
//             Text(
//               'Directions:',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             SizedBox(height: 8),
//             Text('1. Whisk together all ingredients except strawberries in a medium-sized mixing bowl. Spoon mixture into a jar with a tight-fitting lid.'),
//             Text('2. Place in the refrigerator, covered, for at least 6 h or overnight.'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecipeHeader({
//     required String prepTime,
//     required String cookTime,
//     required String servings,
//   }) {
//     return Table(
//       border: TableBorder.all(),
//       children: [
//         TableRow(
//           children: [
//             _buildHeaderCell('Prep time'),
//             _buildHeaderCell('Cook time'),
//             _buildHeaderCell('Servings'),
//           ],
//         ),
//         TableRow(
//           children: [
//             _buildHeaderCell(prepTime, isHeader: false),
//             _buildHeaderCell(cookTime, isHeader: false),
//             _buildHeaderCell(servings, isHeader: false),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildHeaderCell(String text, {bool isHeader = true}) {
//     return Padding(
//       padding: EdgeInsets.all(8),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }
// }

// class FreshFruitScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Fresh fruit'),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildRecipeHeader(
//               prepTime: '2 min',
//               cookTime: '0 min',
//               servings: '1',
//             ),
//             SizedBox(height: 24),
//             Text(
//               'Ingredients:',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             SizedBox(height: 8),
//             Text('- Fresh fruit of your choice: banana, orange, kiwi, or pear.'),
//             SizedBox(height: 24),
//             Text(
//               'Directions:',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             SizedBox(height: 8),
//             Text('1. Fresh fruit is an excellent snack during pregnancy, as it provides vitamins and minerals that are important for you and your baby. Wash the fruit thoroughly before you peel it.'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecipeHeader({
//     required String prepTime,
//     required String cookTime,
//     required String servings,
//   }) {
//     return Table(
//       border: TableBorder.all(),
//       children: [
//         TableRow(
//           children: [
//             _buildHeaderCell('Prep time'),
//             _buildHeaderCell('Cook time'),
//             _buildHeaderCell('Servings'),
//           ],
//         ),
//         TableRow(
//           children: [
//             _buildHeaderCell(prepTime, isHeader: false),
//             _buildHeaderCell(cookTime, isHeader: false),
//             _buildHeaderCell(servings, isHeader: false),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildHeaderCell(String text, {bool isHeader = true}) {
//     return Padding(
//       padding: EdgeInsets.all(8),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }
// }