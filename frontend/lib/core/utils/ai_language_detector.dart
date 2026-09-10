/// Utility for per-message language detection (Arabic / English) in Sorour Logistics ERP.
///
/// Designed specifically for logistics operations where messages frequently contain
/// embedded English system identifiers (container numbers, booking codes, ACID,
/// file codes, dates) within Arabic sentences.
class AiLanguageDetector {
  AiLanguageDetector._();

  /// Regex patterns for system & logistics identifiers that should NOT skew
  /// language detection towards English.
  static final List<RegExp> _identifierPatterns = [
    // Standard 4-letter + 7-digit container numbers (e.g., WHSU81072658, MSCU1000000)
    RegExp(r'\b[A-Z]{4}\d{7}\b', caseSensitive: false),
    // Booking confirmation codes and seals (e.g., THXJ2608090, SL99210, BKG-2026-0001)
    RegExp(r'\bBKG-\d{4}-\d{4,}\b', caseSensitive: false),
    RegExp(r'\b[A-Z]{1,4}[-]?\d{4,10}\b', caseSensitive: false),
    RegExp(r'\b[A-Z0-9]{6,15}\b'),
    // Import file codes (e.g., IMP-2026-0004)
    RegExp(r'\bIMP-\d{4}-\d{4,}\b', caseSensitive: false),
    // Task codes (e.g., TSK-2026-0001, TSK-1)
    RegExp(r'\bTSK-\d+(-\d+)?\b', caseSensitive: false),
    // Purchase order codes (e.g., PO-2026-0001)
    RegExp(r'\bPO-\d{4}-\d{4,}\b', caseSensitive: false),
    // Shipment codes (e.g., SHP-2026-0001)
    RegExp(r'\bSHP-\d{4}-\d{4,}\b', caseSensitive: false),
    // ACID numbers (19-digit numbers)
    RegExp(r'\b\d{15,20}\b'),
    // ISO Dates (YYYY-MM-DD) or DD/MM/YYYY
    RegExp(r'\b\d{4}[-/]\d{1,2}[-/]\d{1,2}\b'),
    RegExp(r'\b\d{1,2}[-/]\d{1,2}([-/]\d{2,4})?\b'),
    // Pure numbers and currency figures
    RegExp(r'\b\d+([.,]\d+)?\b'),
    // URLs
    RegExp(r'https?://\S+'),
  ];

  static final RegExp _arabicCharRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  static final RegExp _latinCharRegex = RegExp(r'[a-zA-Z]');

  /// Detects the dominant language ('ar' or 'en') of an individual incoming message.
  ///
  /// Removes logistics codes, container numbers, and date tokens before calculating
  /// character counts so that embedded identifiers do not falsely trigger English.
  static String detectDominantLanguage(String text, {String fallback = 'ar'}) {
    if (text.trim().isEmpty) return fallback;

    // 1. Strip system identifiers and technical tokens
    String cleaned = text;
    for (final pattern in _identifierPatterns) {
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    // 2. Count natural language Arabic characters vs Latin alphabetic characters
    int arabicCount = 0;
    int latinCount = 0;

    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];
      if (_arabicCharRegex.hasMatch(char)) {
        arabicCount++;
      } else if (_latinCharRegex.hasMatch(char)) {
        latinCount++;
      }
    }

    // 3. Dominant language decision
    if (arabicCount == 0 && latinCount == 0) {
      return fallback;
    }

    // If there is any substantial Arabic grammatical structure, it is predominantly Arabic
    if (arabicCount >= latinCount) {
      return 'ar';
    } else {
      return 'en';
    }
  }

  /// Returns true if the detected dominant language is Arabic.
  static bool isArabic(String text, {String fallback = 'ar'}) {
    return detectDominantLanguage(text, fallback: fallback) == 'ar';
  }

  /// Returns true if the detected dominant language is English.
  static bool isEnglish(String text, {String fallback = 'ar'}) {
    return detectDominantLanguage(text, fallback: fallback) == 'en';
  }

  /// Extracts detected system identifiers (containers, seals, bookings, ACID, dates)
  static List<String> extractSystemIdentifiers(String text) {
    final results = <String>{};
    for (final pattern in _identifierPatterns) {
      final matches = pattern.allMatches(text);
      for (final m in matches) {
        final token = m.group(0)?.trim();
        if (token != null && token.isNotEmpty) {
          results.add(token);
        }
      }
    }
    return results.toList();
  }
}
