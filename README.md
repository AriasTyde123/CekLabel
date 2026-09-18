# CekLabel

## 1. Deskripsi Masalah
Banyak konsumen, terutama mereka yang memiliki alergi, diet khusus, atau orang tua yang peduli dengan kesehatan anak, kesulitan memahami label komposisi makanan. Istilah kimia yang rumit (seperti *maltodekstrin*, *tartrazin*, atau E621) dan nama samaran untuk gula atau alergen sering kali membuat konsumen tidak sadar mengonsumsi bahan yang sebenarnya ingin mereka hindari. Membaca dan mencari tahu arti setiap bahan secara manual saat berbelanja sangat memakan waktu.

## 2. Profil Target Pengguna
* **Individu dengan Alergi/Intoleransi:** Orang yang harus menghindari bahan spesifik (misal: gluten, kacang, susu).
* **Konsumen Sadar Kesehatan:** Orang yang sedang menjalani diet tertentu (mengurangi gula, menghindari pengawet buatan).
* **Orang Tua:** Ibu atau ayah yang ingin memastikan jajanan atau bahan makanan yang dibeli aman untuk anak-anak mereka.

## 3. Manfaat Aplikasi
* **Efisiensi Waktu:** Memungkinkan pengguna mengenali bahan berbahaya atau tidak sehat dalam hitungan detik saat berbelanja.
* **Pencegahan Risiko:** Membantu mencegah reaksi alergi yang tidak diinginkan karena ketidaktahuan membaca label.
* **Edukasi Praktis:** Memberikan pemahaman instan tentang apa arti sebenarnya dari kode kimia pada kemasan makanan menggunakan bahasa awam.

## 4. Daftar Fitur Inti (Skala 12 Pertemuan)
Mengingat batas waktu pengembangan selama 12 pertemuan, fokus pengerjaan akan dibatasi pada *Minimum Viable Product* (MVP):
1. **Kamera Pemindai Teks (OCR):** Fitur untuk mengambil foto label komposisi dan mengekstrak teksnya menggunakan Google ML Kit.
2. **Sistem Deteksi Kata Kunci:** Logika pencocokan teks hasil pindaian dengan basis data lokal.
3. **Peringatan Alergen & Gula:** Indikator visual (warna merah/kuning) jika terdeteksi bahan penyebab alergi atau gula tersembunyi.
4. **Kamus Mini Komposisi:** Halaman pencarian manual bagi pengguna yang ingin mengetik dan mencari arti bahan tertentu tanpa memindai.
5. **Pengaturan Preferensi Pengguna (Lokal):** Pengguna dapat memilih alergen apa yang ingin diwaspadai (misal: centang "Kacang" dan "Susu"), disimpan secara lokal (tanpa server).

## 5. Fitur yang Tidak Dikerjakan (Out of Scope)
Untuk menjaga agar proyek realistis selesai tepat waktu, fitur berikut **tidak** akan dikerjakan pada fase ini:
* **Pemindai Barcode Produk:** Aplikasi murni berfokus membaca teks komposisi (OCR), bukan mencari database produk dari *barcode*.
* **Integrasi Database Online / API Eksternal:** Kamus bahan akan disimpan di dalam aplikasi (*local database/hardcoded*) agar tidak memerlukan pembuatan *backend* dan *server* terpisah.
* **Fitur Login / Autentikasi:** Aplikasi dapat langsung digunakan tanpa perlu mendaftar akun (data disimpan di memori perangkat).
* **Fitur Berbagi Sosial Media / Komunitas.**

## 6. Kriteria Aplikasi Dinyatakan Berhasil
1. Aplikasi dapat berjalan tanpa *crash* di perangkat Android (atau emulator).
2. Fitur kamera berhasil mengambil gambar label yang jelas dan sistem OCR mampu mengekstrak minimal 80% teks yang dapat terbaca.
3. Saat hasil teks mengandung salah satu bahan yang ada dalam daftar preferensi alergi pengguna, aplikasi berhasil memunculkan pop-up atau peringatan warna merah dalam waktu kurang dari 5 detik.
4. Kode aplikasi tersusun rapi dengan pemisahan antara antarmuka (UI) dan logika pemindai.
