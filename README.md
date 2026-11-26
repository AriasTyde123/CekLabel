# CekLabel

## 1. Deskripsi Masalah
Banyak konsumen—terutama penderita alergi, pelaku diet khusus, dan orang tua yang menjaga asupan anak—kesulitan memahami label komposisi makanan di supermarket. Istilah kimia yang rumit (seperti *maltodekstrin*, *tartrazin*, atau *E621*), nama samaran gula/alergen, serta peringatan kecil kontaminasi silang sering kali membuat konsumen tidak sadar mengonsumsi bahan yang berbahaya bagi mereka. Membaca dan mencari arti setiap bahan secara manual saat berbelanja sangat memakan waktu.

## 2. Profil Target Pengguna
* **Individu dengan Alergi/Intoleransi:** Pengguna yang harus menghindari alergen spesifik (kacang, susu, gluten, telur, seafood, kedelai) baik tingkat ringan maupun berat (anafilaksis).
* **Konsumen Sadar Kesehatan & Diet Khusus:** Pengguna yang membatasi gula tersembunyi, MSG, pewarna sintetis, atau memerlukan filter bahan syubhat/non-halal.
* **Orang Tua / Keluarga:** Pengguna yang perlu mengecek keamanan satu produk makanan sekaligus untuk beberapa anggota keluarga dengan profil alergi berbeda.

## 3. Manfaat Aplikasi
* **Analisis Cerdas Berbasis AI:** Memahami variasi nama bahan, memperbaiki *typo* hasil OCR kamera, dan mendeteksi konteks kalimat peringatan kontaminasi silang secara akurat.
* **Keputusan Instan di Lorong Supermarket:** Indikator warna Lampu Lalu Lintas (Hijau/Kuning/Merah) memberi sinyal keamanan produk dalam hitungan detik.
* **Tetap Aman Saat Sinyal Hilang (Offline Fallback):** Jika internet putus di dalam supermarket, aplikasi otomatis beralih ke mesin deteksi lokal, dan **Kartu Darurat Alergi** selalu tersedia tanpa koneksi.

## 4. Daftar Fitur Utama
1. **Multi-Profil Keluarga & Pengaturan Alergi:**
   * Membuat, mengubah, menghapus, dan mengaktifkan beberapa profil sekaligus (misal: *Anak - Alergi Susu*, *Ayah - Rendah Gula*).
   * Pengaturan **Tingkat Sensitivitas** (*Intoleransi Ringan* vs *Alergi Berat/Anafilaksis*).
   * Filter tambahan: *Hindari Gula Tersembunyi*, *Hindari MSG & Pewarna Sintetis*, dan *Filter Bahan Syubhat / Non-Halal*.
2. **Pemindai Komposisi Hybrid (OCR + AI Online / Fallback Offline):**
   * Ekstraksi teks komposisi menggunakan Google ML Kit (kamera atau galeri).
   * **Saat Online:** Teks dianalisis oleh **Gemini AI** untuk hasil lebih akurat dan penjelasan dinamis bagi bahan asing/baru.
   * **Saat Offline:** Otomatis beralih ke pencocokan kamus lokal (`assets/ingredients.json`) dengan penanda `"Mode Offline"`.
3. **Analisis Hasil Scan & Sistem Lampu Lalu Lintas:**
   * Banner status instan: **AMAN** (Hijau), **WASPADA** (Kuning), atau **TIDAK AMAN** (Merah).
   * Ringkasan dampak per anggota keluarga yang aktif.
   * **Deteksi Kontaminasi Silang (*May Contain*):** Mengenali frasa peringatan seperti *"diproduksi di fasilitas yang sama dengan..."* dan otomatis menaikkan status menjadi Bahaya untuk profil dengan *Alergi Berat*.
4. **Kamus "Bahasa Manusia" (Bottom Sheet & Pencarian Manual):**
   * Klik *chip* bahan mana pun pada hasil *scan* untuk membuka *Bottom Sheet* berisi arti singkat, kategori, tingkat risiko, dan nama lain (*alias*).
   * Halaman pencarian manual kamus lokal untuk mengecek bahan tanpa memindai.
5. **Riwayat Scan (*Recent Scans*) & Daftar Aman (*Safe List*):**
   * Menyimpan riwayat hasil pindaian terakhir secara lokal di perangkat.
   * Fitur *bookmark* produk aman ke **Daftar Aman** agar tidak perlu memindai ulang saat belanja bulanan.
6. **Kartu Darurat Alergi (*Emergency Allergy Card*):**
   * Layar kontras tinggi dan teks besar yang selalu dapat dibuka secara *offline*, menampilkan daftar alergi profil aktif dengan *toggle* Bahasa Indonesia / Inggris.

## 5. Fitur yang Tidak Dikerjakan (Out of Scope)
* **Pemindai Barcode Produk:** Fokus murni pada pemindaian teks komposisi (OCR + AI).
* **Backend Database & Login/Autentikasi:** Seluruh data pribadi (profil, riwayat, daftar aman) disimpan privat di perangkat tanpa akun.
* **Rekomendasi Produk (*Smart Swap*) Berbasis Katalog Online & Fitur Sosial Media.**

## 6. Kriteria Aplikasi Dinyatakan Berhasil
1. Seluruh fitur dan tombol di UI berfungsi penuh tanpa *crash* maupun tombol mati (*zero dead UI*).
2. Saat *online*, Gemini AI berhasil menganalisis hasil OCR dan mengembalikan status Lampu Lalu Lintas, dampak Multi-Profil, dan penjelasan bahan dalam format terstruktur.
3. Saat *offline* (Mode Pesawat), aplikasi tetap dapat memindai dengan *fallback* lokal, membuka Riwayat/Daftar Aman, dan menampilkan Kartu Darurat Alergi tanpa *crash*.
4. Profil keluarga, riwayat scan, dan daftar aman tetap tersimpan setelah aplikasi ditutup dan dibuka kembali.

## 7. Panduan Menjalankan Aplikasi

### Prasyarat Sistem
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi >= 3.0.0 dengan Dart 3)
* [Android Studio](https://developer.android.com/studio) dengan Android SDK & Emulator (API 30+, disarankan API 34)
* **Gemini API Key** (opsional untuk pengujian *offline*, wajib untuk mode *AI Online*)

### Langkah Instalasi & Menjalankan
1. **Clone repository dan masuk ke direktori proyek:**
   ```bash
   git clone <URL_REPOSITORY>
   cd CekLabel