abstract class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class PreferenceLoadFailure extends AppFailure {
  const PreferenceLoadFailure([super.message = 'Gagal memuat preferensi.']);
}

class PreferenceSaveFailure extends AppFailure {
  const PreferenceSaveFailure([super.message = 'Gagal menyimpan preferensi. Coba lagi.']);
}

class OcrFailure extends AppFailure {
  const OcrFailure([super.message = 'Gagal membaca teks dari gambar. Coba lagi.']);
}

class DictionaryLoadFailure extends AppFailure {
  const DictionaryLoadFailure([super.message = 'Gagal memuat kamus bahan.']);
}
