import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/system_live_clock_widget.dart';

void main() {
  group('WorldTimezoneHelper - ISO Week & Date Calculations', () {
    test('calculates correct ISO week number for 2026-09-10 (Week 37)', () {
      final date = DateTime(2026, 9, 10);
      final week = WorldTimezoneHelper.getIsoWeekNumber(date);
      expect(week, equals(37));
      expect(getIsoWeekNumber(date), equals(37));
    });

    test('calculates correct ISO week number for start of year 2026', () {
      final date = DateTime(2026, 1, 1);
      final week = WorldTimezoneHelper.getIsoWeekNumber(date);
      expect(week, equals(1));
    });

    test('calculates correct ISO week number for 2026-01-05 (Monday of Week 2)', () {
      final date = DateTime(2026, 1, 5);
      final week = WorldTimezoneHelper.getIsoWeekNumber(date);
      expect(week, equals(2));
    });

    test('calculates correct ISO week number for end of year 2026-12-31', () {
      final date = DateTime(2026, 12, 31);
      final week = WorldTimezoneHelper.getIsoWeekNumber(date);
      expect(week, equals(53));
    });

    test('formats 24-hour time with leading zeros (HH:mm by default, HH:mm:ss with showSeconds)', () {
      final t1 = DateTime(2026, 9, 10, 8, 4, 3);
      expect(WorldTimezoneHelper.formatTime24h(t1), equals('08:04'));
      expect(WorldTimezoneHelper.formatTime24h(t1, showSeconds: true), equals('08:04:03'));

      final t2 = DateTime(2026, 9, 10, 23, 59, 59);
      expect(WorldTimezoneHelper.formatTime24h(t2), equals('23:59'));
      expect(WorldTimezoneHelper.formatTime24h(t2, showSeconds: true), equals('23:59:59'));
    });

    test('returns correct Arabic day names', () {
      expect(WorldTimezoneHelper.getArabicDayName(DateTime(2026, 9, 7)), equals('الإثنين'));
      expect(WorldTimezoneHelper.getArabicDayName(DateTime(2026, 9, 8)), equals('الثلاثاء'));
      expect(WorldTimezoneHelper.getArabicDayName(DateTime(2026, 9, 9)), equals('الأربعاء'));
      expect(WorldTimezoneHelper.getArabicDayName(DateTime(2026, 9, 10)), equals('الخميس'));
      expect(WorldTimezoneHelper.getArabicDayName(DateTime(2026, 9, 11)), equals('الجمعة'));
      expect(WorldTimezoneHelper.getArabicDayName(DateTime(2026, 9, 12)), equals('السبت'));
      expect(WorldTimezoneHelper.getArabicDayName(DateTime(2026, 9, 13)), equals('الأحد'));
    });

    test('returns correct English day names', () {
      expect(WorldTimezoneHelper.getEnglishDayName(DateTime(2026, 9, 7)), equals('Monday'));
      expect(WorldTimezoneHelper.getEnglishDayName(DateTime(2026, 9, 8)), equals('Tuesday'));
      expect(WorldTimezoneHelper.getEnglishDayName(DateTime(2026, 9, 9)), equals('Wednesday'));
      expect(WorldTimezoneHelper.getEnglishDayName(DateTime(2026, 9, 10)), equals('Thursday'));
      expect(WorldTimezoneHelper.getEnglishDayName(DateTime(2026, 9, 11)), equals('Friday'));
      expect(WorldTimezoneHelper.getEnglishDayName(DateTime(2026, 9, 12)), equals('Saturday'));
      expect(WorldTimezoneHelper.getEnglishDayName(DateTime(2026, 9, 13)), equals('Sunday'));
    });

    test('getDayName respects isArabic parameter', () {
      final thu = DateTime(2026, 9, 10);
      expect(WorldTimezoneHelper.getDayName(thu, isArabic: true), equals('الخميس'));
      expect(WorldTimezoneHelper.getDayName(thu, isArabic: false), equals('Thursday'));
    });

    test('getCountryName returns correct Arabic and English names', () {
      expect(WorldTimezoneHelper.getCountryName('egypt', isArabic: true), equals('مصر'));
      expect(WorldTimezoneHelper.getCountryName('egypt', isArabic: false), equals('Egypt'));

      expect(WorldTimezoneHelper.getCountryName('france_italy_spain', isArabic: true), equals('فرنسا وإيطاليا وإسبانيا'));
      expect(WorldTimezoneHelper.getCountryName('france_italy_spain', isArabic: false), equals('France, Italy & Spain'));

      expect(WorldTimezoneHelper.getCountryName('france_italy', isArabic: true), equals('فرنسا وإيطاليا وإسبانيا'));
      expect(WorldTimezoneHelper.getCountryName('france_italy', isArabic: false), equals('France, Italy & Spain'));

      expect(WorldTimezoneHelper.getCountryName('spain', isArabic: true), equals('إسبانيا'));
      expect(WorldTimezoneHelper.getCountryName('spain', isArabic: false), equals('Spain'));

      expect(WorldTimezoneHelper.getCountryName('france', isArabic: true), equals('فرنسا'));
      expect(WorldTimezoneHelper.getCountryName('italy', isArabic: true), equals('إيطاليا'));

      expect(WorldTimezoneHelper.getCountryName('uk', isArabic: true), equals('إنجلترا'));
      expect(WorldTimezoneHelper.getCountryName('uk', isArabic: false), equals('UK'));

      expect(WorldTimezoneHelper.getCountryName('turkey_lithuania', isArabic: true), equals('تركيا وليتوانيا'));
      expect(WorldTimezoneHelper.getCountryName('turkey_lithuania', isArabic: false), equals('Turkey & Lithuania'));

      expect(WorldTimezoneHelper.getCountryName('turkey', isArabic: true), equals('تركيا'));
      expect(WorldTimezoneHelper.getCountryName('turkey', isArabic: false), equals('Turkey'));

      expect(WorldTimezoneHelper.getCountryName('lithuania', isArabic: true), equals('ليتوانيا'));
      expect(WorldTimezoneHelper.getCountryName('lithuania', isArabic: false), equals('Lithuania'));

      expect(WorldTimezoneHelper.getCountryName('china', isArabic: true), equals('الصين'));
      expect(WorldTimezoneHelper.getCountryName('china', isArabic: false), equals('China'));

      expect(WorldTimezoneHelper.getCountryName('uae', isArabic: true), equals('الإمارات'));
      expect(WorldTimezoneHelper.getCountryName('uae', isArabic: false), equals('UAE'));

      expect(WorldTimezoneHelper.getCountryName('us', isArabic: true), equals('أمريكا'));
      expect(WorldTimezoneHelper.getCountryName('us', isArabic: false), equals('USA'));
    });
  });

  group('WorldTimezoneHelper - Daylight Saving & Country Offsets', () {
    test('Egypt DST: true in September (summer), false in January (winter)', () {
      final summerDate = DateTime.utc(2026, 9, 10, 12, 0, 0);
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0, 0);

      expect(WorldTimezoneHelper.isEgyptSummerTime(summerDate), isTrue);
      expect(WorldTimezoneHelper.isEgyptSummerTime(winterDate), isFalse);
    });

    test('EU/UK DST: true in September (summer), false in January (winter)', () {
      final summerDate = DateTime.utc(2026, 9, 10, 12, 0, 0);
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0, 0);

      expect(WorldTimezoneHelper.isEuUkSummerTime(summerDate), isTrue);
      expect(WorldTimezoneHelper.isEuUkSummerTime(winterDate), isFalse);
    });

    test('US DST: true in September (summer), false in January (winter)', () {
      final summerDate = DateTime.utc(2026, 9, 10, 12, 0, 0);
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0, 0);

      expect(WorldTimezoneHelper.isUsSummerTime(summerDate), isTrue);
      expect(WorldTimezoneHelper.isUsSummerTime(winterDate), isFalse);
    });

    test('calculates accurate times for all countries in Summer (September 2026)', () {
      // Reference UTC: 2026-09-10 12:00:00Z
      final refUtc = DateTime.utc(2026, 9, 10, 12, 0, 0);

      // 1. Egypt (UTC+3 summer)
      final egypt = WorldTimezoneHelper.getEgyptTime(refUtc);
      expect(egypt.hour, equals(15));
      expect(egypt.minute, equals(0));

      // 2. France, Italy & Spain (UTC+2 summer)
      final france = WorldTimezoneHelper.getFranceTime(refUtc);
      final italy = WorldTimezoneHelper.getItalyTime(refUtc);
      final spain = WorldTimezoneHelper.getSpainTime(refUtc);
      final franceItalySpain = WorldTimezoneHelper.getFranceItalySpainTime(refUtc);
      expect(france.hour, equals(14));
      expect(italy.hour, equals(14));
      expect(spain.hour, equals(14));
      expect(franceItalySpain.hour, equals(14));

      // 3. England / UK (UTC+1 summer)
      final uk = WorldTimezoneHelper.getUkTime(refUtc);
      expect(uk.hour, equals(13));

      // 4. Turkey (UTC+3 fixed year-round) & Lithuania (UTC+3 summer) - Combined
      final turkey = WorldTimezoneHelper.getTurkeyTime(refUtc);
      final lithuania = WorldTimezoneHelper.getLithuaniaTime(refUtc);
      final turkeyLithuania = WorldTimezoneHelper.getTurkeyLithuaniaTime(refUtc);
      expect(turkey.hour, equals(15));
      expect(lithuania.hour, equals(15));
      expect(turkeyLithuania.hour, equals(15));

      // 6. China (UTC+8 fixed)
      final china = WorldTimezoneHelper.getChinaTime(refUtc);
      expect(china.hour, equals(20));

      // 7. United Arab Emirates (UTC+4 fixed)
      final uae = WorldTimezoneHelper.getUaeTime(refUtc);
      expect(uae.hour, equals(16));

      // 8. United States (UTC-4 EDT summer)
      final us = WorldTimezoneHelper.getUsEasternTime(refUtc);
      expect(us.hour, equals(8));
    });

    test('Spain time: matches France and Italy in both Summer (UTC+2) and Winter (UTC+1)', () {
      final summerDate = DateTime.utc(2026, 9, 10, 12, 0, 0);
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0, 0);

      expect(WorldTimezoneHelper.getSpainTime(summerDate).hour, equals(14));
      expect(WorldTimezoneHelper.getSpainTime(winterDate).hour, equals(13));
      expect(WorldTimezoneHelper.getSpainTime(summerDate), equals(WorldTimezoneHelper.getFranceTime(summerDate)));
      expect(WorldTimezoneHelper.getSpainTime(winterDate), equals(WorldTimezoneHelper.getItalyTime(winterDate)));
      expect(WorldTimezoneHelper.getFranceItalySpainTime(summerDate), equals(WorldTimezoneHelper.getSpainTime(summerDate)));
    });

    test('Turkey time: UTC+3 year-round (no DST changes)', () {
      final summerDate = DateTime.utc(2026, 9, 10, 12, 0, 0);
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0, 0);

      final summerTurkey = WorldTimezoneHelper.getTurkeyTime(summerDate);
      final winterTurkey = WorldTimezoneHelper.getTurkeyTime(winterDate);

      expect(summerTurkey.hour, equals(15));
      expect(winterTurkey.hour, equals(15));
    });

    test('business hours detection (08:00 - 17:00 Mon-Fri default)', () {
      // Thursday 08:00 -> start of business hours (Green)
      final startWork = DateTime(2026, 9, 10, 8, 0);
      expect(WorldTimezoneHelper.isBusinessHours(startWork), isTrue);

      // Thursday 16:59 -> within business hours (Green)
      final endWork = DateTime(2026, 9, 10, 16, 59);
      expect(WorldTimezoneHelper.isBusinessHours(endWork), isTrue);

      // Thursday 07:59 -> before 8 AM (Red)
      final earlyTime = DateTime(2026, 9, 10, 7, 59);
      expect(WorldTimezoneHelper.isBusinessHours(earlyTime), isFalse);

      // Thursday 17:00 -> after 5 PM (Red)
      final closeTime = DateTime(2026, 9, 10, 17, 0);
      expect(WorldTimezoneHelper.isBusinessHours(closeTime), isFalse);

      // Sunday 11:00 -> weekend for standard countries (Red)
      final weekendTime = DateTime(2026, 9, 13, 11, 0);
      expect(WorldTimezoneHelper.isBusinessHours(weekendTime), isFalse);
    });

    test('Egypt business hours detection (Sun-Thu 08:00-17:00, Fri-Sat weekend)', () {
      // Sunday 11:00 in Egypt -> working day within business hours (Green)
      final sundayWork = DateTime(2026, 9, 13, 11, 0);
      expect(WorldTimezoneHelper.isBusinessHours(sundayWork, countryKey: 'egypt'), isTrue);

      // Sunday 07:59 in Egypt -> before 8 AM (Red)
      final sundayEarly = DateTime(2026, 9, 13, 7, 59);
      expect(WorldTimezoneHelper.isBusinessHours(sundayEarly, countryKey: 'egypt'), isFalse);

      // Friday 11:00 in Egypt -> Friday weekend holiday (Red)
      final fridayWeekend = DateTime(2026, 9, 11, 11, 0);
      expect(WorldTimezoneHelper.isBusinessHours(fridayWeekend, countryKey: 'egypt'), isFalse);

      // Saturday 11:00 in Egypt -> Saturday weekend holiday (Red)
      final saturdayWeekend = DateTime(2026, 9, 12, 11, 0);
      expect(WorldTimezoneHelper.isBusinessHours(saturdayWeekend, countryKey: 'egypt'), isFalse);

      // Wednesday 14:00 in Egypt -> regular working day (Green)
      final wednesdayWork = DateTime(2026, 9, 9, 14, 0);
      expect(WorldTimezoneHelper.isBusinessHours(wednesdayWork, countryKey: 'egypt'), isTrue);
    });
  });

  group('System Live Clocks & Date Badges - Widget Tests', () {
    testWidgets('SystemDateWeekBadge renders standalone date, Arabic day and week number', (tester) async {
      final testDate = DateTime(2026, 9, 10, 14, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SystemDateWeekBadge(currentTime: testDate, isArabic: true),
            ),
          ),
        ),
      );

      expect(find.text('الخميس'), findsOneWidget);
      expect(find.text('2026-09-10'), findsOneWidget);
      expect(find.text('الأسبوع: W37'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    });

    testWidgets('SystemWorldClocksBar renders combined France/Italy/Spain, UAE, USA without flags', (tester) async {
      final refUtc = DateTime.utc(2026, 9, 10, 12, 0, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SystemWorldClocksBar(currentTimeUtc: refUtc, isArabic: true),
            ),
          ),
        ),
      );

      // Verify country names in Arabic
      expect(find.text('مصر'), findsOneWidget);
      expect(find.text('فرنسا وإيطاليا وإسبانيا'), findsOneWidget); // Combined
      expect(find.text('إنجلترا'), findsOneWidget);
      expect(find.text('تركيا وليتوانيا'), findsOneWidget);         // Turkey & Lithuania merged
      expect(find.text('الصين'), findsOneWidget);
      expect(find.text('الإمارات'), findsOneWidget);      // UAE
      expect(find.text('أمريكا'), findsOneWidget);        // USA

      // Verify flags are NOT rendered (removed per user request)
      expect(find.text('🇪🇬'), findsNothing);
      expect(find.text('🇪🇺'), findsNothing);
      expect(find.text('🇬🇧'), findsNothing);
      expect(find.text('🇹🇷 🇱🇹'), findsNothing);
      expect(find.text('🇨🇳'), findsNothing);
      expect(find.text('🇦🇪'), findsNothing);
      expect(find.text('🇺🇸'), findsNothing);

      // Verify 24-hour time values (compact HH:mm format without seconds)
      expect(find.text('15:00'), findsNWidgets(2)); // Egypt and Turkey & Lithuania
      expect(find.text('14:00'), findsOneWidget);   // France, Italy & Spain combined
      expect(find.text('13:00'), findsOneWidget);   // UK
      expect(find.text('20:00'), findsOneWidget);   // China
      expect(find.text('16:00'), findsOneWidget);   // UAE
      expect(find.text('08:00'), findsOneWidget);   // USA (08:00 EDT)
    });

    testWidgets('SystemDateWeekBadge renders English day and week label when isArabic is false', (tester) async {
      final testDate = DateTime(2026, 9, 10, 14, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SystemDateWeekBadge(
              currentTime: testDate,
              isArabic: false,
            ),
          ),
        ),
      );

      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('2026-09-10'), findsOneWidget);
      expect(find.text('Week: W37'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    });

    testWidgets('SystemWorldClocksBar renders English country names when isArabic is false', (tester) async {
      final refUtc = DateTime.utc(2026, 9, 10, 12, 0, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SystemWorldClocksBar(
              currentTimeUtc: refUtc,
              isArabic: false,
            ),
          ),
        ),
      );

      // Verify English country names
      expect(find.text('Egypt'), findsOneWidget);
      expect(find.text('France, Italy & Spain'), findsOneWidget);
      expect(find.text('UK'), findsOneWidget);
      expect(find.text('Turkey & Lithuania'), findsOneWidget);
      expect(find.text('China'), findsOneWidget);
      expect(find.text('UAE'), findsOneWidget);
      expect(find.text('USA'), findsOneWidget);

      // Verify flags are NOT rendered (removed per user request)
      expect(find.text('🇪🇬'), findsNothing);
      expect(find.text('🇪🇺'), findsNothing);
      expect(find.text('🇬🇧'), findsNothing);
      expect(find.text('🇹🇷 🇱🇹'), findsNothing);
      expect(find.text('🇨🇳'), findsNothing);
      expect(find.text('🇦🇪'), findsNothing);
      expect(find.text('🇺🇸'), findsNothing);
    });

    testWidgets('SystemDateWeekBadge auto-detects Arabic from RTL Directionality without explicit flag', (tester) async {
      final testDate = DateTime(2026, 9, 10, 14, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SystemDateWeekBadge(currentTime: testDate), // No explicit isArabic
            ),
          ),
        ),
      );

      expect(find.text('الخميس'), findsOneWidget);
      expect(find.text('الأسبوع: W37'), findsOneWidget);
    });

    testWidgets('SystemWorldClocksBar auto-detects Arabic from RTL Directionality without explicit flag', (tester) async {
      final refUtc = DateTime.utc(2026, 9, 10, 12, 0, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SystemWorldClocksBar(currentTimeUtc: refUtc), // No explicit isArabic
            ),
          ),
        ),
      );

      expect(find.text('مصر'), findsOneWidget);
      expect(find.text('فرنسا وإيطاليا وإسبانيا'), findsOneWidget);
      expect(find.text('تركيا وليتوانيا'), findsOneWidget);
      expect(find.text('الصين'), findsOneWidget);
    });

    testWidgets('SystemWorldClocksHeader renders in English when isArabic is false', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SystemWorldClocksHeader(isArabic: false),
          ),
        ),
      );

      expect(find.byType(SystemWorldClocksHeader), findsOneWidget);
      expect(find.text('Egypt'), findsOneWidget);
      expect(find.text('France, Italy & Spain'), findsOneWidget);
      expect(find.text('Turkey & Lithuania'), findsOneWidget);
      expect(find.text('USA'), findsOneWidget);
    });

    testWidgets('WorldClockChip renders green for business hours (8am-5pm) and red for outside', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WorldClockChip(
                  flag: '🇪🇬',
                  countryName: 'مصر',
                  time24h: '10:00',
                  isBusinessHours: true, // 8am-5pm -> Green
                  tooltip: 'مفتوح',
                ),
                WorldClockChip(
                  flag: '🇨🇳',
                  countryName: 'الصين',
                  time24h: '21:00',
                  isBusinessHours: false, // Night -> Red
                  tooltip: 'مغلق',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('21:00'), findsOneWidget);
    });

    testWidgets('SystemWorldClocksHeader renders both tiers in desktop wide mode', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SystemWorldClocksHeader(),
          ),
        ),
      );

      expect(find.byType(SystemWorldClocksHeader), findsOneWidget);
      expect(find.byType(SystemDateWeekBadge), findsOneWidget);
      expect(find.byType(SystemWorldClocksBar), findsOneWidget);
      expect(find.text('24H LIVE'), findsOneWidget);

      // Advance 1 second and re-pump
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SystemWorldClocksHeader), findsOneWidget);
    });

    testWidgets('SystemWorldClocksHeader renders without overflow in compact view', (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SystemWorldClocksHeader(),
          ),
        ),
      );

      expect(find.byType(SystemWorldClocksHeader), findsOneWidget);
      expect(find.byType(SystemDateWeekBadge), findsOneWidget);
      expect(find.byType(SystemWorldClocksBar), findsOneWidget);
    });
  });
}


