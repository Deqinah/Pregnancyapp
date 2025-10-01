// import 'package:flutter/material.dart';
// // import 'package:flutter_markdown/flutter_markdown.dart';

// class ArticleDetailScreen extends StatelessWidget {
  // final PregnancyArticle article;

  // const ArticleDetailScreen({super.key, required this.article});

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
      // No AppBar here
      //body: CustomScrollView(
        // slivers: [
        //   SliverAppBar(
        //     expandedHeight: 400,
        //     flexibleSpace: _buildHeroImage(context),
        //     pinned: false,
        //     snap: false,
        //     floating: false,
        //     automaticallyImplyLeading: false,
        //   ),
        //   SliverPadding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //     sliver: SliverToBoxAdapter(
        //       child: _buildArticleContent(context),
        //     ),
        //   ),
        //   SliverPadding(
        //     padding: const EdgeInsets.all(16),
        //     sliver: _buildRelatedArticles(context),
        //   ),
        // ],
      //),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _shareArticle(context),
      //   backgroundColor: Colors.teal,
      //   child: const Icon(Icons.share, color: Colors.white),
      // ),
  //   );
  // }

  // Widget _buildHeroImage(BuildContext context) {
  //   return Hero(
  //     tag: 'image-${article.id}',
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.grey[200],
  //         borderRadius: const BorderRadius.only(
  //           bottomLeft: Radius.circular(20),
  //           bottomRight: Radius.circular(20),
  //       ),
  //       child: ClipRRect(
  //         borderRadius: const BorderRadius.only(
  //           bottomLeft: Radius.circular(20),
  //           bottomRight: Radius.circular(20),
  //         ),
  //         child: Image.asset(
  //           article.image,
  //           width: double.infinity,
  //           height: 400,
  //           fit: BoxFit.cover,
  //           errorBuilder: (context, error, stackTrace) => Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   'Image not available',
  //                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                         color: Colors.grey,
  //                       ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //     ),
  //   );
  // }

  // // Rest of your methods remain exactly the same...
  // Widget _buildArticleContent(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const SizedBox(height: 16),
  //       Text(
  //         'Key Information',
  //         style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //               fontWeight: FontWeight.bold,
  //               color: Colors.teal[700],
  //             ),
  //       ),
  //       const SizedBox(height: 8),
  //       MarkdownBody(
  //         data: article.content,
  //         styleSheet: MarkdownStyleSheet(
  //           h1: Theme.of(context).textTheme.headlineSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.teal[700],
  //                 fontSize: 22,
  //               ),
  //           h2: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.teal[600],
  //               ),
  //           p: Theme.of(context).textTheme.bodyLarge?.copyWith(
  //                 height: 1.6,
  //                 fontSize: 16,
  //               ),
  //           listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(
  //                 height: 1.8,
  //                 fontSize: 16,
  //               ),
  //           strong: TextStyle(
  //             fontWeight: FontWeight.bold,
  //             color: Colors.teal[700],
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 24),
  //       _buildImportantNotes(context),
  //     ],
  //   );
  // }

  // Widget _buildImportantNotes(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.teal[50],
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.teal[100]!),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.lightbulb_outline, color: Colors.teal[700]),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Pro Tip',
  //               style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.teal[700],
  //                   ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Remember to attend all your prenatal checkups and discuss any concerns with your healthcare provider.',
  //           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                 color: Colors.teal[800],
  //               ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildRelatedArticles(BuildContext context) {
  //   final relatedArticles = [
  //     {'title': 'Nutrition During Pregnancy', 'id': 'nutrition'},
  //     {'title': 'Exercise Guidelines', 'id': 'exercise'},
  //     {'title': 'Preparing for Delivery', 'id': 'delivery'},
  //   ];

  //   return SliverList(
  //     delegate: SliverChildBuilderDelegate(
  //       (context, index) {
  //         final article = relatedArticles[index];
  //         return Card(
  //           margin: const EdgeInsets.only(bottom: 12),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: ListTile(
  //             title: Text(article['title']!),
  //             trailing: const Icon(Icons.chevron_right),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             onTap: () {
  //               // Navigate to related article
  //             },
  //           ),
  //         );
  //       },
  //       childCount: relatedArticles.length,
  //     ),
  //   );
  // }

  // void _shareArticle(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Sharing article...')),
  //   );
  // }

  // void _saveArticle(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Article saved for later')),
  //   );
  // }
// }








// import 'package:flutter/material.dart';

// class ArticleDetailScreen extends StatelessWidget {
//   final Map<String, String> article;

//   const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Image.asset(
//               article['image']!,
//               width: double.infinity,
//               height: 220,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) => 
//               Container(height: 220, color: Colors.grey),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 article['content']!,
//                 style: TextStyle(fontSize: 16, height: 1.5),
//               ),
//             ),
//           ],
//         ),
//       ),
      
//     );
//   }
// }






// class ArticleDetailScreen extends StatelessWidget {
//   final Map<String, String> id;

//   const ArticleDetailScreen({Key? key, required this.id})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(id['title']!),
//         centertile:true,
//         backgroundColor: Colors.blue[900],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Image.network(
//               id['image']!,
//               width: double.infinity,
//               height: 220,
//               fit: BoxFit.cover,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 id['content']
//                 style: TextStyle(fontSize: 16, height: 1.5),
//               ),
//             ),
//             floatingActionButton: FloatingActionButton(
        
//           Naviga.push(
//             {
//       'id': 'week1_foods',
//       'title': 'Cuntada Uurka Toddobaadka 1aad',
//       'description': 'Cuntooyin nafaqo leh looga talagalay toddobaadka 1aad',
//       'image': 'https://example.com/week1_foods.jpg',
//       'content': '''**Cuntada lagu taliyo toddobaadka 1aad ee uurka:**

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
//     },
//           )
//         child: Icon(Icons.add),
//       ),
//           ],
//         ),
//       ),
//     );
//   }
// }



























// class ArticleDetailScreen extends StatelessWidget {
//   final Map<String, dynamic> article;

//   const ArticleDetailScreen ({Key? key, required this.article}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(article['title']),
//         backgroundColor: Colors.pinkAccent,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (article['image'] != null)
//               Container(
//                 height: 200,
//                 width: double.infinity,
//                 color: Colors.grey[200],
//                 child: Image.network(
//                   article['image'],
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             SizedBox(height: 20),
//             Text(
//               article['content'],
//               style: TextStyle(fontSize: 16, height: 1.5),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




// class ArticleDetailScreen extends StatelessWidget {
//   final Map<String, String> article;

//   const ArticleDetailScreen({Key? key, required this.article})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(article['title']!),
//         backgroundColor: Colors.pinkAccent,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Image.network(
//               article['image']!,
//               width: double.infinity,
//               height: 220,
//               fit: BoxFit.cover,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 article['description']! +
//                     "\n\n" +
//                     "This is a detailed article about ${article['title']}. It provides useful information for pregnant women to take care of themselves, stay healthy, and have a happy pregnancy journey.",
//                 style: TextStyle(fontSize: 16, height: 1.5),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
