## Purpose:
Help consumers (especially people with allergies, special diets, and parents) understand food composition labels in seconds. The application scans composition label text via on-device OCR only when the user presses a button, matches it against a local ingredient dictionary, and shows allergen & hidden-sugar warnings plus layman explanations on a result screen. No backend, no login, no barcode.

Adapted from the planning template structure, but fully adjusted to `README.md` (MVP 12 pertemuan) and `AGENTS.md` (Senior Expert Flutter & Dart, offline-first, provider, local-only).

## Use this stack:

* Framework: Flutter + Dart (Null Safety strict)
* State Management: `provider` only
* OCR Engine: `google_mlkit_text_recognition`
* Local Storage: `shared_preferences` for user preferences
* Local Dictionary: bundled asset JSON (`assets/ingredients.json`)
* UI: Material Design 3 (`useMaterial3: true`)
* No Firebase, No Supabase, No MySQL, No external backend API
* Code comments and variable/function names in English, all user-facing UI text in Indonesian

Add to `pubspec.yaml` (planned final):
```yaml
dependencies:
  provider: ^6.1.2
  shared_preferences: ^2.3.2
  google_mlkit_text_recognition: ^0.13.0
  image_picker: ^1.0.0
  camera: ^0.10.0 (optional, if custom camera screen is needed)

flutter:
  assets:
    - assets/ingredients.json
```

## Code rules:

* Do not add comments unless truly necessary.
* Use PascalCase for all classes, enums, models, DTOs, providers, services, screens, and widgets. Example: `ScanResult`, `RiskLevel`, `ScanProvider`, `DetectionService`, `ScanResultScreen`.
* Local variables, function parameters, and file names may use camelCase / snake_case following Dart conventions.
* Keep code lines below 150 characters where practical.
* Use a clean and simple folder structure (see Project structure).
* Do not add authentication. No login/register. App is directly usable.
* Separation of Concerns (mandatory per `AGENTS.md`):
  * NEVER mix business logic or ML processing into `lib/screens/` or `lib/widgets/`.
  * OCR processing logic must live in `lib/services/`.
  * Preference state and scan-result state must live in `lib/providers/`.
  * Complex widgets must be extracted as separate stateless widgets in `lib/widgets/` (avoid deep nesting / spaghetti code).
* Error handling:
  * Always wrap Camera / File System / JSON parsing in `try-catch`.
  * Always show visual feedback (`CircularProgressIndicator`, error message in Indonesian, empty state) if OCR fails or dictionary fails to load.

## Main entities:

### 1. Ingredient
Dictionary entry from `assets/ingredients.json`.

* Id: `String` (slug, e.g. `maltodekstrin`, `tartrazin`, `e621`)
* Name: `String` (canonical chemical / label name)
* Aliases: `List<String>` (hidden names, e.g. gula -> `sukrosa`, `sirup jagung tinggi fruktosa`, `dekstrosa`)
* Category: `IngredientCategory` (`sugarAlias`, `allergen`, `additive`, `preservative`, `coloring`, `sweetener`, `other`)
* AllergenGroup: `String?` (e.g. `Kacang`, `Susu`, `Gluten`, `Telur`, `Udang`, `Kedelai`, null if not allergen)
* Description: `String` (explanation in plain Indonesian / bahasa awam)
* RiskLevelDefault: `RiskLevel` (`danger`, `caution`, `safe`)

### 2. AllergenPreference
Already implemented in `lib/models/allergen_preference.dart`. Keep as-is.

* UserName: `String`
* SelectedAllergens: `Set<String>` (subset of `availableAllergens`: Kacang, Susu, Gluten, Telur, Udang, Kedelai)
* Stored in `shared_preferences` via keys `preference_user_name`, `preference_allergens`

### 3. DetectedIngredient
Result of matching one dictionary entry against OCR text.

* IngredientId: `String`
* MatchedKeyword: `String` (actual substring found in scan text)
* Category: `IngredientCategory`
* RiskLevel: `RiskLevel` (escalated to `danger` if `AllergenGroup` is in user `SelectedAllergens`)
* Description: `String` (copied from `Ingredient` for display)

### 4. ScanResult
In-memory result of one scan session (not persisted to disk in MVP, only held in provider).

* Id: `String` (timestamp-based UUID)
* RawText: `String` (full OCR output)
* DetectedIngredients: `List<DetectedIngredient>`
* DangerCount: `int`
* CautionCount: `int`
* SafeCount: `int`
* ScannedAt: `DateTime`
* CreatedAt: `DateTime`

### 5. RiskLevel (enum)
Adapted from `ActivityStatus` in the template.

* `danger`: matches user-selected allergen -> red badge. Must trigger warning < 5 seconds after scan.
* `caution`: hidden sugar / additive / preservative, not in user allergen list -> yellow/orange badge.
* `safe`: detected but low risk, or no match -> green badge.

```dart
enum RiskLevel { danger, caution, safe }
enum IngredientCategory { sugarAlias, allergen, additive, preservative, coloring, sweetener, other }
enum PreferenceStatus { initial, loading, loaded, saving, success, error }
enum ScanStatus { initial, pickingImage, recognizing, analyzing, success, error }
```

## Local storage rules (adapted from Database rules):

* `ScanResult` is unique by `Id` in memory only. Never persist scan history to disk in MVP.
* Never call network during scan or dashboard open. OCR + matching must run 100% on-device (OFFLINE-FIRST).
* Never delete or overwrite `assets/ingredients.json` at runtime. It is read-only bundled asset.
* When OCR text is analyzed again, re-run case-insensitive substring / token matching against the already-loaded dictionary. Do not mutate dictionary entries.
* After successful preference save, persist only via `PreferenceService` (`shared_preferences`). Keys must remain `preference_user_name` and `preference_allergens`.
* Use `try-catch` + typed failures (`PreferenceLoadFailure`, `PreferenceSaveFailure`, `OcrFailure`, `DictionaryLoadFailure`) for all storage / camera / JSON operations.
* Seed dictionary with minimum viable entries covering: 6 allergen groups (Kacang, Susu, Gluten, Telur, Udang, Kedelai) + ~20 sugar aliases (sukrosa, glukosa, fruktosa, maltodekstrin, dekstrosa, sirup jagung, aspartam, sakarin, siklamat, sorbitol, dll) + common additives (tartrazin, E621/MSG, natrium benzoat, dll).

Example `assets/ingredients.json` entry:
```json
{
  "id": "maltodekstrin",
  "name": "Maltodekstrin",
  "aliases": ["maltodextrin", "dekstrin"],
  "category": "sugarAlias",
  "allergenGroup": "Gluten",
  "description": "Gula tersembunyi dari pati (biasanya jagung/gandum). Cepat menaikkan gula darah.",
  "riskLevelDefault": "caution"
}
```

## App features (adapted from Backend features):

### 1. CRUD Preference (Pengaturan Preferensi Pengguna - Lokal)
Already implemented via `PreferenceService` + `PreferenceProvider`. Keep.

* Load, update user name, toggle allergen, validate (name >= 3 chars, min 1 allergen), save to `shared_preferences`.
* Validation messages in Indonesian: `Nama wajib diisi`, `Nama minimal 3 karakter`, `Pilih minimal 1 alergen`.

### 2. OCR Text Scanner (Kamera Pemindai Teks)
New. Lives in `lib/services/ocr_service.dart`, state in `lib/providers/scan_provider.dart`.

* Triggered only by button click (`Ambil Foto` / `Pilih dari Galeri`). Never auto-scan on screen open.
* Pick image via `image_picker`, run `google_mlkit_text_recognition`, return `RawText`.
* Parse and normalize text (lowercase, trim) before detection.
* Handle failures first: camera permission denied, blurry/empty image, ML Kit unavailable -> show Indonesian error.
* Return result containing:
  * ScanId
  * RawTextLength
  * DetectedCount
  * DangerCount
  * CautionCount
  * ScannedAt
  * Message (e.g. `Ditemukan 3 bahan berisiko`, `Tidak ada bahan berisiko terdeteksi`)
* Target: >= 80% readable text extracted, warning shown < 5 seconds after detection.

### 3. Keyword Detection System (Sistem Deteksi Kata Kunci)
New. Lives in `lib/services/detection_service.dart` + `lib/services/dictionary_service.dart`.

* Load `assets/ingredients.json` once at startup via `rootBundle`.
* Case-insensitive matching of `Name` + `Aliases` against `RawText`.
* Escalation rule: if `AllergenGroup` in `SelectedAllergens` -> `RiskLevel.danger` regardless of default.
* Else if `Category == sugarAlias/additive/preservative/coloring` -> `RiskLevel.caution`.
* Else -> `RiskLevel.safe`.
* Sort output: `danger` first, then `caution`, then `safe`.
* Never mutate dictionary. Insert only new `DetectedIngredient` entries per scan.

### 4. Mini Dictionary (Kamus Mini Komposisi)
New. Lives in `lib/providers/dictionary_provider.dart`.

* Manual search screen: user types keyword without scanning.
* Live filter by `Name` / `Aliases` / `Description`.
* Show category badge + layman description.
* Empty state in Indonesian: `Tidak ditemukan. Coba kata kunci lain.`

### 5. Warning Summary (Ringkasan Hasil - adapted from Dashboard API)
Computed in `ScanProvider`, not a backend API.

* Return scan summary:
  * TotalDetected
  * DangerCount
  * CautionCount
  * HasUserAllergen (bool)
  * TopRisks (first 3 danger items)
* Return per-ingredient display data:
  * IngredientName
  * MatchedKeyword
  * CategoryLabel
  * RiskLevel
  * Description
* RiskLevel rules:
  * `danger`: allergen group matches user preference
  * `caution`: sugar alias / additive without direct allergen match
  * `safe`: low-risk or informational only

## Screens (adapted from Frontend pages):

### 1. Home Screen (`lib/screens/home_screen.dart`)
* App title + short onboarding text.
* Summary cards: total dictionary entries, active allergen preferences, last scan summary.
* Buttons: `Pindai Label`, `Cari Bahan`, `Atur Preferensi`.
* Shows loading state while dictionary loads, error message if load fails.
* Home reads only from local asset + `shared_preferences` when opened. Must not call network or camera automatically.

### 2. Scanner Screen (`lib/screens/scan_screen.dart`)
* Preview placeholder + buttons `Ambil Foto` / `Pilih dari Galeri`.
* Loading indicator during `recognizing` / `analyzing`.
* On success navigate to `ScanResultScreen`. On failure show Indonesian error + `Coba Lagi`.

### 3. Scan Result Screen (`lib/screens/scan_result_screen.dart`)
* Red banner if `DangerCount > 0` containing user allergen (`Awas! Mengandung Kacang`), yellow banner if only caution, green banner if safe.
* Table/list of each detected ingredient: name, matched keyword, category badge, risk badge, layman description.
* Expandable `Lihat Teks Asli` for raw OCR output.
* Button: `Pindai Lagi`.

### 4. Dictionary Screen (`lib/screens/dictionary_screen.dart`)
* Search field (`Cari bahan...`, e.g. `maltodekstrin`, `tartrazin`, `E621`).
* List of ingredients with category + risk badges.
* Detail bottom-sheet / detail screen with full layman explanation.
* Show ingredient count.

### 5. Preference Screen (`lib/screens/preference_screen.dart`)
Already implemented. Keep + polish.

* Form: user name field + allergen checklist (`AllergenCheckbox`, `PreferenceForm` widgets already exist).
* Validation + save button (`Simpan`).
* Show success snackbar (`Preferensi tersimpan`) and error message (`Gagal menyimpan preferensi. Coba lagi.`).
* Confirmation not needed for save; add reset button with confirmation dialog if implemented.

## UI requirements:

* Use Indonesian language for all labels, buttons, messages, and validation. Examples: `Pindai Label`, `Ambil Foto`, `Cari Bahan`, `Awas! Mengandung Alergen`, `Kemungkinan Mengandung Gula Tersembunyi`, `Aman`, `Lihat Teks Asli`, `Pindai Lagi`, `Simpan`.
* Create a clean, responsive mobile layout (works on small phones + emulator).
* Use simple lists, cards, badges, forms, confirmation dialog before destructive actions, loading indicators, and empty states.
* Use status badge colors:
  * Danger (allergen match): red (`Colors.red`)
  * Caution (hidden sugar / additive): orange/yellow (`Colors.orange` / `Colors.amber`)
  * Safe: green (`Colors.green`)
* Do not add charts in the first version.
* Use Material Design 3 components only. No custom design system in MVP.

## Required app routes (adapted from Required API routes):

Use named routes in `MaterialApp` (planned final):

* `/home` -> `HomeScreen` (list summary + navigation hub)
* `/scan` -> `ScanScreen` (camera / gallery + OCR trigger)
* `/scan/result` -> `ScanResultScreen` (arguments: `ScanResult`)
* `/dictionary` -> `DictionaryScreen`
* `/dictionary/detail` -> `IngredientDetailScreen` (arguments: `IngredientId`)
* `/preferences` -> `PreferenceScreen` (form + save)

Route rules:
* `/scan/result` must only be reachable after a successful scan. Direct navigation with empty result shows empty state.
* `/home` must not trigger camera or OCR on open.
* All routes must handle back navigation gracefully (no crash on Android back button).

## Deliverables:

* Complete Flutter source code (`lib/`, `assets/`, `test/`).
* `assets/ingredients.json` dictionary + seed entries (allergen groups + sugar aliases + additives).
* `pubspec.yaml` with `provider`, `shared_preferences`, `google_mlkit_text_recognition`, `image_picker`.
* README with: installation (`flutter pub get`), how to run (`flutter run`), emulator setup, camera permission setup (Android `AndroidManifest.xml`), how to update `ingredients.json`, and offline-first notes.
* Ensure the app builds successfully (`flutter analyze` clean, `flutter build apk` succeeds) and manual scan + detection + preference save work on Android emulator / device.
* Success criteria per `README.md`:
  1. Runs without crash on Android (or emulator).
  2. OCR extracts >= 80% readable text from clear label photo.
  3. Allergen match shows red popup/warning < 5 seconds.
  4. Clean separation between UI and scanner logic.

## Project structure:

* Single Flutter package (no monorepo, no npm workspaces - mobile only, offline-first).
* Structure (planned final, `*` = already exists):

```text
ceklabel/
  assets/
    ingredients.json
  lib/
    main.dart (*)               # MaterialApp, MultiProvider, routes, ThemeData M3
    models/
      allergen_preference.dart (*)  # AllergenPreference
      ingredient.dart           # Ingredient + IngredientCategory
      detected_ingredient.dart  # DetectedIngredient
      scan_result.dart          # ScanResult
      risk_level.dart           # RiskLevel enum
    services/
      preference_service.dart (*)   # shared_preferences load/save
      dictionary_service.dart   # load + parse ingredients.json
      ocr_service.dart          # google_mlkit_text_recognition wrapper
      detection_service.dart    # text matching + risk escalation
    providers/
      preference_provider.dart (*)  # PreferenceStatus + validation + save
      preference_status.dart (*)    # PreferenceStatus enum
      scan_provider.dart        # ScanStatus + RawText + ScanResult
      dictionary_provider.dart  # search query + filtered list
    screens/
      home_screen.dart
      scan_screen.dart
      scan_result_screen.dart
      dictionary_screen.dart
      ingredient_detail_screen.dart
      preference_screen.dart (*)
    widgets/
      allergen_checkbox.dart (*)
      preference_form.dart (*)
      risk_badge.dart           # red/yellow/green badge by RiskLevel
      ingredient_card.dart      # dictionary + result list item
      warning_banner.dart       # red/yellow/green header
      empty_state.dart          # reusable empty + error state
      loading_indicator.dart    # reusable loading
  test/
    detection_service_test.dart
    preference_provider_test.dart
    dictionary_service_test.dart
```

## Shared model requirements (adapted from Shared package requirements):

* There is no `packages/shared` (Flutter single-package). Instead `lib/models/` is the single source of truth.
* Store all shared domain models and enums here. Both `lib/providers/` and `lib/services/` and `lib/screens/` must import from `lib/models/`.
* Do not duplicate model definitions between providers and services.

Example model files:

```text
lib/models/
  ingredient.dart
  detected_ingredient.dart
  scan_result.dart
  allergen_preference.dart
  risk_level.dart
```

## Model rules:

* Define shared Dart classes / enums only once in `lib/models/`.
* Example: `Ingredient`, `DetectedIngredient`, `ScanResult`, and `RiskLevel` must be imported by both providers and services from `lib/models/`.
* JSON parsing stays in services (`dictionary_service.dart` maps raw JSON -> `Ingredient`). Providers and screens must never parse JSON directly.
* Screens must not import `shared_preferences`, `image_picker`, or `google_mlkit_text_recognition` directly. All platform/ML access goes through services.
* Configure `flutter.assets` and `provider` wiring (`MultiProvider` in `main.dart`) correctly so the app compiles and runs offline.

## Out of Scope (must NOT be built in MVP):

* Barcode scanner (text OCR only).
* Online database / external API / backend server.
* Login / authentication.
* Social share / community features.
* Charts / analytics dashboard.
* iOS-specific optimization beyond default Flutter build (focus Android).

## Manual test checklist (definition of done):

1. Fresh install -> open app -> set name + check `Kacang` + `Susu` -> `Simpan` -> reopen app -> preferences persist.
2. `Pindai Label` -> photo of label containing `susu bubuk` -> red danger banner appears < 5s.
3. `Pindai Label` -> photo containing `maltodekstrin` without allergen match -> yellow caution banner.
4. `Cari Bahan` -> type `E621` -> shows MSG explanation in plain Indonesian.
5. Airplane mode ON -> all 4 flows above still work (offline-first proof).
6. `flutter analyze` passes, no crash on back navigation, no network permission required.
