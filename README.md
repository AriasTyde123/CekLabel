# CekLabel (Food Ingredient Translator)

CekLabel adalah aplikasi *mobile* berbasis **Flutter** yang membantu pengguna membaca, menerjemahkan, dan memahami daftar komposisi pada kemasan makanan. Membantu Anda menghindari alergen, mengenali gula tersembunyi, dan membuat keputusan konsumsi yang lebih sehat.

## Fitur Utama

* **Pemindai Cerdas (OCR):** Cukup foto label komposisi makanan, aplikasi akan otomatis mengubahnya menjadi teks menggunakan teknologi *Text Recognition*.
* **Peringatan Alergen:** Berikan peringatan instan jika terdeteksi bahan yang berpotensi memicu alergi (seperti kacang, gluten, susu, dll).
* **Detektif Gula Tersembunyi:** Mengidentifikasi nama-nama samaran gula kimiawi (seperti *maltodekstrin*, *sirup jagung fruktosa tinggi*, dll).
* **Kamus Nutrisi Bahasa Awam:** Menerjemahkan istilah kimia atau kode pengawet (misal: E621) ke dalam bahasa sehari-hari yang mudah dipahami.
* **Lintas Platform:** Berjalan mulus di perangkat Android dan iOS.

## Teknologi yang Digunakan

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Text Recognition / OCR:** [Google ML Kit](https://developers.google.com/ml-kit) (direncanakan)
* **State Management:** Provider / Riverpod (sesuaikan dengan yang Anda pakai)

## Memulai Proyek (Getting Started)

Bagian ini memandu Anda untuk menjalankan proyek CekLabel di komputer lokal Anda.

### Prasyarat
Pastikan Anda sudah menginstal perangkat lunak berikut di komputer Anda:
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Android Studio atau VS Code
* Emulator Android / iOS Simulator (atau perangkat fisik yang dihubungkan dengan kabel data)

### Langkah-langkah Instalasi

1. **Clone repositori ini**
   ```bash
   git clone [https://github.com/username-anda/ceklabel.git](https://github.com/username-anda/ceklabel.git)
