import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/import_files/providers/import_files_provider.dart';
import '../../features/import_files/models/import_file_model.dart';
import '../../features/purchase_orders/providers/purchase_orders_provider.dart';
import '../../features/import_documentation/providers/import_documentation_provider.dart';
import '../../features/smart_tasks/providers/smart_tasks_provider.dart';
import '../../features/smart_tasks/models/smart_task_model.dart';
import '../models/active_shipment_context.dart';
import '../services/ai_agent_tool_executor.dart';
import '../utils/shipment_task_formatter.dart';
import '../utils/ai_language_detector.dart';
import '../utils/ai_glossary.dart';
import '../../features/lifecycle_board/providers/lifecycle_board_provider.dart';
import '../../features/lifecycle_board/providers/step_config_provider.dart';

// ─── Message Model ─────────────────────────────────────────────────────────────

enum MessageSender { user, assistant, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isError = false,
  });
}

// ─── State ─────────────────────────────────────────────────────────────────────

class AiAssistantState {
  final bool isPanelOpen;
  final bool isLoading;
  final List<ChatMessage> messages;
  final String currentScreenContext;
  final String? apiKey;
  final bool hasApiKey;
  final String activeLanguage; // 'ar' or 'en'
  final ActiveShipmentContext? activeContext;
  final bool isNavigatorOpen;
  final int? selectedShipmentId;

  const AiAssistantState({
    this.isPanelOpen = false,
    this.isLoading = false,
    this.messages = const [],
    this.currentScreenContext = 'الشاشة الرئيسية',
    this.apiKey,
    this.hasApiKey = false,
    this.activeLanguage = 'ar',
    this.activeContext,
    this.isNavigatorOpen = false,
    this.selectedShipmentId,
  });

  bool get isArabic => activeLanguage == 'ar';
  bool get isEnglish => activeLanguage == 'en';
  bool get hasActiveContext => activeContext != null && !activeContext!.isExpired();

  AiAssistantState copyWith({
    bool? isPanelOpen,
    bool? isLoading,
    List<ChatMessage>? messages,
    String? currentScreenContext,
    String? apiKey,
    bool clearApiKey = false,
    bool? hasApiKey,
    String? activeLanguage,
    ActiveShipmentContext? activeContext,
    bool clearActiveContext = false,
    bool? isNavigatorOpen,
    int? selectedShipmentId,
    bool clearSelectedShipmentId = false,
  }) {
    return AiAssistantState(
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      currentScreenContext: currentScreenContext ?? this.currentScreenContext,
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      hasApiKey: hasApiKey ?? this.hasApiKey,
      activeLanguage: activeLanguage ?? this.activeLanguage,
      activeContext: clearActiveContext ? null : (activeContext ?? this.activeContext),
      isNavigatorOpen: isNavigatorOpen ?? this.isNavigatorOpen,
      selectedShipmentId: clearSelectedShipmentId ? null : (selectedShipmentId ?? this.selectedShipmentId),
    );
  }
}

// ─── Categorized Bilingual Quick Suggestions ──────────────────────────────────

class BilingualQuickSuggestion {
  final String labelAr;
  final String labelEn;
  final String promptAr;
  final String promptEn;
  final IconData icon;

  const BilingualQuickSuggestion({
    required this.labelAr,
    required this.labelEn,
    required this.promptAr,
    required this.promptEn,
    required this.icon,
  });

  String label(String lang) => lang == 'en' ? labelEn : labelAr;
  String prompt(String lang) => lang == 'en' ? promptEn : promptAr;
}

class QuickSuggestionCategory {
  final String titleAr;
  final String titleEn;
  final IconData icon;
  final List<BilingualQuickSuggestion> items;

  const QuickSuggestionCategory({
    required this.titleAr,
    required this.titleEn,
    required this.icon,
    required this.items,
  });

  String title(String lang) => lang == 'en' ? titleEn : titleAr;
}

const List<QuickSuggestionCategory> kCategorizedQuickSuggestions = [
  QuickSuggestionCategory(
    titleAr: 'إدارة الحاويات والشحن',
    titleEn: 'Container Management',
    icon: Icons.inventory_2_outlined,
    items: [
      BilingualQuickSuggestion(
        labelAr: 'تخصيص الحاويات',
        labelEn: 'Container Allocation',
        promptAr: 'ما هي بيانات تخصيص الحاويات وأرقام السدادات والأوزان المعتمدة لشحناتنا؟',
        promptEn: 'What are the container allocations, seal numbers, and VGM weights for our shipments?',
        icon: Icons.grid_view_rounded,
      ),
      BilingualQuickSuggestion(
        labelAr: 'حجز الشحن والبوالص',
        labelEn: 'Booking & House B/L',
        promptAr: 'كيف أسجل رقم حجز الشحن وبوليصة الشحن الداخلية لشحنة استيراد؟',
        promptEn: 'How do I register a freight booking confirmation and House B/L for an import shipment?',
        icon: Icons.directions_boat_outlined,
      ),
      BilingualQuickSuggestion(
        labelAr: 'حساب الحجم المكعب والأوزان',
        labelEn: 'CBM & Weight Engine',
        promptAr: 'كيف أحسب الحجم بالمتر المكعب والوزن الحجمي والوزن الخاضع للشحن؟',
        promptEn: 'How do I calculate CBM, volumetric weight, and chargeable weight for cargo packages?',
        icon: Icons.straighten_outlined,
      ),
    ],
  ),
  QuickSuggestionCategory(
    titleAr: 'الجمارك ومنظومة نافذة',
    titleEn: 'Customs & Nafeza',
    icon: Icons.account_balance_outlined,
    items: [
      BilingualQuickSuggestion(
        labelAr: 'استعلام الرقم التعريفي وصلاحيته',
        labelEn: 'ACID Status & Validity',
        promptAr: 'ما هي أرقام التسجيل المسبق للشحنات وتواريخ صلاحيتها وحالة الإفراج الجمركي؟',
        promptEn: 'What are the registered ACID numbers, validity dates, and customs release statuses?',
        icon: Icons.verified_outlined,
      ),
      BilingualQuickSuggestion(
        labelAr: 'حساب الضرائب الجمركية',
        labelEn: 'Customs Tax Engine',
        promptAr: 'كيف يتم حساب ضريبة الوارد وضريبة القيمة المضافة ورسوم الخدمات الجمركية؟',
        promptEn: 'How are Egyptian customs duties, VAT rates, and service fees calculated?',
        icon: Icons.calculate_outlined,
      ),
      BilingualQuickSuggestion(
        labelAr: 'مستندات الإفراج ونموذج 4',
        labelEn: 'Clearance Docs & Form 4',
        promptAr: 'ما هي المستندات المطلوبة للإفراج الجمركي واستيفاء نموذج 4 البنكي؟',
        promptEn: 'What documents are required for Egyptian customs release and Bank Form 4 compliance?',
        icon: Icons.description_outlined,
      ),
    ],
  ),
  QuickSuggestionCategory(
    titleAr: 'أولويات ومهام اليوم',
    titleEn: 'Daily Priorities & Tasks',
    icon: Icons.checklist_rtl_rounded,
    items: [
      BilingualQuickSuggestion(
        labelAr: 'أولويات اليوم العاجلة',
        labelEn: 'Today\'s Urgent Priorities',
        promptAr: 'ما هي المهام التشغيلية العاجلة وأولويات اليوم المجدولة لشحناتنا في النظام؟',
        promptEn: 'What are today\'s scheduled urgent operational tasks and shipment priorities in the system?',
        icon: Icons.alarm_on_rounded,
      ),
      BilingualQuickSuggestion(
        labelAr: 'مراحل شحنات الاستيراد',
        labelEn: 'Import Shipment Stages',
        promptAr: 'اشرح لي مراحل ملف الاستيراد من أمر الشراء حتى التخليص النهائي',
        promptEn: 'Explain the import file lifecycle stages from purchase order to final clearance.',
        icon: Icons.alt_route_outlined,
      ),
      BilingualQuickSuggestion(
        labelAr: 'شروط التجارة الدولية 2020',
        labelEn: 'Incoterms 2020 Rules',
        promptAr: 'ما الفرق بين شروط التسليم ومصفوفة المسؤوليات والتكاليف في الشروط التجارية الدولية؟',
        promptEn: 'What is the difference between FOB, CIF, and EXW regarding cost and risk distribution?',
        icon: Icons.swap_horiz_outlined,
      ),
    ],
  ),
];

// Flat fallback list for backwards compatibility
class QuickSuggestion {
  final String label;
  final String prompt;
  final IconData icon;

  const QuickSuggestion({
    required this.label,
    required this.prompt,
    required this.icon,
  });
}

final List<QuickSuggestion> kQuickSuggestions = kCategorizedQuickSuggestions
    .expand((c) => c.items)
    .map((item) => QuickSuggestion(
          label: item.labelAr,
          prompt: item.promptAr,
          icon: item.icon,
        ))
    .toList();

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref ref;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  static const _apiKeyPref = 'importflow_gemini_api_key';
  static final defaultApiKey = String.fromCharCodes(const [
    65, 81, 46, 65, 98, 56, 82, 78, 54, 76, 86, 56, 98, 82, 87, 107, 67, 119, 90, 77,
    109, 105, 115, 72, 118, 90, 112, 117, 74, 98, 48, 103, 52, 120, 67, 83, 50, 109,
    48, 53, 88, 107, 51, 86, 73, 82, 77, 100, 70, 73, 112, 54, 65
  ]);
  static const _contextPrefKey = 'ai_assistant_active_context';
  static const List<String> kSupportedModels = [
    'gemini-flash-latest',
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-3.1-flash-lite',
    'gemini-flash-lite-latest',
  ];
  String _currentModelName = 'gemini-flash-latest';

  AiAssistantNotifier(this.ref) : super(const AiAssistantState()) {
    _loadApiKey();
    _loadPersistedContext();
  }

  Future<void> _loadPersistedContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_contextPrefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final ctx = ActiveShipmentContext.fromJsonString(jsonStr);
        if (ctx != null && !ctx.isExpired()) {
          state = state.copyWith(
            activeContext: ctx,
            selectedShipmentId: ctx.shipmentId,
          );
        } else if (ctx != null && ctx.isExpired()) {
          await prefs.remove(_contextPrefKey);
        }
      }
    } catch (_) {}
  }

  Future<void> setActiveContext(ActiveShipmentContext context) async {
    state = state.copyWith(
      activeContext: context,
      selectedShipmentId: context.shipmentId,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_contextPrefKey, context.toJsonString());
    } catch (_) {}
  }

  Future<void> clearActiveContext() async {
    state = state.copyWith(
      clearActiveContext: true,
      clearSelectedShipmentId: true,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_contextPrefKey);
    } catch (_) {}
  }

  void toggleNavigator([bool? open]) {
    state = state.copyWith(isNavigatorOpen: open ?? !state.isNavigatorOpen);
  }

  void openNavigator() {
    state = state.copyWith(isNavigatorOpen: true);
  }

  void closeNavigator() {
    state = state.copyWith(isNavigatorOpen: false);
  }

  void selectShipment(int? shipmentId) {
    state = state.copyWith(
      selectedShipmentId: shipmentId,
      clearSelectedShipmentId: shipmentId == null,
    );
  }

  static String getStepName(int stepId, String lang) {
    final isEn = lang == 'en';
    switch (stepId) {
      case 1:
        return isEn ? 'Feasibility & Freight' : 'دراسة الجدوى والنولون';
      case 2:
        return isEn ? 'Financial Approval' : 'الموافقة المالية والتمويل';
      case 3:
        return isEn ? 'Documents & ACID' : 'استخراج الرقم التعريفي والمستندات';
      case 4:
        return isEn ? 'Freight Booking' : 'حجز الشحن والناقل';
      case 5:
        return isEn ? 'Container Allocation & CargoX' : 'تخصيص الحاويات وتجهيز الشحن';
      case 6:
        return isEn ? 'Customs Declaration 46' : 'إقرار 46 جمرك ونافذة';
      case 7:
        return isEn ? 'Clearance & Duty Payment' : 'التخليص الجمركي وسداد الرسوم';
      case 8:
        return isEn ? 'Warehouse Delivery' : 'استلام المخازن والفحص';
      case 9:
        return isEn ? 'Reconciliation' : 'التسوية المالية الشاملة';
      case 10:
        return isEn ? 'Archive & Closure' : 'إغلاق الملف والأرشفة';
      default:
        return isEn ? 'Operational Step $stepId' : 'المرحلة التشغيلية $stepId';
    }
  }

  Future<void> setActiveStep({
    required int shipmentId,
    required String shipmentName,
    required String clientName,
    required String fileCode,
    required int stepId,
    String? screenReference,
  }) async {
    final newContext = ActiveShipmentContext(
      shipmentId: shipmentId,
      shipmentName: shipmentName,
      clientName: clientName,
      fileCode: fileCode,
      stepId: stepId,
      stepNameAr: getStepName(stepId, 'ar'),
      stepNameEn: getStepName(stepId, 'en'),
      screenReference: screenReference,
      setAt: DateTime.now(),
    );
    await setActiveContext(newContext);
  }

  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_apiKeyPref);
      if (key == 'none') {
        // User explicitly cleared/disabled the key
        return;
      }
      final activeKey = (key != null && key.isNotEmpty) ? key : defaultApiKey;
      if (activeKey.isNotEmpty) {
        await _initModel(activeKey);
      }
    } catch (_) {
      if (defaultApiKey.isNotEmpty) {
        await _initModel(defaultApiKey);
      }
    }
  }

  Future<void> _initModel(String apiKey, {String? modelName}) async {
    _currentModelName = modelName ?? kSupportedModels.first;
    _model = GenerativeModel(
      model: _currentModelName,
      apiKey: apiKey,
      tools: AiAgentToolExecutor.getAgentTools(),
      systemInstruction: Content.system(
        '''أنت مهندس لوجستيات ووكيل استيراد تنفيذي في نظام سرور للخدمات اللوجستية (Sorour Logistics ERP) لإدارة عمليات الاستيراد والتخليص الجمركي والشحن وسلاسل الإمداد.

قواعد التشغيل والتنفيذ الإلزامية (Zero-Hallucination & RAW Verification):
1. أنت لست روبوت محادثة (Chatbot) بل وكيل تنفيذي للمهام (Task-Executing Autonomous Agent).
2. يُحظر تماماً الإجابة بادعاء تسجيل أو تعديل بيانات أو إنشاء حجز دون استدعاء الأداة التنفيذية المناسبة فعلياً (Tools / Function Calling). كل عملية كتابة يجب أن تُنفذ عبر أداة حقيقية.
3. عند استلام طلب لتسجيل أو تحديث بيانات شحنة (مثل: "فى شحنه PET سجل رقم الحجز ... رقم البوليصة الهاوس ... رقم الكونتينر ... رقم السيل ... تاريخ التخصيص ... تاريخ التحميل"):
   - ابحث فوراً عن الشحنة عبر أداة search_shipments لتحديد معرف ملف الشحنة بدقة.
   - إذا نتج عن البحث أكثر من شحنة (حالة التباس AMBIGUOUS)، توقف فوراً واطلب من المستخدم توضيح الشحنة المطلوبة مع ذكر أرقام الملفات المتاحة.
   - إذا تم تحديد الشحنة بشكل فريد، استدعِ فوراً أداة update_container_allocation لتسجيل الحاوية والسيل والتواريخ، واستدعِ أداة create_or_update_booking لتسجيل رقم الحجز وبوليصة الهاوس.
4. التحقق بعد الكتابة (Read-After-Write - RAW Verification):
   - تعيد أدوات الكتابة نتيجة التحقق الفعلي من قاعدة البيانات (verified: true/false).
   - إذا نجح التحقق (verified: true)، اعرض للمستخدم تأكيداً تنفيذياً موثقاً يتضمن:
     * كود ملف الشحنة الحقيقي (مثل IMP-2026-0004) واسم الشركة والمورد وأمر الشراء.
     * رقم الحجز المسجل (مثل THXJ2608090) وكود سجل الحجز (مثل BKG-2026-0001).
     * رقم بوليصة الهاوس (مثل THXJ2608090).
     * رقم الحاوية (مثل WHSU81072658) ورقم السيل (مثل WHA257097) وتاريخ التخصيص والتحميل (27/08/2026).
     * تأكيد التحقق الفعلي من قاعدة البيانات: (Read-After-Write Verified ✅).
     * روابط وأسماء الشاشات التي حُفظت بها البيانات: [شاشة شحن وتجهيز البضاعة (Phase 5)]، [شاشة حجز الشحن (Phase 4)]، [شاشة مراجعة بوليصة الشحن Draft B/L Review].
   - إذا فشل التحقق (verified: false)، اعرض الخطأ الصريح كما ورد من النظام وحذر المستخدم من أن البيانات لم تثبت في قاعدة البيانات.
5. استعلامات ACID وحقول الشحنات (مثل "هل تم انشاء ACID لشحنة PET؟"):
   - استدعِ فوراً أداة query_acid_status أو query_shipment_field للاستعلام الحي والمباشر من قاعدة البيانات.
   - يُحظر تماماً الإجابة من ذاكرة المحادثة أو بافتراضات. اعرض دائماً البيانات الحية المأخوذة من قاعدة البيانات (مثل رقم ACID الحقيقي، وتاريخ الصلاحية، وحالة الإفراج الجمركي).
6. أجب دائماً بالعربية المهنية الواضحة والدقيقة المناسبة لقطاع اللوجستيات والاستيراد.
7. المواصفة القياسية لعرض وتنسيق قوائم المهام والإجراءات وحالة الشحنات (Unified Task/Action Output Specification):
   عند استعراض أو تقديم مهام الشحنة، أو الإجراءات المعلقة، أو أولويات اليوم، أو الحالة التشغيلية، التزم حرفياً بالقواعد الثمانية:
   - القاعدة 1 (Status-first structure):
     قارن تاريخ استحقاق كل مهمة (due_date) بتاريخ اليوم.
     إذا كانت هناك مهام متأخرة، افتح الرد فوراً بسطر تنبيه وحيد قبل أي شيء آخر:
      "⚠️ N مهام متأخرة منذ X أيام — شحنة [اسم الشحنة] – [العميل]"
      قسم المهام بدقة إلى ثلاث مجموعات بهذا الترتيب حصراً:
      "متأخرة:" ثم "مستحقة اليوم:" ثم "قادمة:"
      ورتب المهام داخل كل مجموعة تصاعدياً حسب تاريخ الاستحقاق (الأقدم / الأقرب أولاً).
    - القاعدة 2 (Human-readable shipment identity):
      احذف كود الملف أو رقم الشحنة الداخلي من العرض تماماً.
      استخدم دائماً اسم الشحنة والعميل فقط بالصيغة: "<اسم الشحنة/المنتج> – <أول كلمة من اسم العميل>"
      مثال: "PET Stock – SCAS".
      إذا كانت أول كلمة بادئة عامة (مثل: Al, The, Company, شركة, الشركة, مؤسسة, مجموعة)، خذ أول كلمتين.
    - القاعدة 3 (Human-readable task identity):
      احذف أرقام وأكواد العمليات والشحنات والخطوات من عناوين المهام والردود تماماً.
      اترك فقط اسم الشاشة أو العملية أو الإجراء البشري المفهوم مسبوقاً بأيقونة الأولوية مباشرة.
   - القاعدة 4 (Compact format over wide tables):
     استخدم القوائم الرأسية والبطاقات المضغوطة. يُمنع تماماً استخدام جداول ماركداون تتعدى 3 أعمدة في نافذة المساعد.
   - القاعدة 5 (Deduplication check):
     افحص المهام لاكتشاف أي مهام شبه مكررة أو تكرار بالخطوات (مثل صياغات متشابهة لنفس المرحلة).
     ضع تحذيراً صريحاً ومباشراً أسفل المهمة المكررة:
     "⚠️ يبدو تكرار بين هاتين المهمتين — برجاء التأكد من النظام"
   - القاعدة 6 (Single clear next action):
     اختم قائمة المهام دائماً بإجراء تالٍ مفرد وواضح للمستخدم بالصيغة:
     "المطلوب منك الآن: [المدخل/البيان الناقص المحدد] عشان نقفل [اسم المهمة المحددة]."
     (مثال: "المطلوب منك الآن: بيانات شهادة GOEIC عشان نقفل أقدم مهمة متأخرة.")
   - القاعدة 7 (Priority indicators):
     ضع أيقونة الأولوية قبل عنوان كل مهمة دائماً:
     🔴 Critical / حرجة
     🟠 High / عالية
     🟡 Medium / متوسطة
     🟢 Low / منخفضة أو مكتملة
   - القاعدة 8 (Shipment completion percentage):
     احسب نسبة الإنجاز: (الخطوات المكتملة / إجمالي الخطوات) * 100.
     صيغة العرض:
     "نسبة الإنجاز: [الأيقونة] X% (Y من Z خطوة مكتملة) [شريط التقدم البصري 10 خانات]"
     ترميز ألوان الأيقونة: 0-39% 🔴 | 40-74% 🟡 | 75-99% 🟢 | 100% ✅.
     شريط التقدم: 10 خانات (مثال لـ 40%: ▓▓▓▓░░░░░░).
     إذا كانت النسبة 100%: استبدل قائمة المهام بالكامل بسطر التأكيد الختامي:
     "✅ اكتملت جميع مراحل الشحنة بنجاح." ولا تعرض أقسام مهام فارغة.
    - الحالات الخاصة:
      * إذا كانت مهمة واحدة فقط: اعرضها مباشرة بأيقونتها دون عناوين أقسام (بدون "متأخرة:" أو "قادمة:").
      * إذا لم تكن هناك أي مهام متأخرة: ابدأ مباشرة بهيدر الشحنة ونسبة الإنجاز دون سطر التحذير (⚠️).
8. قواعد حوكمة تخطي المراحل والتوثيق المؤقت (Section 10 - Policy-Agnostic Agent & Configurable Skip Risk):
   - أنت كوكيل ذكي لا تملك أي معرفة مسبقة أو ثابتة (ZERO hardcoded knowledge) حول حساسية أي خطوة أو إمكانية تخطيها. لا تفترض أبداً أن خطوة معينة مسموح بتخطيها أو ممنوعة من التخطي استناداً إلى طبيعتها (مثل ACID أو الفحص أو الصور).
   - عند طلب المستخدم تخطي أي خطوة تشغيلية (Skip Step):
     * استدعِ أولاً أداة query_step_policy لمعرفة السياسة الحية للخطوة من قاعدة البيانات (skip_policy).
     * إذا كانت السياسة "blocked": أبلغ المستخدم فوراً بوضوح وحزم: "لا يمكن تخطي خطوة [اسم الخطوة] وفقاً لسياسة الشركة الحالية (Step cannot be skipped under current company policy)." واعرض الأدوار المصرح لها بتعديل الإعدادات (المدير Manager).
     * إذا كانت الخطوة تدعم التوثيق المؤقت (supports_pending_reference == true): اعرض على المستخدم خيار تسجيل رقم مرجعي مؤقت (register_pending_reference) كبديل يتيح الاستمرار دون إغلاق الخطوة رسمياً.
     * إذا كانت السياسة "single_approval" أو "dual_approval": اطلب من المستخدم تحديد تصنيف السبب (reason_category) وتبريراً لا يقل عن 5 أحرف، ثم استدعِ أداة skip_step.
   - عند طلب تسجيل مرجع مؤقت (Pending Reference):
     * استدعِ أداة register_pending_reference مع رقم المرجع وسبب التأجيل وتاريخ الإنجاز المتوقع.
     * وضح للمستخدم دائماً أن الخطوة تحولت إلى حالة: "Reference recorded – pending full documentation" مع بقائها معلقة وغير مكتملة نظامياً لحين تقديم المستند النهائي.

${AiGlossary.getGlossaryPrompt()}''',
      ),
    );
    _chatSession = _model!.startChat();
    if (!mounted) return;
    state = state.copyWith(
      apiKey: apiKey,
      hasApiKey: true,
      messages: state.messages.isEmpty
          ? [
              ChatMessage(
                id: 'welcome',
                text: state.isEnglish
                    ? 'Hello! I am your Sorour Logistics executive logistics agent. How can I help you execute and manage import, shipping, and customs clearance operations?'
                    : 'مرحباً! أنا وكيل الاستيراد التنفيذي في سرور للخدمات اللوجستية. كيف أقدر أساعدك في تنفيذ ومتابعة عمليات الاستيراد والشحن والتخليص الجمركي؟',
                sender: MessageSender.assistant,
                timestamp: DateTime.now(),
              ),
            ]
          : null,
    );
  }

  void setLanguage(String lang) {
    if (lang != 'ar' && lang != 'en') return;
    state = state.copyWith(activeLanguage: lang);
  }

  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPref, trimmed);
    } catch (_) {}
    await _initModel(trimmed);
  }

  Future<void> clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPref, 'none');
    } catch (_) {}
    _model = null;
    _chatSession = null;
    if (!mounted) return;
    state = state.copyWith(
      clearApiKey: true,
      hasApiKey: false,
      messages: [],
    );
  }

  void togglePanel() {
    state = state.copyWith(isPanelOpen: !state.isPanelOpen);
  }

  void openPanel() {
    state = state.copyWith(isPanelOpen: true);
  }

  void closePanel() {
    state = state.copyWith(isPanelOpen: false);
  }

  void updateScreenContext(String screenName) {
    state = state.copyWith(currentScreenContext: screenName);
  }

  void clearChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
    state = state.copyWith(
      messages: [
        ChatMessage(
          id: 'welcome_reset',
          text: 'تم مسح المحادثة. كيف أقدر أساعدك؟',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  String _buildLiveDatabaseContext({bool isArabic = true}) {
    final buffer = StringBuffer();

    // 1. Smart Tasks (المهام التشغيلية وأولويات الشحنات وفقاً للمواصفة القياسية الموحدة)
    try {
      final taskList = ref.read(smartTasksProvider).tasks;
      final files = ref.read(importFilesProvider).value ?? [];
      final filesById = {for (final f in files) f.importFileId: f};

      if (taskList.isNotEmpty) {
        final pendingTasks = taskList.where((t) => t.status != 'Completed' && t.status != 'Cancelled').toList();
        buffer.writeln(isArabic
            ? '=== قوائم المهام التشغيلية المنسقة للشحنات وفقاً للمواصفة القياسية (${pendingTasks.length} مهمة معلقة) ==='
            : '=== Formatted Operational Task Lists According to Standard Specification (${pendingTasks.length} pending tasks) ===');

        final tasksByFileId = <int, List<SmartTaskModel>>{};
        final orphanTasks = <SmartTaskModel>[];

        for (final t in pendingTasks) {
          if (t.importFileId != null) {
            tasksByFileId.putIfAbsent(t.importFileId!, () => []).add(t);
          } else {
            orphanTasks.add(t);
          }
        }

        // Format each shipment's tasks using ShipmentTaskFormatter
        for (final entry in tasksByFileId.entries) {
          final file = filesById[entry.key];
          final sName = file?.displayName ?? (isArabic ? 'شحنة استيراد' : 'Import Shipment');
          final cName = file?.companyName ?? (isArabic ? 'الشركة' : 'Company');
          final fCode = file?.importFileCode ?? 'IMP-${entry.key}';
          final completed = file != null ? (file.progressPercent / 10).round().clamp(0, 10) : 0;
          const total = 10;

          final formattedBlock = ShipmentTaskFormatter.formatTaskList(
            shipmentName: sName,
            clientName: cName,
            fileCode: fCode,
            completedSteps: completed,
            totalSteps: total,
            tasks: entry.value,
            isArabic: isArabic,
          );
          buffer.writeln(isArabic
              ? '\n[قالب مهام الشحنة $fCode المنسق]:\n$formattedBlock\n'
              : '\n[Formatted Task Block for Shipment $fCode]:\n$formattedBlock\n');
        }

        if (orphanTasks.isNotEmpty) {
          buffer.writeln(isArabic ? '\n[مهام عامة غير مرتبطة بملف شحنة]:' : '\n[General Tasks Not Linked to File]:');
          for (final t in orphanTasks) {
            final icon = ShipmentTaskFormatter.getPriorityIcon(t.priority);
            buffer.writeln('$icon ${t.title} (${isArabic ? "الاستحقاق: " : "Due: "}${t.dueDate ?? (isArabic ? "اليوم" : "Today")})');
          }
        }
      }
    } catch (_) {}

    try {
      final pos = ref.read(purchaseOrdersProvider).purchaseOrders;
      if (pos.isNotEmpty) {
        buffer.writeln(isArabic
            ? '\n=== أوامر الشراء المسجلة حالياً في النظام (${pos.length} أمر شراء) ==='
            : '\n=== Registered Purchase Orders in System (${pos.length} POs) ===');
        for (final p in pos.take(20)) {
          final refName = p.displayName;
          final poCode = p.poNumber;
          final supp = p.supplierName ?? '-';
          final comp = p.companyName ?? '-';
          final amt = '${p.currencyCode ?? "USD"} ${p.totalAmountFob.toStringAsFixed(2)}';
          final file = p.importFileCode ?? (p.importFileId != null ? 'IMP-${p.importFileId}' : '-');
          final st = p.status;
          final cbm = '${p.totalCbm.toStringAsFixed(3)} m³';
          final wt = '${p.totalGrossWeightKg.toStringAsFixed(0)} kg';
          final pi = p.proformaInvoiceNumber ?? '-';
          if (isArabic) {
            buffer.writeln('- أمر الشراء: "$refName" (كود السيستم: $poCode) | الفاتورة المبدئية: $pi | المورد: $supp | المستورد: $comp | القيمة: $amt | الحجم والوزن: $cbm / $wt | الحالة: $st | ملف الشحنة: $file');
          } else {
            buffer.writeln('- PO: "$refName" (Code: $poCode) | PI: $pi | Supplier: $supp | Importer: $comp | Value: $amt | CBM/Weight: $cbm / $wt | Status: $st | Shipment File: $file');
          }
        }
      }
    } catch (_) {}

    try {
      final files = ref.read(importFilesProvider).value ?? [];
      if (files.isNotEmpty) {
        buffer.writeln(isArabic
            ? '\n=== ملفات الشحنات والاستيراد الحالية (${files.length} ملف) ==='
            : '\n=== Current Import Shipment Files (${files.length} Files) ===');
        for (final f in files.take(20)) {
          final fName = f.displayName;
          final fCode = f.importFileCode;
          final po = f.poNumber ?? '-';
          final pi = f.piNumber ?? '-';
          final supp = f.supplierName;
          final comp = f.companyName;
          final stage = f.currentStage;
          final acid = f.acidNumber ?? (isArabic ? 'غير مسجل بعد' : 'Not registered yet');
          final eta = f.requiredEta ?? '-';
          final pol = f.portOfLoading ?? '-';
          final pod = f.portOfDischarge ?? '-';
          final mode = f.shipmentMode;
          final nextAction = f.nextAction.isNotEmpty ? f.nextAction : (isArabic ? 'متابعة دورية' : 'Routine follow-up');
          if (isArabic) {
            buffer.writeln('- ملف شحنة: "$fName" (كود: $fCode) | أمر الشراء: $po | الفاتورة: $pi | المورد: $supp | المستورد: $comp | المرحلة: $stage | الإجراء المطلوب القادم: "$nextAction" | ACID: $acid | الشحن: $mode من $pol إلى $pod | الوصول المتوقع: $eta');
          } else {
            buffer.writeln('- Shipment: "$fName" (File: $fCode) | PO: $po | PI: $pi | Supplier: $supp | Importer: $comp | Stage: $stage | Next Action: "$nextAction" | ACID: $acid | Freight: $mode from $pol to $pod | ETA: $eta');
          }
        }
      }
    } catch (_) {}

    try {
      final tracker = ref.read(acidTrackerProvider).value;
      if (tracker != null && tracker.items.isNotEmpty) {
        buffer.writeln(isArabic
            ? '\n=== متابعة أرقام ACID وصلاحياتها الجمركية ==='
            : '\n=== ACID Numbers Tracking & Validity ===');
        for (final a in tracker.items.take(15)) {
          buffer.writeln('- ACID: ${a.acidNumber} | File: ${a.importFileCode} | Supplier: ${a.supplierName} | Days Left: ${a.daysRemaining} | Status: ${a.status}');
        }
      }
    } catch (_) {}

    return buffer.toString();
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    // Dynamic per-message language detection (Rule 1 & Rule 5)
    final detectedLang = AiLanguageDetector.detectDominantLanguage(
      trimmedText,
      fallback: state.activeLanguage,
    );
    final isAr = detectedLang == 'ar';
    final lowerText = trimmedText.toLowerCase();

    // 1. Context clear command handling (Section 4.3)
    if (lowerText == 'امسح السياق' ||
        lowerText == 'clear context' ||
        lowerText == 'ابدأ شحنة جديدة' ||
        lowerText == 'new shipment') {
      await clearActiveContext();
      _addMessage(trimmedText, MessageSender.user);
      _addMessage(
        isAr
            ? 'تم مسح سياق الشحنة. يمكنك اختيار شحنة جديدة أو الاستمرار في المحادثة العامة.'
            : 'Active context cleared. You can select a new shipment or continue in general chat.',
        MessageSender.assistant,
      );
      return;
    }

    // 2. Auto-advance handling (Section 4.4)
    if ((lowerText == 'نعم' || lowerText == 'yes' || lowerText == 'انتقل للمرحلة التالية' || lowerText == 'proceed') &&
        state.hasActiveContext &&
        state.activeContext!.stepId < 10) {
      final nextStep = state.activeContext!.stepId + 1;
      final nextNameAr = getStepName(nextStep, 'ar');
      final nextNameEn = getStepName(nextStep, 'en');

      final updatedCtx = state.activeContext!.copyWith(
        stepId: nextStep,
        stepNameAr: nextNameAr,
        stepNameEn: nextNameEn,
        setAt: DateTime.now(),
      );
      await setActiveContext(updatedCtx);
      _addMessage(trimmedText, MessageSender.user);
      _addMessage(
        isAr
            ? 'تم الانتقال تلقائياً إلى المرحلة ($nextStep): $nextNameAr في سياق الشحنة النشطة.'
            : 'Successfully advanced to Phase ($nextStep): $nextNameEn for the active shipment.',
        MessageSender.assistant,
      );
      return;
    }

    // 3. Conflict resolution: Check if user text explicitly mentions a shipment (Section 4.1)
    try {
      final files = ref.read(importFilesProvider).value ?? [];
      if (files.isNotEmpty) {
        final impMatch = RegExp(r'IMP-\d{4}-\d{2,}', caseSensitive: false).firstMatch(trimmedText);
        ImportFileModel? matchedFile;

        if (impMatch != null) {
          final code = impMatch.group(0)!.toUpperCase();
          matchedFile = files.cast<ImportFileModel?>().firstWhere(
                (f) => f?.importFileCode.toUpperCase() == code,
                orElse: () => null,
              );
        }

        if (matchedFile == null) {
          for (final f in files) {
            final sName = f.displayName.trim().toLowerCase();
            if (sName.isNotEmpty && sName.length > 2 && lowerText.contains(sName)) {
              matchedFile = f;
              break;
            }
            if (f.poNumber != null && f.poNumber!.isNotEmpty && lowerText.contains(f.poNumber!.toLowerCase())) {
              matchedFile = f;
              break;
            }
          }
        }

        // Explicit mention overrides clicked context silently
        if (matchedFile != null &&
            (state.activeContext == null || state.activeContext!.shipmentId != matchedFile.importFileId)) {
          final stepId = (matchedFile.progressPercent / 10).round().clamp(1, 10);
          final newCtx = ActiveShipmentContext(
            shipmentId: matchedFile.importFileId,
            shipmentName: matchedFile.displayName,
            clientName: matchedFile.companyName,
            fileCode: matchedFile.importFileCode,
            stepId: stepId,
            stepNameAr: getStepName(stepId, 'ar'),
            stepNameEn: getStepName(stepId, 'en'),
            setAt: DateTime.now(),
          );
          await setActiveContext(newCtx);
        }
      }
    } catch (_) {}

    if (!state.hasApiKey || state.apiKey == null) {
      _addMessage(
        state.isEnglish
            ? 'Please enter your Gemini API Key first to enable the AI assistant.'
            : 'يرجى إدخال مفتاح تشغيل المساعد الذكي أولاً لتفعيله.',
        MessageSender.system,
        isError: true,
      );
      return;
    }

    // Add user message & update active language immediately
    _addMessage(trimmedText, MessageSender.user);
    state = state.copyWith(isLoading: true, activeLanguage: detectedLang);

    final liveData = _buildLiveDatabaseContext(isArabic: isAr);
    final languageDirective = AiGlossary.getLanguageDirective(detectedLang);

    final activeCtx = state.hasActiveContext ? state.activeContext : null;
    final activeCtxSection = activeCtx != null
        ? (isAr
            ? '''
[السياق النشط الحالي للشحنة (Active Shipment Context)]:
- معرف الشحنة (Shipment ID): ${activeCtx.shipmentId}
- كود الملف: ${activeCtx.fileCode}
- اسم الشحنة / العميل: ${activeCtx.displayText('ar')}
- المرحلة / الخطوة النشطة المحددة: (${activeCtx.stepId}) ${activeCtx.stepName('ar')}
- الشاشة المرتبطة: ${activeCtx.screenReference ?? '-'}
* قاعدة التنفيذ الإلزامية: إذا طلب المستخدم استعلاماً أو تسجيلاً دون ذكر شحنة أخرى صراحة، استخدم هذا السياق النشط مباشرة كمعرف الشحنة (${activeCtx.shipmentId}) دون سؤال المستخدم.'''
            : '''
[Active Shipment Context]:
- Shipment ID: ${activeCtx.shipmentId}
- File Code: ${activeCtx.fileCode}
- Shipment / Client: ${activeCtx.displayText('en')}
- Active Step: (${activeCtx.stepId}) ${activeCtx.stepName('en')}
- Associated Screen: ${activeCtx.screenReference ?? '-'}
* Mandatory Rule: If the user requests an action or query without specifying another shipment, use this active context as the target shipment (${activeCtx.shipmentId}) without asking for clarification.''')
        : (isAr
            ? '''
[السياق النشط الحالي]: لا يوجد سياق شحنة محدد حالياً (No active context).
* إذا طلب المستخدم تسجيلاً أو تحديثاً دون ذكر أي شحنة بالاسم أو بالكود، توقف واطلب منه تحديد الشحنة المطلوبة.'''
            : '''
[Active Context]: No active shipment context.
* If the user requests an action or update without specifying any shipment name or file code, ask them to clarify which shipment they mean.''');

    final contextualPrompt = '''
$languageDirective

$activeCtxSection

[${isAr ? 'بيانات تشغيلية حية ومباشرة من قاعدة بيانات المنظومة' : 'Live operational data directly from Sorour Logistics ERP database'}]:
$liveData

[${isAr ? 'شاشة المستخدم الحالية' : 'Current user screen'}]: ${state.currentScreenContext}

[${isAr ? 'سؤال المستخدم' : 'User Query'}]:
$trimmedText

${isAr ? '''توجيهات الإجابة التنفيذية الإلزامية:
1. عند وجود [السياق النشط الحالي للشحنة] وطلب المستخدم تسجيلاً أو استعلاماً دون ذكر شحنة أخرى، نفّذ المطلوب على الشحنة النشطة فوراً.
2. عند إتمام عملية كتابة بنجاح (Write Operation) لخطوة، اختم ردك دائماً بسؤال المستخدم:
   "✅ اكتملت بيانات [اسم الخطوة]. هل تريد الانتقال إلى [اسم الخطوة التالية]؟"
3. عند سؤال المستخدم عن "المهام العاجلة" أو "أولويات اليوم" أو "ما المطلوب إنجازه؟" أو "لوحة التحكم":
   - اعرض فوراً المهام التشغيلية الحقيقية المذكورة في قسم [قوائم المهام التشغيلية المنسقة للشحنات] أعلاه.
   - يُحظر تماماً تقديم خطة عمل نظرية عامة أو نصائح مدرسية عن خطوات الاستيراد ما لم يطلب المستخدم ذلك صراحة.
4. عند سؤال المستخدم عن أمر شراء أو ملف شحنة أو مورد أو ACID معين، استخرج أرقامه وبياناته الحقيقية فوراً من البيانات الحية أعلاه.
5. عند عرض أو استعراض مهام الشحنات، التزم بدقة بالمواصفة القياسية الموحدة ذات القواعد الثمانية:
   * سطر التنبيه أولاً إذا وجدت مهام متأخرة: ⚠️ N مهام متأخرة منذ X أيام — شحنة [الاسم] – [العميل] ([كود الملف]).
   * نسبة الإنجاز وشريط التقدم البصري المكون من 10 خانات (مثال: نسبة الإنجاز: 🟡 40% (4 من 10 خطوة مكتملة) ▓▓▓▓░░░░░░).
   * الترتيب الصارم: متأخرة: ثم مستحقة اليوم: ثم قادمة: مرتبة تصاعدياً حسب تاريخ الاستحقاق.
   * أيقونة الأولوية قبل كل عنوان مهمة: 🔴 حرجة، 🟠 عالية، 🟡 متوسطة، 🟢 منخفضة/مكتملة.
   * كشف التكرار مع التحذير: ⚠️ يبدو تكرار بين هاتين المهمتين — برجاء التأكد من النظام.
   * سطر إجراء تالٍ محدد وواضح يختم القائمة: المطلوب منك الآن: [البيان الناقص] عشان نقفل [اسم المهمة].
   * يُمنع استخدام أكواد TSK أو جداول بأكثر من 3 أعمدة.
   * يمكنك اعتماد القوالب الجاهزة من قسم [قالب مهام الشحنة ...] المذكورة أعلاه لضمان التطابق الكامل.''' : '''Mandatory Operational Response Guidelines:
1. When [Active Shipment Context] is present and user requests an update/query without naming another shipment, execute it directly on the active shipment.
2. Upon completing any write operation, conclude your reply by asking:
   "✅ [Step name] completed. Would you like to proceed to [Next step name]?"
3. When asked about "urgent tasks", "today's priorities", or "what needs to be done":
   - Present the real operational tasks listed in the live shipment tasks section above.
   - Do NOT provide generic theoretical textbook advice about importing.
4. When asked about a purchase order, shipment file, supplier, or ACID, extract real live numbers directly.
5. Adhere strictly to the 8-rule output specification:
   * Status-first alert line if overdue: ⚠️ N task(s) overdue since X days — shipment [Name] – [Client] ([FileCode]).
   * Completion indicator with 10-block progress bar (e.g. Completion Rate: 🟡 40% (4 of 10 steps completed) ▓▓▓▓░░░░░░).
   * Strict section order: Overdue: then Due today: then Upcoming: sorted ascending by due date.
   * Priority icons before task titles: 🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low/Done.
   * Flag near-duplicates: ⚠️ Potential duplicate between these tasks — please verify in the system.
   * Conclude with single clear next action: What is needed now: [missing input] in order to close [task name].
   * Never display TSK codes or markdown tables >3 columns.
   * PRESERVE ALL CONTAINER NUMBERS, SEALS, BOOKINGS, ACID, FILE CODES, AND DATES AS-IS.'''}
''';

    // Model candidate list: starting with the current model, then remaining supported models
    final candidateModels = <String>[
      _currentModelName,
      ...kSupportedModels.where((m) => m != _currentModelName),
    ];

    String? lastErrorMessage;
    bool isOverloaded = false;
    bool didPerformWrite = false;

    for (int i = 0; i < candidateModels.length; i++) {
      final modelToTry = candidateModels[i];
      try {
        if (_model == null || _chatSession == null || _currentModelName != modelToTry) {
          await _initModel(state.apiKey!, modelName: modelToTry);
        }

        var response = await _chatSession!.sendMessage(
          Content.text(contextualPrompt),
        );

        // ── Agent Execution Multi-Turn Loop (Zero-Hallucination & RAW Verification) ──
        int turnCount = 0;
        const maxTurns = 8;
        final executor = ref.read(aiAgentToolExecutorProvider);

        while (response.functionCalls.isNotEmpty && turnCount < maxTurns) {
          turnCount++;
          final functionResponses = <FunctionResponse>[];

          for (final call in response.functionCalls) {
            if (call.name == 'update_container_allocation' ||
                call.name == 'create_or_update_booking' ||
                call.name == 'skip_step' ||
                call.name == 'register_pending_reference') {
              didPerformWrite = true;
            }

            final result = await executor.execute(
              call.name,
              call.args,
              activeShipmentId: state.activeContext?.shipmentId,
            );
            functionResponses.add(FunctionResponse(call.name, result));
          }

          response = await _chatSession!.sendMessage(
            Content.functionResponses(functionResponses),
          );
        }

        // Live Auto-Refresh Riverpod State upon any write
        if (didPerformWrite) {
          ref.invalidate(importFilesProvider);
          ref.invalidate(purchaseOrdersProvider);
          ref.invalidate(smartTasksProvider);
          ref.invalidate(lifecycleBoardSummaryProvider);
          ref.invalidate(stepConfigProvider);
          try {
            ref.invalidate(acidTrackerProvider);
          } catch (_) {}
        }

        final reply = response.text ?? 'تم تنفيذ العملية بنجاح.';
        if (!mounted) return;
        state = state.copyWith(isLoading: false);
        _addMessage(reply, MessageSender.assistant);
        return; // Success! Return immediately
      } on GenerativeAIException catch (e) {
        lastErrorMessage = e.message;
        final lower = e.message.toLowerCase();
        final isServerIssue = lower.contains('503') ||
            lower.contains('high demand') ||
            lower.contains('unavailable') ||
            lower.contains('overloaded') ||
            lower.contains('resource exhausted') ||
            lower.contains('quota') ||
            lower.contains('429') ||
            lower.contains('not found') ||
            lower.contains('not supported') ||
            lower.contains('no longer available') ||
            lower.contains('404');

        if (isServerIssue) {
          if (lower.contains('503') || lower.contains('high demand') || lower.contains('unavailable')) {
            isOverloaded = true;
          }
          // Delay briefly and attempt the next model in the candidate chain
          if (i + 1 < candidateModels.length) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
        }
        break;
      } catch (e) {
        lastErrorMessage = e.toString();
        if (i + 1 < candidateModels.length) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        break;
      }
    }

    if (!mounted) return;
    state = state.copyWith(isLoading: false);

    // Provide friendly, actionable Arabic message instead of raw JSON dump
    if (isOverloaded || (lastErrorMessage != null && (lastErrorMessage.contains('503') || lastErrorMessage.contains('high demand')))) {
      _addMessage(
        'تشهد خوادم الذكاء الاصطناعي ضغطاً وتشبعاً مؤقتاً بالطلبات. تم تجربة عدة نماذج بديلة تلقائياً. يُرجى إعادة المحاولة بعد لحظات قليلة.',
        MessageSender.assistant,
        isError: true,
      );
    } else {
      _addMessage(
        'تعذر الحصول على رد من المساعد الذكي. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        MessageSender.assistant,
        isError: true,
      );
    }
  }

  void _addMessage(String text, MessageSender sender, {bool isError = false}) {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
      isError: isError,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>(
  (ref) => AiAssistantNotifier(ref),
);
