abstract class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileLoadFailure extends AppFailure {
  const ProfileLoadFailure([super.message = 'Gagal memuat profil keluarga.']);
}

class ProfileSaveFailure extends AppFailure {
  const ProfileSaveFailure([super.message = 'Gagal menyimpan profil. Coba lagi.']);
}

class HistoryFailure extends AppFailure {
  const HistoryFailure([super.message = 'Gagal menyimpan riwayat pindaian.']);
}

class OcrFailure extends AppFailure {
  const OcrFailure([super.message = 'Gagal membaca teks dari gambar. Coba lagi.']);
}

class CameraFailure extends AppFailure {
  const CameraFailure([super.message = 'Kamera tidak dapat dibuka. Periksa izin kamera atau gunakan galeri.']);
}

class DictionaryLoadFailure extends AppFailure {
  const DictionaryLoadFailure([super.message = 'Gagal memuat kamus bahan.']);
}

class AiFailure extends AppFailure {
  const AiFailure([super.message = 'Layanan AI tidak tersedia.']);
}
