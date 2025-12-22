import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const AkilliMutfakApp());
}

class AkilliMutfakApp extends StatelessWidget {
  const AkilliMutfakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cebimdeki Şef',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepOrange,
          titleTextStyle: TextStyle(
            color: Colors.deepOrange,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      home: const AnaEkran(),
    );
  }
}

// ANA EKRAN
class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _seciliSayfaIndex = 0;

  final List<Widget> _sayfalar = [
    const KesfetSayfasi(),
    const FavorilerSayfasi(),
  ];

  //RASTGELE YEMEK MANTIĞI
  void _rastgeleSecimDiyaloguGoster() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Canın Ne Çekiyor?", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Şansına güven, birini seç!", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _secimButonu("Tuzlu / Yemek", Icons.restaurant, Colors.orange, "Chicken"),
                  _secimButonu("Tatlı", Icons.cake, Colors.pinkAccent, "Dessert"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _secimButonu(String baslik, IconData ikon, Color renk, String apiKategori) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _rastgeleYemekGetir(apiKategori);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: renk.withOpacity(0.1),
            child: Icon(ikon, color: renk, size: 30),
          ),
          const SizedBox(height: 8),
          Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _rastgeleYemekGetir(String kategori) async {
    // Yükleniyor göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var url = Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?c=$kategori');
      var cevap = await http.get(url);
      
      if (cevap.statusCode == 200) {
        var veri = jsonDecode(cevap.body);
        List yemekler = veri['meals'] ?? [];
        
        if (yemekler.isNotEmpty) {
          var random = Random();
          var sansliYemek = yemekler[random.nextInt(yemekler.length)];

          if (mounted) Navigator.pop(context); // Yükleniyor kapat

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetaySayfasi(id: sansliYemek['idMeal'])),
            );
          }
        } else {
           if (mounted) Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sayfalar[_seciliSayfaIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _rastgeleSecimDiyaloguGoster,
        backgroundColor: Colors.deepOrange,
        elevation: 4,
        child: const Icon(Icons.casino, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSayfaIndex,
        onDestinationSelected: (index) {
          setState(() {
            _seciliSayfaIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.deepOrange.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.manage_search_outlined),
            selectedIcon: Icon(Icons.manage_search, color: Colors.deepOrange),
            label: 'Keşfet',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Colors.red),
            label: 'Favorilerim',
          ),
        ],
      ),
    );
  }
}

// SAYFA: KEŞFET
class KesfetSayfasi extends StatefulWidget {
  const KesfetSayfasi({super.key});

  @override
  State<KesfetSayfasi> createState() => _KesfetSayfasiState();
}

class _KesfetSayfasiState extends State<KesfetSayfasi> {
  List yemekListesi = [];
  bool yukleniyor = false;
  TextEditingController aramaKutusu = TextEditingController();
  final translator = GoogleTranslator();

  final Map<String, String> kategoriler = {
    "Tümü": "all",
    "Tavuk": "chicken",
    "Kırmızı Et": "beef",
    "Makarna": "pasta",
    "Deniz Ürünü": "seafood",
    "Kahvaltı": "breakfast",
    "Tatlı": "dessert",
    "Kuzu Eti": "lamb",
    "Vejetaryen": "vegetarian",
    "Vegan": "vegan",
    "Başlangıç": "starter",
    "Yan Lezzet": "side",
  };

  String seciliKategori = "Tümü";

  Future<void> yemekGetir(String kelime, {bool kategoriMi = false}) async {
    setState(() {
      yukleniyor = true;
      yemekListesi = [];
    });

    Uri url;
    String aranacakKelime = kelime;

    if (!kategoriMi && kelime != "all") {
      try {
        var ceviri = await translator.translate(kelime, to: 'en');
        String text = ceviri.text.toLowerCase();
        
        // Temizlik
        text = text.replaceAll(" and ", ",");
        text = text.replaceAll(" & ", ",");
        text = text.replaceAll(" with ", ",");
        text = text.replaceAll(" ve ", ",");
        text = text.replaceAll(RegExp(r'\s*,\s*'), ','); 
        text = text.replaceAll(" ", "_"); 

        aranacakKelime = text;
      } catch (e) {
        print("Çeviri hatası: $e");
      }
    }

    if (kelime == "all") {
       url = Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=');
    } else if (kategoriMi) {
      url = Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?c=$aranacakKelime');
    } else {
      url = Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?i=$aranacakKelime');
    }

    try {
      var cevap = await http.get(url);
      if (cevap.statusCode == 200) {
        var veri = jsonDecode(cevap.body);
        
        if (veri['meals'] == null && aranacakKelime.contains(',')) {
          // B PLANI
          String ilkMalzeme = aranacakKelime.split(',')[0];
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text("Tam eşleşme bulunamadı, benzer sonuçlar gösteriliyor."),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ));
          }

          var yedekUrl = Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?i=$ilkMalzeme');
          var yedekCevap = await http.get(yedekUrl);
          
          if (yedekCevap.statusCode == 200) {
            var yedekVeri = jsonDecode(yedekCevap.body);
            setState(() {
              yemekListesi = yedekVeri['meals'] ?? [];
              yukleniyor = false;
            });
          }
        } else {
          setState(() {
            yemekListesi = veri['meals'] ?? [];
            yukleniyor = false;
          });
        }
      } else {
         setState(() => yukleniyor = false);
      }
    } catch (e) {
      print("API Hatası: $e");
      setState(() => yukleniyor = false);
    }
  }

  @override
  void initState() {
    super.initState();
    yemekGetir("all", kategoriMi: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.restaurant_menu, color: Colors.deepOrange),
            SizedBox(width: 10),
            Text('Cebimdeki Şef'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: kategoriler.keys.map((turkceIsim) {
                bool seciliMi = seciliKategori == turkceIsim;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: FilterChip(
                    label: Text(turkceIsim),
                    selected: seciliMi,
                    onSelected: (selected) {
                      setState(() {
                        seciliKategori = turkceIsim;
                        aramaKutusu.clear();
                      });
                      yemekGetir(kategoriler[turkceIsim]!, kategoriMi: true);
                    },
                    selectedColor: Colors.deepOrange,
                    labelStyle: TextStyle(
                      color: seciliMi ? Colors.white : Colors.grey[800],
                      fontWeight: seciliMi ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                controller: aramaKutusu,
                decoration: InputDecoration(
                  hintText: 'Ne pişirmek istersin?',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.deepOrange),
                    onPressed: () {
                      if (aramaKutusu.text.trim().isNotEmpty) {
                        FocusScope.of(context).unfocus();
                        setState(() => seciliKategori = "");
                        yemekGetir(aramaKutusu.text.trim(), kategoriMi: false);
                      }
                    },
                  ),
                ),
                onSubmitted: (deger) {
                  if (deger.trim().isNotEmpty) {
                    FocusScope.of(context).unfocus();
                    setState(() => seciliKategori = "");
                    yemekGetir(deger.trim(), kategoriMi: false);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : yemekListesi.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_meals, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 15),
                            const Text("Yemek bulunamadı.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: yemekListesi.length,
                        itemBuilder: (context, index) {
                          var yemek = yemekListesi[index];
                          return YemekKarti(
                            id: yemek['idMeal'],
                            resimUrl: yemek['strMealThumb'],
                            isim: yemek['strMeal'],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// SAYFA: FAVORİLERİM
class FavorilerSayfasi extends StatefulWidget {
  const FavorilerSayfasi({super.key});

  @override
  State<FavorilerSayfasi> createState() => _FavorilerSayfasiState();
}

class _FavorilerSayfasiState extends State<FavorilerSayfasi> {
  List<dynamic> favoriYemeklerDetay = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    favorileriGetir();
  }

  Future<void> favorileriGetir() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> kayitliIdler = prefs.getStringList('favori_yemekler') ?? [];

    if (kayitliIdler.isEmpty) {
      if (mounted) setState(() => yukleniyor = false);
      return;
    }

    List<dynamic> geciciListe = [];
    for (String id in kayitliIdler) {
      var url = Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=$id');
      try {
        var cevap = await http.get(url);
        if (cevap.statusCode == 200) {
          var veri = jsonDecode(cevap.body);
          if (veri['meals'] != null) {
            geciciListe.add(veri['meals'][0]);
          }
        }
      } catch (e) {
        print("Favori hatası: $e");
      }
    }

    if (mounted) {
      setState(() {
        favoriYemeklerDetay = geciciListe;
        yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim ❤️')),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : favoriYemeklerDetay.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 70, color: Colors.grey.shade300),
                      const SizedBox(height: 20),
                      Text("Henüz favori yemeğin yok.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriYemeklerDetay.length,
                  itemBuilder: (context, index) {
                    var yemek = favoriYemeklerDetay[index];
                    return YemekKarti(
                      id: yemek['idMeal'],
                      resimUrl: yemek['strMealThumb'],
                      isim: yemek['strMeal'],
                    );
                  },
                ),
    );
  }
}

class YemekKarti extends StatelessWidget {
  final String id;
  final String resimUrl;
  final String isim;

  const YemekKarti({super.key, required this.id, required this.resimUrl, required this.isim});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetaySayfasi(id: id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                resimUrl,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(height: 200, color: Colors.grey.shade200, child: const Icon(Icons.error)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isim,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.deepOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DETAY SAYFASI ---
class DetaySayfasi extends StatefulWidget {
  final String id;
  const DetaySayfasi({super.key, required this.id});

  @override
  State<DetaySayfasi> createState() => _DetaySayfasiState();
}

class _DetaySayfasiState extends State<DetaySayfasi> {
  Map? detay;
  bool yukleniyor = true;
  bool favoriMi = false;
  final translator = GoogleTranslator();

  String turkceIsim = "";
  String turkceTarif = "";
  List<String> turkceMalzemeler = [];
  List<String> hamIngilizceMalzemeler = [];
  List<bool> malzemeKontrol = [];
  List benzerYemekler = [];

  Map<String, dynamic>? besinDegerleri;
  bool besinYukleniyor = false;

  @override
  void initState() {
    super.initState();
    detayGetirVeCevir();
    favoriKontrol();
  }

  Future<void> favoriKontrol() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriler = prefs.getStringList('favori_yemekler') ?? [];
    if (mounted) setState(() => favoriMi = favoriler.contains(widget.id));
  }

  Future<void> favoriDegistir() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriler = prefs.getStringList('favori_yemekler') ?? [];

    if (favoriMi) {
      favoriler.remove(widget.id);
    } else {
      favoriler.add(widget.id);
    }
    await prefs.setStringList('favori_yemekler', favoriler);
    setState(() => favoriMi = !favoriMi);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(favoriMi ? "Favorilere eklendi ❤️" : "Favorilerden çıkarıldı"),
      backgroundColor: favoriMi ? Colors.green : Colors.black87,
      duration: const Duration(seconds: 1),
    ));
  }

  Future<void> detayGetirVeCevir() async {
    var url = Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=${widget.id}');
    try {
      var cevap = await http.get(url);
      if (cevap.statusCode == 200) {
        var veri = jsonDecode(cevap.body);
        var hamVeri = veri['meals'][0];

        benzerleriGetir(hamVeri['strCategory']);

        String ingilizceIsim = hamVeri['strMeal'];
        String ingilizceTarif = hamVeri['strInstructions'];

        List<String> tempHamMalzemeler = [];
        for (int i = 1; i <= 20; i++) {
          String? ing = hamVeri['strIngredient$i'];
          String? measure = hamVeri['strMeasure$i'];
          
          if (ing != null && ing.trim().isNotEmpty) {
            String temizMeasure = (measure ?? "").trim();
            String temizIng = ing.trim();
            String oge = "$temizMeasure $temizIng"; 
            tempHamMalzemeler.add(oge);
          }
        }

        var anaCeviriler = await Future.wait([
          translator.translate(ingilizceIsim, to: 'tr'),
          translator.translate(ingilizceTarif, to: 'tr'),
        ]);

        List<String> cevrilmisMalzemeler = [];
        if (tempHamMalzemeler.isNotEmpty) {
           String malzemeBlogu = tempHamMalzemeler.join(" /// "); 
           try {
             var malzemeCevirisi = await translator.translate(malzemeBlogu, to: 'tr');
             cevrilmisMalzemeler = malzemeCevirisi.text.split(" /// ");
           } catch (e) {
             cevrilmisMalzemeler = tempHamMalzemeler; // Çeviri hatası olursa orjinali kullan
           }
        }

        if (mounted) {
          setState(() {
            detay = hamVeri;
            turkceIsim = anaCeviriler[0].text;
            turkceTarif = anaCeviriler[1].text;
            turkceMalzemeler = cevrilmisMalzemeler;
            hamIngilizceMalzemeler = tempHamMalzemeler; 
            malzemeKontrol = List.generate(cevrilmisMalzemeler.length, (index) => false);
            yukleniyor = false;
          });
        }
      }
    } catch (e) {
      print("Hata: $e");
    }
  }

  Future<void> benzerleriGetir(String kategori) async {
    try {
      var url = Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?c=$kategori');
      var cevap = await http.get(url);
      if (cevap.statusCode == 200) {
        var veri = jsonDecode(cevap.body);
        if (mounted) {
          setState(() {
            benzerYemekler = veri['meals'] ?? [];
          });
        }
      }
    } catch (e) {
      print("Öneri hatası: $e");
    }
  }

  //BESİN ANALİZİ
  Future<void> besinDegerleriniAnalizEt() async {
    setState(() {
      besinYukleniyor = true;
    });

    List<String> temizlenmisMalzemeler = [];

    for (String malzeme in hamIngilizceMalzemeler) {
      String lowerMalzeme = malzeme.toLowerCase();
      lowerMalzeme = lowerMalzeme.replaceAll("pinch", "");
      lowerMalzeme = lowerMalzeme.replaceAll("to taste", "");
      lowerMalzeme = lowerMalzeme.replaceAll("optional", "");
      lowerMalzeme = lowerMalzeme.trim();

      if (lowerMalzeme.isNotEmpty) {
        // Gramaj yoksa 1 porsiyon ekle
        if (!RegExp(r'^[0-9]').hasMatch(lowerMalzeme) && !lowerMalzeme.startsWith("1/2") && !lowerMalzeme.startsWith("1/4")) {
           lowerMalzeme = "1 serving $lowerMalzeme";
        }
        temizlenmisMalzemeler.add(lowerMalzeme);
      }
    }

    // Eğer malzeme yoksa sorgu atma
    if (temizlenmisMalzemeler.isEmpty) {
        setState(() => besinYukleniyor = false);
        return;
    }

    String query = temizlenmisMalzemeler.join(", ");
    
    // SENİN API KEYİN
    String apiKey = 'buraya kendi api keyinizi yazmalısınız.'; 

    var url = Uri.parse('https://api.calorieninjas.com/v1/nutrition?query=$query');
    try {
      var response = await http.get(url, headers: {'X-Api-Key': apiKey});
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List items = data['items'];
        
        double toplamKalori = 0;
        double toplamProtein = 0;
        double toplamYag = 0;
        double toplamKarb = 0;

        for (var item in items) {
          toplamKalori += item['calories'];
          toplamProtein += item['protein_g'];
          toplamYag += item['fat_total_g'];
          toplamKarb += item['carbohydrates_total_g'];
        }

        // PORSİYON BÖLÜCÜ
        int porsiyon = 3;

        setState(() {
          besinDegerleri = {
            "kalori": toplamKalori / porsiyon,
            "protein": toplamProtein / porsiyon,
            "yag": toplamYag / porsiyon,
            "karb": toplamKarb / porsiyon,
          };
          besinYukleniyor = false;
        });
      } else {
        setState(() => besinYukleniyor = false);
        print("API Hata: ${response.body}");
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
      setState(() => besinYukleniyor = false);
    }
  }

  void paylas() {
    if (detay != null) {
      String malzemeListesiStr = turkceMalzemeler.map((m) => "• $m").join("\n");
      Share.share("🍽️ *Cebimdeki Şef* - $turkceIsim\n\n🛒 *Malzemeler:*\n$malzemeListesiStr\n\n📖 *Tarifi:* $turkceTarif\n\n📸 $turkceIsim");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(detay!['strMealThumb'], fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: paylas),
                    IconButton(
                      icon: Icon(favoriMi ? Icons.favorite : Icons.favorite_border, color: favoriMi ? Colors.red : Colors.white),
                      onPressed: favoriDegistir,
                    )
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(turkceIsim, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2)),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 10,
                          children: [
                            Chip(label: Text(detay!['strCategory']), backgroundColor: Colors.orange.shade50, labelStyle: TextStyle(color: Colors.deepOrange.shade700, fontWeight: FontWeight.bold), side: BorderSide.none),
                            Chip(label: Text(detay!['strArea']), backgroundColor: Colors.blue.shade50, labelStyle: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold), side: BorderSide.none),
                          ],
                        ),
                        const SizedBox(height: 30),

                        //BESİN ANALİZ KISMI
                        besinDegerleri == null
                        ? InkWell(
                            onTap: besinYukleniyor ? null : besinDegerleriniAnalizEt,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  besinYukleniyor 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.analytics_outlined, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                                    besinYukleniyor ? "Hesaplanıyor..." : "Besin Değerlerini Analiz Et", 
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                const Text("Ortalama Porsiyon Değeri", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _besinKutusu(Icons.local_fire_department, "Kalori", "${besinDegerleri!['kalori'].toStringAsFixed(0)}", Colors.orange),
                                    _besinKutusu(Icons.fitness_center, "Protein", "${besinDegerleri!['protein'].toStringAsFixed(1)}g", Colors.blue),
                                    _besinKutusu(Icons.opacity, "Yağ", "${besinDegerleri!['yag'].toStringAsFixed(1)}g", Colors.red),
                                    _besinKutusu(Icons.grain, "Karb", "${besinDegerleri!['karb'].toStringAsFixed(1)}g", Colors.brown),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 30),
                        const Text("Gerekli Malzemeler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Column(
                          children: List.generate(turkceMalzemeler.length, (index) {
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: malzemeKontrol[index],
                              onChanged: (val) { setState(() { malzemeKontrol[index] = val!; }); },
                              title: Text(turkceMalzemeler[index], style: TextStyle(fontSize: 15, decoration: malzemeKontrol[index] ? TextDecoration.lineThrough : null, color: malzemeKontrol[index] ? Colors.grey : Colors.black87)),
                              activeColor: Colors.green,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }),
                        ),
                        const SizedBox(height: 30),
                        const Text("Hazırlanışı", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(turkceTarif, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                        const SizedBox(height: 40),
                        
                        if (benzerYemekler.isNotEmpty) ...[
                          const Divider(),
                          const SizedBox(height: 20),
                          const Text("Bunları da Sevebilirsin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          SizedBox(height: 160, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: benzerYemekler.length, itemBuilder: (context, index) {
                            var benzer = benzerYemekler[index];
                            if (benzer['idMeal'] == widget.id) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetaySayfasi(id: benzer['idMeal']))),
                              child: Container(
                                width: 120, margin: const EdgeInsets.only(right: 15), 
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(benzer['strMealThumb'], height: 100, width: 120, fit: BoxFit.cover)),
                                    const SizedBox(height: 5),
                                    Text(benzer['strMeal'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                                  ],
                                ),
                              ),
                            );
                          })),
                        ],
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _besinKutusu(IconData ikon, String baslik, String deger, Color renk) {
    return Column(
      children: [
        Icon(ikon, color: renk, size: 24),
        const SizedBox(height: 5),
        Text(deger, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(baslik, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
