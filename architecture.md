```markdown
## Purpose
CekLabel membantu konsumen (penderita alergi, pelaku diet khusus, dan orang tua) memahami label komposisi makanan dalam hitungan detik. Aplikasi memindai teks komposisi melalui OCR lokal (*on-device*) saat pengguna menekan tombol pindai, mengevaluasinya terhadap **Multi-Profil Keluarga** yang aktif (termasuk tingkat sensitivitas, kontaminasi silang, gula tersembunyi, aditif, dan filter syubhat/non-halal), menampilkan status **Lampu Lalu Lintas**, menyediakan *Bottom Sheet* kamus bahasa awam, serta menyimpan Riwayat Scan dan Daftar Aman secara lokal. Tanpa backend, tanpa login, tanpa barcode.

## Tech Stack
* **Framework:** Flutter + Dart (Strict Null Safety)
* **State Management:** `provider` only
* **OCR Engine:** `google_mlkit_text_recognition`
* **Image Acquisition:** `image_picker` (camera & gallery; `camera` optional for custom viewfinder overlay)
* **Local Persistence:** `shared_preferences` (JSON-serialized lists for profiles, scan history, and safe list)
* **Local Dictionary:** Bundled read-only asset `assets/ingredients.json`
* **UI:** Material Design 3 (`useMaterial3: true`), palette: Background `#F8FAFC`, Primary Emerald `#10B981`, Danger `#EF4444`, Caution `#F59E0B`, Safe `#10B981`
* **Forbidden:** Firebase, Supabase, MySQL, external REST APIs, Login/Auth, Barcode scanner

Target `pubspec.yaml`:
```yaml
dependencies:
  provider: ^6.1.2
  shared_preferences: ^2.3.2
  google_mlkit_text_recognition: ^0.13.0
  image_picker: ^1.0.0

flutter:
  assets:
    - assets/ingredients.json