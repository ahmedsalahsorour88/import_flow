import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/import_files/providers/import_files_provider.dart';
import '../../features/purchase_orders/providers/purchase_orders_provider.dart';
import '../../features/import_documentation/providers/import_documentation_provider.dart';
import '../../features/smart_tasks/providers/smart_tasks_provider.dart';

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

  const AiAssistantState({
    this.isPanelOpen = false,
    this.isLoading = false,
    this.messages = const [],
    this.currentScreenContext = 'الشاشة الرئيسية',
    this.apiKey,
    this.hasApiKey = false,
  });

  AiAssistantState copyWith({
    bool? isPanelOpen,
    bool? isLoading,
    List<ChatMessage>? messages,
    String? currentScreenContext,
    String? apiKey,
    bool clearApiKey = false,
    bool? hasApiKey,
  }) {
    return AiAssistantState(
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      currentScreenContext: currentScreenContext ?? this.currentScreenContext,
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }
}

// ─── Quick Suggestions ─────────────────────────────────────────────────────────

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

const List<QuickSuggestion> kQuickSuggestions = [
  QuickSuggestion(
    label: 'أولويات اليوم',
    prompt: 'ما هي المهام التشغيلية العاجلة وأولويات اليوم المجدولة لشحناتنا في النظام؟',
    icon: Icons.checklist_rtl_rounded,
  ),
  QuickSuggestion(
    label: 'مراحل الاستيراد',
    prompt: 'اشرح لي مراحل عملية الاستيراد من البداية للنهاية في نظام ImportFlow',
    icon: Icons.alt_route_outlined,
  ),
  QuickSuggestion(
    label: 'محرك الجمارك',
    prompt: 'كيف يتم حساب الضرائب الجمركية المصرية؟ اشرح تسلسل الحساب',
    icon: Icons.calculate_outlined,
  ),
  QuickSuggestion(
    label: 'مستندات الاستيراد',
    prompt: 'ما هي المستندات المطلوبة لعملية الاستيراد من الخارج إلى مصر؟',
    icon: Icons.description_outlined,
  ),
  QuickSuggestion(
    label: 'CBM والأوزان',
    prompt: 'كيف أحسب الـ CBM والوزن الحجمي للشحنة؟',
    icon: Icons.straighten_outlined,
  ),
  QuickSuggestion(
    label: 'Incoterms 2020',
    prompt: 'ما الفرق بين FOB و CIF و EXW في شروط Incoterms 2020؟',
    icon: Icons.swap_horiz_outlined,
  ),
  QuickSuggestion(
    label: 'منظومة نافذة',
    prompt: 'ما هي منظومة نافذة ومتطلبات تسجيل ACID للاستيراد المصري؟',
    icon: Icons.cloud_outlined,
  ),
];

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
      systemInstruction: Content.system(
        '''أنت مساعد استيراد ذكي ومهندس لوجستيات تنفيذي في نظام ImportFlow ERP لإدارة عمليات الاستيراد والتخليص الجمركي المصري والشحن وسلاسل الإمداد.

قواعد الإجابة الأساسية والإلزامية:
1. كن فائق الدقة، عملياً ومباشراً، وقدم الأرقام والبيانات الحقيقية للشحنات وأوامر الشراء والمهام المسجلة بالنظام والمرفقة معك في سياق المحادثة.
2. عندما يسألك المستخدم عن "المهام العاجلة"، "أولويات اليوم"، أو "ما المطلوب إنجازه اليوم؟"، استخرج واعرض فوراً جدولاً أو قائمة بالمهام الحقيقية المذكورة في قسم [المهام التشغيلية العاجلة] وقسم [الإجراء التالي المطلوب لملفات الشحنات] مع ذكر درجات الأولوية (حرجة، عالية) ومواعيد الاستحقاق والشحنات المرتبطة. يُحظر تماماً كتابة نصائح عامة أو خطط نظرية.
3. عندما يسألك المستخدم عن أي أمر شراء أو شحنة أو مورد أو رقم ACID (مثل PET Stock أو YH20260730-6 أو NCIC)، ابحث فوراً في البيانات الحية المرفقة واستخرج بياناته المحددة (رقم أمر الشراء التجاري الحقيقي، ملف الشحنة، المورد، المستورد، القيمة، المتبقي في ACID، المرحلة التنفيذية) وأجب بها بشكل مركز ومحدد فوراً.
4. يُحظر تماماً الرد بنصائح عامة أو نظرية مثل "ابحث في الشاشة" أو "اكتب في خانة البحث" أو سرد تعريفات المراحل ما لم يطلب المستخدم شرحاً نظرياً صريحاً.
5. استخدم تنسيق الجداول أو القوائم النقطية الواضحة للأرقام والتواريخ لتسهيل القراءة والمتابعة.
6. أجب دائماً بالعربية الفصحى البسيطة أو المصرية المهنية المناسبة لقطاع اللوجستيات والاستيراد.''',
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
                text: 'مرحباً! أنا مساعد الاستيراد الذكي في ImportFlow. كيف أقدر أساعدك في عمليات الاستيراد والتخليص الجمركي؟',
                sender: MessageSender.assistant,
                timestamp: DateTime.now(),
              ),
            ]
          : null,
    );
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

  String _buildLiveDatabaseContext() {
    final buffer = StringBuffer();

    // 1. Smart Tasks (المهام التشغيلية العاجلة وأولويات اليوم)
    try {
      final taskList = ref.read(smartTasksProvider).tasks;
      if (taskList.isNotEmpty) {
        final pendingTasks = taskList.where((t) => t.status != 'Completed' && t.status != 'Cancelled').toList();
        buffer.writeln('=== المهام التشغيلية العاجلة وأولويات اليوم المسجلة في النظام (${pendingTasks.length} مهمة معلقة) ===');
        for (final t in pendingTasks.take(15)) {
          final prio = t.priority;
          final title = t.title;
          final code = t.taskCode;
          final due = t.dueDate ?? 'اليوم';
          final fCode = t.importFileCode ?? (t.importFileId != null ? 'IMP-${t.importFileId}' : '-');
          final user = t.assignedUser;
          buffer.writeln('- مهمة [$code] (أولوية: $prio): "$title" | الشحنة المرتبطة: $fCode | الاستحقاق: $due | المسؤول: $user');
        }
      }
    } catch (_) {}

    try {
      final pos = ref.read(purchaseOrdersProvider).purchaseOrders;
      if (pos.isNotEmpty) {
        buffer.writeln('\n=== أوامر الشراء المسجلة حالياً في النظام (${pos.length} أمر شراء) ===');
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
          buffer.writeln('- أمر الشراء: "$refName" (كود السيستم: $poCode) | الفاتورة المبدئية: $pi | المورد: $supp | المستورد: $comp | القيمة: $amt | الحجم والوزن: $cbm / $wt | الحالة: $st | ملف الشحنة: $file');
        }
      }
    } catch (_) {}

    try {
      final files = ref.read(importFilesProvider).value ?? [];
      if (files.isNotEmpty) {
        buffer.writeln('\n=== ملفات الشحنات والاستيراد الحالية (${files.length} ملف) ===');
        for (final f in files.take(20)) {
          final fName = f.displayName;
          final fCode = f.importFileCode;
          final po = f.poNumber ?? '-';
          final pi = f.piNumber ?? '-';
          final supp = f.supplierName;
          final comp = f.companyName;
          final stage = f.currentStage;
          final acid = f.acidNumber ?? 'غير مسجل بعد';
          final eta = f.requiredEta ?? '-';
          final pol = f.portOfLoading ?? '-';
          final pod = f.portOfDischarge ?? '-';
          final mode = f.shipmentMode;
          final nextAction = f.nextAction.isNotEmpty ? f.nextAction : 'متابعة دورية';
          buffer.writeln('- ملف شحنة: "$fName" (كود: $fCode) | أمر الشراء: $po | الفاتورة: $pi | المورد: $supp | المستورد: $comp | المرحلة: $stage | الإجراء المطلوب القادم: "$nextAction" | ACID: $acid | الشحن: $mode من $pol إلى $pod | الوصول المتوقع: $eta');
        }
      }
    } catch (_) {}

    try {
      final tracker = ref.read(acidTrackerProvider).value;
      if (tracker != null && tracker.items.isNotEmpty) {
        buffer.writeln('\n=== متابعة أرقام ACID وصلاحياتها الجمركية ===');
        for (final a in tracker.items.take(15)) {
          buffer.writeln('- ACID: ${a.acidNumber} | ملف الشحنة: ${a.importFileCode} | المورد: ${a.supplierName} | المتبقي للصلاحية: ${a.daysRemaining} يوم | الحالة: ${a.status}');
        }
      }
    } catch (_) {}

    return buffer.toString();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (!state.hasApiKey || state.apiKey == null) {
      _addMessage(
        'يرجى إدخال Gemini API Key أولاً لتفعيل المساعد الذكي.',
        MessageSender.system,
        isError: true,
      );
      return;
    }

    // Add user message
    _addMessage(text.trim(), MessageSender.user);
    state = state.copyWith(isLoading: true);

    final liveData = _buildLiveDatabaseContext();
    final contextualPrompt = '''
[بيانات تشغيلية حية ومباشرة من قاعدة بيانات ImportFlow ERP]:
$liveData

[شاشة المستخدم الحالية]: ${state.currentScreenContext}

[سؤال المستخدم]:
$text

توجيهات الإجابة التنفيذية الإلزامية:
1. عند سؤال المستخدم عن "المهام العاجلة" أو "أولويات اليوم" أو "ما المطلوب إنجازه؟" أو "لوحة التحكم":
   - اعرض فوراً جدولاً أو قائمة بالمهام التشغيلية الحقيقية المذكورة في قسم [المهام التشغيلية العاجلة وأولويات اليوم المسجلة في النظام] وقسم [ملفات الشحنات - الإجراء المطلوب القادم].
   - اذكر كود المهمة، واسم المهمة، والأولوية (حرجة / عالية)، والشحنة المعنية (مثل PET Stock)، والإجراء الفعلي المطلوب تنفيذه اليوم.
   - يُحظر تماماً تقديم خطة عمل نظرية عامة أو نصائح مدرسية عن خطوات الاستيراد ما لم يطلب المستخدم ذلك صراحة.
2. عند سؤال المستخدم عن أمر شراء أو ملف شحنة أو مورد أو ACID معين، استخرج أرقامه وبياناته الحقيقية فوراً من البيانات الحية أعلاه.
''';

    // Model candidate list: starting with the current model, then remaining supported models
    final candidateModels = <String>[
      _currentModelName,
      ...kSupportedModels.where((m) => m != _currentModelName),
    ];

    String? lastErrorMessage;
    bool isOverloaded = false;

    for (int i = 0; i < candidateModels.length; i++) {
      final modelToTry = candidateModels[i];
      try {
        if (_model == null || _chatSession == null || _currentModelName != modelToTry) {
          await _initModel(state.apiKey!, modelName: modelToTry);
        }

        final response = await _chatSession!.sendMessage(
          Content.text(contextualPrompt),
        );
        final reply = response.text ?? 'لم أتلق ردًا، حاول مرة أخرى.';
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
        'تشهد خوادم الذكاء الاصطناعي (Google Gemini) ضغطاً وتشبعاً مؤقتاً بالطلبات (High Demand). تم تجربة عدة نماذج بديلة تلقائياً. يُرجى إعادة المحاولة بعد لحظات قليلة.',
        MessageSender.assistant,
        isError: true,
      );
    } else {
      _addMessage(
        'تعذر الحصول على رد من المساعد الذكي (${lastErrorMessage ?? "خطأ غير متوقع"}). يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
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
