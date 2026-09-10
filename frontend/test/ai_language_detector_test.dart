import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/ai_language_detector.dart';

void main() {
  group('AiLanguageDetector - Rule 1 & 5: Language Detection & Mixed Input', () {
    test('detects pure Arabic message', () {
      const text = 'ما هي الشحنات التي تنتظر إجراءات الجمارك اليوم؟';
      final lang = AiLanguageDetector.detectDominantLanguage(text);
      expect(lang, equals('ar'));
      expect(AiLanguageDetector.isArabic(text), isTrue);
      expect(AiLanguageDetector.isEnglish(text), isFalse);
    });

    test('detects pure English message', () {
      const text = 'What shipments are pending customs clearance today?';
      final lang = AiLanguageDetector.detectDominantLanguage(text);
      expect(lang, equals('en'));
      expect(AiLanguageDetector.isEnglish(text), isTrue);
      expect(AiLanguageDetector.isArabic(text), isFalse);
    });

    test('detects Arabic dominant message containing container numbers and seal numbers', () {
      // Container: WHSU81072658, Seal: WHA257097 - both must be stripped before counting characters
      const text = 'في شحنة PET سجل رقم الحاوية WHSU81072658 ورقم السيل WHA257097';
      final lang = AiLanguageDetector.detectDominantLanguage(text);
      expect(lang, equals('ar'), reason: 'Technical identifiers should not skew Arabic intent');
      expect(AiLanguageDetector.isArabic(text), isTrue);
    });

    test('detects Arabic dominant message containing booking code and file code', () {
      const text = 'حجز الشحن برقم THXJ2608090 في ملف IMP-2026-0004 تم تأكيده';
      final lang = AiLanguageDetector.detectDominantLanguage(text);
      expect(lang, equals('ar'));
    });

    test('detects Arabic dominant message containing 19-digit Egyptian ACID and ISO date', () {
      const text = 'تحقق من صلاحية الرقم المبدئي 5281534391023010013 وتاريخ 2026-08-27';
      final lang = AiLanguageDetector.detectDominantLanguage(text);
      expect(lang, equals('ar'));
    });

    test('detects English dominant message containing logistics identifiers', () {
      const text = 'Please check container WHSU81072658 and booking THXJ2608090 for shipment IMP-2026-0004';
      final lang = AiLanguageDetector.detectDominantLanguage(text);
      expect(lang, equals('en'));
      expect(AiLanguageDetector.isEnglish(text), isTrue);
    });

    test('detects English dominant message with embedded Arabic product name', () {
      const text = 'Update status for shipment بولي إيثيلين to In Transit with seal WHA257097';
      final lang = AiLanguageDetector.detectDominantLanguage(text);
      expect(lang, equals('en'));
    });

    test('falls back gracefully to fallback language on numbers or symbols only', () {
      expect(AiLanguageDetector.detectDominantLanguage('123456 - 7890'), equals('ar'));
      expect(AiLanguageDetector.detectDominantLanguage('123456', fallback: 'en'), equals('en'));
      expect(AiLanguageDetector.detectDominantLanguage(''), equals('ar'));
      expect(AiLanguageDetector.detectDominantLanguage('   ', fallback: 'en'), equals('en'));
    });

    test('extracts technical identifiers accurately for preservation', () {
      const text = 'Check container MSKU0492817 with seal SL99210 under ACID 4829104829104829101 on 2026-09-15';
      final ids = AiLanguageDetector.extractSystemIdentifiers(text);
      expect(ids, contains('MSKU0492817'));
      expect(ids, contains('SL99210'));
      expect(ids, contains('4829104829104829101'));
      expect(ids, contains('2026-09-15'));
    });
  });
}
