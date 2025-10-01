import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key});

  final List<PregnancyArticle> articles = const [
    PregnancyArticle(
      id: 'month1',
      title: 'Bilaha 1aad (Toddobaadka 1-4)',
      description: 'Bilowga uurka iyo horumarinta asaasiga ah',
      image: 'assets/images/ar1.jpg',
      content: '''
## Bilaha 1aad ee Uurka

**Horumarinta Ilmaha:**
- Uurkagu waa qofka ugu yar (0.1-0.2 mm bilowga)
- Toddobaadka 4aad, wuxuu gaaraa 2-5 mm
- Wadne, maskax, iyo xubnaha kale ee ugu horreeya waxay bilaabmaan

**Calaamadaha Hooyada:**
- Hormoonnadu way kordhinayaan
- Caloosha xanuun yar
- Dareen la mid ah habeenka gudaha
- Uurku ma muuqdo ultrasoundka

**Talooyinka Caafimaadka:**
- Ku cun Vitamin B9 (Folic Acid)
- Ka tag cabitaanada iyo sigaarka
- Cab biyo badan (2-3 litir maalintiiba)
- Raaxo badan qaado

**Cuntada Wanaagsan:**
- Khudaar cagaaran (salad, spinach)
- Canjeero
- Miris
- Cuntooyinka ay ku jiraan iron iyo calcium
''',
    ),
    PregnancyArticle(
      id: 'month2',
      title: 'Bilaha 2aad (Toddobaadka 5-8)',
      description: 'Horumarinta xubnaha jirka iyo garaaca wadne',
      image: 'assets/images/ar2.jpg',
      content: '''
## Bilaha 2aad ee Uurka

**Horumarinta Ilmaha:**
- Toddobaadka 8aad, wuxuu gaaraa 1.6 cm
- Wadnaha wuxuu bilaabay garaacista
- Xubnaha jirka waxay bilaabaan inay sameeyaan
- Indhaha, dhegaha, iyo san way samaysmaan

**Calaamadaha Hooyada:**
- Lallabo subaxnimo
- Dareen daal ah
- Calaamado uur oo muuqda
- Wadne garaaca uurjiifka

**Talooyinka Caafimaadka:**
- Cunto nafaqo leh cun
- Ku raaxayso nasasho badan
- Ka fogow cuntada laga yaabo inay keenaan foodborne illnesses
- La xiriir takhtar haddii calaamadaha ay xoog yihiin

**Cuntada Wanaagsan:**
- Khudaar badan
- Miraha
- Cuntooyinka borotiin badan
''',
    ),
    PregnancyArticle(
      id: 'month3',
      title: 'Bilaha 3aad (Toddobaadka 9-13)',
      description: 'Horumarinta farta, cagaaraha iyo xubnaha',
      image: 'assets/images/ar3.jpg',
      content: '''
## Bilaha 3aad ee Uurka

**Horumarinta Ilmaha:**
- Wuxuu gaaraa 7-10 cm
- Far iyo cagaar waxay bilaabaan inay sameeyaan
- Xubnaha gacanta iyo cagta way sii kordhayaan
- Wadnaha wuxuu garaacaa 120-160 marqoobiyiin

**Calaamadaha Hooyada:**
- Xanuun caloosha hoose
- Isbeddelka moodka
- Xoogaa isu dhexgalka
- Xoogaa barar

**Talooyinka Caafimaadka:**
- Samee jimicsi khafiif ah
- Cab biyo badan
- Ka fogow stress
- Cuntooyin qaliin badan cun

**Cuntada Wanaagsan:**
- Canug iyo caano
- Bakhaar
- Macaan badan
''',
    ),
    PregnancyArticle(
      id: 'month4',
      title: 'Bilaha 4aad (Toddobaadka 14-17)',
      description: 'Horumarinta dhegaha iyo garaaca uurjiifka',
      image: 'assets/images/ar4.jpg',
      content: '''
## Bilaha 4aad ee Uurka

**Horumarinta Ilmaha:**
- Wuxuu gaaraa 13-15 cm
- Dhegaha waxay ku soo baxaan meelaha saxda ah
- Garaaca uurjiifku wuu sii xoogowdaa
- Maskaxdu way sii koraysaa

**Calaamadaha Hooyada:**
- Dareenka garaaca uurjiifka
- Xoogaa bararka sii kordha
- Xoogaa isbeddelka moodka
- Caloosha way sii kordhaa

**Talooyinka Caafimaadka:**
- Samee jimicsi khafiif ah
- Cab biyo badan
- Ku raaxayso nasasho badan
- Ka fogow stress

**Cuntada Wanaagsan:**
- Cuntooyinka ay ku jiraan calcium
- Macaan badan
- Bakhaar
''',
    ),
    PregnancyArticle(
      id: 'month5',
      title: 'Bilaha 5aad (Toddobaadka 18-21)',
      description: 'Horumarinta indhaha iyo garaaca uurjiifka',
      image: 'assets/images/ar5.jpg',
      content: '''
## Bilaha 5aad ee Uurka

**Horumarinta Ilmaha:**
- Wuxuu gaaraa 25-30 cm
- Indhaha waxay bilaabaan inay furmaan
- Garaaca uurjiifku wuu sii xoogowdaa
- Maskaxdu way sii koraysaa

**Calaamadaha Hooyada:**
- Dareenka garaaca uurjiifka
- Xoogaa bararka sii kordha
- Xoogaa isbeddelka moodka
- Caloosha way sii kordhaa

**Talooyinka Caafimaadka:**
- Samee jimicsi khafiif ah
- Cab biyo badan
- Ku raaxayso nasasho badan
- Ka fogow stress

**Cuntada Wanaagsan:**
- Cuntooyinka ay ku jiraan calcium
- Macaan badan
- Bakhaar
''',
    ),
    PregnancyArticle(
      id: 'month6',
      title: 'Bilaha 6aad (Toddobaadka 22-26)',
      description: 'Horumarinta maskaxda iyo garaaca uurjiifka',
      image: 'assets/images/ar6.jpg',
      content: '''
## Bilaha 6aad ee Uurka

**Horumarinta Ilmaha:**
- Wuxuu gaaraa 30-35 cm
- Maskaxdu way sii koraysaa
- Garaaca uurjiifku wuu sii xoogowdaa
- Xubnaha jirka way sii kordhayaan

**Calaamadaha Hooyada:**
- Dareenka garaaca uurjiifka
- Xoogaa bararka sii kordha
- Xoogaa isbeddelka moodka
- Caloosha way sii kordhaa

**Talooyinka Caafimaadka:**
- Samee jimicsi khafiif ah
- Cab biyo badan
- Ku raaxayso nasasho badan
- Ka fogow stress

**Cuntada Wanaagsan:**
- Cuntooyinka ay ku jiraan calcium
- Macaan badan
- Bakhaar
''',
    ),
    PregnancyArticle(
      id: 'month7',
      title: 'Bilaha 7aad (Toddobaadka 27-30)',
      description: 'Horumarinta maskaxda iyo garaaca uurjiifka',
      image: 'assets/images/ar7.jpg',
      content: '''
## Bilaha 7aad ee Uurka

**Horumarinta Ilmaha:**
- Wuxuu gaaraa 35-40 cm
- Maskaxdu way sii koraysaa
- Garaaca uurjiifku wuu sii xoogowdaa
- Xubnaha jirka way sii kordhayaan

**Calaamadaha Hooyada:**
- Dareenka garaaca uurjiifka
- Xoogaa bararka sii kordha
- Xoogaa isbeddelka moodka
- Caloosha way sii kordhaa

**Talooyinka Caafimaadka:**
- Samee jimicsi khafiif ah
- Cab biyo badan
- Ku raaxayso nasasho badan
- Ka fogow stress

**Cuntada Wanaagsan:**
- Cuntooyinka ay ku jiraan calcium
- Macaan badan
- Bakhaar
''',
    ),
    PregnancyArticle(
      id: 'month8',
      title: 'Bilaha 8aad (Toddobaadka 31-35)',
      description: 'Horumarinta maskaxda iyo garaaca uurjiifka',
      image: 'assets/images/ar8.jpg',
      content: '''
## Bilaha 8aad ee Uurka

**Horumarinta Ilmaha:**
- Wuxuu gaaraa 40-45 cm
- Maskaxdu way sii koraysaa
- Garaaca uurjiifku wuu sii xoogowdaa
- Xubnaha jirka way sii kordhayaan

**Calaamadaha Hooyada:**
- Dareenka garaaca uurjiifka
- Xoogaa bararka sii kordha
- Xoogaa isbeddelka moodka
- Caloosha way sii kordhaa

**Talooyinka Caafimaadka:**
- Samee jimicsi khafiif ah
- Cab biyo badan
- Ku raaxayso nasasho badan
- Ka fogow stress

**Cuntada Wanaagsan:**
- Cuntooyinka ay ku jiraan calcium
- Macaan badan
- Bakhaar
''',
    ),
    PregnancyArticle(
      id: 'month9',
      title: 'Bilaha 9aad (Toddobaadka 36-40+)',
      description: 'Diyaarinta dhalashada iyo toddobaadaha ugu dambeeyay',
      image: 'assets/images/ar9.jpg',
      content: '''
## Bilaha 9aad ee Uurka

**Horumarinta Ilmaha:**
- Wuxuu gaarayaa cabbir buuxda (50-55 cm, 3-4 kg)
- Maskaxdu way sii koraysaa
- Baruurta jirka way sii kordhaysaa
- Dhammaan unugyada jirka way shaqeeyaan

**Calaamadaha Hooyada:**
- Dheecaannada dhalashada
- Xoogaa xanuun caloosh
- Dareenka inuu uuraygu hoos u dhaco
- Cadaadis hoose ah

**Talooyinka Dhalashada:**
- Raadi caawimaad dhakhtarka
- Hayso neef qabow marka xanuunku yimaado
- Isticmaal dheefta la siiyo
- Diyaarso qalabka ilmaha

**Dib u eegiska Carruurta:**
- Carruurtu waa inay neefta si fiican u qaadaan
- Jidhka hooyadu waa inuu soo noqdaa si dabiici ah
- Raadi caawimaad haddii aad wax walba ogaato

**Cuntada Wanaagsan:**
- Cuntooyin fudud oo nafaqo leh
- Biyo badan cab
- Cuntooyinka tamarta siiya
''',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildArticleCard(context, article);
        },
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, PregnancyArticle article) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'image-${article.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  article.image,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,  
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PregnancyArticle {
  final String id;
  final String title;
  final String description;
  final String image;
  final String content;

  const PregnancyArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.content,
  });
}

class ArticleDetailScreen extends StatelessWidget {
  final PregnancyArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(article.title),
      //   elevation: 0,
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'image-${article.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  article.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            MarkdownBody(
              data: article.content,
              styleSheet: MarkdownStyleSheet(
                h1: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                      fontSize: 24,
                    ),
                h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[600],
                    ),
                p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                strong: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}















// import 'package:flutter/material.dart';
// import 'article_detail.dart';

// class ArticleScreen extends StatelessWidget {
//   final List<Map<String, String>> articles = [
//     //week1
//     {
//       'id': 'week1_article',
//       'title': 'Hordhac Uurka & Toddobaadka 1aad',
//       'description': 'Waxyaabaha la filayo toddobaadka 1aad ee uurka',
//       'image' :  'assets/images/ar1.jpg',
//       'content': '''Toddobaadka 1aad ee uurka waa bilowga safarka wanaagsan. Uurkagu wuxuu noqonayaa qiyaastii 0.1-0.2 mm. Waa weydi qofka ugu yar ee aad awoodo inaad u malaynayso, laakiin waa bilaawga nolosha cusub.

// **Waa Maxay Waxyaabaha La Filayo?**
// - Uurkagu ma muuqdo ultrasoundka
// - Hormoonnadu way kordhin doonaan
// - Caloosha xanuun yar iyo dareen la mid ah kii habeenka gudaha

// **Talooyin Caafimaad:**
// - Ku cun Vitamin B9 (Folic Acid)
// - Ka tag cabitaanada iyo sigaarka
// - Cab biyo badan (2-3 litir maalintiiba)

// **Cuntada Loo Maleynayo:**
// - Khudaar cagaaran (salad, spinach)
// - Canjeero
// - Miris

// Uurkagu wuxuu u baahan yahay nafaqo fiican si uu u koro si sax ah. Ha la yaabin inaadan weli dareemin farxad weyn, waayo jidhkaadu wali wuxuu isu diyaariyay uur-qabadka.'''
//     },
//     // Week 2
//     {
//       'id': 'week2_article',
//       'title': 'Horumarinta Uurka - Toddobaadka 2aad',
//       'description': 'Waxyaabaha ka dhacaya toddobaadka 2aad ee uurka',
//       'image':'assets/images/ar2.jpg',
//       'content': '''Toddobaadka 2aad ee uurka wuxuu ku jiraa marka uu jidhka hooyadu diyaarinayo xilliga uu uuraygu ku dhalan doono. Uurkagu wali waa mid aad u yar, laakiin wuxuu bilaabay inuu sameeyo qaab dhismeedkiisa aasaasiga ah.

// *Waxyaabaha La Filayo:*
// - Hormoonnadu sii kordhinayaan
// - Xilligan ayaa uuraygu ku dhalan karaa
// - Caloosha xanuun yar oo la mid ah kii habeenka gudaha

// *Talooyinka Caafimaad:*
// - Sii cun Folic Acid
// - Ka fogow stresska
// - Hayso hab qaawan oo socdaal ah'''
//     },
//   // Week 3
//     {
//       'id': 'week3_article',
//       'title': 'Horumarinta Uurka - Toddobaadka 3aad',
//       'description': 'Waxyaabaha ka dhacaya toddobaadka 3aad ee uurka',
//       'image': 'assets/images/ar3.jpg',
//       'content': '''Toddobaadka 3aad ee uurka ayaa ah xilliga uu uuraygu bilaabayo inuu ku dhalo. Uurkagu wuxuu sameynayaa xididdada nolosha ee ugu horreeya.

// *Waxyaabaha La Filayo:*
// - Uurkagu wuxuu sameynayaa DNA
// - Qaab dhismeedka jirka ayaa bilaabay inuu sameeyo
// - Hormoonnadu sii kordhinayaan

// *Talooyinka Caafimaad:*
// - Ku sii cun cuntooyin nafaqo badan
// - Ka fogow cabitaanada iyo sigaarka
// - Hayso jidhkaada oo nadiif ah'''
//     },
//  // Week 4
//     {
//       'id': 'week4_article',
//       'title': 'Horumarka Uurka - Toddobaadka 4aad',
//       'description': 'Bilowga uurka oo la xaqiijiyay',
//       'image': 'assets/images/ar4.jpg',
//       'content': '''Toddobaadka 4aad, hooyada waxay xaqiijin kartaa inay uur leedahay iyadoo la adeegsanayo baaritaanka kaadi-mareenka ama dhiigga.

// *Waxyaabaha La Filayo:*
// - Uurku wuxuu bilaabayaa inuu ku dhajiyo ilmo-galeenka
// - Waxaad dareemi kartaa daal ama lalabo
// - Naasaha oo xanuunaya

// *Talooyinka Caafimaad:*
// - Bilaaw la socodka jadwalka uurka
// - Ka fogow walwalka badan
// - Xaqiiji inaad qaadato Folic Acid iyo cuntooyin caafimaad leh'''
//     },
// // Week 5
//     {
//       'id': 'week5_article',
//       'title': 'Horumarka Uurka - Toddobaadka 5aad',
//       'description': 'Uurku wuu kobcayaa si dhaqso leh',
//       'image': 'assets/images/ar5.jpg',
//       'content': '''Toddobaadka 5aad, uurjiifku wuxuu bilaabayaa inuu kobco. Xubnaha muhiimka ah sida maskaxda iyo lafta laf-dhabarta ayaa bilaabaya inay sameysmaan.

// *Waxyaabaha La Filayo:*
// - Lallabo subaxnimo
// - Dareen daal ah
// - Calaamado uur oo muuqda

// *Talooyinka Caafimaad:*
// - Cunto nafaqo leh cun
// - Ku raaxayso nasasho badan
// - La xiriir takhtar haddii calaamadaha ay xoog yihiin'''
//     },
// // Week 6
//     {
//       'id': 'week6_article',
//       'title': 'Horumarka Uurka - Toddobaadka 6aad',
//       'description': 'Uurjiifku wuu soconayaa si fiican',
//       'image': 'assets/images/ar6.jpg',
//       'content': '''Toddobaadka 6aad, uurjiifka ayaa la arki karaa ultrasound-ka. Wadnaha uurjiifka wuxuu bilaabaa inuu garaaco.

// *Waxyaabaha La Filayo:*
// - Wadne garaaca uurjiifka
// - Lallabo iyo matag
// - Dareen korodhay oo ah urta iyo dhadhanka

// *Talooyinka Caafimaad:*
// - Cabb biyo badan
// - Cun cuntooyin fudud oo isbeddelka caloosha caawiya
// - Isticmaal jadwal nasasho'''
//     },
//     // Week 7
// {
//   'id': 'week7_article',
//   'title': 'Horumarka Uurka - Toddobaadka 7aad',
//   'description': 'Toddobaadkan uurku si dhakhso ah ayuu u koraa',
//  'image': 'assets/images/ar7.jpg',
//   'content': '''Toddobaadka 7aad, uurku wuxuu gaarayaa dherer dhan 1.3 cm wuxuuna bilaabayaa inuu yeesho wejigiisa. Wadnaha uur-jiifka wuxuu garaacayaa qiyaastii 150 jeer daqiiqadii.

// *Waxyaabaha La Filayo:*
// - Madax iyo wejiga oo bilaabaya qaab
// - Lafo iyo gacmo bilaabaya inay samaysmaan
// - La dareemi karo daal iyo lalabo

// *Talooyin Caafimaad:*
// - Ku raaxayso hurdo badan
// - Cun cuntooyin dheeli tiran
// - Ka fogow urta keeni karta lalabo'''
// },
// // Week 8
// {
//   'id': 'week8_article',
//   'title': 'Horumarka Uurka - Toddobaadka 8aad',
//   'description': 'Uur-jiifku wuxuu gaarayaa marxalad muhiim ah',
//   'image': 'assets/images/ar8.jpg',
//   'content': '''Toddobaadkan uur-jiifku wuxuu gaaraa dherer dhan 1.6 cm, gacmaha iyo lugaha ayaa si cad u muuqanaya.

// *Waxyaabaha La Filayo:*
// - Wuxuu leeyahay indho, dhago, iyo san
// - Xubin walba waxay bilaabaysaa shaqadeeda
// - Hooyadu way dareemi kartaa daal daran

// *Talooyin Caafimaad:*
// - Ka fogow stress
// - Kordhi hurdo iyo nasasho
// - Cun borotiin ku filan'''
// },

// // Week 9
//     {
//       'id': 'week9_article',
//       'title': 'Uurka - Toddobaadka 9aad',
//       'description': 'Uurka iyo koritaanka ilmaha toddobaadka 9aad',
//       'image': 'assets/images/ar9.jpg',
//       'content': '''Ilmuhu wuxuu dhererkiisu gaarayaa 2.3 cm, wuxuu leeyahay madaxa, jirka, gacmaha iyo lugaha. Wadnaha yar ayaa si joogto ah u garaacaya.

// *Waxyaabaha La Filayo:*
// - Madax xanuun fudud
// - Daallin
// - Dareen koror ah oo xagga dareenka ah

// *Talooyinka Caafimaad:*
// - Sii wad cunista Folic Acid
// - Isticmaal cuntooyin nafaqo leh sida miraha, khudradda
// - Naso hadba marka aad dareento daal'''
//     },
//  // Week 10
//     {
//       'id': 'week10_article',
//       'title': 'Uurka - Toddobaadka 10aad',
//       'description': 'Koritaanka uurjiifka iyo isbeddelka hooyada',
//      'image': 'assets/images/ar10.jpg',
//       'content': '''Ilmuhu wuxuu gaarayaa 3.1 cm wuxuuna bilaabayaa inuu sameysto faraha iyo suulasha. Xubnaha gudaha waxay sii wadaan koritaan.

// *Waxyaabaha La Filayo:*
// - Miisaankaaga ayaa kordhaya
// - Calool istaag
// - Dareen gaajo badan

// *Talooyinka Caafimaad:*
// - Cun cuntooyin yaryar oo badan maalintii
// - Ka fogaansho cuntada saliida badan
// - Jimicsi fudud sida socod'''
//     },
// // Week 11
//     {
//       'id': 'week11_article',
//       'title': 'Uurka - Toddobaadka 11aad',
//       'description': 'Koritaanka uurjiifka iyo isbeddelka hooyada',
//       'image': 'assets/images/ar11.jpg',
//       'content': '''Toddobaadka 11aad uurjiifku wuxuu gaarayaa ilaa 4-6 cm wuxuuna bilaabayaa inuu si dhakhso leh u koro. Madaxiisu weli wuu weyn yahay marka loo eego jirkiisa.

// *Waxyaabaha La Filayo:*
// - Madax iyo gacmo muuqda
// - Wadnaha uurjiifka oo si joogto ah u garaacaya
// - Calool xanuun ama matag yaraanaya

// *Talooyin Caafimaad:*
// - Qaado nasasho badan
// - Isticmaal dhar raaxo leh
// - Raac ballamaha caafimaad si joogto ah'''
//     },
// // Week 12
//     {
//       'id': 'week12_article',
//       'title': 'Uurka - Toddobaadka 12aad',
//       'description': 'Dhamaadka trimester-ka koowaad',
//       'image': 'assets/images/ar12.jpg',
//       'content': '''Toddobaadka 12aad waa dhamaadka trimester-ka koowaad. Uurjiifku wuxuu gaarayaa ilaa 6-7 cm, wuxuuna leeyahay faro iyo suulal kala soocan.

// *Waxyaabaha La Filayo:*
// - Matagga oo yaraada
// - Xanuun caloosha hoose ah
// - Dareen farxad iyo walwal isku jiro

// *Talooyin Caafimaad:*
// - Ku raaxayso nasashadaada
// - Iska jir miisaanka kordha xad-dhaafka ah
// - Cunto isku dheeli tiran cun'''
//     },
//  // Week 13
//     {
//       'id': 'week13_article',
//       'title': 'Horumarinta Uurka - Toddobaadka 13aad',
//       'description': 'Isbeddelada uurka toddobaadka 13aad',
//        'image': 'assets/images/ar13.jpg',
//       'content': '''Toddobaadka 13aad wuxuu calaamad u yahay dhammaadka saddex bilood ee hore. Carruurtu waxay leedahay far iyo suul si fiican u sameysan.

// *Waxyaabaha La Filayo:*
// - Madaxu wuu weyn yahay marka la barbar dhigo jirka
// - Ilkaha aasaaskooda ayaa bilowday
// - Hooyadu waxay dareemi kartaa xoogaa tamar ah

// *Talooyinka Caafimaad:*
// - Ka fogaaw cuntooyinka aan si fiican u karin
// - Ku sii wad cunista Folic Acid
// - Ku dadaal nasasho iyo socod yar'''
//     },
//  // Week 14
//     {
//       'id': 'week14_article',
//       'title': 'Horumarinta Uurka - Toddobaadka 14aad',
//       'description': 'Waxyaabaha dhacaya toddobaadka 14aad ee uurka',
//       'image': 'assets/images/ar14.jpg',
//       'content': '''Toddobaadka 14aad carruurtu waxay bilaabaysaa inay la dhaqanto iftiinka, waxayna ka falcelisaa.

// *Waxyaabaha La Filayo:*
// - Carruurtu waxay bilaabeysaa dhaqdhaqaaq
// - Timaha ayaa koraya
// - Xubnaha galmada ayaa muuqan kara

// *Talooyinka Caafimaad:*
// - Cun cunto borotiin leh
// - Biyo badan cab
// - Iska ilaali caajisnimo badan'''
//     },
// // Week 15
//     {
//       'id': 'week15_article',
//       'title': 'Horumarinta Uurka - Toddobaadka 15aad',
//       'description': 'Koritaanka iyo horumarka uurka toddobaadka 15aad',
//       'image': 'assets/images/ar15.jpg',
//       'content': '''Toddobaadka 15aad, wejiga uuraygu wuxuu yeelanayaa muuqaal bini'aadanimo. Ilkaha iyo lafaha ayaa sii xoogeysanaya.

// *Waxyaabaha La Filayo:*
// - Sanku wuu muuqdaa
// - Lafta dhegaha ayaa samaysanaysa
// - Dhaqdhaqaaq muuqda wuu dhici karaa

// *Talooyinka Caafimaad:*
// - Samee dhaqdhaqaaq fudud
// - Ha hilmaamin ballamaha caafimaadka
// - Cun borotiin iyo kalsiyum badan'''
//     },
// // Week 16
//     {
//       'id': 'week16_article',
//       'title': 'Uurka - Toddobaadka 16aad',
//       'description': 'Waxyaabaha ka dhacaya toddobaadka 16aad ee uurka',
//       'image': 'assets/images/ar16.jpg',
//       'content': '''Toddobaadka 16aad ee uurka, uurjiifka wuxuu bilaabayaa inuu muujiyo wajigiisa. Ilkaha hoose ayaa bilaabaya samaysanka, waxaana la arki karaa dhaqdhaqaaqyo yar yar.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaqa uurjiifka laga yaabaa in la dareemo
// - Maqaarka uurjiifka waa dhuuban yahay
// - Muruqyada wejiga ayaa bilaabaya dhaqaaq

// *Talooyinka Caafimaad:*
// - Kormeer joogto ah samee
// - Isticmaal xirmooyinka dhaqdhaqaaqa jirka ee fudud
// - Cun cuntooyin calcium iyo iron leh'''
//     },
// // Week 17
//     {
//       'id': 'week17_article',
//       'title': 'Uurka - Toddobaadka 17aad',
//       'description': 'Waxyaabaha ka dhacaya toddobaadka 17aad ee uurka',
//       'image': 'assets/images/ar17.jpg',
//       'content': '''Toddobaadka 17aad, uurjiifku wuxuu bilaabayaa inuu yeesho baruur si uu tamar u helo. Hurdada uurjiifka iyo hurdadiisa ayaa is beddelaya.

// *Waxyaabaha La Filayo:*
// - Baruurta uurjiifka ayaa bilaabmaysa
// - Uurjiifka wuxuu dareemayaa iftiin
// - Jirkaagu wuu sii fidayaa

// *Talooyinka Caafimaad:*
// - Cun cuntooyin ay ku jiraan zinc iyo magnesium
// - Nasasho kugu filan hel
// - La tasho dhakhtar haddii aad dareento xanuun aan caadi ahayn'''
//     },
//  // Week 18
//     {
//       'id': 'week18_article',
//       'title': 'Uurka - Toddobaadka 18aad',
//       'description': 'Waxyaabaha ka dhacaya toddobaadka 18aad ee uurka',
//       'image': 'assets/images/ar18.jpg',
//       'content': '''Toddobaadka 18aad, dareemayaasha uurjiifka ayaa bilaabaya inay shaqeeyaan. Dhagaha iyo indhuhu waxay bilaabayaan inay si fiican u shaqeeyaan.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaqyada uurjiifka si wanaagsan ayaa loo dareemi karaa
// - Dareemayaasha maqal iyo arag ayaa horumaraya
// - Hooyadu waxay dareemi kartaa daal badan

// *Talooyinka Caafimaad:*
// - Iska ilaali buuqa iyo walbahaarka
// - Cun cuntooyin nafaqo leh oo leh fitamiin B
// - Samee jimicsi khafiif ah'''
//     },
// // Week 19
//     {
//       'id': 'week19_article',
//       'title': 'Uurka - Toddobaadka 19aad',
//       'description': 'Korriinka uurjiifka iyo dareenka hooyada ee toddobaadka 19aad',
//       'image': 'assets/images/ar19.jpg',
//       'content': '''Toddobaadkan, uurjiifku wuxuu noqon karaa ilaa 15 cm dherer, wuxuuna bilaabayaa inuu yeesho timaha madaxa. Hooyadu waxay dareemi kartaa dhaqdhaqaaq yar.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaq yar oo uurjiifka ah
// - Jirkaaga wuu balaadhayaa
// - Dareen miisaan iyo daal

// *Talooyin Caafimaad:*
// - Ku dadaal hurdo kugu filan
// - Cun cuntooyin ay ku jiraan omega-3
// - Samee jimicsi fudud sida socodka'''
//     },
// // Week 20
//     {
//       'id': 'week20_article',
//       'title': 'Uurka - Toddobaadka 20aad',
//       'description': 'Toddobaadka dhexe ee uurka: kobaca iyo baaritaanka ultrasound',
//       'image': 'assets/images/ar20.jpg',
//       'content': '''Toddobaadka 20aad waxaad joogtaa bartamaha uurka. Uurjiifka wuxuu gaarayaa 16-17 cm, miisaankiisuna waa ilaa 300g.

// *Waxyaabaha La Filayo:*
// - Ultrasoundka muhiimka ah
// - Dareenka uurjiifka si muuqata
// - Koraayo xiidmaha iyo beerka

// *Talooyin Caafimaad:*
// - Hubi jadwalka baaritaanka
// - La xiriir dhaqtarkaaga haddii aad dareento xanuun badan
// - Cab biyo badan'''
//     },
//   // Week 21
//     {
//       'id': 'week21_article',
//       'title': 'Uurka - Toddobaadka 21aad',
//       'description': 'Horumarka uurka toddobaadka 21aad',
//       'image': 'assets/images/ar21.jpg',
//       'content': '''Toddobaadka 21aad, uuraygu wuxuu bilaabayaa inuu sameeyo dhaq-dhaqaaqyo muuqda, hooyaduna way dareemi kartaa dhaqdhaqaaqyadaas.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaqyo muuqda oo uurayga
// - Miisaanka uurayga qiyaastii 360g
// - Hooyada oo dareemaysa daal

// *Talooyin Caafimaad:*
// - Ku dadaal nasasho
// - Cun cuntooyinka birta leh
// - Isticmaal maraqa caafimaadka leh'''
//     },
// // Week 22
//     {
//       'id': 'week22_article',
//       'title': 'Uurka - Toddobaadka 22aad',
//       'description': 'Waxyaabaha la filayo toddobaadka 22aad',
//       'image': 'assets/images/ar22.jpg',
//       'content': '''Toddobaadkan, uurayga ayaa bilaabaya inuu yeesho arag iyo dhadhan. Lafta iyo murqaha ayaa xoogaysta.

// *Waxyaabaha La Filayo:*
// - Indhaha iyo dhadhanka uurayga oo koraya
// - Calool xanuun iyo daal badan

// *Talooyin Caafimaad:*
// - Samee jimicsi fudud sida socodka
// - Cab biyo badan
// - Xiro kabo raaxo leh'''
//     },
//  // Week 23
//     {
//       'id': 'week23_article',
//       'title': 'Uurka - Toddobaadka 23aad',
//       'description': 'Horumarka uurka toddobaadka 23aad',
//       'image': 'assets/images/ar23.jpg',
//       'content': '''Uuraygu wuxuu bilaabayaa inuu helo baruurta ka caawisa kuleylka jirka. Qiyaasta miisaankiisu waa 500g.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaqyo degdeg ah
// - Dheef-shiidka oo yara dhiba

// *Talooyin Caafimaad:*
// - Cun cuntooyinka leh faybar
// - Isticmaal saliid saytuun
// - Jimicsi fudud'''
//     },
//  // Week 24
//     {
//       'id': 'week24_article',
//       'title': 'Uurka - Toddobaadka 24aad',
//       'description': 'Horumarka ilmaha iyo isbeddelka hooyada toddobaadkan',
//       'image': 'assets/images/ar24.jpg',
//       'content': '''Toddobaadka 24aad, ilmahaagu wuxuu gaaraa dherer qiyaastii 30 cm ah iyo miisaan ku dhow 600g. Indhihiisu way samaysmeen laakiin wali ma furan.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaqa ilmaha oo xoogeysanaya
// - Gacmaha iyo lugaha oo si buuxda u sameysma
// - Nabarro caloosha ah (stretch marks)

// *Talooyinka Caafimaad:*
// - Ku tababar neefsashada qoto dheer
// - Hubi heerka sokorta dhiigga
// - Xir dhar raaxo leh oo fidinaya'''
//     },
//     // Week 25
//     {
//       'id': 'week25_article',
//       'title': 'Uurka - Toddobaadka 25aad',
//       'description': 'Ilmaha oo si buuxda u koraaya toddobaadkan',
//       'image': 'assets/images/ar25.jpg',
//       'content': '''Ilmahaagu wuxuu ku dhowaaday inuu helo miisaan dhan 700g. Wuxuu leeyahay xanuun-dareen iyo dhadhanka cuntada.

// *Waxyaabaha La Filayo:*
// - Hurdadaada oo kala go'an
// - Dareen culays ah caloosha hoosteeda
// - Afka hooyada oo qalalay

// *Talooyinka Caafimaad:*
// - Ku dadaal cabitaanka biyo badan
// - Cuntooyin isku dheellitiran cun
// - Neefsasho tababar samee'''
//     },
// // Week 26
//     {
//       'id': 'week26_article',
//       'title': 'Uurka - Toddobaadka 26aad',
//       'description': 'Ilmaha oo leh dareemayaal firfircoon',
//       'image': 'assets/images/ar26.jpg',
//       'content': '''Toddobaadkan, ilmahaagu wuxuu bilaabayaa inuu indhaha furo mararka qaar. Xusuus gaar ah iyo dareen buuxa ayuu yeeshaa.

// *Waxyaabaha La Filayo:*
// - Daal joogto ah
// - Gacmo iyo suulal bararan
// - Neefsasho degdeg ah

// *Talooyinka Caafimaad:*
// - Ku naso dhinaca bidix
// - Cuntooyin khafiif ah cun laakiin waqtiyo badan
// - Ka qaybgal fasalada dhalmada'''
//     },
// // Week 27
//     {
//       'id': 'week27_article',
//       'title': 'Uurka - Toddobaadka 27aad',
//       'description': 'Uurka toddobaadka 27aad iyo isbedellada jirka',
//       'image': 'assets/images/ar27.jpg',
//       'content': '''Toddobaadka 27aad waa bilowga trimester-kii ugu dambeeyay. Uurkagu wuu sii weynaanayaa, dhaqdhaqaaqyadiisuna waa dareemi karaan.

// *Waxyaabaha La Filayo:*
// - Uurjiifku wuu arkayaa oo maqlaa
// - Miisaanka hooyadu wuu kordhaa
// - Hurdo la’aan iyo calool istaag

// *Talooyinka Caafimaad:*
// - Cun cunto yaryar oo isdaba joog ah
// - Qaado nasasho badan
// - Biyo badan cab'''
//     },
// // Week 28
//     {
//       'id': 'week28_article',
//       'title': 'Uurka - Toddobaadka 28aad',
//       'description': 'Uurka toddobaadka 28aad iyo horumarka uurjiifka',
//       'image': 'assets/images/ar28.jpg',
//       'content': '''Toddobaadka 28aad uurjiifku wuxuu bilaabayaa inuu furo indhihiisa. Wuxuu miisaankiisu gaari karaa ilaa 1 kg.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaq badan
// - Neef qabatin markaad seexanayso

// *Talooyinka Caafimaad:*
// - Seexo dhinaca bidix
// - Cun cuntooyin fudud oo nafaqo leh
// - Biyo badan cab'''
//     },
// // Week 29
//     {
//       'id': 'week29_article',
//       'title': 'Uurka - Toddobaadka 29aad',
//       'description': 'Isbeddelka jirka iyo uurjiifka toddobaadka 29aad',
//       'image': 'assets/images/ar29.jpg',
//       'content': '''Toddobaadkan uurjiifka wuxuu gaaraa ilaa 1.2 kg miisaan. Muruqyadiisa iyo sambabbadiisu way horumarayaan.

// *Waxyaabaha La Filayo:*
// - Xanuun dhabarka ah
// - Hurdo la’aan

// *Talooyin Caafimaad:*
// - Jimicsi fudud samee
// - Is deji markaad huruddo
// - Sii wad cunista folic acid'''
//     },
// // Week 30
//     {
//       'id': 'week30_article',
//       'title': 'Uurka - Toddobaadka 30aad',
//       'description': 'Kororka miisaanka iyo dhaqdhaqaaqa uurjiifka',
//       'image': 'assets/images/ar30.jpg',
//       'content': '''Toddobaadka 30aad, uurjiifku wuxuu gaadhay qiyaastii 1.3-1.5 kg. Waxa uu sameeyay dhaq-dhaqaaq joogto ah, hooyaduna waxay dareemi kartaa taasi si cad.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaq uurjiif oo xoog leh
// - Miisaanka uurjiifka oo kordha
// - Neefsashada hooyada oo yara dhibaata ah

// *Talooyinka Caafimaad:*
// - Seexo dhinaca bidix si dhiiggu si fiican u wareego
// - Cab biyo badan
// - La xiriir dhakhtar haddii dhaqdhaqaaqu yaraado'''
//     },
//  // Week 31
//     {
//       'id': 'week31_article',
//       'title': 'Uurka - Toddobaadka 31aad',
//       'description': 'Korriinka maskaxda iyo dheefshiidka uurjiifka',
//       'image': 'assets/images/ar31.jpg',
//       'content': '''Toddobaadkan, maskaxda uurjiifku way sii koraan. Dheefshiidka wuxuu bilaabay inuu shaqeeyo. Waxaad dareemi kartaa daal iyo miisaan culus.

// *Waxyaabaha La Filayo:*
// - Maskaxda uurjiifka oo sii koraan
// - Dheefshiid shaqeynaya
// - Calool xanuun iyo neefsasho culus

// *Talooyinka Caafimaad:*
// - Nasasho badan qaado
// - Cunto yaryar oo badan cun
// - Xiro dhar raaxo leh'''
//     },

//     // Week 32
//     {
//       'id': 'week32_article',
//       'title': 'Uurka - Toddobaadka 32aad',
//       'description': 'Uurjiifka oo diyaarsanaya inuu kasoo baxo',
//       'image': 'assets/images/ar32.jpg',
//       'content': '''Toddobaadkan, uurjiifku wuxuu istaagay si madaxa hoos ugu jeedo. Jidhka hooyadu wuu sii kacsan yahay.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaq xooggan
// - Dareen culays hoose
// - Calool barar yar

// *Talooyinka Caafimaad:*
// - Ka qayb qaado fasalada dhalmada
// - Jimicsi fudud samee
// - La soco dhaqdhaqaaqa uurjiifka'''
//     },
// // Week 33
//     {
//       'id': 'week33_article',
//       'title': 'Uurka - Toddobaadka 33aad',
//       'description': 'Uurjiifku wuu miisaamayaa, hooyaduna way daallan tahay',
//       'image': 'assets/images/ar33.jpg',
//       'content': '''Uurjiifku wuxuu gaadhay 2.0 kg, habdhiska dareenka ayaa sii horumarinaya. Hooyadu waxay dareemi kartaa daal iyo madax xanuun.

// *Waxyaabaha La Filayo:*
// - Miisaanka uurjiifka oo kordha
// - Daalku wuu sii badanayaa
// - Hurdo la'aan ama neef qabasho

// *Talooyinka Caafimaad:*
// - Cunto nafaqo leh cun
// - Is naso maalintii dhowr jeer
// - Isticmaal barkimo taageera dhabarka'''
//     },
// // Week 34
//     {
//       'id': 'week34_article',
//       'title': 'Uurka - Toddobaadka 34aad',
//       'description': 'Waxyaabaha la filayo toddobaadka 34aad ee uurka',
//       'image': 'assets/images/ar34.jpg',
//       'content': '''Toddobaadka 34aad ee uurka, uuraygu wuu sii korayaa wuxuuna gaari karaa ilaa 45 cm dherer iyo 2.1 kg miisaan.

// *Waxyaabaha La Filayo:*
// - Dhaqdhaqaaqyo badan oo uurka ah
// - Calool cadaadis iyo saxaro adag
// - Neefsasho yar sabab la xiriirta cadaadiska

// *Talooyin Caafimaad:*
// - Ku naso dhinaca bidix
// - Cun cuntooyin yaryar oo soo noqnoqda
// - Xiro dhar raaxo leh oo neefsada'''
//     },
// // Week 35
//     {
//       'id': 'week35_article',
//       'title': 'Uurka - Toddobaadka 35aad',
//       'description': 'Waxyaabaha la filayo toddobaadka 35aad ee uurka',
//       'image': 'assets/images/ar35.jpg',
//       'content': '''Toddobaadka 35aad, ilmaha wuxuu bilaabayaa inuu qaato booska uu ku dhalan doono. Madaxu wuxuu hoos ugu socdaa miskaha hooyada.

// *Waxyaabaha La Filayo:*
// - Cadaadis ka yimaada miskaha
// - Dhaqdhaqaaqka ilmaha oo yaraada
// - Lafo xanuun & daal

// *Talooyin Caafimaad:*
// - Ka qayb qaado fasallada dhalmada
// - Kordhi nasashada
// - Ha qaadin wax culus'''
//     },
// // Week 36
//     {
//       'id': 'week36_article',
//       'title': 'Uurka - Toddobaadka 36aad',
//       'description': 'Waxyaabaha la filayo toddobaadka 36aad ee uurka',
//       'image': 'assets/images/ar36.jpg',
//       'content': '''Toddobaadkan, ilmaha wuxuu gaari karaa 47-48 cm dherer iyo 2.5-2.7 kg miisaan. Jirka ilmaha ayaa u dhowyahay dhammaadkiisa korriimada.

// *Waxyaabaha La Filayo:*
// - Kaadida oo soo noqnoqota
// - Uurayga oo hoos ugu dhacaya
// - Neefsasho fududaata

// *Talooyin Caafimaad:*
// - Kordhi tamartaaga
// - La xiriir dhakhtarka si joogto ah
// - Diyaarso boorsada isbitaalka'''
//     },
// // Week 37
//     {
//       'id': 'week37_article',
//       'title': 'Uurka - Toddobaadka 37aad',
//       'description': 'Uurka wuu bislaaday - la soco calaamadaha dhalmada',
//       'image': 'assets/images/ar37.jpg',
//       'content': '''Ilmuhu wuxuu hadda tixgelinayaa inuu bislaaday. Wuxuu miisaankiisu noqon karaa 2.8-3.0 kg, waxaana la sugaa calaamadaha dhalmada.

// *Waxyaabaha La Filayo:*
// - Cadaadis hoose
// - Daal badan
// - Calaamadaha dhalmada (xanuun joogto ah)

// *Talooyin Caafimaad:*
// - Nasasho badan qaado
// - U diyaargarow safarka isbitaalka
// - La soco waqtiga xanuunka'''
//     },
// // Week 38
//     {
//       'id': 'week38_article',
//       'title': 'Uurka - Toddobaadka 38aad',
//       'description': 'Ilmaha wuu dhowyahay inuu soo dhasho',
//       'image': 'assets/images/ar38.jpg',
//       'content': '''Toddobaadkan ilmaha wuxuu noqon karaa 3.1-3.3 kg. Maskaxda iyo dareemayaasha ilmaha ayaa si buuxda u shaqeynaya.

// *Waxyaabaha La Filayo:*
// - Xanuunyo yaryar
// - Neefsasho fudud
// - Cadaadis miskaha

// *Talooyin Caafimaad:*
// - Cunto fudud cun
// - Kordhi biyaha
// - Diyaarso qorshaha dhalmada'''
//     },
// // Week 39
//     {
//       'id': 'week39_article',
//       'title': 'Uurka - Toddobaadka 39aad',
//       'description': 'Uurka wuxuu marayaa dhammaadkii',
//       'image': 'assets/images/ar39.jpg',
//       'content': '''Ilmuhu waa diyaar u ah inuu dhasho. Miisaanka wuxuu noqon karaa 3.4-3.6 kg.

// *Waxyaabaha La Filayo:*
// - Calaamadaha dhalmada
// - Cadaadis hoos ah
// - Dhiig ama dheecaan

// *Talooyin Caafimaad:*
// - Is deji
// - Xasuuso boorsada dhalmada
// - La xiriir dhakhtarka haddii calaamado muuqdaan'''
//     },
// //week 40
//       {
//       'id': 'week40_article',
//       'title': 'Uurka - Toddobaadka 40aad (Dhalashada)',
//       'description': 'Waxyaabaha la filayo toddobaadka 40aad ee uurka',
//       'image': 'assets/images/ar40.jpg',
//       'content': '''Toddobaadka 40aad ee uurka waa xilliga la filayo inuu dhasho carruurta. Uurkagu wuxuu gaaray cabbir buuxda, qiyaastii 50-55 cm dherer iyo 3-4 kg miisaan.

// *Waxyaabaha La Filayo:*
// - Dheecaannada dhalashada
// - Xoogaa xanuun caloosh
// - Dareenka inuu uuraygu hoos u dhaco

// *Astaamaha Dhalashada:*
// - Dheecaannada dhalashada
// - Biqil dhinac kasta 10 daqiiqo
// - Daboolka ukunta jaban

// *Talooyinka Dhalashada:*
// - Raadi caawimaad dhakhtarka
// - Hayso neef qabow
// - Isticmaal dheefta la siiyo

// *Dib u eegiska Carruurta:*
// - Carruurtu waa inay neefta si fiican u qaadaan
// - Jidhka hooyadu waa inuu soo noqdaa si dabiici ah
// - Raadi caawimaad haddii aad wax walba ogaato'''
//     },
// // Week 41
// {
//   'id': 'week41_article',
//   'title': 'Uurka - Toddobaadka 41aad (Muddada Ka Baxsan)',
//   'description': 'Waxyaabaha dhici kara haddii uurka uu dhaafo toddobaadka 40aad',
//   'image': 'assets/images/ar41.jpg',
//   'content': '''Toddobaadka 41aad ee uurka wuxuu tilmaamayaa in ilmaha aanu weli dhalan, inkastoo muddada caadiga ah ee uurka (40 toddobaad) la dhaafay. Qiyaastii 10-15% haweenka uurka leh ayaa gaara toddobaadkan.

// *Waxyaabaha La Filayo:*
// - Ilmaha ayaa laga yaabaa inuu weynaado
// - Dheecaannada uurka ayaa yaraada
// - Dhaqdhaqaaqa ilmaha ayaa laga yaabaa inuu yaraado

// *Talooyin Caafimaad:*
// - La xiriir dhakhtarka si loo qiimeeyo xaaladda ilmaha
// - La soco dhaqdhaqaaqa ilmaha (kick counts)
// - Waxaa laga yaabaa in la bilaabo kicinta dhalmada (induction)

// *Astaamaha Dhalmada La Filayo:*
// - Xanuun joogto ah
// - Dhiig yar ama dheecaan hurdi ah
// - Ilmaha oo hoos u dagaya

// *Daryeel Dheeraad Ah:*
// - Baaritaan ultrasound ah
// - CTG (Cardiotocography) si loo qiimeeyo garaaca ilmaha
// - Kormeer joogto ah ilaa dhalmada la gaaro'''
// },
// // Week 42
// {
//   'id': 'week42_article',
//   'title': 'Uurka - Toddobaadka 42aad (Ka Baxsan Muddadii)',
//   'description': 'Maxaa dhici kara marka uurku dhaafo 42 toddobaad?',
//   'image': 'assets/images/ar42.jpg',
//   'content': '''Toddobaadka 42aad wuxuu tilmaamayaa xaalad aad u dambeeya oo uurka, waxaana loo yaqaannaa "post-term pregnancy". Qiyaastii 2-5% dumarka uurka leh ayaa gaara toddobaadkan.

// *Waxyaabaha Dhici Kara:*
// - Ilmaha ayaa aad u weynaan kara (macrosomia)
// - Biyaha uur-ku-jirta (amniotic fluid) ayaa aad u yaraan kara
// - Ilmaha oo nafaqo yari dareema
// - Halista dhalmo qallafsan ayaa kordheysa

// *Talooyinka Caafimaad:*
// - Qiimeyn degdeg ah oo dhakhtarka ah
// - Kicinta dhalmada (induction) ama qalliinka cesarean haddii loo baahdo
// - Baaritaanno joogto ah sida ultrasound, CTG iyo baaritaanka dareenka ilmaha

// *Daryeel Dheeraad Ah:*
// - Ka feker inaad gasho isbitaalka haddii waqtiga la dhaafay
// - Ogaanshaha calaamadaha dhalmada oo degdeg ah
// - Si joogto ah ula soco dhaqdhaqaaqa ilmaha
// '''
// },

    
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: articles.length,
//         itemBuilder: (context, index) {
//           final article = articles[index];
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ArticleDetailScreen(article: article),
//                 ),
//               );
//             },
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius:
//                         BorderRadius.vertical(top: Radius.circular(16)),
//                     child: Image.asset(
//                       article['image']!,
//                       height: 180,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => 
//                           Container(height: 180, color: Colors.grey),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           article['title']!,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 6),
//                         Text(
//                           article['description']!,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(color: Colors.grey[700]),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }





































// import 'package:flutter/material.dart';
// import 'article_detail.dart';

// class ArticleScreen extends StatelessWidget {
//   final List<Map<String, String>> articles = [
//     //week1
//     {
//      'id': 'week1_article',
//      'title': 'Hordhac Uurka & Toddobaadka 1aad',
//      'description': 'Waxyaabaha la filayo toddobaadka 1aad ee uurka',
//      'image': 'https://example.com/week1_pregnancy.jpg',
//      'content': '''Toddobaadka 1aad ee uurka waa bilowga safarka wanaagsan. Uurkagu wuxuu noqonayaa qiyaastii 0.1-0.2 mm. Waa weydi qofka ugu yar ee aad awoodo inaad u malaynayso, laakiin waa bilaawga nolosha cusub.

// **Waa Maxay Waxyaabaha La Filayo?**
// - Uurkagu ma muuqdo ultrasoundka
// - Hormoonnadu way kordhin doonaan
// - Caloosha xanuun yar iyo dareen la mid ah kii habeenka gudaha

// **Talooyin Caafimaad:**
// - Ku cun Vitamin B9 (Folic Acid)
// - Ka tag cabitaanada iyo sigaarka
// - Cab biyo badan (2-3 litir maalintiiba)

// **Cuntada Loo Maleynayo:**
// - Khudaar cagaaran (salad, spinach)
// - Canjeero
// - Miris

// Uurkagu wuxuu u baahan yahay nafaqo fiican si uu u koro si sax ah. Ha la yaabin inaadan weli dareemin farxad weyn, waayo jidhkaadu wali wuxuu isu diyaariyay uur-qabadka.'''
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Maqaalada Uurka'),
//         centerTitle: true,
//         backgroundColor: Colors.pinkAccent,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: id.length,
//         itemBuilder: (context, index) {
//           final id = id[index];
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ArticleDetailScreen(id: id),
//                 ),
//               );
//             },
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius:
//                         BorderRadius.vertical(top: Radius.circular(16)),
//                     child: Image.network(
//                       id['image']!,
//                       height: 180,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           id['title']!,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 6),
//                         Text(
//                           id['description']!,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(color: Colors.grey[700]),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
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








































// import 'package:flutter/material.dart';
// import 'article_detail.dart';

// class ArticleScreen extends StatelessWidget {
//   final List<Map<String, dynamic>> articles = [
//     // Week 1
//     {
//       'id': 'week1_article',
//       'title': 'Hordhac Uurka & Toddobaadka 1aad',
//       'description': 'Waxyaabaha la filayo toddobaadka 1aad ee uurka',
//       'image': 'https://example.com/week1_pregnancy.jpg',
//       'content': '''Toddobaadka 1aad ee uurka waa bilowga safarka wanaagsan. Uurkagu wuxuu noqonayaa qiyaastii 0.1-0.2 mm. Waa weydi qofka ugu yar ee aad awoodo inaad u malaynayso, laakiin waa bilaawga nolosha cusub.

// **Waa Maxay Waxyaabaha La Filayo?**
// - Uurkagu ma muuqdo ultrasoundka
// - Hormoonnadu way kordhin doonaan
// - Caloosha xanuun yar iyo dareen la mid ah kii habeenka gudaha

// **Talooyin Caafimaad:**
// - Ku cun Vitamin B9 (Folic Acid)
// - Ka tag cabitaanada iyo sigaarka
// - Cab biyo badan (2-3 litir maalintiiba)

// **Cuntada Loo Maleynayo:**
// - Khudaar cagaaran (salad, spinach)
// - Canjeero
// - Miris

// Uurkagu wuxuu u baahan yahay nafaqo fiican si uu u koro si sax ah. Ha la yaabin inaadan weli dareemin farxad weyn, waayo jidhkaadu wali wuxuu isu diyaariyay uur-qabadka.'''
//     },
//     {
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

//     // Week 2
//     {
//       'id': 'week2_article',
//       'title': 'Horumarinta Uurka - Toddobaadka 2aad',
//       'description': 'Waxyaabaha ka dhacaya toddobaadka 2aad ee uurka',
//       'image': 'https://example.com/week2_pregnancy.jpg',
//       'content': '''Toddobaadka 2aad ee uurka wuxuu ku jiraa marka uu jidhka hooyadu diyaarinayo xilliga uu uuraygu ku dhalan doono. Uurkagu wali waa mid aad u yar, laakiin wuxuu bilaabay inuu sameeyo qaab dhismeedkiisa aasaasiga ah.

// **Waxyaabaha La Filayo:**
// - Hormoonnadu sii kordhinayaan
// - Xilligan ayaa uuraygu ku dhalan karaa
// - Caloosha xanuun yar oo la mid ah kii habeenka gudaha

// **Talooyinka Caafimaad:**
// - Sii cun Folic Acid
// - Ka fogow stresska
// - Hayso hab qaawan oo socdaal ah'''
//     },

//     // Week 3
//     {
//       'id': 'week3_article',
//       'title': 'Horumarinta Uurka - Toddobaadka 3aad',
//       'description': 'Waxyaabaha ka dhacaya toddobaadka 3aad ee uurka',
//       'image': 'https://example.com/week3_pregnancy.jpg',
//       'content': '''Toddobaadka 3aad ee uurka ayaa ah xilliga uu uuraygu bilaabayo inuu ku dhalo. Uurkagu wuxuu sameynayaa xididdada nolosha ee ugu horreeya.

// **Waxyaabaha La Filayo:**
// - Uurkagu wuxuu sameynayaa DNA
// - Qaab dhismeedka jirka ayaa bilaabay inuu sameeyo
// - Hormoonnadu sii kordhinayaan

// **Talooyinka Caafimaad:**
// - Ku sii cun cuntooyin nafaqo badan
// - Ka fogow cabitaanada iyo sigaarka
// - Hayso jidhkaada oo nadiif ah'''
//     },

//     // Continue adding weeks 4-39 following the same pattern...

//     // Week 40
//     {
//       'id': 'week40_article',
//       'title': 'Uurka - Toddobaadka 40aad (Dhalashada)',
//       'description': 'Waxyaabaha la filayo toddobaadka 40aad ee uurka',
//       'image': 'https://example.com/week40_pregnancy.jpg',
//       'content': '''Toddobaadka 40aad ee uurka waa xilliga la filayo inuu dhasho carruurta. Uurkagu wuxuu gaaray cabbir buuxda, qiyaastii 50-55 cm dherer iyo 3-4 kg miisaan.

// **Waxyaabaha La Filayo:**
// - Dheecaannada dhalashada
// - Xoogaa xanuun caloosh
// - Dareenka inuu uuraygu hoos u dhaco

// **Astaamaha Dhalashada:**
// - Dheecaannada dhalashada
// - Biqil dhinac kasta 10 daqiiqo
// - Daboolka ukunta jaban

// **Talooyinka Dhalashada:**
// - Raadi caawimaad dhakhtarka
// - Hayso neef qabow
// - Isticmaal dheefta la siiyo

// **Dib u eegiska Carruurta:**
// - Carruurtu waa inay neefta si fiican u qaadaan
// - Jidhka hooyadu waa inuu soo noqdaa si dabiici ah
// - Raadi caawimaad haddii aad wax walba ogaato'''
//     },
//     {
//       'id': 'week40_foods',
//       'title': 'Cuntada Dhalashada',
//       'description': 'Cuntooyin looga talagalay xilliga dhalashada',
//       'image': 'https://example.com/week40_foods.jpg',
//       'content': '''**Cuntada lagu taliyo xilliga dhalashada:**

// 1. **Cuntooyin tamar leh** (banana, dates)
//    - Bixin tamar degdeg ah
//    - Ka caawiya xoogga

// 2. **Bataato**
//    - Tamar joogto ah
//    - Fudud oo la cuni karo

// 3. **Caano khafiif ah**
//    - Ka caawiya hydrationka
//    - Tamar degdeg ah

// 4. **Suugo khafiif**
//    - Tamar joogto ah
//    - Nafaqo badan

// **Loo maleynayo inaad ka fogaato:**
// - Cuntooyin saliida badan
// - Cabitaanada kafeynka badan
// - Cuntooyin qiiqa xooggan'''
//     }
//   ];



//   @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Text('Maqaalada Uurka - Toddobaadkii'),
//       centerTitle: true,
//       backgroundColor: Colors.blue[900],
//     ),
//     body: ListView.builder(
//       itemCount: articles.length,
//       itemBuilder: (context, index) {
//         final article = articles[index];
//         return GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => ArticleDetailScreen(article: article),
//               ),
//             );
//           },
//           child: Card(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             elevation: 4,
//             margin: const EdgeInsets.symmetric(vertical: 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                   child: Image.network(
//                     article['image']!,
//                     height: 180,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         article['title']!,
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 6),
//                       Text(
//                         article['description']!,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(color: Colors.grey[700]),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     ),
//   );
// }














 
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Maqaalada Uurka - Toddobaadkii'),
//         centerTitle: true,
//         backgroundColor: Colors.blue[900],
//       ),
//       body: ListView.builder(
//         itemCount: articles.length,
//         itemBuilder: (context, index) {
//           final article = articles[index];
//           return Card(
//             margin: EdgeInsets.all(8),
//             child: ListTile(
//               leading: Container(
//                   padding: const EdgeInsets.all(12),
//         itemCount: articles.length,
//         itemBuilder: (context, index) {
//           final article = articles[index];
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ArticleDetailScreen(article: article),
//                 ),
//               );
//             },
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius:
//                         BorderRadius.vertical(top: Radius.circular(16)),
//                     child: Image.network(
//                       article['image']!,
//                       height: 180,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           article['title']!,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 6),
//                         Text(
//                           article['description']!,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(color: Colors.grey[700]),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//                 width: 50,
//                 height: 50,
//                 color: Colors.grey[200],
//                 child: article['image'] != null
//                     ? Image.network(article['image'],
//                         width: 50, height: 50, fit: BoxFit.cover)
//                     : Icon(Icons.article, color: Colors.blue[900]),
//               ),
//               title: Text(article['title']),
//               subtitle: Text(article['description']),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => ArticleDetailScreen(article: article),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }






















// import 'package:flutter/material.dart';
// import 'article_detail.dart';

// class ArticleScreen extends StatelessWidget {
//   final List<Map<String, String>> articles = [
//     {
//       'title': 'Talooyinka Nafaqada ee Hooyooyinka Uurka Leh',
//       'description': 'Cunto caafimaad leh waa muhiim inta lagu jiro uurka. Halkan ka akhri talooyin waxtar leh.',
//       'image': 'https://tse2.mm.bing.net/th/id/OIP.SDFYW9LFUXE9NIKPmS0ZEwHaE8?cb=iwp2&rs=1&pid=ImgDetMain',
//     },
//     {
//       'title': 'Jimicsiga Inta Lagu Jiro Uurka',
//       'description': 'Jimicsiyo ammaan ah oo kaa caawinaya caafimaadka inta aad uurka leedahay.',
//       'image': 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1',
//     },
//     {
//       'title': 'Hagaha Saddexda Bil ee Hore',
//       'description': 'Waa maxay waxyaabaha la filayo marka aad uur leedahay saddexda bil ee hore.',
//       'image': 'https://images.unsplash.com/photo-1612192529763-bd0cb2f9a3f0',
//     },
//     {
//       'title': 'Khuraafaadka Ku Saabsan Uurka',
//       'description': 'Waxaan kaa saaraynaa khuraafaadka caanka ah ee aan cilmi ku saleysneyn.',
//       'image': 'https://images.unsplash.com/photo-1598970434795-0c54fe7c0642',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Maqaalada Uurka'),
//         centerTitle: true,
//         backgroundColor: Colors.pinkAccent,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: articles.length,
//         itemBuilder: (context, index) {
//           final article = articles[index];
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ArticleDetailScreen(article: article),
//                 ),
//               );
//             },
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius:
//                         BorderRadius.vertical(top: Radius.circular(16)),
//                     child: Image.network(
//                       article['image']!,
//                       height: 180,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           article['title']!,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 6),
//                         Text(
//                           article['description']!,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(color: Colors.grey[700]),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
