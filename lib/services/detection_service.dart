import '../models/cross_contamination.dart';
import '../models/detected_ingredient.dart';
import '../models/family_profile.dart';
import '../models/ingredient.dart';
import '../models/profile_impact.dart';
import '../models/risk_level.dart';
import '../models/scan_result.dart';

class DetectionService {
  /// Phrases that start a "may contain" / shared facility statement.
  static const List<String> crossContaminationTriggers = [
    'dapat mengandung',
    'mungkin mengandung',
    'bisa mengandung',
    'mengandung jejak',
    'diproduksi di fasilitas',
    'diproduksi pada fasilitas',
    'diproduksi dalam fasilitas',
    'diproduksi di pabrik',
    'diproduksi menggunakan mesin',
    'diproses di fasilitas',
    'diproses pada fasilitas',
    'dikemas di fasilitas',
    'fasilitas yang sama',
    'fasilitas yang juga',
    'may contain',
    'may also contain',
    'traces of',
    'produced in a facility',
    'manufactured in a facility',
    'manufactured on equipment',
    'processed in a facility',
  ];

  static final RegExp _sentenceSplitter = RegExp(r'[.;]');

  List<DetectedIngredient> detect({
    required String rawText,
    required List<Ingredient> dictionary,
    required Set<String> selectedAllergens,
    bool avoidSyubhat = false,
  }) {
    final text = _splitStatements(normalize(rawText)).direct;
    if (text.isEmpty) return const [];

    final results = <DetectedIngredient>[];
    for (final ingredient in dictionary) {
      final keyword = _findKeyword(text, ingredient);
      if (keyword == null) continue;
      final isNonHalal =
          ingredient.category == IngredientCategory.syubhat && ingredient.riskLevelDefault == RiskLevel.danger;
      results.add(DetectedIngredient(
        ingredientId: ingredient.id,
        ingredientName: ingredient.name,
        matchedKeyword: keyword,
        category: ingredient.category,
        allergenGroup: ingredient.allergenGroup,
        riskLevel: resolveRisk(
          ingredient.category,
          ingredient.allergenGroup,
          selectedAllergens,
          avoidSyubhat: avoidSyubhat,
          isNonHalal: isNonHalal,
        ),
        description: ingredient.description,
        isNonHalal: isNonHalal,
      ));
    }
    return _sorted(results);
  }

  /// Finds "may contain" / shared facility warnings and the allergen groups they mention.
  CrossContamination? detectCrossContamination({required String rawText, required List<Ingredient> dictionary}) {
    final statements = _splitStatements(normalize(rawText)).mayContain;
    if (statements.isEmpty) return null;

    final groups = <String>{};
    for (final statement in statements) {
      for (final ingredient in dictionary) {
        final group = ingredient.allergenGroup;
        if (group == null || ingredient.category != IngredientCategory.allergen) continue;
        if (_findKeyword(statement, ingredient) != null) groups.add(group);
      }
    }
    final ordered = [
      for (final item in availableAllergens) if (groups.contains(item)) item,
      for (final item in groups) if (!availableAllergens.contains(item)) item,
    ];
    final statement = statements.map(_capitalize).join('. ');
    return CrossContamination(allergenGroups: ordered, statement: statement.endsWith('.') ? statement : '$statement.');
  }

  /// Re-evaluates stored ingredients against the current allergen set and syubhat filter.
  List<DetectedIngredient> reevaluate(
    List<DetectedIngredient> ingredients,
    Set<String> selectedAllergens, {
    bool avoidSyubhat = false,
  }) {
    return _sorted([
      for (final item in ingredients)
        item.copyWith(
          riskLevel: resolveRisk(
            item.category,
            item.allergenGroup,
            selectedAllergens,
            avoidSyubhat: avoidSyubhat,
            isNonHalal: item.isNonHalal,
          ),
        ),
    ]);
  }

  /// Computes the impact of a product for each active family profile.
  List<ProfileImpact> evaluateProfiles({
    required List<DetectedIngredient> ingredients,
    required CrossContamination? crossContamination,
    required List<FamilyProfile> profiles,
  }) {
    final hasSugar = ingredients.any((item) => item.category == IngredientCategory.sugarAlias);
    final hasAdditive = ingredients.any((item) => _isAdditive(item.category));
    final hasNonHalal = ingredients.any((item) => item.category == IngredientCategory.syubhat && item.isNonHalal);
    final hasSyubhatOnly = ingredients.any((item) => item.category == IngredientCategory.syubhat && !item.isNonHalal);
    final presentGroups = ingredients.map((item) => item.allergenGroup).whereType<String>().toSet();

    return [
      for (final profile in profiles)
        () {
          final direct = [for (final group in profile.orderedAllergens) if (presentGroups.contains(group)) group];
          final cross = [
            for (final group in crossContamination?.allergenGroups ?? const <String>[])
              if (profile.allergens.contains(group) && !direct.contains(group)) group,
          ];
          final crossReason = cross.isEmpty ? null : 'Kontaminasi ${cross.join(', ')}';

          final danger = [
            ...direct,
            if (profile.isSevere && crossReason != null) crossReason,
            if (profile.avoidSyubhat && hasNonHalal) 'Non-Halal',
          ];
          final caution = [
            if (!profile.isSevere && crossReason != null) crossReason,
            if (profile.avoidSyubhat && !hasNonHalal && hasSyubhatOnly) 'Syubhat',
            if (profile.avoidHiddenSugar && hasSugar) 'Gula Tersembunyi',
            if (profile.avoidAdditives && hasAdditive) 'Zat Aditif',
          ];

          if (danger.isNotEmpty) {
            return ProfileImpact(profile: profile, level: RiskLevel.danger, reasons: danger);
          }
          if (caution.isNotEmpty) {
            return ProfileImpact(profile: profile, level: RiskLevel.caution, reasons: caution);
          }
          return ProfileImpact(profile: profile, level: RiskLevel.safe, reasons: const []);
        }(),
    ];
  }

  /// Builds the live summary for [result] against the active [profiles].
  ScanSummary summarize(ScanResult result, List<FamilyProfile> profiles) {
    final allergens = {for (final profile in profiles) ...profile.allergens};
    final avoidSyubhat = profiles.any((profile) => profile.avoidSyubhat);
    final ingredients = reevaluate(result.detectedIngredients, allergens, avoidSyubhat: avoidSyubhat);
    final impacts = evaluateProfiles(
      ingredients: ingredients,
      crossContamination: result.crossContamination,
      profiles: profiles,
    );
    final danger = ingredients.where((item) => item.riskLevel == RiskLevel.danger).toList();
    final cautionCount = ingredients.where((item) => item.riskLevel == RiskLevel.caution).length;
    final groups = [
      for (final group in availableAllergens)
        if (danger.any((item) => item.allergenGroup == group)) group,
    ];
    final hasSugar = ingredients.any((item) => item.category == IngredientCategory.sugarAlias);
    final hasAdditives = ingredients.any((item) => _isAdditive(item.category));
    final hasNonHalal = avoidSyubhat &&
        ingredients.any((item) => item.category == IngredientCategory.syubhat && item.isNonHalal);
    final hasSyubhat = avoidSyubhat &&
        ingredients.any((item) => item.category == IngredientCategory.syubhat && !item.isNonHalal);
    final cross = result.crossContamination;
    final crossRelevant = cross != null &&
        cross.allergenGroups.isNotEmpty &&
        (profiles.isEmpty || impacts.any((impact) => impact.reasons.any((r) => r.startsWith('Kontaminasi'))));

    final level = worstRisk([
      ...ingredients.map((item) => item.riskLevel),
      ...impacts.map((impact) => impact.level),
      if (crossRelevant && profiles.isEmpty) RiskLevel.caution,
    ]);
    final risky = danger.length + cautionCount;

    return ScanSummary(
      totalDetected: ingredients.length,
      dangerCount: danger.length,
      cautionCount: cautionCount,
      hasUserAllergen: groups.isNotEmpty,
      topRisks: danger.take(3).toList(),
      allergenGroups: groups,
      message: risky == 0 ? 'Tidak ada bahan berisiko terdeteksi' : 'Ditemukan $risky bahan berisiko',
      overallLevel: level,
      subtitle: _subtitle(
        level: level,
        total: ingredients.length,
        hasAllergen: groups.isNotEmpty,
        crossRelevant: crossRelevant,
        hasNonHalal: hasNonHalal,
        hasSyubhat: hasSyubhat,
        hasSugar: hasSugar,
        hasAdditives: hasAdditives,
        risky: risky,
      ),
      ingredients: ingredients,
      impacts: impacts,
      crossContamination: cross,
      hasHiddenSugar: hasSugar,
      hasAdditives: hasAdditives,
      hasSyubhat: hasSyubhat,
      hasNonHalal: hasNonHalal,
    );
  }

  /// Guesses a product name from the first plausible OCR line.
  String guessProductName(String rawText) {
    final skip = RegExp(
      r'^(komposisi|bahan|ingredients?|kandungan|informasi nilai gizi|nilai gizi|nutrition|dapat mengandung|'
      r'may contain|diproduksi|diproses|takaran|sajian|berat bersih|netto|net wt|exp|kedaluwarsa|bpom|md |ml |'
      r'halal|simpan|cara|petunjuk|alergen|mengandung)',
      caseSensitive: false,
    );
    for (final line in rawText.split(RegExp(r'[\r\n]+'))) {
      final text = line.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.length < 3 || text.length > 40) continue;
      if (skip.hasMatch(text) || text.contains(',') || text.contains(':')) continue;
      final letters = RegExp(r'[A-Za-z]').allMatches(text).length;
      if (letters < text.length * 0.6) continue;
      return text
          .split(' ')
          .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
          .join(' ');
    }
    return defaultProductName;
  }

  String normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  RiskLevel resolveRisk(
    IngredientCategory category,
    String? allergenGroup,
    Set<String> selectedAllergens, {
    bool avoidSyubhat = false,
    bool isNonHalal = false,
  }) {
    if (allergenGroup != null && selectedAllergens.contains(allergenGroup)) return RiskLevel.danger;
    if (avoidSyubhat && category == IngredientCategory.syubhat) {
      return isNonHalal ? RiskLevel.danger : RiskLevel.caution;
    }
    if (category.isCautionCategory) return RiskLevel.caution;
    return RiskLevel.safe;
  }

  ({String direct, List<String> mayContain}) _splitStatements(String text) {
    final direct = <String>[];
    final mayContain = <String>[];
    for (final sentence in text.split(_sentenceSplitter)) {
      var index = -1;
      for (final trigger in crossContaminationTriggers) {
        final found = sentence.indexOf(trigger);
        if (found >= 0 && (index < 0 || found < index)) index = found;
      }
      if (index < 0) {
        direct.add(sentence);
      } else {
        direct.add(sentence.substring(0, index));
        final statement = sentence.substring(index).trim();
        if (statement.isNotEmpty) mayContain.add(statement);
      }
    }
    return (direct: direct.map((s) => s.trim()).where((s) => s.isNotEmpty).join('. '), mayContain: mayContain);
  }

  String? _findKeyword(String text, Ingredient ingredient) {
    final keywords = ingredient.keywords.map(normalize).where((k) => k.isNotEmpty).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final keyword in keywords) {
      final pattern = RegExp('(?<![a-z0-9])${RegExp.escape(keyword)}(?![a-z0-9])');
      if (pattern.hasMatch(text)) return keyword;
    }
    return null;
  }

  List<DetectedIngredient> _sorted(List<DetectedIngredient> items) {
    return items
      ..sort((a, b) {
        final byRisk = a.riskLevel.index.compareTo(b.riskLevel.index);
        return byRisk != 0 ? byRisk : a.ingredientName.compareTo(b.ingredientName);
      });
  }

  bool _isAdditive(IngredientCategory category) =>
      category == IngredientCategory.additive ||
      category == IngredientCategory.preservative ||
      category == IngredientCategory.coloring;

  String _capitalize(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _subtitle({
    required RiskLevel level,
    required int total,
    required bool hasAllergen,
    required bool crossRelevant,
    required bool hasNonHalal,
    required bool hasSyubhat,
    required bool hasSugar,
    required bool hasAdditives,
    required int risky,
  }) {
    if (level == RiskLevel.safe) {
      return total == 0 ? 'Tidak ada bahan yang dikenali dari label' : 'Tidak ada bahan berisiko untuk profil aktif';
    }
    final parts = [
      if (hasAllergen) 'alergen utama',
      if (hasNonHalal) 'bahan non-halal',
      if (crossRelevant) 'risiko kontaminasi silang',
      if (!hasNonHalal && hasSyubhat) 'bahan syubhat',
      if (hasSugar) 'gula tersembunyi',
      if (hasAdditives) 'zat aditif',
    ];
    if (parts.isEmpty) return 'Ditemukan $risky bahan yang perlu diwaspadai';
    final joined = parts.length == 1
        ? parts.first
        : '${parts.sublist(0, parts.length - 1).join(', ')} & ${parts.last}';
    return 'Mengandung $joined';
  }
}
