/// Approved Domain Glossary & Language Directives for Sorour Logistics ERP AI Assistant.
///
/// Ensures strict terminological consistency across all model responses in both
/// English and Arabic, preventing arbitrary or conflicting translations.
class AiGlossary {
  AiGlossary._();

  /// Standard approved terminology pairs (English -> Arabic)
  static const Map<String, String> termsEnToAr = {
    'Shipment': 'شحنة',
    'Import File': 'ملف استيراد',
    'Purchase Order': 'أمر شراء',
    'Container': 'حاوية',
    'Container Allocation': 'تخصيص الحاويات',
    'Seal Number': 'رقم السيل (الختم الرصاص)',
    'Freight Booking': 'حجز الشحن',
    'Bill of Lading (B/L)': 'بوليصة الشحن',
    'Master B/L': 'بوليصة الماستر',
    'House B/L / Draft B/L': 'بوليصة الهاوس / مسودة بوليصة الشحن',
    'Port of Loading (POL)': 'ميناء الشحن',
    'Port of Discharge (POD)': 'ميناء التفريغ',
    'Customs Clearance': 'التخليص الجمركي',
    'Customs Release': 'الإفراج الجمركي',
    'ACID Number': 'رقم القيد الجمركي المسبق (ACID)',
    'Landed Cost': 'تكلفة الوصول الشاملة',
    'Import Duty': 'ضريبة الوارد (الجمارك)',
    'Value Added Tax (VAT)': 'ضريبة القيمة المضافة',
    'Schedule Tax': 'ضريبة الجدول',
    'Development Fee': 'رسم التنمية',
    'Customs Service Fees': 'رسوم الخدمات الجمركية',
    'Proforma Invoice (PI)': 'الفاتورة المبدئية',
    'Commercial Invoice (CI)': 'الفاتورة التجارية',
    'Packing List (PL)': 'بيان العبوة',
    'Certificate of Origin (COO)': 'شهادة المنشأ',
    'Pre-Shipment Inspection (GOEIC)': 'الفحص المسبق (هيئة الرقابة على الصادرات والواردات)',
    'Demurrage & Detention': 'غرامات التأخير والأرضيات',
    'Free Days': 'فترة السماح',
    'Verified Gross Mass (VGM)': 'وزن الحاوية المعتمد (VGM)',
    'Incoterms 2020': 'الشروط التجارية الدولية (Incoterms 2020)',
    'Read-After-Write (RAW) Verification': 'التحقق الفعلي بعد الكتابة',
  };

  /// Reverse lookup: Arabic -> English
  static const Map<String, String> termsArToEn = {
    'شحنة': 'Shipment',
    'ملف استيراد': 'Import File',
    'أمر شراء': 'Purchase Order',
    'حاوية': 'Container',
    'تخصيص الحاوية': 'Container Allocation',
    'تخصيص الحاويات': 'Container Allocation',
    'رقم السيل': 'Seal Number',
    'حجز الشحن': 'Freight Booking',
    'بوليصة الشحن': 'Bill of Lading (B/L)',
    'بوليصة الماستر': 'Master B/L',
    'بوليصة الهاوس': 'House B/L',
    'مسودة بوليصة الشحن': 'Draft B/L',
    'ميناء الشحن': 'Port of Loading (POL)',
    'ميناء التفريغ': 'Port of Discharge (POD)',
    'التخليص الجمركي': 'Customs Clearance',
    'الإفراج الجمركي': 'Customs Release',
    'رقم القيد الجمركي المسبق': 'ACID Number',
    'تكلفة الوصول الشاملة': 'Landed Cost',
    'ضريبة الوارد': 'Import Duty',
    'ضريبة القيمة المضافة': 'Value Added Tax (VAT)',
    'ضريبة الجدول': 'Schedule Tax',
    'رسم التنمية': 'Development Fee',
    'رسوم الخدمات الجمركية': 'Customs Service Fees',
    'الفاتورة المبدئية': 'Proforma Invoice (PI)',
    'الفاتورة التجارية': 'Commercial Invoice (CI)',
    'بيان العبوة': 'Packing List (PL)',
    'شهادة المنشأ': 'Certificate of Origin (COO)',
    'الفحص المسبق': 'Pre-Shipment Inspection (GOEIC)',
    'غرامات التأخير': 'Demurrage',
    'فترة السماح': 'Free Days',
    'وزن الحاوية المعتمد': 'Verified Gross Mass (VGM)',
    'التحقق الفعلي بعد الكتابة': 'Read-After-Write (RAW) Verification',
  };

  /// Lookup term in English -> Arabic
  static String? lookupEnToAr(String term) => termsEnToAr[term];

  /// Lookup term in Arabic -> English
  static String? lookupArToEn(String term) => termsArToEn[term];

  /// Generates the system prompt instructions ensuring terminology consistency
  /// and handling mixed-language inputs.
  static String getGlossaryPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('''
قواعد الدعم ثنائي اللغة والمسرد اللوجستي المعتمد (Bilingual Support & Approved Domain Glossary):
1. الكشف اللغوي المستقل لكل رسالة (Per-Message Dynamic Language Detection):
   - يجب الرد بنفس لغة الرسالة الحالية للمستخدم (إذا كتب بالعربية أجب بالعربية، وإذا كتب بالإنجليزية أجب بالإنجليزية).
   - إذا غيّر المستخدم لغته في منتصف المحادثة، حوّل لغة الرد فوراً وبشكل تلقائي دون سؤاله.
2. الحفاظ الصارم على المعرفات اللوجستية وأكواد النظام (System Identifiers Preservation):
   - يُحظر تماماً ترجمة أو تعريب أي معرفات أو أكواد نظام؛ يجب أن تبقى بنصها اللاتيني الأصلي في كلا اللغتين:
     * أرقام الحاويات (مثل: WHSU81072658, MSCU1000000)
     * أرقام السيل / الختم (مثل: WHA257097, SL-40HC-1)
     * أرقام الحجز وبوالص الهاوس (مثل: THXJ2608090, BKG-2026-0001)
     * أرقام ACID الجمركية (مثل: 5281534391023010013)
     * أكواد الملفات وأوامر الشراء (مثل: IMP-2026-0004, PO-2026-0001)
     * التواريخ (مثل: 2026-08-27 أو 27/08/2026)
3. المسرد اللوجستي المعتمد (Approved Domain Terminology):
   التزم بترجمة المصطلحات الفنية المعتمدة دون اختراع ترجمات عشوائية مغايرة:''');

    for (final entry in termsEnToAr.entries) {
      buffer.writeln('   * ${entry.key} ⇄ ${entry.value}');
    }

    buffer.writeln('''
4. معالجة الرسائل المختلطة (Mixed-Language Input):
   - إذا تضمنت رسالة المستخدم مزيجاً (مثل جملة عربية تحتوي على مصطلحات أو أكواد إنجليزية)، التزم باللغة السائدة سياقياً للرد، مع إبقاء المصطلحات والأكواد التقنية مدمجة بنصها المعتمد.
''');

    return buffer.toString();
  }

  /// Generates a concise per-turn response language directive for the active message.
  static String getLanguageDirective(String detectedLanguage) {
    if (detectedLanguage == 'en') {
      return '''
[Response Language Requirement]:
- The user's current message is detected as ENGLISH.
- You MUST respond in professional, enterprise ENGLISH.
- Adhere strictly to the Approved Domain Glossary.
- PRESERVE all system identifiers verbatim: container numbers, seal numbers, booking codes, ACID numbers, file codes (e.g. IMP-2026-0004), and dates. DO NOT translate or alter them.
- Format task and status lists using the 8-rule specification in English.
''';
    } else {
      return '''
[توجيه لغة الرد الحالية]:
- لغة رسالة المستخدم الحالية هي العربية (ARABIC).
- يجب أن يكون الرد باللغة العربية المهنية المعتمدة لنظام سرور للخدمات اللوجستية (Sorour Logistics ERP).
- التزم بالمسرد اللوجستي المعتمد.
- حافظ تماماً على أرقام الحاويات، أرقام السيل، بوالص الشحن، أرقام ACID، وأكواد الملفات (مثل IMP-2026-0004) والتواريخ بنصها وصيغتها الأصلية.
- نسق قوائم المهام وحالة الشحنات وفقاً للقواعد القياسية الثمانية بالعربية.
''';
    }
  }
}
