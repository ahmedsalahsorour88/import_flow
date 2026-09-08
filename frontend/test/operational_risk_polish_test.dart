import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Operational Dashboard & Customs Consultation UI Polish Tests', () {
    test('Format stage names correctly according to active locale', () {
      String formatStageName(String? stage, bool isArabic) {
        if (stage == null || stage.trim().isEmpty) return '';
        final s = stage.trim();

        final match = RegExp(r'(?:phase|المرحلة)\s*(\d+)', caseSensitive: false).firstMatch(s);
        int? phaseNum;
        if (match != null) {
          phaseNum = int.tryParse(match.group(1)!);
        } else {
          final lower = s.toLowerCase();
          if (lower.contains('planning') || lower.contains('تخطيط')) {
            phaseNum = 1;
          } else if (lower.contains('acid') || lower.contains('اعتماد')) {
            phaseNum = 2;
          } else if (lower.contains('booking') || lower.contains('حجز')) {
            phaseNum = 3;
          } else if (lower.contains('cargox') || lower.contains('bank')) {
            phaseNum = 4;
          } else if (lower.contains('clearance') || lower.contains('تخليص')) {
            phaseNum = 5;
          } else if (lower.contains('warehouse') || lower.contains('مخازن') || lower.contains('settlement')) {
            phaseNum = 6;
          } else if (lower.contains('closure') || lower.contains('إغلاق') || lower.contains('closed')) {
            phaseNum = 10;
          }
        }

        if (phaseNum != null) {
          const phaseMap = {
            1: {'ar': 'المرحلة الأولى: التخطيط والدراسات المسبقة', 'en': 'Phase 1: Import Planning & Feasibility'},
            2: {'ar': 'المرحلة الثانية: الاعتمادات وطلب ACID', 'en': 'Phase 2: Approvals & ACID Request'},
            3: {'ar': 'المرحلة الثالثة: الحجز وتدقيق المستندات', 'en': 'Phase 3: Booking & Documents Review'},
            4: {'ar': 'المرحلة الرابعة: شحن CargoX والنموذج البنكي', 'en': 'Phase 4: CargoX & Bank Form 4'},
            5: {'ar': 'المرحلة الخامسة: التخليص الجمركي والإفراج', 'en': 'Phase 5: Customs Clearance & Release'},
            6: {'ar': 'المرحلة السادسة: المخازن والتسوية النهائية', 'en': 'Phase 6: Warehouse & Final Settlement'},
            10: {'ar': 'المرحلة العاشرة: إغلاق وأرشفة الملف', 'en': 'Phase 10: Import File Closure & Archival'},
          };
          if (phaseMap.containsKey(phaseNum)) {
            return isArabic ? phaseMap[phaseNum]!['ar']! : phaseMap[phaseNum]!['en']!;
          }
        }

        return s;
      }

      expect(
        formatStageName('Phase 1: Import Planning & Feasibility', true),
        'المرحلة الأولى: التخطيط والدراسات المسبقة',
      );

      expect(
        formatStageName('المرحلة الأولى: التخطيط والدراسات المسبقة', false),
        'Phase 1: Import Planning & Feasibility',
      );

      final file3Arabic = formatStageName('Phase 1: Import Planning & Feasibility', true);
      final file4Arabic = formatStageName('المرحلة الأولى: التخطيط والدراسات المسبقة', true);
      expect(file3Arabic, equals(file4Arabic));
    });

    test('Clean task titles eliminates double parens and repeated phrases', () {
      String cleanTaskTitle(String title) {
        var cleaned = title.trim();
        cleaned = cleaned.replaceAll('((', '(').replaceAll('))', ')');
        if (cleaned.contains('شهادة المنشأ') && (cleaned.contains('Certificate of Origin') || cleaned.contains('COO'))) {
          cleaned = cleaned.replaceAll(
            RegExp(r'استيفاء شهادة المنشأ[\s\S]*?وتوثيقها رسمياً'),
            'استيفاء وتوثيق شهادة المنشأ المعتمدة (COO) رسمياً',
          );
        }
        if (cleaned.contains('إصدار شهادة الفحص المسبق') && (cleaned.contains('GOEIC') || cleaned.contains('الصادرات والواردات'))) {
          cleaned = cleaned.replaceAll(
            RegExp(r'إصدار شهادة الفحص المسبق قبل الشحن[\s\S]*?\)\)?'),
            'إصدار شهادة الفحص المسبق قبل الشحن (GOEIC - هيئة الرقابة على الصادرات والواردات)',
          );
        }
        return cleaned;
      }

      const legacyCoo = '[IMP-2026-0004] [ACID: 100] استيفاء شهادة المنشأ (شهادة المنشأ الموثقة للشحنة الكاملة (Certificate of Origin — COO)) وتوثيقها رسمياً';
      final cleanedCoo = cleanTaskTitle(legacyCoo);
      expect(cleanedCoo, '[IMP-2026-0004] [ACID: 100] استيفاء وتوثيق شهادة المنشأ المعتمدة (COO) رسمياً');
      expect(cleanedCoo.contains('(('), isFalse);

      const legacyGoeic = '[IMP-2026-0004] [ACID: 100] إصدار شهادة الفحص المسبق قبل الشحن (GOEIC (هيئة الصادرات والواردات))';
      final cleanedGoeic = cleanTaskTitle(legacyGoeic);
      expect(cleanedGoeic, '[IMP-2026-0004] [ACID: 100] إصدار شهادة الفحص المسبق قبل الشحن (GOEIC - هيئة الرقابة على الصادرات والواردات)');
      expect(cleanedGoeic.contains('(('), isFalse);
    });

    test('Document status mapping rules for checklist icons', () {
      bool isDocApproved(String status) {
        final s = status.toLowerCase();
        return s == 'approved' || s == 'verified' || s == 'completed' || s == 'received' || s == 'obtained' || s.contains('معتمد') || s.contains('مستوفى');
      }

      bool isDocRejected(String status) {
        final s = status.toLowerCase();
        return s == 'rejected' || s.contains('مرفوض');
      }

      expect(isDocApproved('Approved'), isTrue);
      expect(isDocApproved('معتمد'), isTrue);
      expect(isDocApproved('Verified'), isTrue);
      expect(isDocApproved('Pending'), isFalse);

      expect(isDocRejected('Rejected'), isTrue);
      expect(isDocRejected('Pending'), isFalse);

      bool shouldShowBlockingBadge(String status, bool isBlockingShipment) {
        return isBlockingShipment && !isDocApproved(status);
      }

      expect(shouldShowBlockingBadge('Approved', true), isFalse);
      expect(shouldShowBlockingBadge('Pending', true), isTrue);
      expect(shouldShowBlockingBadge('Pending', false), isFalse);
    });
  });
}
