# 👨‍🍳 Cebimdeki Şef (Pocket Chef)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![API](https://img.shields.io/badge/API-Integration-green?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)

**Cebimdeki Şef**, kullanıcıların dünya mutfağından binlerce tarife ulaşmasını sağlayan, bu tarifleri anlık olarak Türkçeye çeviren ve yapay zeka destekli besin analizi sunan modern bir mobil uygulamadır.

<p align="center">
  <img src="assets/icon.png" width="100" height="100" />
</p>

## 🚀 Özellikler

Bu uygulama sadece veri çekip gösteren bir arayüz değildir; arkasında karmaşık algoritmalar ve çoklu API entegrasyonu barındırır.

* **🌍 Çoklu API Mimarisi:** `TheMealDB` (Tarifler), `CalorieNinjas` (Besin Analizi) ve `Google Translate` servislerinin senkronize çalışması.
* **🇹🇷 Anlık Yerelleştirme:** İngilizce gelen tüm veri setlerinin (Tarif, Malzemeler, Başlıklar) uygulama içinde anlık olarak Türkçeye çevrilmesi.
* **🥗 NutriChef Analizi:** Seçilen yemeğin malzemelerini analiz eden, porsiyon hesabı yapan ve Kalori/Protein/Karbonhidrat değerlerini sunan akıllı algoritma.
* **🎲 Akıllı Öneri Sistemi:** Kullanıcının kararsız kaldığı anlarda kategori bazlı (Tatlı/Yemek) rastgele tarif öneren "Şansına Güven" modülü.
* **❤️ Yerel Veritabanı:** `Shared Preferences` kullanılarak favori yemeklerin kalıcı hafızada saklanması.
* **🎨 Modern UI/UX:** `Google Fonts (Poppins)` tipografisi, Hero animasyonları, Splash Screen ve kullanıcı dostu geçişler.
* **🛠️ Hata Yönetimi (Error Handling):** API kesintileri veya veri uyuşmazlıkları için geliştirilmiş "Fallback" mekanizmaları.

## 🛠️ Kullanılan Teknolojiler ve Paketler

* **Framework:** Flutter (Dart)
* **HTTP Requests:** `http` - REST API haberleşmesi için.
* **Localization:** `translator` - Dinamik metin çevirisi için.
* **Local Storage:** `shared_preferences` - Favori işlemleri için.
* **UI/Design:** `google_fonts`, `flutter_native_splash`, `flutter_launcher_icons`.
* **Utilities:** `share_plus` - Tarif paylaşımı için.

## 🧠 Algoritma ve Mantık

Uygulamanın en kritik noktası **"Besin Değeri Analizi"** algoritmasıdır:

1.  **Veri Temizliği (Data Cleaning):** Tarif API'sinden gelen "pinch of salt", "to taste pepper" gibi belirsiz ifadeler RegEx (Düzenli İfadeler) ile temizlenir.
2.  **Standardizasyon:** Gramajı belli olmayan malzemelere varsayılan porsiyon değerleri atanır.
3.  **API İletişimi:** Temizlenen veri seti `CalorieNinjas` API'sine gönderilir.
4.  **Porsiyon Bölme:** Gelen toplam kalori değeri, yemeğin türüne göre ortalama porsiyon sayısına (3-4) bölünerek kullanıcıya "1 Tabak" değeri sunulur.

## ⬇️ Kurulum

Projeyi yerel makinenizde çalıştırmak için:

1.  Repoyu klonlayın:
    ```bash
    git clone [https://github.com/KULLANICI_ADIN/cebimdeki-sef.git](https://github.com/KULLANICI_ADIN/cebimdeki-sef.git)
    ```
2.  Proje dizinine gidin:
    ```bash
    cd cebimdeki-sef
    ```
3.  Paketleri yükleyin:
    ```bash
    flutter pub get
    ```
4.  Uygulamayı çalıştırın:
    ```bash
    flutter run
    ```

## 🔮 Gelecek Planları (Roadmap)

* [ ] Firebase Authentication ile kullanıcı girişi.
* [ ] Yapay zeka ile fotoğrafı çekilen malzemenin tanınması.
* [ ] Alışveriş listesi oluşturma modülü.

## 👨‍💻 Geliştirici

**[Senin Adın]** - *Cyber Security Student & Mobile Developer*

* GitHub: [@egnake](https://github.com/egnake)
* LinkedIn: [@egeparlak](https://www.linkedin.com/in/ege-parlak-7b860b332/)

---
*Bu proje, açık kaynak API'lerin mobil uygulamalara entegrasyonunu göstermek amacıyla geliştirilmiştir.*
