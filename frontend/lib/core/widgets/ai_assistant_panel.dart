import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ai_assistant_provider.dart';
import '../../core/theme/app_theme.dart';

/// A persistent floating AI Import Assistant panel that overlays all screens.
/// Appears as a draggable button that opens a chat panel when tapped.
class AiAssistantOverlay extends ConsumerStatefulWidget {
  const AiAssistantOverlay({super.key});

  @override
  ConsumerState<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends ConsumerState<AiAssistantOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<double> _panelAnimation;
  late final Animation<double> _fadeAnimation;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _greetingDismissed = false;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _panelAnimation = CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic);
    _fadeAnimation = CurvedAnimation(parent: _panelController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _panelController.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePanel() {
    final notifier = ref.read(aiAssistantProvider.notifier);
    notifier.togglePanel();
    final isOpen = ref.read(aiAssistantProvider).isPanelOpen;
    if (isOpen) {
      _panelController.forward();
      Future.delayed(const Duration(milliseconds: 350), _scrollToBottom);
    } else {
      _panelController.reverse();
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    await ref.read(aiAssistantProvider.notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);

    // Sync animation when panel state changes externally
    if (state.isPanelOpen && _panelController.status == AnimationStatus.dismissed) {
      _panelController.forward();
    } else if (!state.isPanelOpen && _panelController.status == AnimationStatus.completed) {
      _panelController.reverse();
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // ── Chat Panel ──────────────────────────────────────────────────────
        if (state.isPanelOpen)
          Positioned(
            bottom: 80,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _panelAnimation,
                alignment: Alignment.bottomRight,
                child: _buildChatPanel(state),
              ),
            ),
          ),

        // ── Greeting Bubble (Exact match to user's uploaded image) ───────────
        if (!state.isPanelOpen && !_greetingDismissed)
          Positioned(
            bottom: 80,
            right: 16,
            child: _buildGreetingBubble(),
          ),

        // ── Floating Button (Orange circular button with chat icon) ──────────
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildFloatingButton(state),
        ),
      ],
    );
  }

  // ─── Greeting Bubble ────────────────────────────────────────────────────────

  Widget _buildGreetingBubble() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hello',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _greetingDismissed = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _togglePanel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Here to help - Feedback,\nChat.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Flexible(
                        child: Text(
                          'مساعد الاستيراد الذكي متصل',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.cobalt,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ─── Floating Button ────────────────────────────────────────────────────────

  Widget _buildFloatingButton(AiAssistantState state) {
    return Tooltip(
      message: state.isPanelOpen ? 'إغلاق المساعد الذكي' : 'مساعد الاستيراد الذكي — AI',
      preferBelow: false,
      child: GestureDetector(
        onTap: _togglePanel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: state.isPanelOpen ? 48 : 56,
          height: state.isPanelOpen ? 48 : 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: state.isPanelOpen
                  ? [AppTheme.charcoal, const Color(0xFF1E293B)]
                  : [const Color(0xFFF4511E), const Color(0xFFE64A19)], // Exact vibrant orange from image
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (state.isPanelOpen ? AppTheme.charcoal : const Color(0xFFE64A19))
                    .withOpacity(0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                state.isPanelOpen ? Icons.close_rounded : Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: state.isPanelOpen ? 20 : 24,
              ),
              // Loading indicator ring
              if (state.isLoading)
                Positioned.fill(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              // Online green badge
              if (!state.isPanelOpen)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  // ─── Chat Panel ─────────────────────────────────────────────────────────────

  Widget _buildChatPanel(AiAssistantState state) {
    return Container(
      width: 360,
      height: 520,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildPanelHeader(state),
            Expanded(
              child: state.hasApiKey
                  ? _buildMessageList(state)
                  : _buildApiKeySetup(),
            ),
            if (state.hasApiKey) _buildInputBar(state),
          ],
        ),
      ),
    );
  }

  // ─── Panel Header ────────────────────────────────────────────────────────────

  Widget _buildPanelHeader(AiAssistantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.cobalt, Color(0xFF2980B9)],
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.cobalt.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مساعد الاستيراد الذكي',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  state.currentScreenContext,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Clear chat
          if (state.hasApiKey && state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 16),
              tooltip: 'مسح المحادثة',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => ref.read(aiAssistantProvider.notifier).clearChat(),
            ),
          const SizedBox(width: 8),
          // API Key settings
          IconButton(
            icon: const Icon(Icons.key_outlined, color: Colors.white70, size: 16),
            tooltip: 'إعدادات API Key',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showApiKeyDialog(state.apiKey),
          ),
          const SizedBox(width: 4),
          // Close
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
            tooltip: 'إغلاق',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _togglePanel,
          ),
        ],
      ),
    );
  }

  // ─── Message List ───────────────────────────────────────────────────────────

  Widget _buildMessageList(AiAssistantState state) {
    if (state.messages.isEmpty) {
      return _buildWelcomeScreen();
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == state.messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(state.messages[i]);
      },
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'اقتراحات سريعة',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kQuickSuggestions.map((s) => _buildSuggestionChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(QuickSuggestion s) {
    return GestureDetector(
      onTap: () => _sendMessage(s.prompt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.cobalt.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(s.icon, size: 13, color: AppTheme.cobalt),
            const SizedBox(width: 5),
            Text(
              s.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.cobalt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;
    final isSystem = msg.sender == MessageSender.system;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: msg.isError ? AppTheme.crimson.withOpacity(0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: msg.isError ? AppTheme.crimson.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              msg.isError ? Icons.error_outline : Icons.info_outline,
              size: 13,
              color: msg.isError ? AppTheme.crimson : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 12,
                  color: msg.isError ? AppTheme.crimson : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 40 : 0,
          right: isUser ? 0 : 40,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.cobalt : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 12.5,
            color: isUser ? Colors.white : AppTheme.charcoal,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(150),
            const SizedBox(width: 4),
            _dot(300),
          ],
        ),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppTheme.cobalt.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // ─── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar(AiAssistantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              focusNode: _focusNode,
              enabled: !state.isLoading,
              maxLines: 3,
              minLines: 1,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'اسألني عن الاستيراد، الجمارك، الشحن...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppTheme.cobalt),
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onSubmitted: (v) => _sendMessage(v),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: state.isLoading ? null : () => _sendMessage(_inputCtrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: state.isLoading ? Colors.grey.shade300 : AppTheme.cobalt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: state.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  // ─── API Key Setup ──────────────────────────────────────────────────────────

  Widget _buildApiKeySetup() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.key_rounded, color: AppTheme.cobalt, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'فعّل المساعد الذكي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل Gemini API Key الخاص بك لبدء الدردشة مع مساعد الاستيراد الذكي.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showApiKeyDialog(null),
            icon: const Icon(Icons.key_outlined, size: 16),
            label: const Text('إدخال API Key'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cobalt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              // Open Gemini AI Studio link in browser context
            },
            icon: Icon(Icons.open_in_new, size: 13, color: Colors.grey.shade500),
            label: Text(
              'احصل على API Key من Google AI Studio',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ─── API Key Dialog ─────────────────────────────────────────────────────────

  void _showApiKeyDialog(String? currentKey) {
    final ctrl = TextEditingController(text: currentKey ?? '');
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: AppTheme.cobalt, size: 20),
              SizedBox(width: 10),
              Text('Gemini API Key'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أدخل Gemini API Key من Google AI Studio (aistudio.google.com)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'AIzaSy...',
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 16,
                      ),
                      onPressed: () => setLocal(() => obscure = !obscure),
                    ),
                  ),
                ),
                if (currentKey != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'API Key محفوظ مسبقاً',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (currentKey != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(aiAssistantProvider.notifier).clearApiKey();
                },
                style: TextButton.styleFrom(foregroundColor: AppTheme.crimson),
                child: const Text('حذف الـ Key'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(aiAssistantProvider.notifier).saveApiKey(ctrl.text);
              },
              child: const Text('حفظ وتفعيل'),
            ),
          ],
        ),
      ),
    );
  }
}
