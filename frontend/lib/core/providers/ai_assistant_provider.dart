import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    bool? hasApiKey,
  }) {
    return AiAssistantState(
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      currentScreenContext: currentScreenContext ?? this.currentScreenContext,
      apiKey: apiKey ?? this.apiKey,
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
  GenerativeModel? _model;
  ChatSession? _chatSession;
  static const _apiKeyPref = 'importflow_gemini_api_key';

  AiAssistantNotifier() : super(const AiAssistantState()) {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_apiKeyPref);
      if (key != null && key.isNotEmpty) {
        await _initModel(key);
      }
    } catch (_) {}
  }

  Future<void> _initModel(String apiKey) async {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        '''أنت مساعد استيراد ذكي متخصص في نظام ImportFlow ERP لإدارة عمليات الاستيراد والتخليص الجمركي المصري.

تخصصاتك:
- عمليات الاستيراد والتصدير المصرية
- التخليص الجمركي والتعريفة الجمركية المصرية (HS Codes)
- حساب الضرائب والرسوم الجمركية (Import Duty, VAT, Schedule Tax)
- Incoterms 2020 وشروط التسليم
- منظومة نافذة ومتطلبات ACID
- النقل البحري والجوي والبري وحساب CBM
- خطابات الاعتماد والمستندات البنكية
- شروط الدفع وعمليات التمويل

أجب دائماً بالعربية. كن محدداً وعملياً. إذا كان السؤال خارج نطاق الاستيراد واللوجستيات، وجّه المستخدم بلطف.''',
      ),
    );
    _chatSession = _model!.startChat();
    state = state.copyWith(
      apiKey: apiKey,
      hasApiKey: true,
      messages: [
        ChatMessage(
          id: 'welcome',
          text: 'مرحباً! أنا مساعد الاستيراد الذكي في ImportFlow. كيف أقدر أساعدك في عمليات الاستيراد والتخليص الجمركي؟',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> saveApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey.trim());
    await _initModel(apiKey.trim());
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPref);
    _model = null;
    _chatSession = null;
    state = state.copyWith(
      apiKey: null,
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

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (!state.hasApiKey || _chatSession == null) {
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

    try {
      // Add screen context to the prompt
      final contextualPrompt =
          '[السياق: المستخدم حالياً في شاشة "${state.currentScreenContext}"]\n$text';

      final response = await _chatSession!.sendMessage(
        Content.text(contextualPrompt),
      );
      final reply = response.text ?? 'لم أتلق ردًا، حاول مرة أخرى.';
      state = state.copyWith(isLoading: false);
      _addMessage(reply, MessageSender.assistant);
    } on GenerativeAIException catch (e) {
      state = state.copyWith(isLoading: false);
      _addMessage(
        'خطأ في Gemini API: ${e.message}',
        MessageSender.assistant,
        isError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _addMessage(
        'خطأ غير متوقع: $e',
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
  (ref) => AiAssistantNotifier(),
);
